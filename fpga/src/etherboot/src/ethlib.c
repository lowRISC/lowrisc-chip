/*
 * Copyright (c) 2001-2003, Adam Dunkels.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * This file is derived from the uIP TCP/IP stack.
 *
 *
 */

// An ethernet loader program
//#define VERBOSE
//#define UDP_DEBUG

#include "encoding.h"
#include "misc.h"
#include "elfriscv.h"
#include "uart.h"
#include "ariane.h"
#include "eth.h"
#include "qspi.h"
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

volatile uint32_t *const plic = (volatile uint32_t *)PLICBase;
volatile uint64_t * get_ddr_base() { return (uint64_t *) DRAMBase; }
volatile uint64_t   get_ddr_size() { return (uint64_t) DRAMLength; }

uip_ipaddr_t uip_hostaddr, uip_draddr, uip_netmask;
uip_eth_addr mac_addr;

const uip_ipaddr_t uip_broadcast_addr =
  { { 0xff, 0xff, 0xff, 0xff } };

const uip_ipaddr_t uip_all_zeroes_addr = { { 0x0, /* rest is 0 */ } };

uip_lladdr_t uip_lladdr;

volatile uint64_t *const eth_base = (volatile uint64_t *)EthernetBase;

void *mysbrk_(size_t len)
{
  static unsigned long rused = 0;
  char *rd = rused + (char *)get_ddr_base() +  ((uint64_t)get_ddr_size()) / 2;
  rused += ((len-1)|7)+1;
  return rd;
}


#define PORT 69   //The TFTP well-known port on which to send data

#define min(x,y) (x) < (y) ? (x) : (y)

int eth_discard;

static int copyin_pkt(void)
{
  int i;
  int rsr = eth_read(RSR_OFFSET);
  int buf = rsr & RSR_RECV_FIRST_MASK;
  int errs = eth_read(RBAD_OFFSET);
  int len = eth_read(RPLR_OFFSET+((buf&7)<<3)) - 4;
#ifdef VERBOSE
      printf("length = %d (buf = %x)\n", len, buf);
#endif      
      if ((len >= 14) && (len <= max_packet) && ((0x101<<(buf&7)) & ~errs) && !eth_discard)
    {
      int rnd, start = (RXBUFF_OFFSET>>3) + ((buf&7)<<8);
#ifdef BUFFERED
      uint64_t *alloc = rxbuf[rxhead].alloc;
#else
      uint64_t alloc[ETH_FRAME_LEN/sizeof(uint64_t)+1];
#endif
      uint32_t *alloc32 = (uint32_t *)(eth_base+start);
      // Do we need to read the packet at all ??
      uint16_t rxheader = alloc32[HEADER_OFFSET >> 2];
      int proto_type = ntohs(rxheader) & 0xFFFF;
      switch (proto_type)
          {
          case ETH_P_IP:
          case ETH_P_ARP:
            rnd = (((len-1)|7)+1); /* round to a multiple of 8 */
            for (i = 0; i < rnd/8; i++)
              {
                alloc[i] = eth_base[start+i];
              }
#ifdef BUFFERED
            rxbuf[rxhead].len = len;
            rxhead = (rxhead + 1) % queuelen;
#else
            recog_packet(proto_type, (uint32_t *)alloc, len);
#endif            
            break;            
          case ETH_P_IPV6:
            break;
          }
    }
  eth_write(RSR_OFFSET, buf+1); /* acknowledge */
  return len;
}

// max size of file image is increased to 17M to support FreeBSD downloading

// size of DDR RAM (128M for NEXYS4-DDR) 
#define DDR_SIZE 0x8000000

static int oldidx;
static int dhcp_off_cnt;
static int dhcp_ack_cnt;
const char *const regnam(int ix)
{
 switch (ix)
   {
   case MACLO_OFFSET: return "MACLO_OFFSET";
   case MACHI_OFFSET: return "MACHI_OFFSET";
   case TPLR_OFFSET: return "TPLR_OFFSET";
   case TFCS_OFFSET: return "TFCS_OFFSET";
   case MDIOCTRL_OFFSET: return "MDIOCTRL_OFFSET";
   case RFCS_OFFSET: return "RFCS_OFFSET";
   case RSR_OFFSET: return "RSR_OFFSET";
   case RBAD_OFFSET: return "RBAD_OFFSET";
   case RPLR_OFFSET: return "RPLR_OFFSET";
   default: if (ix < RPLR_OFFSET+64)
       {
         static char nam[24];
         sprintf(nam, "RPLR_OFFSET+%d", ix-RPLR_OFFSET);
         return nam;
       }
     else return "????";
   }
  
};

static void dumpregs(const char *msg)
{
#ifdef VERBOSE  
  int i;
  printf("== %s ==\n", msg);
  for (i = MACLO_OFFSET; i < RPLR_OFFSET+64; i+=8)
    {
      printf("eth_read(%s) = %lx\n", regnam(i), eth_read(i));
    }
#endif  
}

void eth_interrupt(void)
{
  int claim, handled = 0;
#ifdef VERBOSE
  printf("Hello external interrupt! "__TIMESTAMP__"\n");
#endif  
  claim = plic[0x80001];
  //  eth_write(MACHI_OFFSET, eth_read(MACHI_OFFSET)&~MACHI_IRQ_EN);
  dumpregs("before");
  /* Check if there is Rx Data available */
  while (eth_read(RSR_OFFSET) & RSR_RECV_DONE_MASK)
    {
#ifdef VERBOSE
      printf("Ethernet interrupt\n");
#endif  
      copyin_pkt();
      handled = 1;
    }
#if 0
  if (uart_check_read_irq())
    {
      int rslt = uart_read_irq();
      printf("uart interrupt read %x (%c)\n", rslt, rslt);
      handled = 1;
    }
#endif  
  if (!handled)
    {
      printf("unhandled interrupt!\n");
    }
  dumpregs("after");
  plic[0x80001] = claim;
  //  eth_write(MACHI_OFFSET, eth_read(MACHI_OFFSET)|MACHI_IRQ_EN);
}
    // Function for checksum calculation. From the RFC,
    // the checksum algorithm is:
    //  "The checksum field is the 16 bit one's complement of the one's
    //  complement sum of all 16 bit words in the header.  For purposes of
    //  computing the checksum, the value of the checksum field is zero."

unsigned short csum(uint8_t *buf, int nbytes)
    {       //
            unsigned long sum;
            for(sum=0; nbytes>0; nbytes-=2)
              {
                unsigned short src;
                memcpy(&src, buf, 2);
                buf+=2;
                sum += ntohs(src);
              }
            sum = (sum >> 16) + (sum & 0xffff);
            sum += (sum >> 16);
            return (unsigned short)(~sum);
    }

//static uintptr_t old_mstatus, old_mie;

//static uint64_t random_pkt[max_packet/sizeof(uint64_t)];

static uint16_t saved_peer_port;
static uint32_t saved_peer_ip;
static u_char saved_peer_addr[6];

void recog_packet(int proto_type, uint32_t *alloc32, int xlength)
{
        switch (proto_type)
          {
          case ETH_P_IP:
            {
              uint32_t peer_ip;
              static u_char peer_addr[6];
              struct ethip_hdr {
                struct uip_eth_hdr ethhdr;
                /* IP header. */
                uint8_t vhl,
                  tos,
                  len[2],
                  ipid[2],
                  ipoffset[2],
                  ttl,
                  proto;
                uint16_t ipchksum;
                uip_ipaddr_t srcipaddr, destipaddr;
                uint8_t body[];
              } *BUF = ((struct ethip_hdr *)alloc32);
              memcpy(&peer_ip, &(BUF->srcipaddr), sizeof(uip_ipaddr_t));
              memcpy(peer_addr, BUF->ethhdr.src.addr, 6);
#ifdef VERBOSE
              printf("IP proto = %d\n", BUF->proto);
              printf("Source IP Address:  %d.%d.%d.%d\n", uip_ipaddr_to_quad(&(BUF->srcipaddr)));
              printf("Destination IP Address:  %d.%d.%d.%d\n", uip_ipaddr_to_quad(&(BUF->destipaddr)));
#endif
              switch (BUF->proto)
                {
                case IPPROTO_ICMP:
                  {
                    struct icmphdr
                    {
                      uint8_t type;		/* message type */
                      uint8_t code;		/* type sub-code */
                      uint16_t checksum;
                      uint16_t	id;
                      uint16_t	sequence;
                      uint64_t	timestamp;	/* gateway address */
                      uint8_t body[];
                    } *icmp_hdr = (struct icmphdr *)&(BUF->body);
#ifdef VERBOSE
                  printf("IP proto = ICMP\n");
#endif
                  if (uip_ipaddr_cmp(&BUF->destipaddr, &uip_hostaddr))
                    {
                      uint16_t chksum;
                      int len = xlength - sizeof(struct ethip_hdr);
                      memcpy(BUF->ethhdr.dest.addr, BUF->ethhdr.src.addr, 6);
                      memcpy(BUF->ethhdr.src.addr, uip_lladdr.addr, 6);
                
                      uip_ipaddr_copy(&BUF->destipaddr, &BUF->srcipaddr);
                      uip_ipaddr_copy(&BUF->srcipaddr, &uip_hostaddr);

                      icmp_hdr->type = 0; /* reply */
                      icmp_hdr->checksum = 0;
                      chksum = csum((uint8_t *)icmp_hdr, len);
                      icmp_hdr->checksum = htons(chksum);
#ifdef VERBOSE                      
                      printf("sending ICMP reply (header = %d, total = %d, checksum = %x)\n", sizeof(struct icmphdr), len, chksum);
                      PrintData((u_char *)icmp_hdr, len);
#endif                      
                      lite_queue(0, alloc32, xlength);
                    }
                  }
                  break;
                case    IPPROTO_IGMP:
#ifdef VERBOSE
                  printf("IP Proto = IGMP\n");
#else
		  printf("G");
#endif
                  break;
                case    IPPROTO_IPIP: printf("IP Proto = IPIP\n"); break;
                case    IPPROTO_TCP:
#ifdef VERBOSE
                  printf("IP Proto = TCP\n");
#else
		  printf("T");
#endif                  
                  break;
                case    IPPROTO_EGP: printf("IP Proto = EGP\n"); break;
                case    IPPROTO_PUP: printf("IP Proto = PUP\n"); break;
                case    IPPROTO_UDP:
                  {
                    struct udphdr {
                      uint16_t	uh_sport;		/* source port */
                      uint16_t	uh_dport;		/* destination port */
                      uint16_t	uh_ulen;		/* udp length */
                      uint16_t	uh_sum;			/* udp checksum */
                      const u_char body[];              /* payload */
                    } *udp_hdr = (struct udphdr *)&(BUF->body);

                    int16_t dport = ntohs(udp_hdr->uh_dport);
                    int16_t ulen = ntohs(udp_hdr->uh_ulen);
                    uint16_t peer_port = ntohs(udp_hdr->uh_sport);
#ifdef VERBOSE
                    if (dport != 1534) printf("IP Proto = UDP, source port = %d, dest port = %d, length = %d, ethlen = %d\n",
                           ntohs(udp_hdr->uh_sport),
                           dport,
                           ulen, xlength);
#endif                        
                    if (dport == PORT)
                      {
                        saved_peer_port = peer_port;
                        saved_peer_ip = peer_ip;
                        memcpy(saved_peer_addr, peer_addr, sizeof(saved_peer_addr));
                        process_udp_packet(0, udp_hdr->body, ulen-sizeof(struct udphdr), peer_port, peer_ip, peer_addr);
                      }
                    else if (peer_port == DHCP_SERVER_PORT)
                      {
                        saved_peer_ip = peer_ip;
                        if (!(dhcp_off_cnt && dhcp_ack_cnt))
                          dhcp_input((dhcp_t *)(udp_hdr->body), mac_addr.addr, &dhcp_off_cnt, &dhcp_ack_cnt);
                      }
                    else if (dport == 1234) /* a test port */
                      {
                        printf("test header:\n");
                        PrintData((void *)alloc32, xlength);
                        printf("test contents:\n");
                        PrintData((void *)(udp_hdr->body), ulen);
                      }
                    else if (dport == 1534) /* annoying undocumented port, possibly to do with license servers */
                      {
                        
                      }
                    else if ((BUF->destipaddr.u16[0] != 0xFFFFU) && (BUF->destipaddr.u16[1] != 0xFFFFU))
                      {
                        uint32_t srcaddr;
                        memcpy(&srcaddr, &uip_hostaddr, 4);
#ifdef VERBOSE
                        printf("IP Proto = UDP, source port = %d, dest port = %d, length = %d\n",
                           ntohs(udp_hdr->uh_sport),
                           dport,
                           ulen);
#else
                        //        print_uart_short(dport);
#endif
                        //        udp_send(mac_addr.addr, (void *)(udp_hdr->body), ulen, PORT, peer_port, srcaddr, peer_ip, peer_addr);
                      }
                  }
                  break;
                case    IPPROTO_IDP: printf("IP Proto = IDP\n"); break;
                case    IPPROTO_TP: printf("IP Proto = TP\n"); break;
                case    IPPROTO_DCCP: printf("IP Proto = DCCP\n"); break;
                case    IPPROTO_IPV6:
#ifdef VERBOSE
		  printf("IP Proto = IPV6\n");
#else
		  printf("6");
#endif                      
		  break;
                case    IPPROTO_RSVP: printf("IP Proto = RSVP\n"); break;
                case    IPPROTO_GRE: printf("IP Proto = GRE\n"); break;
                case    IPPROTO_ESP: printf("IP Proto = ESP\n"); break;
                case    IPPROTO_AH: printf("IP Proto = AH\n"); break;
                case    IPPROTO_MTP: printf("IP Proto = MTP\n"); break;
                case    IPPROTO_BEETPH: printf("IP Proto = BEETPH\n"); break;
                case    IPPROTO_ENCAP: printf("IP Proto = ENCAP\n"); break;
                case    IPPROTO_PIM:
#ifdef VERBOSE
                  printf("IP Proto = PIM\n");
#else
		  printf("M");
#endif
                  break;
                case    IPPROTO_COMP: printf("IP Proto = COMP\n"); break;
                case    IPPROTO_SCTP: printf("IP Proto = SCTP\n"); break;
                case    IPPROTO_UDPLITE: printf("IP Proto = UDPLITE\n"); break;
                case    IPPROTO_MPLS: printf("IP Proto = MPLS\n"); break;
                case    IPPROTO_RAW: printf("IP Proto = RAW\n"); break;
                default:
                  printf("IP proto = unsupported (%x)\n", BUF->proto);
                  break;
                }
            }
            break;
          case ETH_P_ARP:
            {
              struct arp_hdr {
                struct uip_eth_hdr ethhdr;
                uint16_t hwtype;
                uint16_t protocol;
                uint8_t hwlen;
                uint8_t protolen;
                uint16_t opcode;
                struct uip_eth_addr shwaddr;
                uip_ipaddr_t sipaddr;
                struct uip_eth_addr dhwaddr;
                uip_ipaddr_t dipaddr;
              } *BUF = ((struct arp_hdr *)alloc32);
#ifdef VERBOSE
             printf("proto = ARP\n");
#endif
             if(uip_ipaddr_cmp(&BUF->dipaddr, &uip_hostaddr))
               {
                int len = sizeof(struct arp_hdr);
                BUF->opcode = __htons(2);
                
                memcpy(BUF->dhwaddr.addr, BUF->shwaddr.addr, 6);
                memcpy(BUF->shwaddr.addr, uip_lladdr.addr, 6);
                memcpy(BUF->ethhdr.src.addr, uip_lladdr.addr, 6);
                memcpy(BUF->ethhdr.dest.addr, BUF->dhwaddr.addr, 6);
                
                uip_ipaddr_copy(&BUF->dipaddr, &BUF->sipaddr);
                uip_ipaddr_copy(&BUF->sipaddr, &uip_hostaddr);
                
                BUF->ethhdr.type = __htons(UIP_ETHTYPE_ARP);
                
#ifdef VERBOSE
                printf("sending ARP reply (length = %d)\n", len);
#endif
                lite_queue(0, alloc32, len);
               }
             else
               {
#ifdef VERBOSE
                 printf("Discarded ARP  %d.%d.%d.%d, my addr =  %d.%d.%d.%d\n", uip_ipaddr_to_quad(&BUF->dipaddr), uip_ipaddr_to_quad(&uip_hostaddr));
#endif                 
               }
            }
            break;
          case ETH_P_IPV6:
#ifdef VERBOSE                      
            printf("proto_type = IPV6\n");
#else
	    printf("6");
#endif                      
            break;
          default:
            printf("proto_type = 0x%x\n", proto_type);
            lite_queue(0, alloc32, 0);
            break;
          }
}

int mysend(int sock, void *buf, int ulen) {
  uint32_t srcaddr;
  memcpy(&srcaddr, &uip_hostaddr, 4);
  udp_send(mac_addr.addr, buf, ulen, PORT, saved_peer_port, srcaddr, saved_peer_ip, saved_peer_addr);
  return ulen;
}

uint16_t __bswap_16(uint16_t x)
{
        return ((x << 8) & 0xff00) | ((x >> 8) & 0x00ff);
}

uint32_t __bswap_32(uint32_t x)
{
  return
     ((((x) & 0xff000000) >> 24) | (((x) & 0x00ff0000) >>  8) |               \
      (((x) & 0x0000ff00) <<  8) | (((x) & 0x000000ff) << 24)) ;
}

void set_dummy_mac(void)
{
  enum {oem_mac_addr = 0x20}; // The address of the OEM MAC address in OTP qspi flash
  uint32_t macaddr_lo, macaddr_hi;
  uint32_t i, data = ((sizeof(mac_addr)+3) << 24) | (oem_mac_addr-2); // +1 for dummy byte +2 for luck
  uint64_t rslt = qspi_send(CMD_OTPR, 1, 0, &data);
#ifndef SIMULATION  
  printf("Setup MAC addr\n");
#endif
  if (((rslt&0xFFFFFFFFFFFF)==0xFFFFFFFFFFFF) || !rslt)
    {
    mac_addr.addr[0] = (uint8_t)0xEE;
    mac_addr.addr[1] = (uint8_t)0xE1;
    mac_addr.addr[2] = (uint8_t)0xE2;
    mac_addr.addr[3] = (uint8_t)0xE3;
    mac_addr.addr[4] = (uint8_t)0xE4;
    mac_addr.addr[5] = (uint8_t)(0xE0|(gpio_sw()&0xF));
    }
  else for (i = 2; i < 8; i++)
    {
      mac_addr.addr[i-2] = (uint8_t)(rslt >> ((7-i)*8));
      printf("QSPI OEM[%d] = %x\n", i-2, mac_addr.addr[i-2]);
    }  
  memcpy (&macaddr_lo, mac_addr.addr+2, sizeof(uint32_t));
  memcpy (&macaddr_hi, mac_addr.addr+0, sizeof(uint16_t));
  eth_base[MACLO_OFFSET>>3] = __bswap_32(macaddr_lo);
  eth_base[MACHI_OFFSET>>3] = __bswap_16(macaddr_hi);

  macaddr_lo = eth_base[MACLO_OFFSET>>3];
  macaddr_hi = eth_base[MACHI_OFFSET>>3] & MACHI_MACADDR_MASK;
  eth_write(RFCS_OFFSET, 8); /* use 8 buffers */
}

void eth_main(void) {
  uint64_t cnt = 0;
  //  uip_ipaddr_t addr;
  uint64_t lo = eth_read(MACLO_OFFSET);
  uint64_t hi = eth_read(MACHI_OFFSET) & MACHI_MACADDR_MASK;
  eth_write(MACHI_OFFSET, MACHI_IRQ_EN|hi);
#ifdef BUFFERED
  rxbuf = (inqueue_t *)mysbrk(sizeof(inqueue_t)*queuelen);
  txbuf = (outqueue_t *)mysbrk(sizeof(outqueue_t)*queuelen);
#endif  
  
#ifndef VERBOSE  
  printf("MAC = %lx:%lx\n", hi&MACHI_MACADDR_MASK, lo);
  
  printf("MAC address = %02x:%02x:%02x:%02x:%02x:%02x.\n",
         mac_addr.addr[0],
         mac_addr.addr[1],
         mac_addr.addr[2],
         mac_addr.addr[3],
         mac_addr.addr[4],
         mac_addr.addr[5]
         );
#endif
  uip_setethaddr(mac_addr);
  saved_peer_port = 0;
  saved_peer_ip = 0;
  eth_discard = 0;
  dhcp_off_cnt = 0;
  dhcp_ack_cnt = 0;
  oldidx = 0;
#ifdef INTERRUPT_MODE
  printf("Enabling interrupts\n");
  old_mstatus = read_csr(mstatus);
  old_mie = read_csr(mie);
  set_csr(mstatus, MSTATUS_MIE|MSTATUS_HIE);
  set_csr(mie, ~(1 << IRQ_M_TIMER));

  printf("Enabling UART interrupt\n");
  uart_enable_read_irq();
#endif
  do {
    if (cnt-- == 0)
      {
        if (!saved_peer_ip)
          {
            dhcp_main(mac_addr.addr);
            cnt = 2500000;       
          }
        else if (dhcp_ack_cnt)
          {
            tftps_tick(0);
            cnt = 10000;       
          }
      }
#ifndef INTERRUPT_MODE
    while (eth_read(RSR_OFFSET) & RSR_RECV_DONE_MASK) copyin_pkt();
#endif
#ifdef BUFFERED    
    if ((txhead != txtail) && (TPLR_BUSY_MASK & ~eth_read(TPLR_OFFSET)))
      {
        uint64_t *alloc = txbuf[txtail].alloc;
        int length = txbuf[txtail].len;
        int i, rslt;
        lite_queue(0, alloc, length);
        txtail = (txtail + 1) % queuelen;
      }
#endif    
#ifndef INTERRUPT_MODE
    while (eth_read(RSR_OFFSET) & RSR_RECV_DONE_MASK) copyin_pkt();
#endif
#ifdef BUFFERED    
    if (rxhead != rxtail)
      {
	int i, bad = 0;
        uint32_t *alloc32 = (uint32_t *)(rxbuf[rxtail].alloc); // legacy size to avoid tweaking header offset
        int length, xlength = rxbuf[rxtail].len;
        uint16_t rxheader = alloc32[HEADER_OFFSET >> 2];
        int proto_type = ntohs(rxheader) & 0xFFFF;
#ifdef VERBOSE
        printf("alloc32 = %x\n", alloc32);
        printf("rxhead = %d, rxtail = %d\n", rxhead, rxtail);
#endif
        recog_packet(proto_type, alloc32, xlength);
        rxtail = (rxtail + 1) % queuelen;
      }
#endif    
  } while (1);
}

#if defined(UDP_DEBUG)
void PrintData (const u_char * data , int Size)
{
    int i , j;
    for(i=0 ; i < Size ; i++)
    {
        if( i!=0 && i%16==0)
        {
            printf("         ");
            for(j=i-16 ; j<i ; j++)
            {
                if(data[j]>=32 && data[j]<=128)
                    printf("%c",(unsigned char)data[j]);
                else printf(".");
            }
            printf("\n");
        }
        if(i%16==0) printf("   ");
            printf(" %02X",(unsigned int)data[i]);
        if( i==Size-1)
        {
            for(j=0;j<15-i%16;j++)
            {
              printf("   ");
            }
            printf("         ");
            for(j=i-i%16 ; j<=i ; j++)
            {
                if(data[j]>=32 && data[j]<=128)
                {
                  printf("%c",(unsigned char)data[j]);
                }
                else
                {
                  printf(".");
                }
            }
            printf("\n" );
        }
    }
}
#endif
