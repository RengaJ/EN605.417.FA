__kernel void sub_kernel(__global const float *a, __global const float *b, __global float *result)
{
  int globalId = get_global_id(0);
  
  result[globalId] = a[globalId] - b[globalId];
}