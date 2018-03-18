/// Assignment 07: Streams and Events
///
/// Author: Justin Renga

#include <time.h>
#include <stdio.h>
#include <stdlib.h>

// Declare constant definitions here
#define DOUBLE_SIZE sizeof(double)
#define THREAD_MIN 64
#define THREAD_MAX 4096

// Declare global host data here:
unsigned int initializedRNG;

// ---------------------------------------- DEVICE OPERATIONS -----------------------------------------

// @brief GPU Kernel that takes three vector components (x,y,z) and produces the reciprocal magnitude of
//         the provided vector.   DEVICE ONLY
//
// @param [ in] x    The x-component of the vector
// @param [ in] y    The y-component of the vector
// @param [ in] z    The z-component of the vector
//
// @return  The reciprocal of the vector's magnitude
__device__ double getRMagnitude(const double x, const double y, const double z)
{
  // Return 1/ (Square Root(x^2 + y^2 + z^2))
  return rsqrt(pow(x, 2.0) + pow(y, 2.0) + pow(z, 2.0));
}

// @brief GPU kernel that takes three vector component vectors (x, y and z) and replaces
//        the contents with the unit vector components
//
// @param [inout] xComponents   INPUT: original x-components of the vectors | OUTPUT: normalized x-component
// @param [inout] yComponents   INPUT: original y-components of the vectors | OUTPUT: normalized y-component
// @param [inout] zComponents   INPUT: original z-components of the vectors | OUTPUT: normalized z-component
__global__ void normalize(double* xComponents, double* yComponents, double* zComponents)
{
  const unsigned int threadIndex = (blockIdx.x * blockDim.x) + threadIdx.x;
  
  double rMagnitude = getRMagnitude(xComponents[threadIndex], yComponents[threadIndex], zComponents[threadIndex]);
  
  xComponents[threadIndex] = xComponents[threadIndex] * rMagnitude;
  yComponents[threadIndex] = yComponents[threadIndex] * rMagnitude;
  zComponents[threadIndex] = zComponents[threadIndex] * rMagnitude;
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
__host__ void generateRandomNumbers(            double* data,
                                    const unsigned int  elementCount,
                                    const unsigned int  max)
{
  // Check to make sure the RNG has been initialized
  if (initializedRNG == 0)
  {
    // If not, initialize the RNG
    initializeRandomNumbers();
  }
  
  double division = max / (double)RAND_MAX;
  
  // Generate random data between 0 and the provided maximum value
  for (unsigned int i = 0; i < elementCount; ++i)
  {
    data[i] = rand() * division;
  }
}

__host__ void run_gpu_algorithm(int blockCount, int threadCount)
{
  // Compute the size of the device array based on the block and thread/per block counts
  static unsigned int elementCount = THREAD_MAX;
  static unsigned int deviceSize   = DOUBLE_SIZE * elementCount;
  
  // Allocate the necessary host memory (thee input arrays, three output arrays)
  double* hostXInput;
  double* hostYInput;
  double* hostZInput;
  
  double* hostXOutput;
  double* hostYOutput;
  double* hostZOutput;
  
  cudaMallocHost((void**)&hostXInput, deviceSize, cudaHostAllocDefault);
  cudaMallocHost((void**)&hostYInput, deviceSize, cudaHostAllocDefault);
  cudaMallocHost((void**)&hostZInput, deviceSize, cudaHostAllocDefault);
  
  cudaMallocHost((void**)&hostXOutput, deviceSize, cudaHostAllocDefault);
  cudaMallocHost((void**)&hostYOutput, deviceSize, cudaHostAllocDefault);
  cudaMallocHost((void**)&hostZOutput, deviceSize, cudaHostAllocDefault);
  
  // Populate the input arrays with random data, using the device size as the maximum value
  // (the device size is used purely as a convenience number, and to ensure that the maximum
  // value has the potential to change between each run)
  generateRandomNumbers(hostXInput, elementCount, deviceSize);
  generateRandomNumbers(hostYInput, elementCount, deviceSize);
  generateRandomNumbers(hostZInput, elementCount, deviceSize);
  
  // Allocate the GPU memory arrays
  double* deviceIO_X;
  double* deviceIO_Y;
  double* deviceIO_Z;
  
  cudaMalloc((void**)&deviceIO_X, deviceSize);
  cudaMalloc((void**)&deviceIO_Y, deviceSize);
  cudaMalloc((void**)&deviceIO_Z, deviceSize);
  
  // Initialize the CUDA event start/stop timers for benchmarking
  cudaEvent_t stopStreamEvent;
  cudaEvent_t stopStandardEvent;
  cudaEvent_t startStreamEvent;
  cudaEvent_t startStandardEvent;
  
  cudaEventCreate(&stopStreamEvent);  
  cudaEventCreate(&stopStandardEvent);
  cudaEventCreate(&startStreamEvent);
  cudaEventCreate(&startStandardEvent);
  
  // Create the data stream
  cudaStream_t data_stream;
  cudaStreamCreate(&data_stream);
  
  // Start recording the stream process (starting from the first copy)
  cudaEventRecord(startStreamEvent);
  
  // Perform the asynchronous memory copy from the host to the device, utilizing the stream
  cudaMemcpyAsync(deviceIO_X, hostXInput, deviceSize, cudaMemcpyHostToDevice, data_stream);
  cudaMemcpyAsync(deviceIO_Y, hostYInput, deviceSize, cudaMemcpyHostToDevice, data_stream);
  cudaMemcpyAsync(deviceIO_Z, hostZInput, deviceSize, cudaMemcpyHostToDevice, data_stream);
  
  // Invoke the normalization routine
  normalize<<<blockCount, threadCount>>>(deviceIO_X, deviceIO_Y, deviceIO_Z);
  
  // Retrieve the memory from the device asynchronously
  cudaMemcpyAsync(hostXOutput, deviceIO_X, deviceSize, cudaMemcpyDeviceToHost, data_stream);
  cudaMemcpyAsync(hostYOutput, deviceIO_Y, deviceSize, cudaMemcpyDeviceToHost, data_stream);
  cudaMemcpyAsync(hostZOutput, deviceIO_Z, deviceSize, cudaMemcpyDeviceToHost, data_stream);
  
  cudaStreamSynchronize(data_stream);
  
  // Record the stop time for the stream process
  cudaEventRecord(stopStreamEvent, 0);
  cudaEventSynchronize(stopStreamEvent);
  
  cudaThreadSynchronize();
  cudaGetLastError();
  
  // Obtain the ms duration for the stream normalization kernel invocation
  float streamTimeMS = 0.0f;
  cudaEventElapsedTime(&streamTimeMS, startStreamEvent, stopStreamEvent);
  
  // Perform the same steps above, but without the stream's involvement
  cudaEventRecord(startStandardEvent);
  
  cudaMemcpy(deviceIO_X, hostXInput, deviceSize, cudaMemcpyHostToDevice);
  cudaMemcpy(deviceIO_Y, hostYInput, deviceSize, cudaMemcpyHostToDevice);
  cudaMemcpy(deviceIO_Z, hostZInput, deviceSize, cudaMemcpyHostToDevice);
  
  // Invoke the normalization routine
  normalize<<<blockCount, threadCount>>>(deviceIO_X, deviceIO_Y, deviceIO_Z);
  
  cudaMemcpy(hostXOutput, deviceIO_X, deviceSize, cudaMemcpyDeviceToHost);
  cudaMemcpy(hostYOutput, deviceIO_Y, deviceSize, cudaMemcpyDeviceToHost);
  cudaMemcpy(hostZOutput, deviceIO_Z, deviceSize, cudaMemcpyDeviceToHost);
  
  cudaEventRecord(stopStandardEvent);
  
  cudaThreadSynchronize();
  cudaGetLastError();
  
  // Obtain the ms duration for the synchronous normalization kernel invocation
  cudaEventSynchronize(stopStandardEvent);
  
  float standardTimeMS = 0.0f;
  cudaEventElapsedTime(&standardTimeMS, startStandardEvent, stopStandardEvent);

  // Display the results of the two operations
  printf("Block Count: %d\t Threads Per Block: %d\t", blockCount, threadCount);
  printf("Stream Duration: %2f ms\t", streamTimeMS);
  printf("Standard Duration: %2f ms\n", standardTimeMS );
  
  // Free device memory:
  cudaFree(deviceIO_X);
  cudaFree(deviceIO_Y);
  cudaFree(deviceIO_Z);
  
  // Free host memory
  cudaFreeHost(hostXInput);
  cudaFreeHost(hostYInput);
  cudaFreeHost(hostZInput);
  
  cudaFreeHost(hostXOutput);
  cudaFreeHost(hostYOutput);
  cudaFreeHost(hostZOutput);
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
  printf("  module_7_jrenga2.exe <bc> <tpb>\n");
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
