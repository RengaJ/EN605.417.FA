#!/bin/bash

echo "Attempting to compile module9_jrenga2_thrust.exe"

if [ -z "$NVCC_LIBRARY_PATH" ]; then
  echo "Please set the nvcc library path variable (NVCC_LIBRARY_PATH) for proper compilation."
  exit 1
fi

nvcc module9_jrenga2_thrust.cu -L "$NVCC_LIBRARY_PATH" -lcudart -o module9_jrenga2_thrust.exe

#echo "Attempting to run module9_jrenga2_thrust.exe"
#echo "-------------------------------------"
#echo ""
#echo "Enter Maximum Block Count:"
#read BLOCK_COUNT
#echo "Enter Maximum Threads Per Block:"
#read THREAD_COUNT
#
./module9_jrenga2_thrust.exe
#RETVAL=$?
#
#if [ $RETVAL -eq 0 ]; then
#  echo "Execution was successful! :)"
#else
#  echo "Execution failed!"
#fi
#
#echo ""
#cat stdout.log
#rm  stdout.log