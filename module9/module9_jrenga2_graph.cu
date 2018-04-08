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
  
  // Start filling out the contents of the provided topology
  topology->nvertices           = num_vertices;
  topology->nedges              = num_non_zero;
  topology->source_offsets      = (int*) calloc((num_vertices + 1), sizeof(int));
  topology->destination_offsets = (int*) calloc(num_non_zero, sizeof(int));
  
  // Create an index for the destination_offsets array
  int num_zero_counter = 0;

  // Create a number that will contain the current entry
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
        ++topology->destination_offsets[num_zero_counter];
        ++sum;
      }
    }
    
    topology->source_offsets[i + 1] = sum;
    ++num_zero_counter;
  }

  std::cout << "[DEBUG]  NUM_VERTICES: " << num_vertices << std::endl;
  std::cout << "[DEBUG]  NUM_NON_ZERO: " << num_non_zero << std::endl;
  std::cout << "[DEBUG]  topology->source_offsets: {";

  for (int i = 0; i < num_vertices + 1; ++i)
  {
    std::cout << topology->source_offsets[i];
    if (i < num_vertices - 1)
    {
      std::cout << ", ";
    }
  }
  std::cout << "}" << std::endl;


  std::cout << "[DEBUG]  topology->destination_offets: {";
  for (int i = 0; i < num_non_zero; ++i)
  {
    std::cout << topology->destination_offsets[i];
    if (i < num_non_zero - 1)
    {
      std::cout << ", ";
    }
  }

  std::cout << "}" << std::endl;
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
  std::ifstream graphStream(input_file);
  
  if (!graphStream.good())
  {
    std::cout << "File " << input_file << " not found." << std::endl;
    show_program_usage();

    graphStream.close();
    
    return EXIT_FAILURE;
  }

  // Allocate memory for the graph topology
  // Note that the nvgraphCSRTopology32I_t is a typedef for
  //   struct nvgraphCSRTopology32I_st*, so the correct type must be provided
  //   to malloc for proper construction
  nvgraphCSRTopology32I_t graphTopology =
    (nvgraphCSRTopology32I_t)malloc(sizeof(struct nvgraphCSRTopology32I_st));

  populate_topology(graphStream, graphTopology);
   
  // Close the stream
  graphStream.close();

  free(graphTopology.source_offsets);
  free(graphTopology.destination_offsets);
  free(graphTopology);
  
  return EXIT_SUCCESS;
}