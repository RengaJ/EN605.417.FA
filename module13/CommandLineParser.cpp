#include "CommandLineParser.h"

#include <iostream>
#include <string>

InputData CommandLineParser::ParseInput(int argc, char* argv[])
{
  // Create an empty InputData structure to be filled out
  InputData parsedInputs;

  // Check the number of arguments to ensure they are correct:
  if (argc < 3 || argc > 4)
  {
    // If the number of arguments is not correct, return the empty
    // (and invalid) InputData structure.
    //
    // This should be handled by the caller.

    std::cout << "<< ERROR >> INVALID NUMBER OF ARGUMENTS PROVIDED";
    std::cout << " - EXPECTED 2 OR 3, DETECTED " << (argc - 1) << std::endl;

    return parsedInputs;
  }

  // We know that the number of arguments is correct. Now it's time to
  // properly parse the values. First is the input file-name. It should
  // terminate with a '.dat' extension:
  std::string inputFilename(argv[1]);
  size_t inputSize = inputFilename.length();
  if (inputFilename.substr(inputSize - 4, 4) != ".dat")
  {
    // If .dat is not the final four characters of the input filename,
    // return the empty (and invalid) InputData structure.

    std::cout << "<< ERROR >> PROVIDED INPUT FILE DOES NOT HAVE .DAT EXTENSION" << std::endl;

    return parsedInputs;
  }

  // At this point, the input file should be okay, so assign the value into the
  // InputData structure
  parsedInputs.inputFile = inputFilename;

  // Check the kernel flag
  std::string kernelFlag = argv[2];

  if (kernelFlag == "--cubic")        { parsedInputs.kernel = "cubic";   }
  else if (kernelFlag == "--quartic") { parsedInputs.kernel = "quartic"; }
  else if (kernelFlag == "--double")  { parsedInputs.kernel = "double";  }
  else
  {
    // If an invalid flag is found, return the 
    // current state of the parsed inputs
    std::cout << "<< ERROR >> INVALID ALGORITHM DETECTED" << std::endl;

    return parsedInputs;
  }

  // Check for the final
  if (argc == 4)
  {
    std::string timing = argv[3];
    if (timing == "--enable-timing")
    {
      parsedInputs.enableTimings = true;
    }
    else
    {
      std::cout << "<< ERROR >> INVALID TIMING FLAG DETECTED" << std::endl;

      return parsedInputs;
    }
  }

  // At this point, the inputs are properly assigned and valid, so make the
  // structure indicate this.
  parsedInputs.valid = true;

  // Return the completed InputData structure
  return parsedInputs;
}

void CommandLineParser::ShowProgramUsage()
{
  std::cout << std::endl;
  std::cout << std::endl;
  std::cout << "----------------------------------------------------------------------------------" << std::endl;
  std::cout << " EXPECTED PROGRAM USAGE"                                                            << std::endl;
  std::cout << ""                                                                                   << std::endl;
  std::cout << "module13_jrenga2.exe <INPUT FILE> <KERNEL FILE> [TIMINGS]"                          << std::endl;
  std::cout << ""                                                                                   << std::endl;
  std::cout << "<INPUT FILE>  -- REQUIRED -- Indicates the name of the input file. Must have an   " << std::endl;
  std::cout << "                             extension of '.dat'"                                   << std::endl;
  std::cout << "<KERNEL FILE> -- REQUIRED -- Indicates what kernel should be used for execution.  " << std::endl;
  std::cout << "                             Can be one of the following:"                          << std::endl;
  std::cout << "                                --cubic   : Cube the input"                         << std::endl;
  std::cout << "                                --quartic : Raise the input the fourth power"       << std::endl;
  std::cout << "                                --double  : Double the input"                       << std::endl;
  std::cout << "[TIMINGS]     -- OPTIONAL -- Indicates if timings should be recorded and displayed" << std::endl;
  std::cout << "                             Enable with the '--enable-timing' value. "             << std::endl;
  std::cout << "----------------------------------------------------------------------------------" << std::endl;
}