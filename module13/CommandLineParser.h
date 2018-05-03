#ifndef GPU_FFT_COMMAND_LINE_PARSER_H
#define GPU_FFT_COMMAND_LINE_PARSER_H

#include "InputData.h"

class CommandLineParser
{
	public:
		static InputData ParseInput(int argc, char* argv[]);
    static void      ShowProgramUsage();
	private:
		CommandLineParser() {}   // DO NOTHING
		~CommandLineParser() {}  // DO NOTHING
};
#endif