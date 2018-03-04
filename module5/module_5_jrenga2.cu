// Introduction to GPU Programming
// Module 05: Shared and Constant Memory
// Author   : Justin Renga
// Date     : 03/03/2017

// Bibliography (source-list):
// [1] http://cuda-programming.blogspot.com/2013/01/what-is-constant-memory-in-cuda.html
// [2] constant_memory.cu
// [3] shared_memory2.cu

// #includes
#include <time.h>
#include <stdio.h>
#include <stdlib.h>

#define ELEMENT_COUNT 2048

// Declare CONSTANT Memory here:
__constant__ static unsigned int MASKS[2];

// Declare static SHARED Memory here:
__shared__   unsigned int sharedMemory [ELEMENT_COUNT];

// Declare global host data here:
unsigned int initializedRNG;

// ---------------------------------------- DEVICE OPERATIONS -----------------------------------------

// @brief Perform a masking operation based on the evenness of the data
//
// @param [ in] data   An array that contains input data
// @param [out] output An array that contains the resulting data
__global__ void maskBits(const unsigned int*       data,
                               unsigned int* const output)
{
  // Compute the thread index
  const unsigned int threadIndex = (blockIdx.x * blockDim.x) + threadIdx.x;
  
  const unsigned int dataValue = data[threadIndex];
    
  // Apply the appropriate mask value and assign to the output
  output[threadIndex] = dataValue ^ MASKS[dataValue % 2];
}

// @brief Performs an array reversal
//
// @param [   in] The shared memory
// @param [inout] The device memory
// @param [   in] The number of elements
// @param [   in] The current thread index
__device__ void rotateArray(unsigned int* const data,
                            unsigned int* const deviceData,
                            unsigned int        elementCount,
                            unsigned int        threadIndex)
{
  // Get the next appropriately rotated thread index
  unsigned int rotatedIndex = elementCount - threadIndex - 1;
  
  data[threadIndex] = deviceData[rotatedIndex];
  
  __syncthreads();
  
  // Store the newly rotated memory back into global memory
  deviceData[threadIndex] = data[threadIndex];
}

// @brief A kernel function used to flip the contents of an array
__global__ void swapArray(unsigned int* data, const unsigned int elementCount)
{
  // Get the current thread index
  unsigned int threadIndex = (blockIdx.x * blockDim.x) + threadIdx.x;
  
  rotateArray(sharedMemory, data, elementCount, threadIndex);
}

// ----------------------------------------- HOST OPERATIONS -----------------------------------------

// @brief Initialize the Random number generator and ensure it only initializes one time
void initializeRandomNumbers()
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
void generateRandomNumbers(      unsigned int* data,
                           const unsigned int  elementCount,
                           const unsigned int  max)
{
  // Check to make sure the RNG has been initialized
  if (initializedRNG == 0)
  {
    // If not, initialize the RNG
    initializeRandomNumbers();
  }
  for (unsigned int i = 0; i < elementCount; ++i)
  {
    data[i] = rand() % max;
  }
}

// @brief Host function to run the GPU algorithms
//
// @param [in] threadCount Number of threads per block
// @param [in] blockCount  Number of blocks
// @param [in] maskMode    Should the algorithm to run be the mask algorithm?
void runAlgorithm(unsigned int threadCount, unsigned int blockCount, bool maskMode)
{
  static unsigned int elementCount = threadCount * blockCount;
  
  // Declare the device array size
  static unsigned int deviceSize = sizeof(unsigned int) * elementCount;
  
  // Allocate host memory to copy to/from the GPU
  unsigned int* hostInput  = (unsigned int*)malloc(deviceSize);
  unsigned int* hostOutput = (unsigned int*)calloc(elementCount, sizeof(unsigned int));
  
  // Populate the host memory with random numbers from 0 to elementCount - 1
  generateRandomNumbers(hostInput, elementCount, elementCount);
  
  // Allocate global memory for the GPU
  unsigned int* deviceInput;
  unsigned int* deviceOutput;
  
  cudaMalloc((void**)&deviceInput , deviceSize);
  cudaMalloc((void**)&deviceOutput, deviceSize);
  
  // Initialize the device output memory to zero
  cudaMemset(deviceOutput, 0, deviceSize);
  
  // Copy the host input memory to GPU input memory
  cudaMemcpy(deviceInput,  hostInput,  deviceSize, cudaMemcpyHostToDevice);
  
    if (maskMode)
  {
    // Define the constant values for the MASK
    static unsigned int masks[2];
    
    // Mask ZERO: 00000001 00100011 01000101 01100111
    // Mask ONE : 10111111 11101010 11001101 00010110
    masks[0] = 0x01234567;
    masks[1] = 0xBFEACD16;
    
    // Copy the masks symbol from host to constant GPU memory:
    cudaMemcpyToSymbol(MASKS, masks, sizeof(unsigned int) * 2);
    
      // Execute the kernel
    maskBits<<<blockCount, threadCount>>>(deviceInput, deviceOutput);
  }
  else
  {
    swapArray<<<blockCount, threadCount>>>(deviceInput, elementCount);
  
    // Make sure the GPU has completed before copying everything over
    cudaThreadSynchronize();
  }
  
  if (maskMode)
  {
    // Copy memory from device to host for output
    cudaMemcpy(hostOutput, deviceOutput, deviceSize, cudaMemcpyDeviceToHost);
  }
  else
  {
    // Copy memory from device to host for output
    cudaMemcpy(hostOutput, deviceInput, deviceSize, cudaMemcpyDeviceToHost);
  }
  
  // Print the trimmed results (the first and last 4 values)
  for (unsigned int i = 0; i < 4; ++i)
  {
    printf("[INDEX %5u] Input: %4u   Output: %u\n", i, hostInput[i], hostOutput[i]);
  }
  
  printf("\n...Trimmed output...\n\n");
  
  for (unsigned int i = elementCount - 5; i < elementCount; ++i)
  {
    printf("[INDEX %5u] Input: %4u   Output: %u\n", i, hostInput[i], hostOutput[i]);
  }
  
  // Free the device memory
  cudaFree(deviceInput );
  cudaFree(deviceOutput);
  
  // Free the host memory
  free(hostInput);
  free(hostOutput);
  
  hostInput = NULL;
  hostOutput = NULL;
}

// @brief Display the proper program usage
void showUsage()
{
  printf("Invalid arguments provided. Please see the usage below:\n");
  printf("  module_3_jrenga2.exe <bc> <tpb>\n");
  printf("  bc  - The number of blocks to run with. Must be a positive integer.\n");
  printf("  tpb - The number of threads per blocks. Must be a positive integer.\n");
  printf("NOTE: The total number of threads (bc * tpb) must be greater than 64 \n");
  printf("      and less than 2048.\n");
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
  if (numBlocks <= 0)
  {
    showUsage();
    return EXIT_FAILURE;
  }

  int numThreads = atoi(argv[2]);
  if (numThreads <= 0)
  {
    showUsage();
    return EXIT_FAILURE;
  }
  
  int totalThreads = numBlocks * numThreads;

  // 2.5 Check to see if the minimum number of threads has been achieved (64)
  if (totalThreads < 64 || totalThreads > 2048)
  {
    showUsage();
    return EXIT_FAILURE;
  }
  
  // Do some pre-processing to set up the random number generation
  initializedRNG = false;

  initializeRandomNumbers();
  
  printf("Swapping Algorithm (SHARED MEMORY) [BLOCKS = %2d, THREADS/BLOCK = %2d]\n", numBlocks, numThreads);
  printf("********************************************************************\n");
  
  // Run the swapping algorithm using shared memory
  runAlgorithm(numBlocks, numThreads, false);
  
  printf("Masking Algorithm (CONSTANT MEMORY) [BLOCKS = %2d, THREADS/BLOCK = %2d]\n", numBlocks, numThreads);
  printf("*********************************************************************\n");
  
  // Run the masking algorithm using constant memory
  runAlgorithm(numBlocks, numThreads, true);

  return EXIT_SUCCESS;
}
