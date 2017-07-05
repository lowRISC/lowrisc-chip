// See LICENSE for license details.

#ifndef DPI_RAM_BEHAV_H
#define DPI_RAM_BEHAV_H

#include <svdpi.h>
#include <ostream>

#ifdef __cplusplus
extern "C" {
#endif

  extern svBit memory_write_req (
                                 const svBitVecVal *id_16b,
                                 const svBitVecVal *addr_32b,
                                 const svBitVecVal *len_8b,
                                 const svBitVecVal *size_3b,
                                 const svBitVecVal *user_16b
                                 );
  extern svBit memory_write_data (
                                  const svBitVecVal *data_256,
                                  const svBitVecVal *strb_32,
                                  const svBit last
                                  );
  extern svBit memory_write_resp (
                                  svBitVecVal *id_16b,
                                  svBitVecVal *resp_2b,
                                  svBitVecVal *user_16b
                                  );
  extern svBit memory_read_req (
                                const svBitVecVal *id_16b,
                                const svBitVecVal *addr_32b,
                                const svBitVecVal *len_8b,
                                const svBitVecVal *size_3b,
                                const svBitVecVal *user_16b
                                );
  extern svBit memory_read_resp (
                                 svBitVecVal *id_16b,
                                 svBitVecVal *data_256b,
                                 svBitVecVal *resp_2b,
                                 svBit *last,
                                 svBitVecVal *user_16b
                                 );
  extern svBit memory_model_init ();
  extern svBit memory_model_close ();
  extern svBit memory_model_step ();
  extern svBit memory_load_mem (const char* filename);

#ifdef __cplusplus
}
#endif

#include <map>
#include <list>
#include <string>

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
  // burst write
  void write_block(uint32_t addr, uint32_t size, const uint8_t* buf);
  // read a value
  bool read(const uint32_t addr, uint32_t &data);
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
                  const uint32_t data = 0, const uint32_t mask = 0xf)
    : rw(rw), tag(tag), addr(addr), data(data), mask(mask) {}

  // copy constructor
  MemoryOperation(const MemoryOperation& rhs)
    : rw(rhs.rw), tag(rhs.tag), addr(rhs.addr), data(rhs.data), mask(rhs.mask) {}

  // streamout (print)
  std::ostream& streamout(std::ostream& os) const;
};

inline std::ostream& operator<< (std::ostream& os, const MemoryOperation& rhs) {
  return rhs.streamout(os);
}

class MemoryController {
  Memory32 mem;
  const unsigned int op_max;            // maximal parallel operation FIFOs
  const unsigned int pending_max;       // maximal number of pending operations
  std::list<MemoryOperation> op_fifo;   // parallel operation FIFOs
  std::map<uint32_t, std::list<uint32_t> > resp_map; // the read response map
  std::map<uint32_t, unsigned int>         resp_len; // the len of each response
  std::list<uint32_t>                      resp_que;

public:
  MemoryController(const unsigned int op_max = 8, const unsigned int pending_max = 128)
    : op_max(op_max), pending_max(pending_max) {}

  void add_read_req(const uint32_t tag, const uint32_t addr);
  void record_read_size(const uint32_t tag, const unsigned int beat_size) {
    resp_len[tag] = beat_size;
  }
  void add_write_req(const uint32_t tag, const uint32_t addr,
                     const uint32_t data, const uint32_t mask);
  // simulation step function
  void step();
  // get an empty queue
  bool busy();
  std::list<uint32_t>* get_resp(uint32_t &tag);

  // load an initial memory
  void load_mem(const std::string& filename);
};

// global memory controller
extern MemoryController *memory_controller;

// AXI controllers
class AXIMemWriter {
  uint32_t tag;          // tag to denote the requestor
  uint32_t addr;         // the starting address of the write burst
  unsigned int len;      // the length of burst (-1)
  unsigned int size;     // the size of a beat
  uint32_t mask;         // the maximal mask defined by the size field
  unsigned int fifo;     // the chosen memory controller fifo
  bool valid;
  std::list<uint32_t> resps; // response queue

public:
  AXIMemWriter()
    : valid(false) {}

  bool write_addr_req(const uint32_t tag, const uint32_t addr, const unsigned int len, const unsigned int size);
  bool write_data_req(const uint32_t *data, const uint32_t mask, const bool last);

  bool writer_resp_req(uint32_t *tag, uint32_t *resp);
};

extern AXIMemWriter* axi_mem_writer;

class AXIMemReader {
  std::map<uint32_t, unsigned int> tracker_len;     // tracking burst length
  std::map<uint32_t, unsigned int> tracker_size;    // tracking beat size
public:
  bool reader_addr_req(const uint32_t tag, const uint32_t addr, const unsigned int len, const unsigned int size);
  bool reader_data_req(uint32_t *tag, uint32_t *data, uint32_t *resp, bool *last, const unsigned int width);
};

extern AXIMemReader *axi_mem_reader;

#endif

// emacs local variable

// Local Variables:
// mode: c++
// End:
