//
// Book:      OpenCL(R) Programming Guide
// Authors:   Aaftab Munshi, Benedict Gaster, Timothy Mattson, James Fung, Dan Ginsburg
// ISBN-10:   0-321-74964-2
// ISBN-13:   978-0-321-74964-2
// Publisher: Addison-Wesley Professional
// URLs:      http://safari.informit.com/9780132488006/
//            http://www.openclprogrammingguide.com
//


// Convolution.cpp
//
//    This is a simple example that demonstrates OpenCL platform, device, and context
//    use.

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <cmath>
#include <time.h>

#ifdef __APPLE__
#include <OpenCL/cl.h>
#else
#include <CL/cl.h>
#endif

#if !defined(CL_CALLBACK)
#define CL_CALLBACK
#endif

#define MAX_ITERATIONS 2

// Define the input signal to be a 49x49 array:
const unsigned int inputSignalWidth  = 49;
const unsigned int inputSignalHeight = 49;
cl_uint inputSignal[inputSignalWidth][inputSignalHeight];

const unsigned int outputSignalWidth  = 7;
const unsigned int outputSignalHeight = 7;

cl_float outputSignal[outputSignalWidth][outputSignalHeight];

// Define the mask to be a 7x7 array:
const unsigned int maskWidth  = 7;
const unsigned int maskHeight = 7;
cl_float mask[maskWidth][maskHeight] =
{
  {0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50},
  {0.50, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75},
  {0.50, 0.75, 1.00, 1.00, 1.00, 1.00, 1.00},
  {0.50, 0.75, 1.00, 0.00, 1.00, 0.75, 0.50},
  {0.50, 0.75, 1.00, 1.00, 1.00, 0.75, 0.50},
  {0.50, 0.75, 0.75, 0.75, 0.75, 0.75, 0.50},
  {0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50},
};

///
// Function to check and handle OpenCL errors
inline void checkErr(cl_int err, const char* name)
{
    if (err != CL_SUCCESS)
    {
        std::cerr << "ERROR: " <<  name << " (" << err << ")" << std::endl;
        exit(EXIT_FAILURE);
    }
}

void CL_CALLBACK contextCallback(const char * errInfo,
                                 const void * private_info,
                                 size_t cb,
                                 void * user_data)
{
	std::cout << "Error occured during context use: " << errInfo << std::endl;
	// should really perform any clearup and so on at this point
	// but for simplicitly just exit.
	exit(1);
}

void run_kernel()
{
  cl_int           errNum;             // Keep track of the current error value
  cl_uint          numPlatforms;       // Keep track of the number of platforms available
	cl_uint          numDevices;         // Keep track of the number of devices available
  cl_platform_id*  platformIDs;        // Keep track of the available platform IDs
	cl_device_id*    deviceIDs;          // Keep track of the available device IDs
  cl_context       context = NULL;     // Keep track of the current context
	cl_command_queue queue;              // Keep track of the current command queue
	cl_program       program;            // Keep track of the convolution kernel program
	cl_kernel        kernel;             // Keep track of the convolve kernel function
	cl_mem           inputSignalBuffer;  // Keep track of the buffer data holding the input signal
	cl_mem           outputSignalBuffer; // Keep track of the buffer data holding the output signal
	cl_mem           maskBuffer;         // Keep track of the buffer data holding the mask
  cl_event         event;              // Keep track of an event for timing purposes

  // First, select an OpenCL platform to run on.
  // 1. Get the number of available platforms
	errNum = clGetPlatformIDs(0, NULL, &numPlatforms);
	checkErr((errNum != CL_SUCCESS) ? errNum : (numPlatforms <= 0 ? -1 : CL_SUCCESS), "clGetPlatformIDs"); 
 
  // 2. Allocate the array for the number of available platform IDs
	platformIDs = (cl_platform_id *)alloca(sizeof(cl_platform_id) * numPlatforms);

  // 3. Get the list of platform IDs
  errNum = clGetPlatformIDs(numPlatforms, platformIDs, NULL);
  checkErr((errNum != CL_SUCCESS) ? errNum : (numPlatforms <= 0 ? -1 : CL_SUCCESS), "clGetPlatformIDs");

	// Iterate through the list of platforms until we find one that supports
	// a GPU device, otherwise fail with an error.
	deviceIDs = NULL;
	cl_uint i;
	for (i = 0; i < numPlatforms; i++)
	{
		errNum = clGetDeviceIDs(platformIDs[i], CL_DEVICE_TYPE_GPU, 0, NULL, &numDevices);
		if (errNum != CL_SUCCESS && errNum != CL_DEVICE_NOT_FOUND)
	  {
		  checkErr(errNum, "clGetDeviceIDs");
    }
	  else if (numDevices > 0) 
	  {
		  deviceIDs = (cl_device_id *)alloca(sizeof(cl_device_id) * numDevices);
			errNum = clGetDeviceIDs(platformIDs[i], CL_DEVICE_TYPE_GPU, numDevices,  &deviceIDs[0], NULL);
			checkErr(errNum, "clGetDeviceIDs");
			break;
	  }
	}

  // Next, create an OpenCL context on the selected platform.  
  cl_context_properties contextProperties[] =
  {
    CL_CONTEXT_PLATFORM,
    (cl_context_properties)platformIDs[i],
    0
  };
  context = clCreateContext(contextProperties, numDevices, deviceIDs, &contextCallback, NULL, &errNum);
	checkErr(errNum, "clCreateContext");

	std::ifstream srcFile("Convolution.cl");
  checkErr(srcFile.is_open() ? CL_SUCCESS : -1, "reading Convolution.cl");

	std::string srcProg(std::istreambuf_iterator<char>(srcFile), (std::istreambuf_iterator<char>()));

	const char * src = srcProg.c_str();
	size_t length    = srcProg.length();

	// Create program from source
	program = clCreateProgramWithSource(context, 1, &src, &length, &errNum);
  checkErr(errNum, "clCreateProgramWithSource");

	// Build program
	errNum = clBuildProgram(program, numDevices, deviceIDs, NULL, NULL, NULL);
  if (errNum != CL_SUCCESS)
  {
    // Determine the reason for the error
    char buildLog[16384];
    clGetProgramBuildInfo(program, deviceIDs[0], CL_PROGRAM_BUILD_LOG, sizeof(buildLog), buildLog, NULL);
    std::cerr << "Error in kernel: " << std::endl;
    std::cerr << buildLog;
		checkErr(errNum, "clBuildProgram");
  }

	// Create kernel object
	kernel = clCreateKernel(program, "convolve", &errNum);
	checkErr(errNum, "clCreateKernel");
  
  // Iterate by row and column
  for (unsigned int r = 0; r < inputSignalHeight; ++r)
  {
    for (unsigned int c = 0; c < inputSignalWidth; ++c)
    {
      // Generate a random number
      unsigned int randomNum = (unsigned int)(std::abs(rand()));
      
      // Ensure the number is somewhere between 0 and 9,
      // and assign its value to the current position within the data array
      inputSignal[r][c] = (cl_uint)randomNum % 10;
      if (r < outputSignalHeight && c < outputSignalWidth)
      {
        outputSignal[r][c] = 0;
      }
    }
  }
  
	// Now allocate buffers
  
  // The first buffer to create in the input signal buffer
  // Note that this buffer is READ ONLY and will be copied to the device
  // Note that the fourth argument performs the data copying into the buffer itself
	inputSignalBuffer = clCreateBuffer(context,
                                     CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                     sizeof(cl_uint) * inputSignalHeight * inputSignalWidth,
                                     static_cast<void *>(inputSignal),
                                     &errNum);
	checkErr(errNum, "clCreateBuffer(inputSignal)");

  // The second buffer to create is the mask buffer
  // Note that this buffer is READ ONLY and will be copied to the device
  // Note that the fourth argument performs the data copying into the buffer itself
	maskBuffer = clCreateBuffer(context,
                              CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                              sizeof(cl_float) * maskHeight * maskWidth,
                              static_cast<void *>(mask),
                              &errNum);
	checkErr(errNum, "clCreateBuffer(mask)");

  // The final buffer to create is the output signal buffer
  // Note that this is WRITE ONLY (no need to read from it)
  // Note that no copying is performed here, since we want the buffer to be empty initially
	outputSignalBuffer = clCreateBuffer(context,
                                      CL_MEM_WRITE_ONLY,
                                      sizeof(cl_float) * outputSignalHeight * outputSignalWidth,
                                      NULL,
                                      &errNum);
	checkErr(errNum, "clCreateBuffer(outputSignal)");

	// Pick the first device and create command queue.
  // Make sure to enable profiling capabilities
	queue = clCreateCommandQueue(context, deviceIDs[0], CL_QUEUE_PROFILING_ENABLE, &errNum);
	checkErr(errNum, "clCreateCommandQueue");

  // Ensure that the arguments to the kernel are set appropriately
  errNum  = clSetKernelArg(kernel, 0, sizeof(cl_mem),  &inputSignalBuffer);
	errNum |= clSetKernelArg(kernel, 1, sizeof(cl_mem),  &maskBuffer);
  errNum |= clSetKernelArg(kernel, 2, sizeof(cl_mem),  &outputSignalBuffer);
	errNum |= clSetKernelArg(kernel, 3, sizeof(cl_uint), &inputSignalWidth);
	errNum |= clSetKernelArg(kernel, 4, sizeof(cl_uint), &maskWidth);
	checkErr(errNum, "clSetKernelArg");

  // Set the number of workers, both the total and the number of workers per executing core
	const size_t globalWorkSize[1] = { outputSignalWidth * outputSignalHeight };
  const size_t localWorkSize [1] = { 1 };

  // Queue the kernel up for execution across the array
  errNum = clEnqueueNDRangeKernel(queue,
                                  kernel,
                                  1,
                                  NULL,
                                  globalWorkSize,
                                  localWorkSize,
                                  0,
                                  NULL,
                                  &event);
	checkErr(errNum, "clEnqueueNDRangeKernel");
  
  // Get the profile information
  clWaitForEvents(1, &event);
  clFinish(queue);
    
  // Retrieve the data from the outputSignalBuffer into the pre-prepared output array
	errNum = clEnqueueReadBuffer(queue,
                               outputSignalBuffer,
                               CL_TRUE,
                               0,
                               sizeof(cl_float) * outputSignalHeight * outputSignalWidth,
                               outputSignal,
                               0,
                               NULL,
                               NULL);
	checkErr(errNum, "clEnqueueReadBuffer");
  
  for (unsigned int i = 0; i < outputSignalHeight; ++i)
  {
    for (unsigned int j = 0; j < outputSignalWidth; ++j)
    {
      std::cout << outputSignal[i][j] << " ";
    }
    std::cout << std::endl;
  }

  cl_ulong times[2];
  
  clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_START, sizeof(cl_ulong), &times[0], NULL);
  clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_END  , sizeof(cl_ulong), &times[1], NULL);
  
  double milliseconds = (times[1] - times[0]) / 1000000.0;
  std::cout << "*********** Duration (ms): " << milliseconds << std::endl;
}

///
//	main() for Convoloution example
//
int main(int argc, char** argv)
{
  // Seed the random number generator with the current time
  srand(time(NULL));
  
  for (unsigned int i = 0; i < MAX_ITERATIONS; ++i)
  {
    run_kernel();
  }
  
  return EXIT_SUCCESS;
}