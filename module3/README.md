MODULE 3 ASSIGNMENT:
====================

The Module 3 Assignment is to produce a program that will perform a simple arithmetic 
operation using CUDA and multiple blocks and threads per block. This is encapsulated in
the module_3_jrenga2.cu program.

To compile the program, run the following commmand (note that the library path *will* need 
to change*):

nvcc module_3_jrenga2.cu -L /cygdrive/c/Program\ Files/NVIDIA\ GPU\ Computing\ 
Toolkit/CUDA/v9.1/lib/x64/ -lcudart -o module_3_jrenga2.exe

To run the program, use the following format:

./module_3_jrenga2.exe <number of blocks> <threads per block>

If you miss an argument (or put too many in, or provide bad values), the program will 
inform you that a mistake was made and to please try again.

The output of the program will be a list of the values computed and in what index they 
reside.
