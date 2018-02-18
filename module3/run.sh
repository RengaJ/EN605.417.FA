#!/bin/bash

echo "Attempting to compile module_3_jrenga2.exe"
echo "************************************************************"
echo "** WARNING: THIS WAS COMPILED ON A WINDOWS MACHINE!       **"
echo "**          THE COMPILATION MAY FAIL DUE TO LIBRARY PATH  **"
echo "**          ISSUES. IF THIS HAPPENS, PLEASE MODIFY THIS   **"
echo "**          COMMAND TO USE THE PROPER PATH!               **"
echo "************************************************************"

nvcc module_3_jrenga2.cu -L /cygdrive/c/Program\ Files/NVIDIA\ GPU\ Computing\ Toolkit/CUDA/v9.1/lib/x64/ -lcudart -o module_3_jrenga2.exe

echo "Attemping to run module_3_jrenga2.exe"
echo "-------------------------------------"
echo ""
echo "Enter Block Count:"
read BLOCK_COUNT
echo "Enter Threads Per Block:"
read THREAD_COUNT

./module_3_jrenga2.exe $BLOCK_COUNT $THREAD_COUNT > stdout.log
RETVAL=$?

if [ $RETVAL -eq 0 ]; then
  echo "Execution was successful! :)"
  echo "Tail of output:"
  tail stdout.log
  rm stdout.log
else
  echo "Execution failed! :("
  exit 1
fi
