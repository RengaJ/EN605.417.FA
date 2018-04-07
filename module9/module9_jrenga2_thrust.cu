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

// http://docs.nvidia.com/cuda/thrust/index.html



// Perform a simple value replacement algorithm
void count_adj_diffs(const unsigned int offset)
{
  int data_size = 32 << offset;
  
  cudaEvent_t adjDiffStart;
  cudaEvent_t adjDiffStop;
  
  cudaEventCreate(&adjDiffStart);
  cudaEventCreate(&adjDiffStop);
  
  cudaEventRecord(adjDiffStart);
  
  thrust::host_vector<unsigned int> host_data(data_size);
  thrust::device_vector<unsigned int> results(data_size);
  
  thrust::generate(host_data.begin(), host_data.end(), rand);
  thrust::device_vector<unsigned int> device_data(host_data.begin(), host_data.end());
  
  thrust::adjacent_difference(device_data.begin(), device_data.end(), results.begin());
  
  int result = thrust::reduce(results.begin(), results.end());
  
  cudaEventRecord(adjDiffStop, 0);
  cudaEventSynchronize(adjDiffStop);
  
  float adjDiffTime;
  
  cudaEventElapsedTime(&adjDiffTime, adjDiffStart, adjDiffStop);
  
  std::cout << "Number of random numbers: " << data_size;
  if (data_size < 100000)
  {
    std::cout << "\t";
  }
  std::cout << "\tTotal difference size: " << result << "\tElapsed Time (ms): " << adjDiffTime << std::endl;
}

// Perfom a count of odd random numbers 32 << offset numbers
void add_odd_randoms(const unsigned int offset)
{
  int data_size = 32 << offset;
  
  cudaEvent_t randomStart;
  cudaEvent_t randomStop;
  
  cudaEventCreate(&randomStart);
  cudaEventCreate(&randomStop);
  
  cudaEventRecord(randomStart);

  thrust::host_vector<unsigned int> host_data(data_size);
  
  thrust::generate(host_data.begin(), host_data.end(), rand);
  
  thrust::device_vector<unsigned int> device_data(host_data.begin(), host_data.end());
  thrust::device_vector<unsigned int> modulo_data(data_size);
  
  thrust::fill(modulo_data.begin(), modulo_data.end(), 2);
  
  thrust::transform(device_data.begin(), device_data.end(), modulo_data.begin(), device_data.begin(), thrust::modulus<unsigned int>());
  
  int count = thrust::reduce(device_data.begin(), device_data.end());
  
  cudaEventRecord(randomStop, 0);
  cudaEventSynchronize(randomStop);
  
  float randomTime;
  
  cudaEventElapsedTime(&randomTime, randomStart, randomStop);
  
  std::cout << "Number of random numbers: " << data_size;
  if (data_size < 100000)
  {
    std::cout << "\t";
  }
  std::cout << "\tNumber of odd numbers: " << count << "\tElapsed Time (ms): " << randomTime << std::endl;
}


int main(int argc, char* argv[])
{
  srand(time(NULL));
  
  for (unsigned int i = 0; i < 20; ++i)
  {
    count_adj_diffs(i);
    add_odd_randoms(i);
  }

  return EXIT_SUCCESS;
}