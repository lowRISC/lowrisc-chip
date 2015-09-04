// See LICENSE for license details.

#include "dpi_ram_behav.h"
#include <cassert>
#include <cstdlib>
#include <cmath>
#include <algorithm>

using std::pair;
using std::list;

// the SystemVerilog DPI functions


// Memory module

bool Memory32::write(const uint32_t addr, const uint32_t& data, const uint32_t& mask) {
  assert(addr & 0xf == 0);
  if(addr >= addr_max) return false;

  uint32_t data_m = mem[addr];
  for(int i=0; i<4; i++) {
    if((mask & (1 << i))) { // write when mask[i] is 1'b1
      data_m = (data_m & ~(0xff << i*8)) | (data & (0xff << i*8));
    }
  }
  mem[addr] = rdata;

  return true;
}

bool Memory32::read(const uint32_t addr, uint32 &data) {
  assert(addr & 0xf == 0);
  if(addr >= addr_max || !mem.count(addr)) return false;

  data = mem[addr];

  return true;
}

// Memory controller

void MemoryController::add_read_req(const unsigned int fifo, const uint32_t tag, const uint32_t addr) {
  assert(fifo < op_max);
  op_fifo[fifo].push_back(MemoryOperation(0, tag, addr));
}

void MemoryController::add_write_req(const unsigned int fifo, const uint32_t tag, const uint32_t addr, 
                                     const uint32_t data, const unit32_t mask) {
  assert(fifo < op_max);
  op_fifo[fifo].push_back(MemoryOperation(1, tag, addr, data, mask));
}

void MemoryController::step() {
  // decide to handle how many operations
  const unsigned int max_random = 2048;
  const double random_step = (double)(max_random) / op_max;
  unsigned int rand_num = rand() % max_random;
  unsigned int op_total = 1 + ceil(rand_num / random_step);

  for(int i=0; i<op_total; i++) {
    if(!op_fifo[rr_index].empty()) {
      // get the operation
      MemoryOperation op = op_fifo[rr_index].fron();
      op_fifo[rr_index].pop_front();
      rr_index++;

      if(op.rw)
        mem.write(op.addr, op.data, op.mask);
      else {
        if(mem.read(op.addr, op.data))
          resp_map[op.tag].push_back(op.data);
        else
          resp_map[op.tag].push_back(0);
      }
    }
  }
}
  
// return the least loaded queue
bool MemoryController::load_balance(unsigned int &chosen) {
  chosen = rr_index;
  for(int i=0; i<op_max; i++) {
    if(op_fifo[chosen].empty())
      return true;
    else
      chosen++;
  }
  return false;                 // all fifos occupied
}

// AXI controllers

bool AXIMemWriter::write_addr_req(const uint32_t tag, const uint32_t addr, unsigned int len, unsigned int size) {
  if(valid) return false;       // another AXI write in operation
  
  // check whether there is an empty queue
  if(!memory_controller->load_balance(this.fifo))
    return false;               // no empty queue

  // register the request
  this.tag = tag;
  this.addr = addr;
  this.len = len;
  this.size = (unsigned int)(pow(2, size));
  this.mask = (1 << this.size) - 1;
  this.valid = true;

  return true;
}

bool AXIMemWriter::write_data_req(const uint32_t *data, const uint32_t mask, bool last) {
  uint32_t mask_m = mask;

  if(!valid) return false;      // have not received an address request yet
  
  if(size < 4) {
    memory_controller->add_write_req(fifo, tag, addr, data[0], this.mask & mask);
    addr += size;
  } else {
    for(int i=0; i<size/4; i++) {
      memory_controller->add_write_req(fifo, tag, addr, data[i], mask_m & 0xf);
      addr += 4;
      mask_m >>= 4;
    }
  }

  if(len) len--;
  else {
    assert(last);               // last should be high
    valid = false;
  }

  return true;
}

bool AXIMemReader::reader_addr_req(const uint32_t tag, const uint32_t addr, unsigned int len, unsigned int size) {
  unsigned int fifo;
  unsigned int size_m = (unsigned int)(pow(2, size));
  unsigned int len_m = len + 1;
  uint32_t addr_m = addr;

  // check whether there is an empty queue
  if(!memory_controller->load_balance(fifo))
    return false;               // no empty queue

  // fire the read requests
  tracker_len[tag] = len;
  tracker_size[tag] = size_m;

  if(size_m < 4) {
    for(int i=0; i<=len_m; i++) {
      memory_controller->add_read_req(fifo, tag, addr_m);
      addr_m += size_m;
    }
  } else {
    for(int i=0; i<=len_m*size_m/4; i++) {
      memory_controller->add_read_req(fifo, tag, addr_m);
      addr_m += 4;
    }
  }

  return true;
}

bool AXIMemReader::reader_data_req(const uint32_t tag, uint32_t **data, bool *last) {
  list<uint32_t> &resp = memory_controller->get_resp(tag);
  unsigned int size = tracker_size[tag];

  if(size < 4) {
    if(resp.empty()) return false;
    *data = new uint32_t [1];
    (*data)[0] = resp.front();
    resp.pop_front();
  } else {
    if(resp.size() < size/4) return false;
    *data = new uint32_t [size/4];
    for(int i=0; i<size/4; i++) {
      (*data)[0] = resp.front();
      resp.pop_front();
    }
  }
  
  *last = false;
  if(tracker_len[tag] == 0)
    *last = true;
  else
    tracker_len[tag]--;

  return true;
}
