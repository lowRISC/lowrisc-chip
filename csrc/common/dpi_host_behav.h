// See LICENSE for license details.

#ifndef DPI_HOST_BEHAV_H
#define DPI_HOST_BEHAV_H

#include <svdpi.h>

#ifdef __cplusplus
extern "C" {
#endif

  extern void host_resp (unsigned int id, unsigned long long data);
  extern void host_req (unsigned int id, unsigned long long data);

#ifdef __cplusplus
}
#endif

inline uint8_t host_extract_device(uint64_t data) {
  return data >> 56;
}

inline uint8_t host_extract_cmd(uint64_t data) {
  return data >> 48;
}

inline uint64_t host_extract_payload(uint64_t data) {
  return data << 16 >>16;
}


#endif
