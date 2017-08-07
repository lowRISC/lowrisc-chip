// See LICENSE for license details.

#ifndef DPI_HOST_BEHAV_H
#define DPI_HOST_BEHAV_H

#include <svdpi.h>

#ifdef __cplusplus
extern "C" {
#endif

  // purely legacy code for ISA regression test
  extern void host_req (unsigned int id, unsigned long long data);
  extern int check_exit ();

#ifdef __cplusplus
}
#endif

#endif
