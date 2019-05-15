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

#ifndef MINION_HASH_MD5_H
#define MINION_HASH_MD5_H

# define MD5_DIGEST_LENGTH hash_length

enum {hash_length = 16};

typedef struct md5_ctx_t {
 uint8_t wbuffer[64];
 void (*process_block)(struct md5_ctx_t*) ;
 uint64_t total64;
 uint32_t hash[8];
} md5_ctx_t;

void md5_begin(md5_ctx_t *ctx) ;
void md5_hash(md5_ctx_t *ctx, const void *buffer, size_t len);
void md5_end(md5_ctx_t *ctx);
unsigned char *hash_bin_to_hex(md5_ctx_t *ctx);
uint8_t *hash_buf(const void *in_buf, int count);

#endif
