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
  bool write(const uint32_t addr, const uint32_t& data, const uint32_t& mask) {
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

  // read a value
  bool read(const uint32_t addr, uint32 *data) {
    if(addr >= addr_max || !mem.count(addr)) return false;

    *data = mem[addr];

    return true;
  }

}


#endif

// emacs local variable

// Local Variables:
// mode: c++
// End:
