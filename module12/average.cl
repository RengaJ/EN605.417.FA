__kernel void average(__global * buffer)
{
  size_t id = get_global_id(0);
  
  //buffer[id] = buffer[id] * reciprocal;
  buffer[id] = buffer[id] * 2;
}