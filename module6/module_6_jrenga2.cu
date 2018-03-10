/// Assignment 06: Local Register Memory
///
/// Author: Justin Renga

/// Two Kernels -- Same Operation
///
/// Operation: Take an integer (randomly generated) from two input arrays,
///            take their modulo (input1 % input2) and store the result.
///
/// Kernel 1: Use the global memory to perform the operation (using local memory as an
///           intermediate.

/// Kernel 2: Transfer the data from global memory to local memory, perform the operation,
///           then transfer back to global memory

// Bibliography (source-list):
// [1] register.cu
// [2] http://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__EVENT.html
// [3] https://devblogs.nvidia.com/how-implement-performance-metrics-cuda-cc/

#include <time.h>
#include <stdio.h>
#include <stdlib.h>

// Declare constant definitions here
#define UINT_SIZE sizeof(unsigned int)
#define INITIAL_DATA 0
#define THREAD_MIN 64
#define THREAD_MAX 4096

// Declare device constant memory here
__constant__ static unsigned int ADDITIVE_VALUES[16];

// Declare global host data here:
unsigned int initializedRNG;

// ---------------------------------------- DEVICE OPERATIONS -----------------------------------------

/// @brief GPU Kernel that utilizes only global data to perform a simple modular division operation. To
///        be used on conjunction with localModularDivide for comparison metrics. Algorithm performed:
///        output = input1 % input2
///
/// @param [ in] input1    The first of the two input arrays to be used in the modular division operation
/// @param [ in] input2    The second of the two input arrays to be used in the modular division operation
/// @param [out] output    The array containing the results of the modular division operation
__global__ void globalModularDivide(const unsigned int* const input1,
                                    const unsigned int* const input2,
                                          unsigned int* const output)
{
  // Compute the current thread index
  unsigned int thread_index = (blockIdx.x * blockDim.x) + threadIdx.x;
  
  // Perform the modular operation and store in the output array (without using local memory)
  output[thread_index] = input1[thread_index] % input2[thread_index];
}

/// @brief GPU Kernel that offloads the computations from global data completely, then re-inserts
///        the data back into global memory. To be used with globalModularDivide for comparison metrics.
///        Algorithm performed: output = input1 % input2
///
/// @param [ in] input1    The first of the two input arrays to be used in the modular division operation
/// @param [ in] input2    The second of the two input arrays to be used in the modular division operation
/// @param [out] output    The array containing the results of the modular division operation
__global__ void localModularDivide(const unsigned int* const input1,
                              const unsigned int* const input2,
                                    unsigned int* const output)
{
  // Compute the current thread index
  unsigned int thread_index = (blockIdx.x * blockDim.x) + threadIdx.x;
  
  // Create local registers to store the intermediate data for the algorithm
  unsigned int input1_local = input1[thread_index];
  unsigned int input2_local = input2[thread_index];
  
  // Create a local register that will store the result of the algorithm
  unsigned int output_local = input1_local % input2_local;
  
  // Store the result of the algorithm into the global array
  output[thread_index] = output_local;
}

__global__ void add_values_shared(unsigned int* deviceData, const unsigned int elementCount)
{
  // Declare externally defined shared memory
  __shared__ unsigned int sharedMemory[THREAD_MAX];
  
  // Compute the current thread index
  unsigned int threadIndex = (blockIdx.x * blockDim.x) + threadIdx.x;
  
  // Copy data from the device to the shared memory pool (and perform an operation using constant memory)
  sharedMemory[threadIndex] = deviceData[threadIndex];
  
  // Perform thread synchronization
  __syncthreads();
  
  unsigned int exponentPrimer = threadIndex % 2;
  
  for (unsigned int i = 0; i < 16; ++i)
  {
    unsigned int currentConstant =  ADDITIVE_VALUES[i];
    
    float value = powf(-1, exponentPrimer) * currentConstant;
    
    sharedMemory[threadIndex] += value;
  }
  
  __syncthreads();
  
  // Copy the data from the shared memory back to the device
  deviceData[threadIndex] = sharedMemory[elementCount - threadIndex - 1];
}

// ----------------------------------------- HOST OPERATIONS -----------------------------------------

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
__host__ void generateRandomNumbers(      unsigned int* data,
                                    const unsigned int  elementCount,
                                    const unsigned int  max)
{
  // Check to make sure the RNG has been initialized
  if (initializedRNG == 0)
  {
    // If not, initialize the RNG
    initializeRandomNumbers();
  }
  
  // Generate random data between 0 and the provided maximum value
  for (unsigned int i = 0; i < elementCount; ++i)
  {
    data[i] = rand() % max;
  }
}

__host__ void run_gpu_algorithm(int blockCount, int threadCount)
{
  // Step 1: Compute the size of the device array based on the block and thread/per block counts
  unsigned int elementCount = threadCount * blockCount;
  unsigned int deviceSize   = UINT_SIZE   * elementCount;
  
  // Step 2: Allocate the necessary host memory (two input arrays and an output array
  //         (use malloc for the input, and calloc for the output since we want to modify
  //          the contents of the input PRIOR to executing the GPU kernels, but we want to
  //          initialize the output to 0 before copying the device output over)
  unsigned int* hostInput1 = (unsigned int*) malloc(deviceSize);
  unsigned int* hostInput2 = (unsigned int*) malloc(deviceSize);
  unsigned int* hostOutput = (unsigned int*) calloc(elementCount, UINT_SIZE);
  
  // Step 3: Populate the input arrays with random data, using the device size as the maximum value
  //         (the device size is used purely as a convenience number, and to ensure that the maximum
  //          value has the potential to change between each run)
  generateRandomNumbers(hostInput1, elementCount, deviceSize);
  generateRandomNumbers(hostInput2, elementCount, deviceSize);
  
  // Step 4: Allocate the GPU memory arrays
  unsigned int* deviceInput1;
  unsigned int* deviceInput2;
  unsigned int* deviceOutput;
  
  cudaMalloc((void**)&deviceInput1, deviceSize);
  cudaMalloc((void**)&deviceInput2, deviceSize);
  cudaMalloc((void**)&deviceOutput, deviceSize);
  
  // Step 5: Populate the GPU input with the host input data
  cudaMemcpy(deviceInput1, hostInput1, deviceSize, cudaMemcpyHostToDevice);
  cudaMemcpy(deviceInput2, hostInput2, deviceSize, cudaMemcpyHostToDevice);
  
  // Step 6: Set the GPU output with all zeros
  cudaMemset(deviceOutput, INITIAL_DATA, deviceSize);
  
  // Step 7: Initialize the CUDA event start/stop timers for benchmarking
  cudaEvent_t stopLocalEvent;
  cudaEvent_t stopGlobalEvent;
  cudaEvent_t stopSharedEvent;
  cudaEvent_t startLocalEvent;
  cudaEvent_t startGlobalEvent;
  cudaEvent_t startSharedEvent;

  cudaEventCreate(&stopLocalEvent);  
  cudaEventCreate(&stopGlobalEvent);
  cudaEventCreate(&stopSharedEvent);
  cudaEventCreate(&startLocalEvent);  
  cudaEventCreate(&startGlobalEvent);
  cudaEventCreate(&startSharedEvent);
  
  // Step 8: Invoke the global algorithm kernel with recording enabled
  cudaEventRecord(startGlobalEvent);
  globalModularDivide<<<blockCount, threadCount>>>(deviceInput1, deviceInput2, deviceOutput);
  cudaEventRecord(stopGlobalEvent);
  
  cudaThreadSynchronize();
  cudaGetLastError();
  
  // Step 9: Retrieve the output from the global algorithm kernel
  cudaMemcpy(hostOutput, deviceOutput, deviceSize, cudaMemcpyDeviceToHost);
  
  // Step 10: Obtain the ms duration for the global algorithm
  cudaEventSynchronize(stopGlobalEvent);
  
  float globalTimeMS = 0.0f;
  cudaEventElapsedTime(&globalTimeMS, startGlobalEvent, stopGlobalEvent);
  
  // Step 11: Invoke the local algorithm kernel with recording enabled
  cudaEventRecord(startLocalEvent);
  localModularDivide<<<blockCount, threadCount>>>(deviceInput1, deviceInput2, deviceOutput);
  cudaEventRecord(stopLocalEvent);
  
  cudaThreadSynchronize();
  cudaGetLastError();
  
  // Step 12: Retrieve the output from the local algorithm kernel
  cudaMemcpy(hostOutput, deviceOutput, deviceSize, cudaMemcpyDeviceToHost);
  
  // Step 13: Obtain the ms duration for the local algorithm
  cudaEventSynchronize(stopLocalEvent);
  
  float localTimeMS = 0.0f;
  cudaEventElapsedTime(&localTimeMS, startLocalEvent, stopLocalEvent);
  
  // Step 14: Upload the constant memory values to the device:
  unsigned int* constantMemory = (unsigned int*) malloc(deviceSize);
  generateRandomNumbers(constantMemory, elementCount, deviceSize);
  
  cudaMemcpyToSymbol(ADDITIVE_VALUES, constantMemory, UINT_SIZE * 16);
  
  // Step 15: Invoke the shared algorithm kernel with recording enabled
  cudaEventRecord(startSharedEvent);
  add_values_shared<<<blockCount, threadCount>>>(deviceOutput, elementCount);
  cudaEventRecord(stopSharedEvent);
  
  cudaThreadSynchronize();
  cudaGetLastError();
  
  // Step 16: Retrieve the output from the global algorithm kernel
  cudaMemcpy(hostOutput, deviceOutput, deviceSize, cudaMemcpyDeviceToHost);
  
  // Step 17: Obtain the ms duration for the global algorithm
  cudaEventSynchronize(stopSharedEvent);
  
  float sharedTimeMS = 0.0f;
  cudaEventElapsedTime(&sharedTimeMS, startSharedEvent, stopSharedEvent);

  // Step 18: Display the results of the two operations
  printf("Block Count: %d\t Threads Per Block: %d\t", blockCount, threadCount);
  printf("Global Duration: %2f ms\t", globalTimeMS);
  printf("Shared Duration: %2f ms\t", sharedTimeMS);
  printf("Local  Duration: %2f ms\n", localTimeMS );
  
  // Step 19: Free device memory:
  cudaFree(deviceInput1);
  cudaFree(deviceInput2);
  cudaFree(deviceOutput);
  
  // Step 20: Free host memory
  free(hostInput1);
  free(hostInput2);
  free(hostOutput);
  
  // Step 21: Free constant memory
  free(constantMemory);
}

/// @brief determine if the provided number is a power of two
///
/// @param [in] number   The number to validate
///
/// @return True if the provided number is a power of two, false otherwise
__host__ bool isPowerOfTwo(const int number)
{
  // Initialize a mask a 00000000 00000000 00000000 00000001 (on 32-bit machines)
  int mask = 0x1;
  
  // Iterate over each of the bits in the mask, left shifting by one to
  // iterate to the next power of two
  for (unsigned int i = 0; i < sizeof(int) * 8; ++i, mask = mask << 1)
  {
   
    // Compute the resulting masked value
    int maskedValue = number & mask;
    
    // If the computed value is non-zero and is not the provided number,
    // the provided number is not a power of two:
    //
    // For example, 3 would not be a power of two:
    //           3 = 00000000 00000000 00000000 00000011
    //        mask = 00000000 00000000 00000000 00000010
    // maskedValue = 00000000 00000000 00000000 00000010
    // makedValue is non-zero (2), but is also not provided number (2 != 3)
    if (maskedValue != 0 && maskedValue != number)
    {
      return false;
    }
    
    // If the maskedValue is the provided number, then we've confirmed that the
    // value is a power of two
    if (maskedValue == number)
    {
      return true;
    }
  }
  
  // Return false if we've exhausted all possible powers of two the computer can handle
  return false;
}

// @brief Display the proper program usage
__host__ void showUsage()
{
  printf("Invalid arguments provided. Please see the usage below:\n");
  printf("  module_6_jrenga2.exe <bc> <tpb>\n");
  printf("  bc  - The maximum number of blocks to run with. Must be a positive integer and a power of two.\n");
  printf("  tpb - The maximum number of threads per blocks. Must be a positive integer and a power of two.\n");
  printf("NOTE: The maximum number of threads (bc * tpb) must be greater than %d \n", THREAD_MIN);
  printf("      and less than %d.\n", THREAD_MAX);
  printf(" ** TERMINATING **\n");
}

// @brief Main Entry-Point
int main(int argc, char* argv[])
{
 // 1. Check the number of arguments.
  if (argc != 3)
  {
    showUsage();
    return EXIT_FAILURE;
  }

  // 2. Attempt to retrieve the integer values of the parameters
  //    (a value less than or equal to 0 is considered invalid)
  int numBlocks = atoi(argv[1]);
  if (numBlocks <= 0 || !isPowerOfTwo(numBlocks))
  {
    showUsage();
    return EXIT_FAILURE;
  }

  int numThreads = atoi(argv[2]);
  if (numThreads <= 0 || !isPowerOfTwo(numThreads))
  {
    showUsage();
    return EXIT_FAILURE;
  }
  
  int totalThreads = numBlocks * numThreads;

  // 2.5 Check to see if the minimum number of threads has been achieved (64)
  if (totalThreads < THREAD_MIN || totalThreads > THREAD_MAX)
  {
    showUsage();
    return EXIT_FAILURE;
  }
  
  // Do some pre-processing to set up the random number generation
  initializedRNG = false;
  
  // Initialize the random numbers
  initializeRandomNumbers();
  
  // Iterate from 1 -> numBlocks and 1 -> numThreads to perform metrics on numerous configurations
  for (unsigned int blockCount = 1; blockCount <= numBlocks; blockCount = blockCount << 1)
  {
    for (unsigned int threadCount = 1; threadCount <= numThreads; threadCount = threadCount << 1)
    {
      run_gpu_algorithm(blockCount, threadCount);
    }
  }
  
  return EXIT_SUCCESS;
}
