#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/copy.h>
#include <thrust/generate.h>        // Allow for the 
#include <thrust/reduce.h>          // Include the reduce operation
#include <thrust/fill.h>            // Include the fill operation
#include <thrust/functional.h>      // Include the modulus operation
#include <thrust/adjacent_difference.h>

#include <time.h>
#include <iostream>

// Bibliography
// [1] http://docs.nvidia.com/cuda/thrust/index.html


// Adds the sum of the differences between random numbers
void count_adj_diffs(const unsigned int offset)
{
  // Compute the size of the data
  int data_size = 32 << offset;
  
  // Create events (for timing)
  cudaEvent_t adjDiffStart;
  cudaEvent_t adjDiffStop;
  
  cudaEventCreate(&adjDiffStart);
  cudaEventCreate(&adjDiffStop);
  
  // Record the current time
  cudaEventRecord(adjDiffStart);
  
  // Create the host data and results vector (they are not data dependent)
  thrust::host_vector<unsigned int> host_data(data_size);
  thrust::device_vector<unsigned int> results(data_size);
  
  // Generate random data and place it in the host vector
  thrust::generate(host_data.begin(), host_data.end(), rand);
  
  // Create a device vector that copies the host data
  thrust::device_vector<unsigned int> device_data(host_data.begin(), host_data.end());
  
  // Take the adjacent differences between each element in the device vector
  thrust::adjacent_difference(device_data.begin(), device_data.end(), results.begin());
  
  // Add the differences together and obtain the result
  int result = thrust::reduce(results.begin(), results.end());
  
  // Stop recording
  cudaEventRecord(adjDiffStop, 0);
  cudaEventSynchronize(adjDiffStop);
  
  // Get the time duration
  float adjDiffTime;
  
  cudaEventElapsedTime(&adjDiffTime, adjDiffStart, adjDiffStop);
  
  // Display the results
  std::cout << "Number of random numbers: " << data_size;
  
  // (perform some formatting)
  if (data_size < 100000)
  {
    std::cout << "\t";
  }
  std::cout << "\tTotal difference size: " << result << "\tElapsed Time (ms): " << adjDiffTime << std::endl;
}

// Perfom a count of odd random numbers 32 << offset numbers
void add_odd_randoms(const unsigned int offset)
{
  // Compute the size of the data
  int data_size = 32 << offset;
  
  // Create events (for timing)
  cudaEvent_t randomStart;
  cudaEvent_t randomStop;
  
  cudaEventCreate(&randomStart);
  cudaEventCreate(&randomStop);
  
  // Record the current time
  cudaEventRecord(randomStart);

  // Create the host data vector
  thrust::host_vector<unsigned int> host_data(data_size);
  
  // Generate random data and place it in the host vector
  thrust::generate(host_data.begin(), host_data.end(), rand);
  
  // Create a device vector that copies the host data
  thrust::device_vector<unsigned int> device_data(host_data.begin(), host_data.end());
  
  // Create the vector that will contain the modulo value
  thrust::device_vector<unsigned int> modulo_data(data_size);
  
  // Fill the modulo vector with 2 (all data values will be modulo 2)
  thrust::fill(modulo_data.begin(), modulo_data.end(), 2);
  
  // Perform the modulo opereration in place
  thrust::transform(device_data.begin(), device_data.end(), modulo_data.begin(), device_data.begin(), thrust::modulus<unsigned int>());
  
  // Add the number of 1's together (the number of odd numbers)
  int count = thrust::reduce(device_data.begin(), device_data.end());
  
  // Stop recording
  cudaEventRecord(randomStop, 0);
  cudaEventSynchronize(randomStop);
  
  // Get the time duration
  float randomTime;
  
  cudaEventElapsedTime(&randomTime, randomStart, randomStop);
  
  // Display the results
  std::cout << "Number of random numbers: " << data_size;
  
  // (perform some formatting)
  if (data_size < 100000)
  {
    std::cout << "\t";
  }
  std::cout << "\tNumber of odd numbers: " << count << "\tElapsed Time (ms): " << randomTime << std::endl;
}

// The main entry point (inputs are ignored)
int main(int argc, char* argv[])
{
  // Seed the random number generator with the current time
  srand(time(NULL));
  
  // Iterate 20 times, calling each algorithm
  for (unsigned int i = 0; i < 20; ++i)
  {
    count_adj_diffs(i);
    add_odd_randoms(i);
  }

  return EXIT_SUCCESS;
}