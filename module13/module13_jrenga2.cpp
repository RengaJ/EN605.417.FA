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
#define KERNEL_COUNT 3
#define BUILD_LOG_SIZE 16384

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

/// @brief Create the program with a context and provided kernel source and
///        perform the compilation as well
///
/// @param [inout] program       The resulting program
/// @param [in]    context       The associated context
/// @param [in]    kernelSource  The contents of the kernel source.
void getProgram(cl_program& program,
                cl_context& context,
                std::string& kernelSource,
                cl_uint deviceCount,
                std::vector<cl_device_id>& deviceIDs)
{
  // Create the program
  const char* source = kernelSource.c_str();
  size_t length = kernelSource.length();
  cl_int error;
  program = clCreateProgramWithSource(context, 1, &source, &length, &error);
  
  // Check for errors
  CheckError(error, "clCreateProgramWithSource");
  
  // Build the program
  error = clBuildProgram(program, deviceCount, &deviceIDs[0], "-I.", NULL, NULL);
  
  // Check for errors and display any compilation failures
  if (error != CL_SUCCESS)
  {
    char buildLog[BUILD_LOG_SIZE];
    clGetProgramBuildInfo(program,
                          deviceIDs[0],
                          CL_PROGRAM_BUILD_LOG,
                          sizeof(buildLog),
                          buildLog,
                          NULL);
    std::cout << "<<<<<<<<<<<<<<<<<<<" << std::endl;
    std::cout << "OpenCL BUILD ERRORS" << std::endl;
    std::cout << buildLog              << std::endl;
    std::cout << "<<<<<<<<<<<<<<<<<<<" << std::endl;
    
    CheckError(error, "clBuildProgram");
  }
}

/// @brief Create the command queue to be associated with a given device and context
///
/// @param [inout] queue         The resulting command queue
/// @param [in]    context       The context to assocaite with the command queue
/// @param [in]    device        The device to associate with the command queue
/// @param [in]    enableTiming  Flag to enable queue profiling
void getQueue(cl_command_queue& queue,
              cl_context& context,
              cl_device_id& device,
              bool enableTiming)
{
  cl_int error;
  
  // Determine if profiling should be enabled (timing profiling)
  cl_command_queue_properties property = (enableTiming ? CL_QUEUE_PROFILING_ENABLE : 0);
  
  queue = clCreateCommandQueue(context, device, property, &error);
  
  CheckError(error, "clCreateCommandQueue");
}

/// @brief Create a kernel given a particular function and a program
///
/// @param [inout] kernel          The resulting kernel object
/// @param [in]    program         The program that contains the provided function name
/// @param [in]    kernelFunction  The name of the kernel to create an object from
/// @param [in]    buffer          The buffer used as the kernel input
void createKernel(cl_kernel& kernel,
                  cl_program& program,
                  std::string kernelFunction,
                  cl_mem& buffer)
{
  cl_int error;
  
  kernel = clCreateKernel(program, kernelFunction.c_str(), &error);
  CheckError(error, "clCreateKernel");
  
  error = clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&buffer);
  CheckError(error, "clSetKernelArg");
}

/// @brief Given a context and a size, create a buffer that will contain input data
///
/// @param [inout] buffer    The resulting buffer object
/// @param [in]    context   The associated context
/// @param [in]    inputSize The number of elements in the input
void getBuffer(cl_mem& buffer, cl_context& context, size_t inputSize)
{
  cl_int error;
  
  buffer = clCreateBuffer(context,
                          CL_MEM_READ_WRITE,
                          sizeof(int) * inputSize,
                          NULL,
                          &error);

  CheckError(error, "clCreateBuffer");
}

void writeToBuffer(std::vector<int>& inputData,
                   cl_command_queue& commandQueue,
                   cl_mem& buffer,
                   cl_event& event)
{
  cl_int error;
  error = clEnqueueWriteBuffer(commandQueue,
                               buffer,
                               CL_FALSE,                       /* ENSURE NON-BLOCKING */
                               0,
                               sizeof(int) * inputData.size(),
                               (void*)&inputData[0],
                               0,
                               NULL,
                               &event);
  CheckError(error, "clEnqueueWriteBuffer");
}
/// @brief The main entry point into the program
///
/// @param [in] argc   The number of arguments to the program (including the program name)
/// @param [in] argv   The array of arguments to the program (including the program name)
int main(int argc, char* argv[])
{
  // Use the command-line parser to read the command-line arguments and return
  // an InputData structure
  InputData parsedInputs = CommandLineParser::ParseInput(argc, argv);
  
  if (!parsedInputs.valid)
  {
    CommandLineParser::ShowProgramUsage();
    exit(EXIT_SUCCESS);
  }
  
  // Ensure the provided input file exists
  Filereader inputReader(parsedInputs.inputFile);
  if (!inputReader.exists())
  {
    std::cout << std::endl;
    std::cout << "||| ERROR ||| PROVIDED INPUT FILE DOES NOT EXIST." << std::endl;
    exit(EXIT_FAILURE);
  }
  
  // Retrieve the contents of the kernel file (hard-coded here)
  std::string kernelSource;
  Filereader kernelReader("kernel.cl");
  kernelReader.readFile(kernelSource);
  
  cl_uint platformCount;
  cl_uint deviceCount;
  std::vector<cl_platform_id> platforms;
  std::vector<cl_device_id> devices;

  cl_context context;

  // Get the platforms
  getPlatforms(platforms, platformCount);
  
  // Get the devices
  getDevices(devices, deviceCount, platforms, DEFAULT_PLATFORM);

  // Get the context
  getContext(context, devices, deviceCount, platforms[DEFAULT_PLATFORM]);

  // Create the program
  cl_program kernelProgram;
  getProgram(kernelProgram, context, kernelSource, deviceCount, devices);
  
  // Create the command queue
  std::vector<cl_command_queue> commandQueues;
  commandQueues.resize((parsedInputs.multipleQueues ? KERNEL_COUNT : 1));
  for (int i = 0; i < commandQueues.size(); ++i)
  {
    getQueue(commandQueues[i], context, devices[0], parsedInputs.enableTimings);
  }
  
  // Create the buffer to contain the input data
  std::vector<int> inputData;
  inputReader.readFile(inputData);
 
  char* kernelFunctions[3] = {"double_value", "cubic", "quartic"};
  std::vector<cl_mem> buffers;
  std::vector<cl_kernel> kernels;
  for (int i = 0; i < KERNEL_COUNT; ++i)
  { 
    cl_mem buffer;
    getBuffer(buffer, context, inputData.size()); 
    
    // Create the kernel and the buffers
    cl_kernel kernelObject;
    createKernel(kernelObject, kernelProgram, kernelFunctions[i], buffer);
    
    buffers.push_back(buffer);
    kernels.push_back(kernelObject);
  }
  
  // WRITE TO BUFFER (ADD ALL EVENTS TO AN EVENT LIST)
  std::vector<cl_event> eventList;
  for (int i = 0; i < KERNEL_COUNT; ++i)
  {
    int queueIndex = (parsedInputs.multipleQueues ? i : 0);
    cl_event event;
    writeToBuffer(inputData, commandQueues[queueIndex], buffers[i], event);
    
    eventList.push_back(event);
  }
  
  std::cout << "BUFFER WRITES ENQUEUED" << std::endl;
  
  // [ENQUEUE EVENT WAIT LIST BARRIER]
  clWaitForEvents(eventList.size(), &eventList[0]);
  
  std::cout << "BUFFER WRITES COMPLETED" << std::endl;
  
  // 2. ENQUEUE KERNELS (ADD ALL EVENTS TO AN EVENT LIST)
  // 3. READ FROM BUFFER (ADD ALL EVENTS TO AN EVENT LIST)
  
  ///////////////////////////////////////////////////////////////////////////////////////////
  //
  ///////////////////////////////////////////////////////////////////////////////////////////
  
  return 0;
}