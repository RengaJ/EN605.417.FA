#!/bin/bash

echo "Attempting to compile module13_jrenga2.exe"

if [ -z "$NVCC_LIBRARY_PATH" ]; then
  echo "Please set the nvcc library path variable (NVCC_LIBRARY_PATH) for proper compilation."
  exit 1
fi

if [ -z "$CUDA_INCLUDE_PATH" ]; then
  echo "Please set the cuda include path variable (CUDA_INCLUDE_PATH) for proper compilation."
  exit 1
fi

nvcc -I "$CUDA_INCLUDE_PATH" -L "$NVCC_LIBRARY_PATH" -lOpenCL CommandLineParser.cpp Filereader.cpp module13_jrenga2.cpp -o module13_jrenga2.exe

echo "TEST 1: INPUT FILE 1 WITH MULTIPLE QUEUES AND TIMING"
./module13_jrenga2.exe input.dat --multiple --enable-timing
read -s
clear

echo "TEST 2: INPUT FILE 1 WITH SINGLE QUEUE AND TIMING"
./module13_jrenga2.exe input.dat --single --enable-timing
read -s
clear

echo "TEST 3: INPUT FILE 1 WITH MULTIPLE QUEUES AND NO TIMING"
./module13_jrenga2.exe input.dat --multiple
read -s
clear

echo "TEST 4: INPUT FILE 1 WITH SINGLE QUEUE AND NO TIMING"
./module13_jrenga2.exe input.dat --single
read -s
clear

echo "TEST 5: INPUT FILE 2 WITH SINGLE QUEUE AND TIMING"
./module13_jrenga2.exe input_2.dat --multiple --enable-timing
