/*----------------------------------------------------------------------------
 * Copyright (c) 2013-2015, The Regents of the University of California (Regents).
 * All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the Regents nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 * 
 * IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
 * SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF REGENTS HAS
 * BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED
 * HEREUNDER IS PROVIDED "AS IS". REGENTS HAS NO OBLIGATION TO PROVIDE
 * MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 *----------------------------------------------------------------------------
 * Copyright (c) 2015-2017, University of Cambridge.
 * All Rights Reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University of Cambridge nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 * 
 * IN NO EVENT SHALL UNIVERSITY OF CAMBRIDGE BE LIABLE TO ANY PARTY FOR DIRECT,
 * INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF REGENTS
 * HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * UNIVERSITY OF CAMBRIDGE SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT
 * NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY,
 * PROVIDED HEREUNDER IS PROVIDED "AS IS". UNIVERSITY OF CAMBRIDGE HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *----------------------------------------------------------------------------*/

#include "elfriscv.h"
#include <string.h>
// #include <stdio.h>
#include "mini-printf.h"
#include "hash-md5.h"

#ifndef IS_ELF64
#define IS_ELF(hdr)					  \
  ((hdr).e_ident[0] == 0x7f && (hdr).e_ident[1] == 'E' && \
   (hdr).e_ident[2] == 'L'  && (hdr).e_ident[3] == 'F')

#define IS_ELF32(hdr) (IS_ELF(hdr) && (hdr).e_ident[4] == 1)
#define IS_ELF64(hdr) (IS_ELF(hdr) && (hdr).e_ident[4] == 2)
#endif

int64_t load_elf(void (*elfn)(void *dst, uint32_t off, uint32_t sz)) {
  Elf64_Ehdr eh;
  elfn(&eh, 0, sizeof(eh));
  if(!IS_ELF64(eh))
    return -2;                   /* not a elf64 file */

  uint32_t i;
  for(i=0; i<eh.e_phnum; i++) {
    Elf64_Phdr ph;
    elfn(&ph, eh.e_phoff + i*sizeof(ph), sizeof(ph));
    if(ph.p_type == PT_LOAD && ph.p_memsz) { /* need to load this physical section */
      printf("Section[%d]: ", i);
      if(ph.p_filesz) {                         /* has data */
	uint8_t *paddr = (uint8_t *)ph.p_paddr;
	size_t len = ph.p_filesz;
        if ((size_t)paddr < 0x80000000 || ((size_t)paddr >= 0x88000000))
          {
            printf("paddr sanity error %p\n", paddr);
            return -3;
          }
	printf("elfn(%x,0x%x,0x%x);\n", paddr, ph.p_offset, len);
        elfn(paddr, ph.p_offset, len);
#ifdef VERBOSE_MD5
        hash_buf(paddr, len);
#endif        
      }
      if(ph.p_memsz > ph.p_filesz) { /* zero padding */
	uint8_t *bss = (uint8_t *)ph.p_paddr + ph.p_filesz;
	size_t len = ph.p_memsz - ph.p_filesz;
	printf("memset(%x,0,0x%x);\n", bss, len);
        memset(bss, 0, len);
#ifdef VERBOSE_MD5
	hash_buf(bss, len);
#endif
      }
    }
  }

  return eh.e_entry;
}
