#!/bin/bash

echo "Attempting to compile module_3_jrenga2.exe"

if [ -z "$NVCC_LIBRARY_PATH" ]; then
  echo "Please set the nvcc library path variable (NVCC_LIBRARY_PATH) for proper compilation."
  exit 1
fi

nvcc module_3_jrenga2.cu -L "$NVCC_LIBRARY_PATH" -lcudart -o module_3_jrenga2.exe

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
  cat stdout.log
  rm stdout.log
  exit 1
fi
