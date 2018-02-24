#!/bin/bash

echo "Attempting to compile module_4_jrenga2.exe"

if [ -z "$NVCC_LIBRARY_PATH" ]; then
  echo "Please set the nvcc library path variable (NVCC_LIBRARY_PATH) for proper compilation."
  exit 1
fi

nvcc module_4_jrenga2.cu -L "$NVCC_LIBRARY_PATH" -lcudart -o module_4_jrenga2.exe

echo "Attemping to run module_4_jrenga2.exe"
echo "-------------------------------------"
echo ""

./module_4_jrenga2.exe
RETVAL=$?

if [ $RETVAL -eq 0 ]; then
  echo "Execution was successful! :)"
else
  echo "Execution failed! :("
  exit 1
fi

exit 0
