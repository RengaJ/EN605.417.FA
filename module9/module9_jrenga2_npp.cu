#include <time.h>
#include <string>
#include <sstream>
#include <iostream>

#include <cuda_runtime.h>
#include <npp.h>

// Declare global host data here:
unsigned int initializedRNG = 0;

// @brief Initialize the Random number generator and ensure it only initializes one time
void initializeRandomNumbers()
{
  if (initializedRNG == 0)
  {
    srand(time(NULL));
    initializedRNG = 1;
  }
}

/// @brief Generate random number data, perform a simple thresholding. NOTE: **VERY** INEFFICIENT
///
/// @param [in] lengthModifier  The modifier 
void threshold_random_data(unsigned int lengthModifier)
{
  // Compute the total size of the npp32u array as 32 left-shifted by lengthModifier
  int data_size = 32 << lengthModifier;
  
  // Allocate the space for the data array
  Npp32s* signal1_data = nppsMalloc_32s(data_size);
  
  NppStatus returnStatus;
  
  Npp32s randomValue;
  
  // Attempt to fill the array with data.
  // Note that this implementation is the only way that I was able
  // to figure out how to assign different data to the array, and
  // is VERY inefficient
  for (int i = 0; i < data_size; ++i)
  {
    randomValue = rand();
    
    returnStatus = nppsSet_32s(randomValue, signal1_data + i, 1);
    
    if (returnStatus != NPP_SUCCESS && returnStatus != NPP_NO_ERROR)
    {
      std::cout << "Something failed attempting to set signal 1 data" << std::endl;
      std::cout << "Failure Code: " << returnStatus << std::endl;
      return;
    }
    
  }
  
  // Create the device buffer
  Npp8u deviceBuffer = 0;
  
  // Get the event handles for recording
  cudaEvent_t start;
  cudaEvent_t stop;
  
  // Create the event handles
  cudaEventCreate(&start);
  cudaEventCreate(&stop);
  
  // Record the start
  cudaEventRecord(start);
  
  // Get the maximum value of signal1_data
  Npp32s maximum_data_value;
  returnStatus = nppsMax_32s(signal1_data, data_size, &maximum_data_value, &deviceBuffer);
  
    if (returnStatus != NPP_SUCCESS && returnStatus != NPP_NO_ERROR)
    {
      std::cout << "Something failed attempting to get maximum" << std::endl;
      std::cout << "Failure Code: " << returnStatus << std::endl;
      return;
    }
  
  // Record the stop
  cudaEventRecord(stop);
  cudaEventSynchronize(stop);
  
  // Get the time
  float duration = 0;
  cudaEventElapsedTime(&duration, start, stop);
  
  // Print the results
  std::cout << "Data Size: " << data_size << "\t\tMaximum Value: " << maximum_data_value << "\tComputation Duration (ms): " << duration << std::endl;
  
  // Free the host data
  nppsFree((void*)signal1_data);
  
  cudaDeviceReset();
}

// The main entry point into the program.
int main(int argc, char* argv[])
{
  initializeRandomNumbers();
  
  for (unsigned int i = 0; i < 20; ++i)
  {
    threshold_random_data(i);
  }
  return EXIT_SUCCESS;
}