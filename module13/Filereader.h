#ifndef FILEREADER_H
#define FILEREADER_H

#include <fstream>

class Filereader
{
  public:
    Filereader(std::string filename);
      
    ~Filereader();
      
    bool exists();
      
    void readFile(std::string& data);
      
  private:
    std::ifstream _stream;
};

#endif