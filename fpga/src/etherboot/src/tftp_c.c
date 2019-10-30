/**********************************************

Copyright (c) 2016 tftpx Authors
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the tftpx nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 * Author: Jonathan Kimmitt (based on work_thread.c by ideawu)
 * Original Author: ideawu(www.ideawu.net)
 * Date: 2007-04, 2007-05
 * File: tftp_c.c
 * Description: Bare metal tftp server for Ariane/lowRISC
 *********************************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "eth.h"
#include "hid.h"
#include "uart.h"
#include "ariane.h"
#include "hash-md5.h"
#include "encoding.h"
#include "elfriscv.h"

#define CMD_RRQ (int16_t)1
#define CMD_WRQ (int16_t)2
#define CMD_DATA (int16_t)3
#define CMD_ACK (int16_t)4
#define CMD_ERROR (int16_t)5
#define CMD_LIST (int16_t)6
#define CMD_HEAD (int16_t)7

// TFTPX_DATA_SIZE
#define DATA_SIZE 512
//
#define LIST_BUF_SIZE (DATA_SIZE * 8)

struct tftpx_packet {
	uint16_t cmd;
	union{
		uint16_t code;
		uint16_t block;
		// For a RRQ and WRQ TFTP packet
		char filename[2];
	};
	char data[DATA_SIZE];
};

struct tftpx_request {
	int size;
	void *client;
	struct tftpx_packet packet;
};

/*
Error Codes

   Value     Meaning

   0         Not defined, see error message (if any).
   1         File not found.
   2         Access violation.
   3         Disk full or allocation exceeded.
   4         Illegal TFTP operation.
   5         Unknown transfer ID.
   6         File already exists.
   7         No such user.
*/

void myputn(int wid, unsigned n)
{
  if ((wid > 0) || (n > 9)) myputn(wid-1, n / 10);
  hid_send(n % 10 + '0');
}

enum {verbose=0, md5sum = 1};
static char *file_ptr, *strt_ptr, fullpath[80];
static int crc_err_old, fram_err_old;

void tftp_elfn(void *dst, uint32_t off, uint32_t sz)
{
  /* since we don't know how much RAM we have, we may be
     overwriting the front part of the ELF image with the expanded executable (!?!) */

  /* this will go wrong if the big Linux payload segment is not last in the ELF file */
  memcpy(dst, strt_ptr+off, sz);
}

void file_open(const char *r_path)
{
  crc_err_old = eth_read(RFCS_OFFSET) >> 32;
  fram_err_old = eth_read(TFCS_OFFSET) >> 32;
  strt_ptr = 0x1000000 + (char *)DRAMBase;
  file_ptr = strt_ptr;
  if (strlen(r_path) > sizeof(fullpath) - 1) {		
    printf("Request path too long. %ld\n", strlen(r_path));
    return;
  }
	
  strcpy(fullpath, r_path);
}

void file_write(void *data, int siz)
{
  memcpy(file_ptr, data, siz);
  file_ptr += siz;
}

void file_close(void)
{
  uint8_t *hash_value;
  int siz = file_ptr - strt_ptr;
  int64_t entry_point;
  printf("File length = %d\n", siz);
  if (md5sum)
    {
      hash_value = hash_buf(strt_ptr, siz);
      printf("md5(%p,%d) = %s\n", strt_ptr, siz, hash_value);
      if (strcmp((char *)hash_value, fullpath))
        {
          printf("Aborting boot, expected hash value %s\n", fullpath);
          return;
        }
    }
  printf("load elf to DDR memory\n");
  entry_point = load_elf(tftp_elfn);
  if (entry_point < 0)
    {
    printf("elf read failed with code %ld", -entry_point);
    }
  else
    just_jump(entry_point);
}

// Send an ACK packet. Return bytes sent.
// If error occurs, return -1;
int send_ack(int sock, struct tftpx_packet *packet, int size){
	if(mysend(sock, packet, size) != size){
		return -1;
	}
	
	return size;
}

int myrecv(int sock, struct tftpx_packet *rcv_packet, int siz)
{
  return 0;
}

static ushort block;
static struct tftpx_packet ack_packet;

void handle_wrq(int sock, struct tftpx_request *request) {
	char *r_path = request->packet.filename;	// request file
	char *mode = r_path + strlen(r_path) + 1;
        if (strcmp(mode, "octet")) {
		printf("Only octet mode is supported (client specified %s)\n", mode);
		return;
	}          
          
	printf("wrq: \"%s\", blocksize=%d\n", r_path, DATA_SIZE);
	
	//if(!strncasecmp(mode, "octet", 5) && !strncasecmp(mode, "netascii", 8)){
	//	// send error packet
	//	return;
	//}
		
	file_open(r_path);
	
	ack_packet.cmd = htons(CMD_ACK);
	ack_packet.block = htons(0);
	send_ack(sock, &ack_packet, 4);
	block = 1;
}

void handle_data_packet(int sock, struct tftpx_packet *rcv_packet, int r_size) {
  if(r_size >= 4 && rcv_packet->cmd == htons(CMD_DATA) && rcv_packet->block == htons(block))
    {
      if (verbose)
        printf("DATA: block=%d, data_size=%d\n", ntohs(rcv_packet->block), r_size - 4);
      // Valid DATA
      file_write(rcv_packet->data, r_size - 4);
      ack_packet.cmd = htons(CMD_ACK);
      ack_packet.block = htons(block);
      send_ack(sock, &ack_packet, 4);
      if (verbose)
        printf("Send ACK=%d\n", block);
      else
        {
          hid_send('\r');
          myputn(5, block);
          hid_send(' ');
        }
      block++;
    }
  if (r_size < DATA_SIZE + 4)
    {
      int crc_err = eth_read(RFCS_OFFSET) >> 32;
      int fram_err = eth_read(TFCS_OFFSET) >> 32;
      printf("Receive file end (blocks = %d, crc err = %d, fram err = %d)\n", block, crc_err-crc_err_old, fram_err-fram_err_old);
      file_close();
    }
} 

void handle_switch(int sock, struct tftpx_request *request)
{
  // Choose handler
  switch(ntohs(request->packet.cmd))
    {
    case CMD_WRQ:
      printf("handle_wrq called.\n");
      handle_wrq(sock, request);
      break;
    case CMD_DATA:
      //      printf("handle_data_packet called.\n");
      handle_data_packet(sock, &(request->packet), request->size);
      break;      
    default:
      printf("Illegal TFTP operation.\n");
      break;
    }
}

void process_udp_packet(int sock, const u_char *data, int ulen, uint16_t peer_port, uint32_t peer_ip, const u_char *peer_addr)
{
  struct tftpx_request request;
  memset(&request, 0, sizeof(request));
  request.size = ulen;
  request.client = 0;
  memcpy(&(request.packet), data, sizeof(struct tftpx_packet));
  handle_switch(sock, &request);
}

void tftps_tick(int sock)
{
  if (block > 0)
    send_ack(sock, &ack_packet, 4);
}
