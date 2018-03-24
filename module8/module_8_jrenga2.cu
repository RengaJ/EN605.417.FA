/// Module 08 Assignment : NVidia GPU Accelerated Libraries Part 1
///
/// Author: Justin Renga
///
/// Date: March 21st, 2018
///
/// Purpose: This homework assignment is intended to show the usage of two
///          of the accelerated libraries showcased during this weeks lectures:
///            o cuFFT
///            o cuBLAS
///            o cuSPARSE
///            o cuSOLVER
///            o cuRAND
///
///          This implementation will utilize the cuRAND and cuSOLVER accelerated
///          libraries.

/// ------------------------------- FILE INCLUDES -------------------------------

// Include system files
#include <time.h>
#include <stdio.h>
#include <stdlib.h>

// Include the cuFFT file
#include <cufft.h>

// Include the cuRAND files
#include <curand.h>
#include <curand_kernel.h>

// Include the utility functions file (custom)
#include "module_8_jrenga2_utility.h"

/// ---------------------------- CONSTANT DEFINITIONS ---------------------------

#define THREAD_MIN 1
#define THREAD_MAX 4096

#define UINT_SIZE sizeof(unsigned int)
#define FLOAT_SIZE sizeof(float)
#define SAMPLE_SIZE 256
#define FLOAT2_SIZE sizeof(float2)

/// ---------------------------- GLOBAL DEFINITIONS -----------------------------
unsigned int initializedRNG;

/// ----------------------------- DEVICE OPERATIONS -----------------------------

__global__ void initializeCURAND(const unsigned int seed, curandState_t* stateList)
{
  // Initialize the cuRAND random-number generator on the device side.
  // Arguments into the curand_init function are as follows:
  //  1. The seed        - this is used to initialize pseudo-random generator
  //  2. The subsequence - the subsequence to start at
  //  3. The offset      - the number of values into the sequence that will be skipped upon
  //                       initialization
  //  4. The state       - The state pointer to initialize
  
  // In this case, each thread will have the same seed, but each core will have a different subsequence
  // of random numbers
  curand_init(seed, blockIdx.x, 0, &stateList[blockIdx.x]);
}

__global__ void generateRandom(unsigned int* result, curandState_t* stateList)
{
  unsigned int threadIndex = (blockIdx.x * blockDim.x) + threadIdx.x;
  
  unsigned int count = 0;
  float value = 0.0;
  
  curandState_t localState = stateList[blockIdx.x];
  
  for (unsigned int i = 0; i < SAMPLE_SIZE; ++i)
  {
    value = curand_uniform(&localState);
    
    if (value > 0.5)
    {
      ++count;
    }
  }
  
  stateList[blockIdx.x] = localState;
  result[threadIndex]   = count;
}

__global__ void addComplexNumbers(float2* complexA, float2* complexB)
{
  const unsigned int threadIndex = (blockIdx.x * blockDim.x) + threadIdx.x;
  
  const unsigned int indexBase = 2 * threadIndex;
  
  complexA[indexBase].x = complexA[indexBase].x + complexB[indexBase].x;
  complexA[indexBase].y = complexA[indexBase].y + complexB[indexBase].y;
  
  complexA[indexBase + 1].x = complexA[indexBase + 1].x + complexB[indexBase + 1].x;
  complexA[indexBase + 1].y = complexA[indexBase + 1].y + complexB[indexBase + 1].y;
}

/// ------------------------------ HOST OPERATIONS ------------------------------

// @brief Initialize the Random number generator and ensure it only initializes one time
__host__ void initializeRandomNumbers()
{
  if (initializedRNG == 0)
  {
    srand(time(NULL));
    initializedRNG = 1;
  }
}

// @brief Generates a series of random numbers for the provided array, given the number of desired numbers
//        and the maximum (exclusive) value.
//
// @param [inout] data         The data array that will contain the random numbers
// @param [   in] elementCount The number of elements to store in the data array
// @param [   in] max          The maximum random number to use (exclusive)
__host__ void generateRandomNumbers(            float2* data,
                                    const unsigned int  elementCount,
                                    const unsigned int  max)
{
  // Check to make sure the RNG has been initialized
  if (initializedRNG == 0)
  {
    // If not, initialize the RNG
    initializeRandomNumbers();
  }
  
  float division = max / (float)RAND_MAX;
  
  // Generate random data between 0 and the provided maximum value
  for (unsigned int i = 0; i < elementCount; ++i)
  {
    data[i].x = rand() * division;
    
    // The imaginary component of the complex number will be set to zero
    data[i].y = 0;
  }
}

/// ============================== cuFFT OPERATIONS =============================
__host__ void executeFFT(const int blockCount, const int threadCount)
{
  // Obtain the element and device counts
  unsigned int elementCount = blockCount * threadCount * 2;
  unsigned int deviceSize   = elementCount * FLOAT2_SIZE;
  
  // Allocate the memory for the complex numbers (on the host)
  float2* hostComplex_A = (float2*) malloc(deviceSize);
  float2* hostComplex_B = (float2*) malloc(deviceSize);
  
  // Fill the complex numbers with data
  generateRandomNumbers(hostComplex_A, elementCount, deviceSize);
  generateRandomNumbers(hostComplex_B, elementCount, deviceSize);
  
  // Create the cuFFT complex data arrays (on the device)
  cufftComplex* deviceComplex_A;
  cufftComplex* deviceComplex_B;
  
  cudaMalloc((void**)&deviceComplex_A, deviceSize);
  cudaMalloc((void**)&deviceComplex_B, deviceSize);
  
  // Perform the memory copy from host to device
  cudaMemcpy(deviceComplex_A, hostComplex_A, deviceSize, cudaMemcpyHostToDevice);
  cudaMemcpy(deviceComplex_B, hostComplex_B, deviceSize, cudaMemcpyHostToDevice);
  
  // Create the handle to the cuFFT plan (and create the plan)
  // -- The plan to be created will be a 1-D plan with a
  //    Complex --> Complex transform type using single precision --
  cufftHandle fftPlanHandle;
  cufftPlan2d(&fftPlanHandle, blockCount, threadCount * 2, CUFFT_C2C);
  
  // Create the timing events (one set for forward transform, one set for
  // inverse transform)
  cudaEvent_t startForwardEvent;
  cudaEvent_t startInverseEvent;
  cudaEvent_t stopForwardEvent;
  cudaEvent_t stopInverseEvent;
  
  cudaEventCreate(&startForwardEvent);
  cudaEventCreate(&startInverseEvent);
  cudaEventCreate(&stopForwardEvent);
  cudaEventCreate(&stopInverseEvent);
  
  // Perform the forward transformation (start the forward event recording)
  cudaEventRecord(startForwardEvent);
  
  // Perform an in-place transform of both complex arrays (forward)
  cufftExecC2C(fftPlanHandle, deviceComplex_A, deviceComplex_A, CUFFT_FORWARD);
  cufftExecC2C(fftPlanHandle, deviceComplex_B, deviceComplex_B, CUFFT_FORWARD);
  
  // Record the end of the forward transform
  cudaEventRecord(stopForwardEvent);
  cudaEventSynchronize(stopForwardEvent);
  
  // Perform the custom kernel operation
  addComplexNumbers<<<blockCount, threadCount>>>(deviceComplex_A, deviceComplex_B);
  
  // Perform the inverse transformation (start the inverse event recording)
  cudaEventRecord(startInverseEvent);
  
  // Perform the inverse transform of the first complex array
  cufftExecC2C(fftPlanHandle, deviceComplex_A, deviceComplex_A, CUFFT_INVERSE);
  
  // Record the end of the inverse transform
  cudaEventRecord(stopInverseEvent);
  cudaEventSynchronize(stopInverseEvent);
 
  // Copy the contents of the resulting signal back to the host
  cudaMemcpy(hostComplex_A, deviceComplex_A, deviceSize, cudaMemcpyDeviceToHost);
  
    // Get the duration between the two events
  float cufftForwardDuration_MS;
  float cufftInverseDuration_MS;
  cudaEventElapsedTime(&cufftForwardDuration_MS, startForwardEvent, stopForwardEvent);
  cudaEventElapsedTime(&cufftInverseDuration_MS, startInverseEvent, stopInverseEvent);
  
  printf("\tForward Duration: %f ms\tInverse Duration: %f ms\n",
    cufftForwardDuration_MS, cufftInverseDuration_MS);
  
  // Destroy the cuFFT Plan
  cufftDestroy(fftPlanHandle);

  // Free the device complex number memory
  cudaFree(deviceComplex_A);
  cudaFree(deviceComplex_B);
  
  // Free the host complex number memory
  free(hostComplex_A);
  free(hostComplex_B);
}  

/// ============================= cuRAND OPERATIONS =============================
__host__ void executeRandomNumbers(const int blockCount, const int threadCount)
{
  // Obtain the element and device counts
  unsigned int elementCount = blockCount * threadCount;
  unsigned int deviceSize   = elementCount * UINT_SIZE;
  
  // Allocate the host-side memory
  unsigned int* hostMemory = (unsigned int*) calloc(elementCount, UINT_SIZE);
  
  curandState_t* stateList;
  cudaMalloc((void**)&stateList, elementCount * sizeof(curandState_t));
  
  // Allocate the CUDA memory
  unsigned int* deviceMemory;
  cudaMalloc((void**)&deviceMemory, deviceSize);
  
  cudaMemset(deviceMemory, 0, deviceSize);
  
  // Create events to be used for timing purposes
  cudaEvent_t cuRandDevAPI_Start;
  cudaEvent_t cuRandDevAPI_Stop;
  
  cudaEventCreate(&cuRandDevAPI_Start);
  cudaEventCreate(&cuRandDevAPI_Stop);
  
  // Record the start event
  cudaEventRecord(cuRandDevAPI_Start);
  
  // Initialize cuRAND
  initializeCURAND<<<blockCount, 1>>>(time(NULL), stateList);
  
  // Invoke the RNG kernel
  generateRandom<<<blockCount, threadCount>>>(deviceMemory, stateList);

  // Perform the copy from the device to the host
  cudaMemcpy(hostMemory, deviceMemory, deviceSize, cudaMemcpyDeviceToHost);
  
  // Record the start event
  cudaEventRecord(cuRandDevAPI_Stop);
  cudaEventSynchronize(cuRandDevAPI_Stop);

  // Get the duration between the two events
  float cuRandDevAPI_DurationMS;
  cudaEventElapsedTime(&cuRandDevAPI_DurationMS, cuRandDevAPI_Start, cuRandDevAPI_Stop);
  
  unsigned int finalResult = 0;
  for (unsigned int i = 0; i < elementCount; ++i)
  {
    finalResult += hostMemory[i];
  }
  
  float distribution = (finalResult / (float)(elementCount * SAMPLE_SIZE)) * 100.0f;
  
  // Display the results:
  printf("\tRandom Duration: %2f ms -- Distribution %03.2f%%\n", cuRandDevAPI_DurationMS, distribution);
  
  // Free the host memory
  free(hostMemory);
  
  // Free the device memory
  cudaFree(deviceMemory);
  cudaFree(stateList);
}


/// @brief Display the proper way to invoke the program.
__host__ void showProgramUsage()
{
  printf("Invalid arguments provided. Please see the usage below:\n");
  printf("  module_8_jrenga2.exe <bc> <tpb>\n");
  printf("  bc  - The maximum number of blocks to run with. Must be a positive integer and a power of two.\n");
  printf("  tpb - The maximum number of threads per blocks. Must be a positive integer and a power of two.\n");
  printf("NOTE: The maximum number of threads (bc * tpb) must be greater than %d \n", THREAD_MIN);
  printf("      and less than %d.\n", THREAD_MAX);
  printf(" ** TERMINATING **\n");
}

/// @brief The main function that will be used to drive the program.
///
/// @param [in] argc    The number of arguments passed into the program
/// @param [in] argv    The actual arguments passed into the program
///
/// @return An integer indicating the state of the program upon execution. If
///         successful, this will return EXIT_SUCCESS Otherwise, it will return
///         EXIT_FAILURE.
int main(int argc, char* argv[])
{
  // Check the number of arguments to determine how the program should operate
  if (argc != 3)
  {
    // If the number of arguments is not exactly 3, show the program usage and terminate
    // with a failure.
    showProgramUsage();
    
    return EXIT_FAILURE;
  }
  
  // Extract the maximum number of blocks to be used for the duration of the program.
  int maximumBlocks = atoi(argv[1]);
  
  // Extract the maximum number of threads to be used for each block for the duration of the program.
  int maximumThreads = atoi(argv[2]);
  
  // Ensure that the provided maximum number of blocks (and threads) are:
  //   1. Valid numbers (positive integer)
  //   2. A power of two
  if ((maximumBlocks  <= 0 || !isPowerOfTwo(maximumBlocks) ) ||
      (maximumThreads <= 0 || !isPowerOfTwo(maximumThreads))   )
  {
    // If any of the above conditions are violated for either the maximum number of blocks or
    // the maximum number of threads per block, show the program usage and terminate with a
    // failure.
    showProgramUsage();
    
    return EXIT_FAILURE;
  }
  
  // Compute the current total of threads
  int totalThreads = maximumBlocks * maximumThreads;
  
  // Ensure that the total number of threads is between the minimum and maximum thread counts
  // (defined above as THREAD_MIN and THREAD_MAX)
  if (totalThreads < THREAD_MIN || totalThreads > THREAD_MAX)
  {
    // If the total number of threads exceeds the bounds (in either direction), show the
    // program usage and terminate with a failure.
    showProgramUsage();
    
    return EXIT_FAILURE;
  }
  
  printf("Random Numbers:\n\n");
  
  // Iterate from 1 -> numBlocks and 1 -> numThreads to perform metrics on numerous configurations
  for (unsigned int blockCount = 1; blockCount <= maximumBlocks; blockCount = blockCount << 1)
  {
    for (unsigned int threadCount = 1; threadCount <= maximumThreads; threadCount = threadCount << 1)
    {
      printf("Blocks: %3d\tThreads: %3d", blockCount, threadCount);
      executeRandomNumbers(blockCount, threadCount);
    }
  }
  
  printf("FFT:\n\n");
  
  // Iterate from 1 -> numBlocks and 1 -> numThreads to perform metrics on numerous configurations
  for (unsigned int blockCount = 1; blockCount <= maximumBlocks; blockCount = blockCount << 1)
  {
    for (unsigned int threadCount = 1; threadCount <= maximumThreads; threadCount = threadCount << 1)
    {
      printf("Blocks: %3d\tThreads: %3d", blockCount, threadCount);
      executeFFT(blockCount, threadCount);
    }
  }
  
  // Reset the device to its original state
  cudaDeviceReset();
  
  return EXIT_SUCCESS;
}