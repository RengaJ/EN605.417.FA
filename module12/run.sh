#!/bin/bash

echo "Attempting to compile module12_jrenga2.exe"

if [ -z "$NVCC_LIBRARY_PATH" ]; then
  echo "Please set the nvcc library path variable (NVCC_LIBRARY_PATH) for proper compilation."
  exit 1
fi

if [ -z "$CUDA_INCLUDE_PATH" ]; then
  echo "Please set the cuda include path variable (CUDA_INCLUDE_PATH) for proper compilation."
  exit 1
fi

nvcc -I "$CUDA_INCLUDE_PATH" -L "$NVCC_LIBRARY_PATH" -lOpenCL module12_jrenga2.cpp -o module12_jrenga2.exe

./module12_jrenga2.exe

