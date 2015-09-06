// See LICENSE for license details.

#include "dpi_ram_behav.h"
#include <cassert>
#include <cstdlib>
#include <cmath>
#include <algorithm>

using std::pair;
using std::list;

// the SystemVerilog DPI functions
svBit memory_write_req (
                        const svLogicVecVal *id_16b,
                        const svLogicVecVal *addr_32b,
                        const svLogicVecVal *len_8b,
                        const svLogicVecVal *size_3b,
                        const svLogicVecVal *user_16b
                        ) {
  // collect all data
  uint32_t id = SV_GET_UNSIGNED_BITS(id_16b[0].aval, 16);
  assert(SV_GET_UNSIGNED_BITS(id_16b[0].bval, 16) == 0);

  uint32_t addr = addr_32b[0].aval;
  assert(addr_32b[0].bval == 0);

  unsigned int len = SV_GET_UNSIGNED_BITS(len_8b[0].aval, 8);
  assert(SV_GET_UNSIGNED_BITS(len_8b[0].bval, 8) == 0);

  unsigned int size = SV_GET_UNSIGNED_BITS(size_3b[0].aval, 3);
  assert(SV_GET_UNSIGNED_BITS(size_3b[0].bval, 3) == 0);

  uint32_t user = SV_GET_UNSIGNED_BITS(user_16b[0].aval, 16);
  assert(SV_GET_UNSIGNED_BITS(user_16b[0].bval, 16) == 0);

  // call axi controller
  if(axi_mem_writer->write_addr_req((user<<16)|id, addr, len, size))
    return sv_1;
  else
    return sv_0;
}

svBit memory_write_data (
                         const svLogicVecVal *data_256,
                         const svLogicVecVal *strb_32,
                         const svLogic last
                         )
{
  // collect all data
  uint32_t data[8];
  for(int i=0; i<8; i++)
    data[i] = data_256[i].aval;
  uint32_t strb = strb_32[0].aval;
  bool last_m = last == sv_1;

  // call axi controller
  if(axi_mem_writer->write_data_req(data, strb, last_m))
    return sv_1;
  else
    return sv_0;
}

svBit memory_write_resp (
                         svLogicVecVal *id_16b,
                         svLogicVecVal *resp_2b,
                         svLogicVecVal *user_16b
                         )
{
  uint32_t tag;
  uint32_t resp;

  if(axi_mem_writer->writer_resp_req(&tag, &resp)) {
    id_16b[0].aval = tag & 0xffff;
    id_16b[0].bval = 0;
    resp_2b[0].aval = resp;
    resp_2b[0].bval = 0;
    user_16b[0].aval = tag >> 16;
    user_16b[0].bval = 0;
    return sv_1;
  } else {
    id_16b[0].aval = 0xffffffff;
    id_16b[0].bval = 0xffffffff;
    resp_2b[0].aval = 0xffffffff;
    resp_2b[0].bval = 0xffffffff;
    user_16b[0].aval = 0xffffffff;
    user_16b[0].bval = 0xffffffff;
    return sv_0;
  }
}

svBit memory_read_req (
                       const svLogicVecVal *id_16b,
                       const svLogicVecVal *addr_32b,
                       const svLogicVecVal *len_8b,
                       const svLogicVecVal *size_3b,
                       const svLogicVecVal *user_16b
                       )
{
  // collect all data
  uint32_t id = SV_GET_UNSIGNED_BITS(id_16b[0].aval, 16);
  assert(SV_GET_UNSIGNED_BITS(id_16b[0].bval, 16) == 0);

  uint32_t addr = addr_32b[0].aval;
  assert(addr_32b[0].bval == 0);

  unsigned int len = SV_GET_UNSIGNED_BITS(len_8b[0].aval, 8);
  assert(SV_GET_UNSIGNED_BITS(len_8b[0].bval, 8) == 0);

  unsigned int size = SV_GET_UNSIGNED_BITS(size_3b[0].aval, 3);
  assert(SV_GET_UNSIGNED_BITS(size_3b[0].bval, 3) == 0);
  
  uint32_t user = SV_GET_UNSIGNED_BITS(user_16b[0].aval, 16);
  assert(SV_GET_UNSIGNED_BITS(user_16b[0].bval, 16) == 0);
  
  // call axi controller
  if(axi_mem_reader->reader_addr_req((user<<16)|id, addr, len, size))
    return sv_1;
  else
    return sv_0;
}

svBit memory_read_resp (
                        svLogicVecVal *id_16b,
                        svLogicVecVal *data_256b,
                        svLogicVecVal *resp_2b,
                        svLogic *last,
                        svLogicVecVal *user_16b
                        )
{
  uint32_t tag;
  uint32_t data[8];
  uint32_t resp;
  bool last_m;

  if(axi_mem_reader->reader_data_req(&tag, data, &resp, &last_m, 8)) {
    id_16b[0].aval = tag & 0xffff;
    id_16b[0].bval = 0;
    for(int i=0; i<8; i++) {
      data_256b[i].aval = data[i];
      data_256b[i].bval = 0;
    }
    resp_2b[0].aval = resp;
    resp_2b[0].bval = 0;
    user_16b[0].aval = tag >> 16;
    user_16b[0].bval = 0;
    *last = last_m ? sv_1 : sv_0;
    return sv_1;
  } else {
    id_16b[0].aval = 0xffffffff;
    id_16b[0].bval = 0xffffffff;
    for(int i=0; i<8; i++) {
      data_256b[i].aval = 0xffffffff;
      data_256b[i].bval = 0xffffffff;
    }
    resp_2b[0].aval = 0xffffffff;
    resp_2b[0].bval = 0xffffffff;
    user_16b[0].aval = 0xffffffff;
    user_16b[0].bval = 0xffffffff;
    *last = sv_x;
    return sv_0;
  }
}

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
  mem[addr] = data_m;

  return true;
}

bool Memory32::read(const uint32_t addr, uint32_t &data) {
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
                                     const uint32_t data, const uint32_t mask) {
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
      MemoryOperation op = op_fifo[rr_index].front();
      op_fifo[rr_index].pop_front();
      rr_index = (rr_index + 1) % op_max;

      if(op.rw)
        mem.write(op.addr, op.data, op.mask);
      else {
        if(mem.read(op.addr, op.data))
          resp_map[op.tag].push_back(op.data);
        else
          resp_map[op.tag].push_back(0);
        if(resp_map[op.tag].size() % resp_len[op.tag] == 0)
          resp_que.push_back(op.tag);
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
      chosen = (chosen + 1) % op_max;
  }
  return false;                 // all fifos occupied
}

// find if there is any response ready
std::list<uint32_t>* MemoryController::get_resp(uint32_t &tag) {
  if(resp_que.empty()) return NULL;
  tag = resp_que.front();
  resp_que.pop_front();
  return &(resp_map[tag]);
}

// AXI controllers

bool AXIMemWriter::write_addr_req(const uint32_t tag, const uint32_t addr,
                                  const unsigned int len, const unsigned int size)
{
  if(valid) return false;       // another AXI write in operation

  // check whether there is an empty queue
  if(!memory_controller->load_balance(this->fifo))
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
    memory_controller->add_write_req(fifo, tag, addr, data[0], this->mask & mask);
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

  memory_controller->record_read_size(tag, size_m);
  return true;
}

bool AXIMemReader::reader_data_req(uint32_t *tag, uint32_t *data, uint32_t *resp, bool *last, const unsigned int width) {
  list<uint32_t> *read_resp = memory_controller->get_resp(*tag);
  if(read_resp == NULL) return false;

  unsigned int size = tracker_size[*tag];

  if(size < 4) {
    data[0] = read_resp->front();
    for(int i=1; i<width; i++) data[i] = 0;
    read_resp->pop_front();
  } else {
    for(int i=0; i<size/4; i++) {
      data[0] = read_resp->front();
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
