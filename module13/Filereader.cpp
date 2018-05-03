#include "Filereader.h"
#include <string>
#include <sstream>

// Expected file-format:
//
// <number of entries>
// <entry list>
Filereader::Filereader(std::string filename)
{
  _stream = std::ifstream(filename.c_str());
}
  
Filereader::~Filereader()
{
  if (_stream && _stream.is_open())
  {
    _stream.close();
  }
}


bool Filereader::exists()
{
  return _stream.is_open();
}

/// @brief Read the contents of the file into std::string
///
/// @param [inout] data    The std::string containing the file data
void Filereader::readFile(std::string& data)
{
  data = std::string(std::istreambuf_iterator<char>(_stream),
                    (std::istreambuf_iterator<char>()));
}