#ifndef GPU_FFT_INPUT_DATA_H
#define GPU_FFT_INPUT_DATA_H

#include <string>

struct InputData
{
	/// @brief Constructor for the InputData structure
	InputData()
	{
		inputFile      = "__INVALID__";
    multipleQueues = false;
    enableTimings  = false;
		valid          = false;
	}

	std::string inputFile;  // The name of the input file
  bool multipleQueues;    // Enable multiple queue processing
  bool enableTimings;     // Enable timing operations
	bool valid;             // Was the input successfully parsed?
};
#endif