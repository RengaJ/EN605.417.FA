#ifndef MODULE_8_JRENGA2_UTILITY_H
#define MODULE_8_JRENGA2_UTILITY_H

/// @brief Determine if the provided integer is a power of two.
///
/// @param [in] value   The value for which the power of two condition is to
///                     be checked.
///
/// @return A value of true will be returned if the provided value is a power of two,
///         otherwise a value of false will be returned.
bool isPowerOfTwo(const int value)
{
  // Initialize a mask a 00000000 00000000 00000000 00000001 (on 32-bit machines)
  int mask = 0x1;
  
  // Iterate over each of the bits in the mask, left shifting by one to
  // iterate to the next power of two
  for (unsigned int i = 0; i < sizeof(int) * 8; ++i, mask = mask << 1)
  {
   
    // Compute the resulting masked value
    int maskedValue = value & mask;
    
    // If the computed value is non-zero and is not the provided number,
    // the provided number is not a power of two:
    //
    // For example, 3 would not be a power of two:
    //           3 = 00000000 00000000 00000000 00000011
    //        mask = 00000000 00000000 00000000 00000010
    // maskedValue = 00000000 00000000 00000000 00000010
    // makedValue is non-zero (2), but is also not provided number (2 != 3)
    if (maskedValue != 0 && maskedValue != value)
    {
      return false;
    }
    
    // If the maskedValue is the provided number, then we've confirmed that the
    // value is a power of two
    if (maskedValue == value)
    {
      return true;
    }
  }
  
  // Return false if we've exhausted all possible powers of two the computer can handle
  return false;
}

#endif