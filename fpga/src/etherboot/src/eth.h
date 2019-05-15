// See LICENSE for license details.

#ifndef ETH_HEADER_H
#define ETH_HEADER_H

#include <stdint.h>
#include <sys/types.h>
#include "mini-printf.h"

/* Register offsets (in bytes) for the LowRISC Core */
#define TXBUFF_OFFSET       0x1000          /* Transmit Buffer */

#define MACLO_OFFSET        0x0800          /* MAC address low 32-bits */
#define MACHI_OFFSET        0x0808          /* MAC address high 16-bits and MAC ctrl */
#define TPLR_OFFSET         0x0810          /* Tx packet length */
#define TFCS_OFFSET         0x0818          /* Tx frame check sequence register */
#define MDIOCTRL_OFFSET     0x0820          /* MDIO Control Register */
#define RFCS_OFFSET         0x0828          /* Rx frame check sequence register(read) and last register(write) */
#define RSR_OFFSET          0x0830          /* Rx status and reset register */
#define RBAD_OFFSET         0x0838          /* Rx bad frame and bad fcs register arrays */
#define RPLR_OFFSET         0x0840          /* Rx packet length register array */

#define RXBUFF_OFFSET       0x4000          /* Receive Buffer */

/* MAC Ctrl Register (MACHI) Bit Masks */
#define MACHI_MACADDR_MASK    0x0000FFFF     /* MAC high 16-bits mask */
#define MACHI_FIAD_MASK       0x001F0000     /* PHY address */
#define MACHI_NOPRE_EN        0x00200000     /* No preamble flag */
#define MACHI_ALLPKTS_MASK    0x00400000     /* Rx all packets (promiscuous mode) */
#define MACHI_IRQ_EN          0x00800000     /* Rx packet interrupt enable */
#define MACHI_DIVIDER_MASK    0xFF000000     /* MDIO Clock Divider Mask */

/* MDIO Control Register Bit Masks */
#define MDIOCTRL_CTRLDATA_MASK 0x0000FFFF    /* MDIO Data Mask */
#define MDIOCTRL_RGAD_MASK     0x001F0000    /* MDIO Reg select Mask */
#define MDIOCTRL_WCTRL_MASK    0x00200000    /* MDIO Write Ctrl */
#define MDIOCTRL_RSTAT_MASK    0x00400000    /* MDIO Read Status */
#define MDIOCTRL_SCAN_MASK     0x00800000    /* MDIO Scan Status */
#define MDIOCTRL_BUSY_EN       0x01000000    /* MDIO Busy Status */
#define MDIOCTRL_LINKFAIL_EN   0x02000000    /* MDIO Link Fail */
#define MDIOCTRL_NVALID_EN     0x04000000    /* MDIO Not Valid Status */

/* Transmit Status Register (TPLR) Bit Masks */
#define TPLR_FRAME_ADDR_MASK  0x0FFF0000     /* Tx frame address */
#define TPLR_PACKET_LEN_MASK  0x00000FFF     /* Tx packet length */
#define TPLR_BUSY_MASK        0x80000000     /* Tx busy mask */

/* Receive Status Register (RSR) */
#define RSR_RECV_FIRST_MASK   0x0000000F      /* first available buffer (static) */
#define RSR_RECV_NEXT_MASK    0x000000F0      /* current rx buffer (volatile) */
#define RSR_RECV_LAST_MASK    0x00000F00      /* last available rx buffer (static) */
#define RSR_RECV_DONE_MASK    0x00001000      /* Rx complete */
#define RSR_RECV_IRQ_MASK     0x00002000      /* Rx irq bit */

/* General Ethernet Definitions */
#define HEADER_OFFSET               12      /* Offset to length field */
#define HEADER_SHIFT                16      /* Shift value for length */
#define ARP_PACKET_SIZE             28      /* Max ARP packet size */
#define HEADER_IP_LENGTH_OFFSET     16      /* IP Length Offset */

// ETH APIs

#define uip_sethostaddr(addr) uip_ipaddr_copy(&uip_hostaddr, (addr))
#define uip_setnetmask(addr) uip_ipaddr_copy(&uip_netmask, (addr))
#define uip_ipaddr_to_quad(a) (a)->u8[0],(a)->u8[1],(a)->u8[2],(a)->u8[3]
#define uip_ipaddr_copy(dest, src) (*(dest) = *(src))
#define uip_ipaddr_cmp(addr1, addr2) ((addr1)->u16[0] == (addr2)->u16[0] && \
                                       (addr1)->u16[1] == (addr2)->u16[1])

#define uip_ipaddr(addr, addr0,addr1,addr2,addr3) do {  \
    (addr)->u8[0] = addr0;                              \
    (addr)->u8[1] = addr1;                              \
    (addr)->u8[2] = addr2;                              \
    (addr)->u8[3] = addr3;                              \
  } while(0)

#define uip_setethaddr(eaddr) do {uip_lladdr.addr[0] = eaddr.addr[0]; \
                              uip_lladdr.addr[1] = eaddr.addr[1];\
                              uip_lladdr.addr[2] = eaddr.addr[2];\
                              uip_lladdr.addr[3] = eaddr.addr[3];\
                              uip_lladdr.addr[4] = eaddr.addr[4];\
                              uip_lladdr.addr[5] = eaddr.addr[5];} while(0)

enum {queuelen = 1024, max_packet = 1536};

enum
  {
    IPPROTO_IP = 0,
    IPPROTO_ICMP = 1,
    IPPROTO_IGMP = 2,
    IPPROTO_IPIP = 4,
    IPPROTO_TCP = 6,
    IPPROTO_EGP = 8,
    IPPROTO_PUP = 12,
    IPPROTO_UDP = 17,
    IPPROTO_IDP = 22,
    IPPROTO_TP = 29,
    IPPROTO_DCCP = 33,
    IPPROTO_IPV6 = 41,
    IPPROTO_RSVP = 46,
    IPPROTO_GRE = 47,
    IPPROTO_ESP = 50,
    IPPROTO_AH = 51,
    IPPROTO_MTP = 92,
    IPPROTO_BEETPH = 94,
    IPPROTO_ENCAP = 98,
    IPPROTO_PIM = 103,
    IPPROTO_COMP = 108,
    IPPROTO_SCTP = 132,
    IPPROTO_UDPLITE = 136,
    IPPROTO_MPLS = 137,
    IPPROTO_RAW = 255,
    IPPROTO_MAX
  };

extern void eth_init();

typedef union uip_ip4addr_t {
  uint8_t  u8[4];                       /* Initializer, must come first. */
  uint16_t u16[2];
} uip_ip4addr_t;

typedef uip_ip4addr_t uip_ipaddr_t;

typedef struct uip_eth_addr {
  uint8_t addr[6];
} uip_eth_addr;

struct uip_eth_hdr {
  struct uip_eth_addr dest;
  struct uip_eth_addr src;
  uint16_t type;
};

typedef unsigned short __be16;

struct ethhdr {
 unsigned char h_dest[6];
 unsigned char h_source[6];
 __be16 h_proto;
} __attribute__((packed));

struct iphdr
  {
    unsigned int ihl:4;
    unsigned int version:4;
    uint8_t tos;
    uint16_t tot_len;
    uint16_t id;
    uint16_t frag_off;
    uint8_t ttl;
    uint8_t protocol;
    uint16_t check;
    uint32_t saddr;
    uint32_t daddr;
  };

struct udphdr
{
  __extension__ union
  {
    struct
    {
      uint16_t uh_sport;
      uint16_t uh_dport;
      uint16_t uh_ulen;
      uint16_t uh_sum;
    };
    struct
    {
      uint16_t source;
      uint16_t dest;
      uint16_t len;
      uint16_t check;
    };
  };
};

typedef unsigned int u_int8_t __attribute__ ((__mode__ (__QI__)));
typedef unsigned int u_int16_t __attribute__ ((__mode__ (__HI__)));
//typedef unsigned int u_int32_t __attribute__ ((__mode__ (__SI__)));
typedef unsigned int u_int64_t __attribute__ ((__mode__ (__DI__)));
typedef unsigned short int u_short;

typedef uint32_t in_addr_t;
struct in_addr
  {
    in_addr_t s_addr;
  };

struct ip
  {
    unsigned int ip_hl:4;
    unsigned int ip_v:4;
    u_int8_t ip_tos;
    u_short ip_len;
    u_short ip_id;
    u_short ip_off;
    u_int8_t ip_ttl;
    u_int8_t ip_p;
    u_short ip_sum;
    struct in_addr ip_src, ip_dst;
  };

#define UIP_ETHTYPE_ARP  0x0806
#define UIP_ETHTYPE_IP   0x0800
#define UIP_ETHTYPE_IPV6 0x86dd
#define ETHERTYPE_IP UIP_ETHTYPE_IP
#define ETHER_ADDR_LEN   6
#define IPVERSION        4
#define PCAP_ERRBUF_SIZE 256
#define DHCP_CHADDR_LEN 16
#define DHCP_SNAME_LEN  64
#define DHCP_FILE_LEN   128
#define DHCP_SERVER_PORT    67
#define DHCP_CLIENT_PORT    68

/* General Ethernet Definitions */
#define ARP_PACKET_SIZE         28      /* Max ARP packet size */
#define HEADER_IP_LENGTH_OFFSET 16      /* IP Length Offset */

#define ETH_DATA_LEN    1500            /* Max. octets in payload        */
#define ETH_P_IP        0x0800          /* Internet Protocol packet     */
#define ETH_HLEN        14              /* Total octets in header.       */
#define ETH_FCS_LEN     4               /* Octets in the FCS             */
#define ETH_P_ARP       0x0806          /* Address Resolution packet    */
#define ETH_P_IPV6      0x86DD          /* IPv6 */
#define ETH_FRAME_LEN   1514            /* Max. octets in frame sans FCS */

extern uip_eth_addr mac_addr;

typedef uip_eth_addr uip_lladdr_t;
typedef uint8_t u_char;

#if 0
uint16_t __bswap_16(uint16_t x);
uint32_t __bswap_32(uint32_t x);
#endif

#define ntohl(x) ({ uint32_t __tmp; \
      uint8_t *optr = (uint8_t *)&__tmp; \
      uint8_t *iptr = (uint8_t *)&(x); \
      int i; \
      for (i = 0; i < sizeof(uint32_t); i++) optr[sizeof(uint32_t)-i-1] = iptr[i]; \
      __tmp; })

#define ntohs(x) ({ uint16_t __tmp; \
      uint8_t *optr = (uint8_t *)&__tmp; \
      uint8_t *iptr = (uint8_t *)&(x); \
      int i; \
      for (i = 0; i < sizeof(uint16_t); i++) optr[sizeof(uint16_t)-i-1] = iptr[i]; \
      __tmp; })

static inline uint32_t htonl(uint32_t x) { return ntohl(x); }
static inline uint16_t htons(uint16_t x) { return ntohs(x); }

typedef unsigned int __u_int;
typedef __u_int bpf_u_int32;
// typedef long int __time_t;
typedef long int __suseconds_t;
typedef unsigned int u_int16_t __attribute__ ((__mode__ (__HI__)));

struct ether_header
{
  u_int8_t ether_dhost[6];
  u_int8_t ether_shost[6];
  u_int16_t ether_type;
} __attribute__ ((__packed__));

struct __timeval
  {
    __time_t tv_sec;
    __suseconds_t tv_usec;
  };

struct pcap_pkthdr {
 struct __timeval ts;
 bpf_u_int32 caplen;
 bpf_u_int32 len;
};

typedef u_int32_t ip4_t;

/*
 * http://www.tcpipguide.com/free/t_DHCPMessageFormat.htm
 */
typedef struct dhcp
{
    u_int8_t    opcode;
    u_int8_t    htype;
    u_int8_t    hlen;
    u_int8_t    hops;
    u_int32_t   xid;
    u_int16_t   secs;
    u_int16_t   flags;
    ip4_t       ciaddr;
    ip4_t       yiaddr;
    ip4_t       siaddr;
    ip4_t       giaddr;
    u_int8_t    chaddr[DHCP_CHADDR_LEN];
    char        bp_sname[DHCP_SNAME_LEN];
    char        bp_file[DHCP_FILE_LEN];
    uint32_t    magic_cookie;
    u_int8_t    bp_options[0];
} dhcp_t;

typedef struct inqueue_t {
  uint64_t alloc[max_packet];
  uint64_t len;
} inqueue_t;

typedef struct outqueue_t {
  uint64_t alloc[max_packet];
  uint64_t len;
} outqueue_t;

extern uip_ipaddr_t uip_hostaddr, uip_draddr, uip_netmask;
extern volatile uint64_t *const eth_base;

#ifdef BUFFERED
extern volatile int rxhead, rxtail, txhead, txtail;
extern inqueue_t *rxbuf;
extern outqueue_t *txbuf;
#endif

int dhcp_main(u_int8_t mac[6]);
void lite_queue(int sock, const void *buf, int length);
void dhcp_input(dhcp_t *dhcp, u_int8_t mac[6], int *offcount, int *ackcount);
int udp_send(const u_int8_t *mac, const void *msg, int payload_size, uint16_t client, uint16_t server, uint32_t srcaddr, uint32_t dstaddr, const u_int8_t *destmac);
void loopback_test(int loops, int sim);
void process_ip_packet(const u_char *, int);
void print_ip_packet(const u_char * , int);
void print_tcp_packet(const u_char * , int);
void process_udp_packet(int sock, const u_char *, int, uint16_t, uint32_t, const u_char *);
void PrintData (const u_char * , int);
unsigned short csum(uint8_t *buf, int nbytes);
void lite_queue(int sock, const void *buf, int length);
void eth_interrupt(void);
void recog_packet(int proto_type, uint32_t *alloc32, int xlength);
void *mysbrk(size_t len);
int mysend(int sock, void *buf, int ulen);
void tftps_tick(int sock);
void ethboot(void);
void set_dummy_mac(void);

static inline void eth_write(size_t addr, uint64_t data)
{
#ifdef DEBUG
  if ((addr < 0x8000) && !(addr&7))
#endif    
    {
#ifdef VERBOSE
      printf("eth_write(%lx,%lx)\n", addr, data);
#endif      
      eth_base[addr >> 3] = data;
    }
#ifdef DEBUG
  else
    printf("eth_write(%lx,%x) out of range\n", addr, data);
#endif  
}

static inline uint64_t eth_read(size_t addr)
{
  uint64_t retval = 0xDEADBEEF;
#ifdef DEBUG
  if ((addr < 0x8000) && !(addr&7))
#endif  
    {
      retval = eth_base[addr >> 3];
#ifdef VERBOSE
      printf("eth_read(%lx) returned %lx\n", addr, retval);
#endif      
    }
#ifdef DEBUG  
  else
    printf("eth_read(%lx) out of range\n", addr);
#endif  
  return retval;
}

#endif
