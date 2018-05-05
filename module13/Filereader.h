#ifndef FILEREADER_H
#define FILEREADER_H

#include <vector>
#include <fstream>

class Filereader
{
  public:
    Filereader(std::string filename);
      
    ~Filereader();
      
    bool exists();
      
    void readFile(std::string& data);
    void readFile(std::vector<int>& input);
      
  private:
    std::ifstream _stream;
};

#endif