// See LICENSE for license details.

#ifndef LOADELF_CXX_HEADER
#define LOADELF_CXX_HEADER

#include <cstdlib>
#include <functional>
#include <map>
#include <string>

typedef std::function<void(uint32_t, uint32_t, const uint8_t*)> write_callback;

class elfLoader {
  // write callback function void write(paddr, size, pbuffer)
  const write_callback write;
  
public:
  elfLoader(write_callback func) : write(func) {}

  // load an elf file
  std::map<std::string, uint64_t> operator() (const std::string&);
};


#endif
