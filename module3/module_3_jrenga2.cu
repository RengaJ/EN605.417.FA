// Assignment For Module 03:
// Blocks, Warps and Threads

// Author: Justin Renga

#include <stdio.h>
#include <stdlib.h>

/// @brief The Kernel function that will execute on the GPU.
///
/// @param [inout] input1    The first input array (contains integers)
/// @param [inout] input2    The second input array (contains integers)
/// @param [inout] output    The resulting array (first + second)
__global__ void integer_addition(int* input1, int* input2, int* output)
{
  const unsigned int thread_index = (blockIdx.x * blockDim.x) + threadIdx.x;
  output[thread_index] = input1[thread_index] + input2[thread_index];
}

/// @brief The main function
///
/// @param [in] argc    The number of arguments passed into the program
/// @param [in] argv    The actual arguments passed into the program
///
/// @return    EXIT_SUCCESS upon success
int main(int argc, const char* argv[])
{
  // 1. Check the number of arguments.
  if (argc != 3)
  {
    printf("ERROR: Incorrect number of arguments provided!\n");
    printf("----------------------------------------------\n");
    printf("Usage:\n");
    printf("  module_3_jrenga2.exe <number of blocks> <number of thread per block>\n");
    printf("\nPlease check your inputs and try again. Thank you! :)\n");

    return EXIT_FAILURE;
  }

  // 2. Attempt to retrieve the integer values of the parameters
  //    (a value less than or equal to 0 is considered invalid)
  int numBlocks = atoi(argv[1]);
  if (numBlocks <= 0)
  {
    printf("ERROR: Invalid number of blocks provided!\n");
    printf("-----------------------------------------\n");
    printf("The number of blocks must be a positive integer.\n");
    printf("\nPlease check your inputs and try again. Thank you! :)\n");

    return EXIT_FAILURE;
  }

  int numThreads = atoi(argv[2]);
  if (numThreads <= 0)
  {
    printf("ERROR: Invalid number of threads provided!\n");
    printf("------------------------------------------\n");
    printf("The number of threads per block must be a positive integer.\n");
    printf("\nPlease check your inputs and try again. Thank you! :)\n");

    return EXIT_FAILURE;
  }

  // 2.5 Check to see if the minimum number of threads has been achieved (64)
  if ((numBlocks * numThreads) < 64)
  {
    int threadCount = numBlocks * numThreads;
    printf("ERROR: Minimum number of threads not achieved!\n");
    printf("----------------------------------------------\n");
    printf("The total number of threads must be greater than 64. You have provided %d threads.\n", threadCount);
    printf("\nPlease check your inputs and try again. Thank you! :)\n");

    return EXIT_FAILURE;
  }
  // 3. Compute necessary array structures

  int array_size = numBlocks * numThreads;
  int array_size_in_bytes = array_size * sizeof(unsigned int);

  unsigned int* cpu_input_array1 = (unsigned int*) calloc(array_size, sizeof(unsigned int));
  unsigned int* cpu_input_array2 = (unsigned int*) calloc(array_size, sizeof(unsigned int));
  unsigned int* cpu_output_array = (unsigned int*) calloc(array_size, sizeof(unsigned int));

  int* gpu_input_1;
  int* gpu_input_2;
  int* gpu_output;

  int loopCounter = 0;

  for ( ; loopCounter < array_size; loopCounter++)
  {
    cpu_input_array1[loopCounter] = loopCounter;
    cpu_input_array2[loopCounter] = loopCounter * 2;
  }

  // 4. Prepare the GPU call

  cudaMalloc((void **)&gpu_input_1, array_size_in_bytes);
  cudaMemcpy(gpu_input_1, cpu_input_array1, array_size_in_bytes, cudaMemcpyHostToDevice);

  cudaMalloc((void **)&gpu_input_2, array_size_in_bytes);
  cudaMemcpy(gpu_input_2, cpu_input_array2, array_size_in_bytes, cudaMemcpyHostToDevice);

  cudaMalloc((void **)&gpu_output,  array_size_in_bytes);
  cudaMemcpy(gpu_output, cpu_output_array,  array_size_in_bytes, cudaMemcpyHostToDevice);

  // 5. Perform the GPU call
  integer_addition<<< numBlocks, numThreads >>>(gpu_input_1, gpu_input_2, gpu_output);

  // 6. Retrieve the data
  cudaMemcpy( cpu_output_array, gpu_output, array_size_in_bytes, cudaMemcpyDeviceToHost);

  // 6.1 Free the remaining data
  cudaFree(gpu_output);
  cudaFree(gpu_input_2);
  cudaFree(gpu_input_1);

  // 7. Display the data
  for ( loopCounter = 0; loopCounter < array_size; loopCounter++)
  {
    printf("Computed value (index %d): %u\n", loopCounter, cpu_output_array[loopCounter]);
  }

  free(cpu_output_array);
  free(cpu_input_array2);
  free(cpu_input_array1);

  return EXIT_SUCCESS;
}
