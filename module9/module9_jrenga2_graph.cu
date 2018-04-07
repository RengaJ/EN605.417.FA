#include <string>
#include <ifstream>
#include <stringstream>

#include <nvgraph.h>

void show_program_usage()
{
  std::cout << "Improper program use detected. Please see the following for instructions:"                     << std::endl;
  std::cout << "\tmodule9_jrenga2_graph.exe <input_file>"                                                      << std::endl;
  std::cout << ""                                                                                              << std::endl;
  std::cout << "input_file           - The input file containg the graph data. Must have a .dat extension. "   << std::endl;
  std::cout << ""                                                                                              << std::endl;
  std::cout << "Please verify your inputs and try again."                                                      << std::endl;
}

void populate_topology(std::ifstream& stream, nvgraphCSRTopology32I_t topology)
{
  // Expected file format:
  //
  // <# vertices> <# non zero>
  // [                  ]
  // [                  ]
  // [ ADJACENCY MATRIX ]
  // [                  ]
  // [                  ]
  
  std::string line;
  std::getline(stream, line)
  
  // Need the number of vertices
  int num_vertices;
  int num_non_zero;
  
  std::stringstream metadata(line);
  
  metaData >> num_vertices;
  metaData >> num_non_zero;
  
  topology->nvertices           = num_vertices;
  topology->nedges              = num_non_zero;
  topology->source_offsets      = (int*) calloc((num_vertices + 1), sizeof(int));
  topology->destination_offsets = (int*) calloc(num_non_zero, sizeof(int));
    
  int num_zero_counter = 0;
  int data;
  int sum = 0;
  
  // Read each row of the adjacency matrix and perform the following:
  for (int i = 0; i < num_vertices; ++i)
  {
    if (!std::getline(stream, line).good())
    {
      break;
    }
    
    std::stringstream adjData(line);
    
    for (int j = 0; j < i; ++j)
    {
      adjData >> data;
      if (data != 0)
      {
        ++topology->
        destination_offsets[num_zero_counter];
        ++sum;
      }
    }
    
    topology->source_offsets[i + 1] = sum;
    ++num_zero_counter;
  }
}

int main(int argc, char* argv)
{
  if (argc != 2)
  {
    show_program_usage();
    return EXIT_FAILURE;
  }
  
  std::string input_file = argv[1];
  
  size_t extension = input_file.find(".dat");
  if ((extension == std::string::npos) || extension != input_file.size() - 4)
  {
    std::cout << "File " << input_file << " does not have a .dat extension." << std::endl;
    show_program_usage();
    return EXIT_FAILURE;
  }
  
  // Create the image stream
  std::ifstream imageStream(input_file);
  
  if (!imageStream.good())
  {
    std::cout << "File " << input_file << " not found." << std::endl;
    show_program_usage();
    
    return EXIT_FAILURE;
  }
   
  // Close the stream
  imageStream.close();
  
  return EXIT_SUCCESS;
}