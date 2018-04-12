/// @brief A simple kernel for adding two numbers together
///
/// @param[   in] a      The first of two input vectors
/// @param[   in] b      The second of two input vectors
/// @param[inout] result The resulting output vector (a + a + b)

__kernel void pow_kernel(__global const float *a,
                         __global const float *b,
                         __global float *result )
{
  int globalId = get_global_id(0);
  
  result[globalId] = pow(a[globalId], b[globalId]);
}