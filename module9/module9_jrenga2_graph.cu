#include <string>
#include <fstream>
#include <sstream>
#include <iostream>

#include <nvgraph.h>

// Bibliography:
// [1] http://docs.nvidia.com/cuda/nvgraph/index.html#nvgraph-trianglescounting-example
// [2] https://en.wikipedia.org/wiki/Sparse_matrix#Compressed_sparse_row_(CSR,_CRS_or_Yale_format)

/// @brief In case of improper program usage, display the proper way to launch the program
void show_program_usage()
{
  std::cout << "Improper program use detected. Please see the following for instructions:"                     << std::endl;
  std::cout << "\tmodule9_jrenga2_graph.exe <input_file>"                                                      << std::endl;
  std::cout << ""                                                                                              << std::endl;
  std::cout << "input_file           - The input file containg the graph data. Must have a .dat extension. "   << std::endl;
  std::cout << ""                                                                                              << std::endl;
  std::cout << "Please verify your inputs and try again."                                                      << std::endl;
}

/// @brief Given a stream that contains graph information and an empty topology, fill
///        the contents of the topology with graph information in the CSR (compressed
///        sparse row) format. This assumes that the provided graph is undirected, and
///        thus only the lower-triangle of the matrix is being processed.
///
/// @param[in] stream   The input file stream pointing to graph data
/// @param[in] topology The empty nvgraphCSRTopology32I_t that will be filled
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
  std::getline(stream, line);
  
  // Need the number of vertices
  int num_vertices;
  int num_non_zero;
  
  std::stringstream metaData(line);
  
  metaData >> num_vertices;
  metaData >> num_non_zero;
  
  // Start filling out the contents of the provided topology
  topology->nvertices           = num_vertices;
  topology->nedges              = num_non_zero;
  topology->source_offsets      = (int*) calloc((num_vertices + 1), sizeof(int));
  topology->destination_indices = (int*) calloc(num_non_zero, sizeof(int));
  
  // Create an index for the destination_indices array
  int num_zero_counter = 0;

  // Create a number that will contain the current entry
  int data;

  int sum = 0;
  
  // Read each row of the adjacency matrix and perform the following:
  for (int i = 0; i < num_vertices + 1 && !stream.eof(); ++i)
  {
    // Read the next line
    std::getline(stream, line);
    
    // If we encounter a blank line, just skip it
    if (line == "")
    {
      continue;
    }
    
    // Put the line of data into something parsable
    std::stringstream adjData(line);
    
    for (int j = 0; j < i; ++j)
    {
      // Extract the current data value from the string stream
      adjData >> data;
      
      // If the data's non-zero, assign the current index
      if (data != 0)
      {
        topology->destination_indices[num_zero_counter++] = j;
        
        // Increase the number of non-zero number to-date
        ++sum;
      }
    }
    
    // Assign the current sum to the 1-indexed position
    topology->source_offsets[i + 1] = sum;
  }
  
  // The last entry in the source_offsets array will always be the number of non-zero entries
  // (may not be necessary, but better safe than sorry)
  topology->source_offsets[num_vertices] = num_non_zero;
}

/// @brief Perform the compute triangles algorithm and return the result
///
/// @param[in] topology  A nvgraphCSRTopology32I_t that has been properly initialized
///
/// @return The number of triangles located in the provided topology
uint64_t compute_triangles(nvgraphCSRTopology32I_t topology)
{
  // Create a handle for a graph
  nvgraphHandle_t graph_handle;
  nvgraphCreate(&graph_handle);
  
  // Create a graph description
  nvgraphGraphDescr_t graphDescription;
  nvgraphCreateGraphDescr(graph_handle, &graphDescription);
  
  // Assign the provided topology to the graph description
  nvgraphSetGraphStructure(graph_handle, graphDescription, (void*) topology, NVGRAPH_CSR_32);
  
  uint64_t triangle_count;
  
  // Perform the algorithm
  nvgraphTriangleCount(graph_handle, graphDescription, &triangle_count);
  
  // Perform cleanup
  nvgraphDestroyGraphDescr(graph_handle, graphDescription);
  nvgraphDestroy(graph_handle);
  
  // Return the result
  return triangle_count;
}

int main(int argc, char* argv[])
{
  if (argc != 2)
  {
    show_program_usage();
    return EXIT_FAILURE;
  }
  
  std::string input_file(argv[1]);
  
  size_t extension = input_file.find(".dat");
  if ((extension == std::string::npos) || extension != input_file.size() - 4)
  {
    std::cout << "File " << input_file << " does not have a .dat extension." << std::endl;
    show_program_usage();
    return EXIT_FAILURE;
  }
  
  // Create the graph stream
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

  // Populate the contents of the topology
  populate_topology(graphStream, graphTopology);
  
  // Close the stream (it's no longer needed)
  graphStream.close();
  
  // Get the number of triangles
  uint64_t triangle_count = compute_triangles(graphTopology);
  
  // Display the results
  if (triangle_count == 0)
  {
    std::cout << "No triangles were detected in the provided graph." << std::endl;
  }
  else
  {
    bool multipleTriangles = triangle_count > 1;
    
    std::cout << "Triangles were detected in the provided graph." << std::endl;
    std::cout << "There " << (multipleTriangles ? "are" : "is") << " " << triangle_count;
    std::cout << " triangle" << (multipleTriangles ? "s" : "") << " in the provded graph." << std::endl;
  }

  // Clean up
  free(graphTopology->source_offsets);
  free(graphTopology->destination_indices);
  free(graphTopology);
  
  return EXIT_SUCCESS;
}