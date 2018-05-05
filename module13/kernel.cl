__kernel void double_value(__global * buffer)
{
  size_t id = get_global_id(0);
  buffer[id] = buffer[id] * 2;
}

__kernel void cubic(__global * buffer)
{
  size_t id = get_global_id(0);
  buffer[id] = buffer[id] * buffer[id] * buffer[id];
}

__kernel void quartic(__global * buffer)
{
  size_t id = get_global_id(0);
  buffer[id] = buffer[id] * buffer[id] * buffer[id] * buffer[id];
}