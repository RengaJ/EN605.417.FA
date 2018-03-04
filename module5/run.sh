#!/bin/bash

echo "Attempting to compile module_5_jrenga2.exe"

if [ -z "$NVCC_LIBRARY_PATH" ]; then
  echo "Please set the nvcc library path variable (NVCC_LIBRARY_PATH) for proper compilation."
  exit 1
fi

nvcc module_5_jrenga2.cu -L "$NVCC_LIBRARY_PATH" -lcudart -o module_5_jrenga2.exe

echo "Attempting to run module_5_jrenga2.exe"
echo "-------------------------------------"
echo ""
echo "Enter Block Count:"
read BLOCK_COUNT
echo "Enter Threads Per Block:"
read THREAD_COUNT

./module_5_jrenga2.exe $BLOCK_COUNT $THREAD_COUNT > stdout.log
RETVAL=$?

if [ $RETVAL -eq 0 ]; then
  echo "Execution was successful! :)"
else
  echo "Execution failed!"
fi

cat stdout.log
rm stdout.log
