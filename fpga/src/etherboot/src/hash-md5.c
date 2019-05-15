/*
 * Compute MD5 checksum of strings according to the
 * definition of MD5 in RFC 1321 from April 1992.
 *
 * Written by Ulrich Drepper <drepper@gnu.ai.mit.edu>, 1995.
 *
 * Copyright (C) 1995-1999 Free Software Foundation, Inc.
 * Copyright (C) 2001 Manuel Novoa III
 * Copyright (C) 2003 Glenn L. McGrath
 * Copyright (C) 2003 Erik Andersen
 *
 * Licensed under GPLv2 or later, see file LICENSE in this source tree.
 */

// MD5 computation for host side Ethernet downloader

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "hash-md5.h"

static __attribute__ ((always_inline)) __inline__ uint32_t rotl32(uint32_t x, unsigned n)
{
 return (x << n) | (x >> (32 - n));
}

void md5_hash(md5_ctx_t *ctx, const void *buffer, size_t len)
{
 unsigned bufpos = ctx->total64 & 63;

 ctx->total64 += len;

 while (1) {
  unsigned remaining = 64 - bufpos;
  if (remaining > len)
   remaining = len;

  memcpy(ctx->wbuffer + bufpos, buffer, remaining);
  len -= remaining;
  buffer = (const char *)buffer + remaining;
  bufpos += remaining;

  bufpos -= 64;
  if (bufpos != 0)
   break;

  ctx->process_block(ctx);

 }
}

void md5_end(md5_ctx_t *ctx)
{
 unsigned bufpos = ctx->total64 & 63;

 ctx->wbuffer[bufpos++] = 0x80;

 while (1) {
  unsigned remaining = 64 - bufpos;
  memset(ctx->wbuffer + bufpos, 0, remaining);

  if (remaining >= 8) {

   uint64_t t = ctx->total64 << 3;

   *(uint64_t *) (&ctx->wbuffer[64 - 8]) = t;
  }
  ctx->process_block(ctx);
  if (remaining >= 8)
   break;
  bufpos = 0;
 }
}

static void md5_process_block64(md5_ctx_t *ctx)
{
 static const uint32_t C_array[] = {

  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
  0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
  0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,

  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
  0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
  0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,

  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
  0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x4881d05,
  0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,

  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
  0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
  0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
 };
 static const char P_array[] __attribute__((aligned(1))) = {

  1, 6, 11, 0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12,
  5, 8, 11, 14, 1, 4, 7, 10, 13, 0, 3, 6, 9, 12, 15, 2,
  0, 7, 14, 5, 12, 3, 10, 1, 8, 15, 6, 13, 4, 11, 2, 9
 };

 uint32_t *words = (void*) ctx->wbuffer;
 uint32_t A = ctx->hash[0];
 uint32_t B = ctx->hash[1];
 uint32_t C = ctx->hash[2];
 uint32_t D = ctx->hash[3];
 uint32_t A_save = A;
 uint32_t B_save = B;
 uint32_t C_save = C;
 uint32_t D_save = D;

 const uint32_t *pc;
 const char *pp;
 int i;
 pc = C_array;
 for (i = 0; i < 4; i++) {
  do { A += (D ^ (B & (C ^ D))) + (*words ) + *pc++; words++; A = rotl32(A, 7); A += B; } while (0);
  do { D += (C ^ (A & (B ^ C))) + (*words ) + *pc++; words++; D = rotl32(D, 12); D += A; } while (0);
  do { C += (B ^ (D & (A ^ B))) + (*words ) + *pc++; words++; C = rotl32(C, 17); C += D; } while (0);
  do { B += (A ^ (C & (D ^ A))) + (*words ) + *pc++; words++; B = rotl32(B, 22); B += C; } while (0);
 }
 words -= 16;
 pp = P_array;
 for (i = 0; i < 4; i++) {
  do { A += (C ^ (D & (B ^ C))) + words[(int) (*pp++)] + *pc++; A = rotl32(A, 5); A += B; } while (0);
  do { D += (B ^ (C & (A ^ B))) + words[(int) (*pp++)] + *pc++; D = rotl32(D, 9); D += A; } while (0);
  do { C += (A ^ (B & (D ^ A))) + words[(int) (*pp++)] + *pc++; C = rotl32(C, 14); C += D; } while (0);
  do { B += (D ^ (A & (C ^ D))) + words[(int) (*pp++)] + *pc++; B = rotl32(B, 20); B += C; } while (0);
 }
 for (i = 0; i < 4; i++) {
  do { A += (B ^ C ^ D) + words[(int) (*pp++)] + *pc++; A = rotl32(A, 4); A += B; } while (0);
  do { D += (A ^ B ^ C) + words[(int) (*pp++)] + *pc++; D = rotl32(D, 11); D += A; } while (0);
  do { C += (D ^ A ^ B) + words[(int) (*pp++)] + *pc++; C = rotl32(C, 16); C += D; } while (0);
  do { B += (C ^ D ^ A) + words[(int) (*pp++)] + *pc++; B = rotl32(B, 23); B += C; } while (0);
 }
 for (i = 0; i < 4; i++) {
  do { A += (C ^ (B | ~D)) + words[(int) (*pp++)] + *pc++; A = rotl32(A, 6); A += B; } while (0);
  do { D += (B ^ (A | ~C)) + words[(int) (*pp++)] + *pc++; D = rotl32(D, 10); D += A; } while (0);
  do { C += (A ^ (D | ~B)) + words[(int) (*pp++)] + *pc++; C = rotl32(C, 15); C += D; } while (0);
  do { B += (D ^ (C | ~A)) + words[(int) (*pp++)] + *pc++; B = rotl32(B, 21); B += C; } while (0);
 }
 ctx->hash[0] = A_save + A;
 ctx->hash[1] = B_save + B;
 ctx->hash[2] = C_save + C;
 ctx->hash[3] = D_save + D;

}
void md5_begin(md5_ctx_t *ctx)
{
 ctx->hash[0] = 0x67452301;
 ctx->hash[1] = 0xefcdab89;
 ctx->hash[2] = 0x98badcfe;
 ctx->hash[3] = 0x10325476;
 ctx->total64 = 0;
 ctx->process_block = md5_process_block64;
}

static void minion_bin2hex(char *p, const char *cp, int count)
{
  static const char *hex = "0123456789abcdef";
 while (count) {
  unsigned char c = *cp++;

  *p++ = hex[c >> 4];
  *p++ = hex[c & 0xf];
  count--;
 }
}

unsigned char *hash_bin_to_hex(md5_ctx_t *ctx)
{

 static char hex_value[hash_length * 2 + 1];
 char resbuf[sizeof(ctx->hash[0]) * 4];
 memcpy(resbuf, ctx->hash, sizeof(ctx->hash[0]) * 4);
 minion_bin2hex(hex_value, resbuf, hash_length);
 return (unsigned char *)hex_value;
}

uint8_t *hash_buf(const void *in_buf, int count)
{
 md5_ctx_t context;
 uint8_t *hash_value;

 md5_begin(&context);
 md5_hash(&context, in_buf, count);
 md5_end(&context);
 hash_value = hash_bin_to_hex(&context);
 // printf("md5(%p,%d) = %s\n", in_buf, count, hash_value);
 return hash_value;
}

#ifdef TEST_MAIN
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
  if (argc > 1)
    {
      FILE *fd = fopen(argv[1], "r");
      int pos = fseek(fd, 0, SEEK_END);
      long siz = ftell(fd);
      int bgn = fseek(fd, 0, SEEK_SET);
      char *buf = malloc(siz);
      int rslt = fread(buf, 1, siz, fd);
      uint8_t *hash_value = hash_buf(buf, siz);
      printf("md5(%p,%ld) = %s\n", buf, siz, hash_value);
    }
}

#endif
