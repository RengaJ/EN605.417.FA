// Assignment For Module 04:
//
//
// Author: Justin Renga

// NOTE: This implementation was inspired from the sample code from
// https://devblogs.nvidia.com/how-optimize-data-transfers-cuda-cc/
// and, as such, there may be similarities between them.

#include <stdio.h>
#include <stdlib.h>

#define BLOCKSIZE 8
#define THREADCOUNT 256

// Define the array size as a constant value
#define ARRAY_SIZE 2048
#define BYTES ARRAY_SIZE * sizeof(unsigned int)

/// @brief The kernel function that will be used to test the functionality
///        of pinned and pageable memory.

__global__ void manipulateInput(unsigned int* input, unsigned int* output)
{
  const unsigned int thread_index = (blockIdx.x * blockDim.x) + threadIdx.x;
  output[thread_index] = (2 * input[thread_index]) - (thread_index/2);
}

/// @brief A function to test the usage of Pinned Memory.
float test_pinnedMemory()
{
  // Define data containers
  unsigned int* pinnedMemory;
  unsigned int* pinnedOutput;
  unsigned int* deviceIn;
  unsigned int* deviceOut;
  unsigned int* hostPageable;
  
  // Establish CUDA start/stop events
  cudaEvent_t startEvent;
  cudaEvent_t stopEvent;
  
  // Define the time container
  float time;
  
  cudaEventCreate(&startEvent);
  cudaEventCreate(&stopEvent);
  
  // Start the event timer:
  cudaEventRecord(startEvent, 0);

  // Allocate Pageable Memory (on host)
  hostPageable = (unsigned int*) malloc(BYTES);

  // Allocate Pinned Memory (on host)
  // Need to use cudaMallocHost() to establish pinned memory
  cudaMallocHost((void**)&pinnedMemory, BYTES);
  cudaMallocHost((void**)&pinnedOutput, BYTES);
  cudaMalloc((void**)&deviceIn, BYTES);
  cudaMalloc((void**)&deviceOut, BYTES);

  // Initialize the pageable memory
  for (unsigned int i = 0; i < ARRAY_SIZE; ++i)
  {
    hostPageable[i] = (i + 1);
  }

  // Copy the pageable memory to the pinned memory
  memcpy(pinnedMemory, hostPageable, BYTES);
  memset(pinnedOutput, 0,            BYTES);
  
  // Copy the pinned memory to the device
  cudaMemcpy(deviceIn,  pinnedMemory, BYTES, cudaMemcpyHostToDevice);
  // Execute the KERNEL
  manipulateInput<<<BLOCKSIZE, THREADCOUNT>>>(deviceIn, deviceOut);
  // Obtain the output
  cudaMemcpy(pinnedOutput, deviceOut, BYTES, cudaMemcpyDeviceToHost);

  printf("Final Output Value:\n");
  printf("pinnedOutput[%d] = %u\n", ARRAY_SIZE-1, pinnedOutput[ARRAY_SIZE-1]);

  // Free Memory
  cudaFree(deviceIn);
  cudaFree(deviceOut);
  cudaFreeHost(pinnedOutput);
  cudaFreeHost(pinnedMemory);
  free(hostPageable);
  
  // Stop the event timer
  cudaEventRecord(stopEvent, 0);
  cudaEventSynchronize(stopEvent);
  
  cudaEventElapsedTime(&time, startEvent, stopEvent);
  
  cudaEventDestroy(startEvent);
  cudaEventDestroy(stopEvent);
  
  return time;
}

/// @ brief A function to test the usage of Pageable Memory
float test_pageableMemory()
{
  // Define data containers
  unsigned int* deviceIn;
  unsigned int* deviceOut;
  unsigned int* pageableInput;
  unsigned int* pageableOutput;
  
  // Establish CUDA start/stop events
  cudaEvent_t startEvent;
  cudaEvent_t stopEvent;
  
  // Define the time container
  float time;
  
  cudaEventCreate(&startEvent);
  cudaEventCreate(&stopEvent);
  
  // Start the event timer:
  cudaEventRecord(startEvent, 0);
  
  // Begin the memory allocations
  
  // Allocate Pageable Memory (on host)
  pageableInput  = (unsigned int*) malloc(BYTES);
  pageableOutput = (unsigned int*) malloc(BYTES);
  cudaMalloc((void**)&deviceIn, BYTES);
  cudaMalloc((void**)&deviceOut, BYTES);
  
  // Initialize the pageable memory
  for (unsigned int i = 0; i < ARRAY_SIZE; ++i)
  {
    pageableInput[i]  = (i + 1);
    pageableOutput[i] = 0;
  }
  
  // Copy the pinned memory to the device
  cudaMemcpy(deviceIn,  pageableInput, BYTES, cudaMemcpyHostToDevice);
  cudaMemcpy(deviceOut, pageableOutput, BYTES, cudaMemcpyHostToDevice);

  // Execute the KERNEL
  manipulateInput<<<BLOCKSIZE, THREADCOUNT>>>(deviceIn, deviceOut);
  
  // Obtain the output
  cudaMemcpy(pageableOutput, deviceOut, BYTES, cudaMemcpyDeviceToHost);

  printf("Final Output Value:\n");
  printf("pageableOutput[%d] = %u\n", ARRAY_SIZE-1, pageableOutput[ARRAY_SIZE-1]);
  
  // Free Memory
  cudaFree(deviceIn);
  cudaFree(deviceOut);
  free(pageableInput);
  free(pageableOutput);

  // Stop the event timer
  cudaEventRecord(stopEvent, 0);
  cudaEventSynchronize(stopEvent);
  
  cudaEventElapsedTime(&time, startEvent, stopEvent);
  
  cudaEventDestroy(startEvent);
  cudaEventDestroy(stopEvent);
  
  return time;
}

/// @brief The main function
///
/// @param [in] argc    The number of arguments passed into the program
/// @param [in] argv    The actual arguments passed into the program
///
/// @return    EXIT_SUCCESS upon success
int main(int argc, const char* argv[])
{
  // Create an array that will hold the durations of the tests
  float duration[2];

  // Execute and store the results of the two tests
  duration[0] = test_pinnedMemory();
  duration[1] = test_pinnedMemory();

  // Output the results of the tests
  printf("Results:\n");
  printf("--------\n");
  printf("Pinned Memory   Test Duration: %3f seconds\n", duration[0]);
  printf("Pageable Memory Test Duration: %3f seconds\n", duration[1]);
 
  return EXIT_SUCCESS;
}
