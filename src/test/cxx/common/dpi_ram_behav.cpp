// See LICENSE for license details.

#include "globals.h"
#include "dpi_ram_behav.h"
#include <cassert>
#include <cmath>
#include <algorithm>
#include <fstream>
#include <iostream>
#include <boost/lexical_cast.hpp>
#include <boost/format.hpp>
#include <iostream>
#include <functional>
#include "loadelf.hpp"

using std::pair;
using std::list;
using std::string;
using std::ifstream;
using boost::lexical_cast;
using boost::format;

// global objects
MemoryController *memory_controller;
AXIMemWriter* axi_mem_writer;
AXIMemReader *axi_mem_reader;

// the SystemVerilog DPI functions
svBit memory_write_req (
                        const svBitVecVal *id_16b,
                        const svBitVecVal *addr_32b,
                        const svBitVecVal *len_8b,
                        const svBitVecVal *size_3b,
                        const svBitVecVal *user_16b
                        ) {
  // collect all data
  uint32_t id = SV_GET_UNSIGNED_BITS(id_16b[0], 16);
  uint32_t addr = addr_32b[0];
  unsigned int len = SV_GET_UNSIGNED_BITS(len_8b[0], 8);
  unsigned int size = SV_GET_UNSIGNED_BITS(size_3b[0], 3);
  uint32_t user = SV_GET_UNSIGNED_BITS(user_16b[0], 16);
  uint32_t tag = (user<<16)|id;

  // call axi controller
  if(axi_mem_writer->write_addr_req(tag, addr, len, size)) {
#ifdef VERBOSE_MEMORY
    std::cout << format("memory write request: %1$x @ %2$x [%3$x]") % tag % addr % (len+1) << std::endl;
#endif
    return sv_1;
  } else
    return sv_0;
}

svBit memory_write_data (
                         const svBitVecVal *data_256,
                         const svBitVecVal *strb_32,
                         const svBit last
                         )
{
  // collect all data
  uint32_t data[8];
  for(int i=0; i<8; i++)
    data[i] = data_256[i];
  uint32_t strb = strb_32[0];
  bool last_m = last == sv_1;

  // call axi controller
  if(axi_mem_writer->write_data_req(data, strb, last_m)) {
#ifdef VERBOSE_MEMORY
    std::cout << format("memory write data: %1$08x %2$08x %3$08x %4$08x") % data[3] % data[2] % data[1] % data[0] << std::endl;
#endif
    return sv_1;
  } else
    return sv_0;
}

svBit memory_write_resp (
                         svBitVecVal *id_16b,
                         svBitVecVal *resp_2b,
                         svBitVecVal *user_16b
                         )
{
  uint32_t tag;
  uint32_t resp;

  if(axi_mem_writer->writer_resp_req(&tag, &resp)) {
    id_16b[0] = tag & 0xffff;
    resp_2b[0] = resp;
    user_16b[0] = tag >> 16;
    return sv_1;
  } else {
    return sv_0;
  }
}

svBit memory_read_req (
                       const svBitVecVal *id_16b,
                       const svBitVecVal *addr_32b,
                       const svBitVecVal *len_8b,
                       const svBitVecVal *size_3b,
                       const svBitVecVal *user_16b
                       )
{
  // collect all data
  uint32_t id = SV_GET_UNSIGNED_BITS(id_16b[0], 16);
  uint32_t addr = addr_32b[0];
  unsigned int len = SV_GET_UNSIGNED_BITS(len_8b[0], 8);
  unsigned int size = SV_GET_UNSIGNED_BITS(size_3b[0], 3);
  uint32_t user = SV_GET_UNSIGNED_BITS(user_16b[0], 16);
  uint32_t tag = (user<<16)|id;


  // call axi controller
  if(axi_mem_reader->reader_addr_req(tag, addr, len, size)) {
#ifdef VERBOSE_MEMORY
    std::cout << format("memory read request: %1$x @ %2$x") % tag % addr << std::endl;
#endif
    return sv_1;
  } else
    return sv_0;
}

svBit memory_read_resp (
                        svBitVecVal *id_16b,
                        svBitVecVal *data_256b,
                        svBitVecVal *resp_2b,
                        svBit *last,
                        svBitVecVal *user_16b
                        )
{
  uint32_t tag;
  uint32_t data[8];
  uint32_t resp;
  bool last_m;

  if(axi_mem_reader->reader_data_req(&tag, data, &resp, &last_m, 8)) {
#ifdef VERBOSE_MEMORY
    std::cout << format("memory read resp: %1$x with data %2$08x %3$08x %4$08x %5$08x") % tag % data[3] % data[2] % data[1] % data[0]<< std::endl;
#endif
    id_16b[0] = tag & 0xffff;
    for(int i=0; i<8; i++) {
      data_256b[i] = data[i];
    }
    resp_2b[0] = resp;
    user_16b[0] = tag >> 16;
    *last = last_m ? sv_1 : sv_0;
    return sv_1;
  } else {
    return sv_0;
  }
}

svBit memory_model_init()
{
  memory_controller = new MemoryController(4);
  axi_mem_writer = new AXIMemWriter;
  axi_mem_reader = new AXIMemReader;
}

svBit memory_model_close()
{
  delete memory_controller;
  delete axi_mem_writer;
  delete axi_mem_reader;
}

svBit memory_model_step()
{
  memory_controller->step();
}

svBit memory_load_mem(const char* filename)
{
  memory_controller->load_mem(filename);
}

// Memory module

bool Memory32::write(const uint32_t addr, const uint32_t& data, const uint32_t& mask) {
  assert((addr & 0x3) == 0);
  if(addr_max != 0 && addr >= addr_max) return false;

  uint32_t data_m = mem[addr];
  for(int i=0; i<4; i++) {
    if((mask & (1 << i))) { // write when mask[i] is 1'b1
      data_m = (data_m & ~(0xff << i*8)) | (data & (0xff << i*8));
    }
  }
  mem[addr] = data_m;

  //std::cout << format("memory32 write [%1$08x] = %2$08x") % addr % data_m << std::endl;
  return true;
}

void Memory32::write_block(uint32_t addr, uint32_t size, const uint8_t* buf) {
  uint32_t burst_size = 4;
  uint32_t mask = (1 << burst_size) - 1;

  // prologue
  if(uint32_t offset = addr%4) {
    uint32_t m_size = 4 - offset;
    mask >>= (m_size > size) ? m_size - size : 0;
    m_size = (m_size > size) ? size : m_size;
    mask <<= offset;
    write(addr - offset, *((uint32_t*)(buf - offset)), mask);
    size -= m_size;
    buf += m_size;
    addr += m_size;
  }

  // block write
  mask = (1 << burst_size) - 1;
  while(size >= burst_size) {
    write(addr, *((uint32_t*)(buf)), mask);
    size -= burst_size;
    buf += burst_size;
    addr += burst_size;
  }

  // epilogue
  if(size) {
    write(addr, *((uint32_t*)(buf)), (1 << size) - 1);
  }
}

bool Memory32::read(const uint32_t addr, uint32_t &data) {
  assert((addr & 0x3) == 0);
  if(addr_max != 0 && addr >= addr_max || !mem.count(addr)) return false;

  data = mem[addr];

  //std::cout << format("memory32 read [%1$08x] = %2$08x") % addr % data << std::endl;
  return true;
}

// memory operation
std::ostream& MemoryOperation::streamout(std::ostream& os) const {
  if(rw) os << "write: ";
  else   os << "read:  ";
  os << format("%1$x @ %2$x m%3$x t%4$x") % data % addr % mask % tag;
  return os;
}

// Memory controller

void MemoryController::add_read_req(const uint32_t tag, const uint32_t addr) {
  op_fifo.push_back(MemoryOperation(0, tag, addr));
}

void MemoryController::add_write_req(const uint32_t tag, const uint32_t addr, 
                                     const uint32_t data, const uint32_t mask) {
  op_fifo.push_back(MemoryOperation(1, tag, addr, data, mask));
}

void MemoryController::step() {
  // decide to handle how many operations
  unsigned int rand_num = 1 + (rand() % op_max);
  
  for(int i=0; i<rand_num; i++) {
    if(!op_fifo.empty()) {
      // get the operation
      MemoryOperation op = op_fifo.front();
      op_fifo.pop_front();

      if(op.rw) {
        mem.write(op.addr, op.data, op.mask);
      } else {
        if(mem.read(op.addr, op.data))
          resp_map[op.tag].push_back(op.data);
        else {
          resp_map[op.tag].push_back(0);
        }

        if(resp_map[op.tag].size() % resp_len[op.tag] == 0) {
          resp_que.push_back(op.tag);
        }
      }
    }
  }
}
  
// return the least loaded queue
bool MemoryController::busy() {
  return op_fifo.size() >= pending_max;
}

// find if there is any response ready
std::list<uint32_t>* MemoryController::get_resp(uint32_t &tag) {
  if(resp_que.empty()) return NULL;
  tag = resp_que.front();
  resp_que.pop_front();
  return &(resp_map[tag]);
}

// load initial memory
void MemoryController::load_mem(const string& filename) {
  using namespace std::placeholders;
  std::function<void(uint32_t, uint32_t, const uint8_t*)> f =
    std::bind(&Memory32::write_block, &mem, _1, _2, _3);
  elfLoader loader = elfLoader(f);
  loader(filename);
}

// AXI controllers

bool AXIMemWriter::write_addr_req(const uint32_t tag, const uint32_t addr,
                                  const unsigned int len, const unsigned int size)
{
  if(valid) return false;       // another AXI write in operation

  // check whether there is an empty queue
  if(memory_controller->busy())
    return false;               // no empty queue

  // register the request
  this->tag = tag;
  this->addr = addr;
  this->len = len;
  this->size = (unsigned int)(pow(2, size));
  this->mask = (1 << this->size) - 1;
  this->valid = true;

  return true;
}

bool AXIMemWriter::write_data_req(const uint32_t *data, const uint32_t mask,
                                  const bool last)
{
  uint32_t mask_m = mask;

  if(!valid) return false;      // have not received an address request yet
  
  if(size < 4) {
    memory_controller->add_write_req(tag, addr, data[0], this->mask & mask);
    addr += size;
  } else {
    for(int i=0; i<size/4; i++) {
      memory_controller->add_write_req(tag, addr, data[i], mask_m & 0xf);
      addr += 4;
      mask_m >>= 4;
    }
  }

  if(len) len--;
  else {
#ifdef DELAY_EXIT
    if(!last) {
      std::cerr << main_time << " Error: AXI write last mismatch!" << std::endl;
      exit_code = 1;
      exit_delay = 100;
    }
#else
    assert(last);
#endif
    valid = false;
    resps.push_back(tag);
  }
  return true;
}

bool AXIMemWriter::writer_resp_req(uint32_t *tag, uint32_t *resp) {
  if(resps.empty()) return false;
  
  *tag = resps.front();
  *resp = 0;
  resps.pop_front();
  return true;
}

bool AXIMemReader::reader_addr_req(const uint32_t tag, const uint32_t addr, const unsigned int len, const unsigned int size) {
  unsigned int fifo;
  unsigned int size_m = (unsigned int)(pow(2, size));
  unsigned int len_m = len + 1;
  uint32_t addr_m = addr;

  // check whether there is an empty queue
  if(memory_controller->busy())
    return false;               // no empty queue

  // fire the read requests
  tracker_len[tag] = len;
  tracker_size[tag] = size_m;

  if(size_m < 4) {
    for(int i=0; i<len_m; i++) {
      memory_controller->add_read_req(tag, addr_m);
      addr_m += size_m;
    }
    memory_controller->record_read_size(tag, 1);
  } else {
    for(int i=0; i<len_m*size_m/4; i++) {
      memory_controller->add_read_req(tag, addr_m);
      addr_m += 4;
    }
    memory_controller->record_read_size(tag, size_m/4);
  }

  return true;
}

bool AXIMemReader::reader_data_req(uint32_t *tag, uint32_t *data, uint32_t *resp, bool *last, const unsigned int width) {
  list<uint32_t> *read_resp = memory_controller->get_resp(*tag);
  if(read_resp == NULL) return false;

  unsigned int size = tracker_size[*tag];

  if(size < 4) {
    data[0] = read_resp->front();
    read_resp->pop_front();
    for(int i=1; i<width; i++) data[i] = 0;
  } else {
    for(int i=0; i<size/4; i++) {
      data[i] = read_resp->front();
      read_resp->pop_front();
    }
    for(int i=size/4; i<width; i++) data[i] = 0;
  }
  
  *last = false;
  if(tracker_len[*tag] == 0)
    *last = true;
  else
    tracker_len[*tag]--;

  *resp = 0;

  return true;
}
