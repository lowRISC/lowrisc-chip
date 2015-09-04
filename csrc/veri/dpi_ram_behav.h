// See LICENSE for license details.

#ifndef DPI_RAM_BEHAV_H
#define DPI_RAM_BEHAV_H

#include <svdpi.h>

#ifdef __cplusplus
extern "C" {
#endif

  extern svBit memory_write_req (
                                 const svLogicVecVal *id_16b,
                                 const svLogicVecVal *addr_32b,
                                 const svLogicVecVal *len_8b,
                                 const svLogicVecVal *size_3b,
                                 const svLogicVecVal *user_16b
                                 );
  extern svBit memory_write_data (
                                  const svLogicVecVal *data_256,
                                  const svLogicVecVal *strb_32,
                                  const svLogic last
                                  );
  extern svBit memory_write_resp (
                                  svLogicVecVal *id_16b,
                                  svLogicVecVal *resp_2b,
                                  svLogicVecVal *user_16b
                                  );
  extern svBit memory_read_req (
                                const svLogicVecVal *id_16b,
                                const svLogicVecVal *addr_32b,
                                const svLogicVecVal *len_8b,
                                const svLogicVecVal *size_3b,
                                const svLogicVecVal *user_16b
                                );
  extern svBit memory_read_resp (
                                 svLogicVecVal *id_16b,
                                 svLogicVecVal *data_256b,
                                 svLogicVecVal *resp_2b,
                                 svLogic last,
                                 svLogicVecVal *user_16b
                                 );
#ifdef __cplusplus
}
#endif

#include <map>
#include <list>

class Memory32 {                // data width = 32-bit
  std::map<uint32_t, uint32_t> mem; // memory storage
  const uint32_t addr_max;          // the maximal address, 0 means all 32-bit

public:
  Memory32(uint32_t addr_max)
    : addr_max(addr_max) {}

  Memory32() : addr_max(0) {}

  // initialize a memory location with a value
  void init(const uint32_t addr, const uint32_t& data) {
    mem[addr] = data;
  }

  // write a value
  bool write(const uint32_t addr, const uint32_t& data, const uint32_t& mask);
  // read a value
  bool read(const uint32_t addr, uint32 &data);
};

class MemoryOperation {
public:
  bool rw;                      // write 1, read 0
  uint32_t tag;                 // transaction tag
  uint32_t addr;
  uint32_t data;
  uint32_t mask;                // byte-mask

  // default constructor
  MemoryOperation()
    : rw(0), tag(0), addr(0), data(0), mask(0) {}
  
  // normal constructor
  MemoryOperation(const bool rw, const uint32_t tag, const uint32_t addr,
                  const uint32_t data = 0, const unit32_t mask = 0xf)
    : rw(rw), tag(tag), addr(addr), data(data), mask(mask) {}

  // copy constructor
  MemoryOperation(const MemoryOperation& rhs)
    : rw(rhs.rw), tag(rhs.tag), addr(rhs.addr), data(rhs.data), mask(rhs.mask) {}
}


  class MemoryController {
    Memory32 mem;
    const unsigned int op_max;            // maximal parallel operation FIFOs
    std::list<MemoryOperation> *op_fifo;  // parallel operation FIFOs
    std::map<uint32_t, std::list<uint32_t> > resp_map; // the read response map
    unsigned int rr_index;                // round-robin index used to randomize operation handling

  public:
    MemoryController(const unsigned int op_max = 4)
      : op_max(op_max)
    {
      op_fifo = new std::list<MemoryOperation> [op_max];
      rr_index = 0;
    }

    virtual ~MemoryController() {
      delete[] op_fifo;
    }

    void add_read_req(const unsigned int fifo, const uint32_t tag, const uint32_t addr);
    void add_write_req(const unsigned int fifo, const uint32_t tag, const uint32_t addr, 
                       const uint32_t data, const unit32_t mask);
    // simulation step function
    void step();
    // get an empty queue
    bool load_balance(unsigned int&);
    std::list<uint32_t>& get_resp(const uint32_t tag) {
      return resp_map[tag];
    }

  };


// global memory controller
extern MemoryController *memory_controller

// AXI controllers
class AXIMemWriter {
  uint32_t tag;          // tag to denote the requestor
  uint32_t addr;         // the starting address of the write burst
  unsigned int len;      // the length of burst (-1)
  unsigned int size;     // the size of a beat
  uint32_t mask;         // the maximal mask defined by the size field
  unsigned int fifo;     // the chosen memory controller fifo
  bool valid;

public:
  AXIMemWriter()
    : valid(false) {}

  bool write_addr_req(const uint32_t tag, const uint32_t addr, unsigned int len, unsigned int size);
  bool write_data_req(const uint32_t *data, const uint32_t mask, bool last);
};

extern AXIMemWriter* axi_mem_writer;

class AXIMemReader {
  std::map<uint32_t, unsigned int> tracker_len;     // tracking burst length
  std::map<uint32_t, unsigned int> tracker_size;    // tracking beat size
public:
  bool reader_addr_req(const uint32_t tag, const uint32_t addr, unsigned int len, unsigned int size);
  bool reader_data_req(const uint32_t tag, uint32_t **data, bool *last);
};

extern AXIMemReader *axi_mem_reader;

#endif

// emacs local variable

// Local Variables:
// mode: c++
// End:
