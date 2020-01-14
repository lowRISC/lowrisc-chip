/* Copyright (GPL), 2004 Mike Chirico mchirico@comcast.net or mchirico@users.sourceforge.net
   http://prdownloads.sourceforge.net/souptonuts/working_with_time.tar.gz?download

   This program queries a timeserver on UDP port 123 and allows us to peek at 
   at the NTP timestamp format.

Need a list of Public NTP Secondary (stratum 2) Time Servers?
http://www.eecis.udel.edu/~mills/ntp/clock2b.html

A good reference of the standard:
http://www.eecis.udel.edu/~mills/database/rfc/rfc2030.txt

   Below is a description of the NTP/SNTP Version 4 message format,
   which follows the IP and UDP headers. This format is identical to
   that described in RFC-1305, with the exception of the contents of the
   reference identifier field. The header fields are defined as follows:

                           1                   2                   3
       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |LI | VN  |Mode |    Stratum    |     Poll      |   Precision   |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                          Root Delay                           |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                       Root Dispersion                         |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                     Reference Identifier                      |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                   Reference Timestamp (64)                    |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                   Originate Timestamp (64)                    |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                    Receive Timestamp (64)                     |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                    Transmit Timestamp (64)                    |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                 Key Identifier (optional) (32)                |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      |                                                               |
      |                 Message Digest (optional) (128)               |
      |                                                               |
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+



   Reference Timestamp: This is the time at which the local clock was
   last set or corrected, in 64-bit timestamp format.

   Originate Timestamp: This is the time at which the request departed
   the client for the server, in 64-bit timestamp format.

   Receive Timestamp: This is the time at which the request arrived at
   the server, in 64-bit timestamp format.

   Transmit Timestamp: This is the time at which the reply departed the
   server for the client, in 64-bit timestamp format.










*/

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include "ariane.h"
#include "eth.h"

/*
 * Time of day conversion constant.  Ntp's time scale starts in 1900,
 * Unix in 1970.
 */
#define JAN_1970        0x83aa7e80      /* 2208988800 1970 - 1900 in seconds */

#define NTP_TO_UNIX(n,u) do {  u = n - JAN_1970; } while (0)

#define HTONL_FP(h, n)  do { (n)->l_ui = __htonl((h)->l_ui); \
                             (n)->l_uf = __htonl((h)->l_uf); } while (0)

#define NTOHL_FP(n, h)  do { (h)->l_ui = __ntohl((n)->l_ui); \
                             (h)->l_uf = __ntohl((n)->l_uf); } while (0)

#define SA      struct sockaddr
#define MAXLINE 16384
#define READMAX 16384		//must be less than MAXLINE or equal
#define NUM_BLK 20
#define MAXSUB  512
#define URL_LEN 256
#define MAXHSTNAM 512
#define MAXPAGE 1024
#define MAXPOST 1638

#define LISTENQ         1024

extern int h_errno;

/*
 * NTP uses two fixed point formats.  The first (l_fp) is the "long"
 * format and is 64 bits long with the decimal between bits 31 and 32.
 * This is used for time stamps in the NTP packet header (in network
 * byte order) and for internal computations of offsets (in local host
 * byte order). We use the same structure for both signed and unsigned
 * values, which is a big hack but saves rewriting all the operators
 * twice. Just to confuse this, we also sometimes just carry the
 * fractional part in calculations, in both signed and unsigned forms.
 * Anyway, an l_fp looks like:
 *
 *    0                   1                   2                   3
 *    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 *   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *   |                         Integral Part                         |
 *   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *   |                         Fractional Part                       |
 *   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * REF http://www.eecis.udel.edu/~mills/database/rfc/rfc2030.txt
 */


typedef struct {
  union {
    uint32_t Xl_ui;
    int32_t Xl_i;
  } Ul_i;
  union {
    uint32_t Xl_uf;
    int32_t Xl_f;
  } Ul_f;
} l_fp;

#define l_ui    Ul_i.Xl_ui              /* unsigned integral part */
#define l_i     Ul_i.Xl_i               /* signed integral part */
#define l_uf    Ul_f.Xl_uf              /* unsigned fractional part */
#define l_f     Ul_f.Xl_f               /* signed fractional part */

#define HTONL_F(f, nts) do { (nts)->l_uf = htonl(f); \
                                if ((f) & 0x80000000) \
                                        (nts)->l_i = -1; \
                                else \
                                        (nts)->l_i = 0; \
                        } while (0)

struct pkt {
  uint8_t  li_vn_mode;     /* leap indicator, version and mode */
  uint8_t  stratum;        /* peer stratum */
  uint8_t  ppoll;          /* peer poll interval */
  int8_t  precision;      /* peer clock precision */
  uint32_t    rootdelay;      /* distance to primary clock */
  uint32_t    rootdispersion; /* clock dispersion */
  uint32_t refid;          /* reference clock ID */
  l_fp    ref;        /* time peer clock was last updated */
  l_fp    org;            /* originate time stamp */
  l_fp    rec;            /* receive time stamp */
  l_fp    xmt;            /* transmit time stamp */

#define LEN_PKT_NOMAC   12 * sizeof(uint32_t) /* min header length */
#define LEN_PKT_MAC     LEN_PKT_NOMAC +  sizeof(uint32_t)
#define MIN_MAC_LEN     3 * sizeof(uint32_t)     /* DES */
#define MAX_MAC_LEN     5 * sizeof(uint32_t)     /* MD5 */

  /*
   * The length of the packet less MAC must be a multiple of 64
   * with an RSA modulus and Diffie-Hellman prime of 64 octets
   * and maximum host name of 128 octets, the maximum autokey
   * command is 152 octets and maximum autokey response is 460
   * octets. A packet can contain no more than one command and one
   * response, so the maximum total extension field length is 672
   * octets. But, to handle humungus certificates, the bank must
   * be broke.
   */
  uint32_t exten[1];       /* misused */
  uint8_t  mac[MAX_MAC_LEN]; /* mac */
};

enum {t1980=315536400-3600};

void ntp_snd( int sockfd )
{
  int len;

  struct pkt msg;

  msg.li_vn_mode=227;
  msg.stratum=0;
  msg.ppoll=4;
  msg.precision=0;
  msg.rootdelay=0;
  msg.rootdispersion=0;
  msg.ref.Ul_i.Xl_i=0;
  msg.ref.Ul_f.Xl_f=0;
  msg.org.Ul_i.Xl_i=0;
  msg.org.Ul_f.Xl_f=0;
  msg.rec.Ul_i.Xl_i=0;
  msg.rec.Ul_f.Xl_f=0;
  msg.xmt.Ul_i.Xl_i=0;
  msg.xmt.Ul_f.Xl_f=0;

  len=48;

  ntp_send(sockfd, (char *) &msg, len);
}

void convert(time_t t1970)
{
  int t = t1970 - t1980;
  char months[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
  int d1 = t / 86400;
  int y = d1 * 4 / 1461;
  int hms = t % 86400;
  int h = hms / 3600;
  int m1 = hms % 3600;
  int m = m1 / 60;
  int s = m1 % 60;
  int dom, doy, mon = 0;
  if (y%4 == 0)
    {
      doy = d1 % 1461;
      months[1]++;
    }
  else
    {
      doy = (d1 % 1461 - 366) % 365;
    }
  dom = doy;
  while ((mon < 12) && (dom >= months[mon])) dom -= months[mon++];
  printf("%d: %d/%d/%d: %d:%d:%d\n", doy, dom+1, mon+1, (y+1980), h, m, s);
}

void process_ntp_packet(int sock, const u_char *data, int len, uint16_t peer_port, uint32_t peer_ip, const u_char *peer_addr)
{
  struct pkt msg, prt;
  time_t seconds, rtc = rtc_secs();

  memcpy(&msg, data, sizeof(struct pkt));

  NTOHL_FP(&msg.ref, &prt.ref);
  NTOHL_FP(&msg.org, &prt.org);
  NTOHL_FP(&msg.rec, &prt.rec);
  NTOHL_FP(&msg.xmt, &prt.xmt);

  NTP_TO_UNIX(prt.rec.Ul_i.Xl_ui, seconds);
  printf("rec: %lX.%u\n",seconds,prt.rec.Ul_f.Xl_f);
  if (rtc < t1980)
    {
      rtc_write(seconds, prt.rec.Ul_f.Xl_f);
    }
  rtc = rtc_secs();
  printf("rtc: %lX.%u\n",rtc,rtc_usecs());
  convert(seconds);
  convert(rtc);
  printf("diff = %ld\n", seconds - rtc);
}
