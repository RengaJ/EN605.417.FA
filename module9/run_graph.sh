#!/bin/bash

echo "Attempting to compile module9_jrenga2_graph.exe"

if [ -z "$NVCC_LIBRARY_PATH" ]; then
  echo "Please set the nvcc library path variable (NVCC_LIBRARY_PATH) for proper compilation."
  exit 1
fi

nvcc module9_jrenga2_graph.cu -L "$NVCC_LIBRARY_PATH" -lcudart -lnvgraph -o module9_jrenga2_graph.exe

echo "Attempting to run module9_jrenga2_graph.exe"
echo "-------------------------------------"
echo ""
echo "Enter file location (can be relative):"
read INPUT_FILE

./module9_jrenga2_graph.exe $INPUT_FILE