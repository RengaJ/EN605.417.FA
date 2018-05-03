#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include <CL/opencl.h>   // Include OpenCL

// Include "local" files
#include "Filereader.h"
#include "CommandLineParser.h"

#define DEFAULT_PLATFORM 0

inline void CheckError(cl_int error, std::string name)
{
  if (error != CL_SUCCESS)
  {
    std::cerr << "<<ERROR>> " << name << " (" << error << ") " << std::endl;
    exit(EXIT_FAILURE);
  }
}

/// @brief Get the number of platforms and the actual platform ids
///
/// @param [inout] platforms      A vector that contains the platform IDs
/// @param [inout] platformCount  The number of platforms
void getPlatforms(std::vector<cl_platform_id>& platforms, cl_uint& platformCount)
{
  // Get the platform counts
  cl_int error = clGetPlatformIDs(0, NULL, &platformCount);
  if (error == CL_SUCCESS && platformCount <= 0)
  {
    error = -1;
  }
  CheckError(error, "clGetPlatformIDs - Get Num Platforms");

  // Ensure the platform ID arrays are clear
  platforms.clear();
  platforms.resize(platformCount);

  // Get the platform IDs
  error = clGetPlatformIDs(platformCount, &platforms[0], NULL);
  if (error == CL_SUCCESS && platformCount <= 0)
  {
    error = -1;
  }
  CheckError(error, "clGetPlatformIDs - Get Platform IDs");
}

/// @brief Get the number of devices and the actual device ids
///
/// @params [inout] devices      A vector that contains the device IDs
/// @params [inout] deviceCount  The number of devices
void getDevices(std::vector<cl_device_id>& devices, cl_uint& deviceCount,
                std::vector<cl_platform_id>& platforms, cl_uint platformIndex)
{
  // Get the device counts
  cl_int error = clGetDeviceIDs(platforms[platformIndex],
                                CL_DEVICE_TYPE_ALL,
                                0,
                                NULL,
                                &deviceCount);
  if (error != CL_SUCCESS && error != CL_DEVICE_NOT_FOUND)
  {
    CheckError(error, "clGetDeviceIDs - Get Num Devices");
  }

  // Ensure the device ID arrays are clear
  devices.clear();
  devices.resize(deviceCount);

  // Get the device IDs
  error = clGetDeviceIDs(platforms[platformIndex],
                         CL_DEVICE_TYPE_ALL,
                         deviceCount,
                         &devices[0],
                         NULL);
}

/// @brief Get the context that is associated with a given platform
///
/// @param [inout] context     The context that is associated with a given platform
/// @param [in]    deviceIDs   The list of device IDs available on the system
/// @param [in]    deviceCount The number of devices available on the system
/// @param [in]    platform    The selected platform
void getContext(cl_context& context,
                std::vector<cl_device_id>& deviceIDs,
                cl_uint deviceCount,
                cl_platform_id& platform)
{
  cl_int error;
  cl_context_properties contextProperties[] =
  {
    CL_CONTEXT_PLATFORM,
    (cl_context_properties)platform,
    0
  };
  context = clCreateContext(contextProperties,
                            deviceCount,
                            &deviceIDs[0],
                            NULL,
                            NULL,
                            &error);

  CheckError(error, "clCreateContext");
}

int main(int argc, char* argv[])
{
  // Use the command-line parser to read the command-line arguments and return
  // an InputData structure
  InputData parsedInputs = CommandLineParser::ParseInput(argc, argv);

  // Display the provided inputs
  std::cout << std::endl;
  std::cout << "PROVIDED INPUTS:" << std::endl;
  std::cout << "****************" << std::endl;
  std::cout << "Input File Name: " << parsedInputs.inputFile << std::endl;
  std::cout << "Selected Kernel: " << parsedInputs.kernel    << std::endl;
  std::cout << "Timings Enabled: " << (parsedInputs.enableTimings ? "True" : "False") << std::endl;
  
  if (!parsedInputs.valid)
  {
    CommandLineParser::ShowProgramUsage();
    exit(EXIT_SUCCESS);
  }

  cl_uint platformCount;
  cl_uint deviceCount;
  std::vector<cl_platform_id> platforms;
  std::vector<cl_device_id> devices;

  cl_context context;

  // Get the platforms
  getPlatforms(platforms, platformCount);
  
  // Get the devices
  getDevices(devices, deviceCount, platforms, DEFAULT_PLATFORM);
  
  std::cout << std::endl;
  std::cout << "PLATFORM INFORMATION:"                  << std::endl;
  std::cout << "====================="                  << std::endl;
  std::cout << "Number of platforms: " << platformCount << std::endl;
  std::cout << "Number of devices  : " << deviceCount   << std::endl;

  // Get the context
  getContext(context, devices, deviceCount, platforms[DEFAULT_PLATFORM]);

  std::cout << "============================" << std::endl;
  std::cout << "CONTEXT CREATED SUCCESSFULLY" << std::endl;
  std::cout << "============================" << std::endl;

  return 0;
}