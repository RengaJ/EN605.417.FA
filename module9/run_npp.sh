#!/bin/bash

echo "Attempting to compile module9_jrenga2_npp.exe"

if [ -z "$NVCC_LIBRARY_PATH" ]; then
  echo "Please set the nvcc library path variable (NVCC_LIBRARY_PATH) for proper compilation."
  exit 1
fi

nvcc module9_jrenga2_npp.cu -L "$NVCC_LIBRARY_PATH" -lnppc -lnppial -lnppicc -lnppicom -lnppidei -lnppif -lnppig -lnppim -lnppist -lnppisu -lnppitc -lnpps -o module9_jrenga2_npp.exe

echo "Attempting to run module9_jrenga2_npp.exe"
echo "-------------------------------------"
echo ""

./module9_jrenga2_npp.exe