
/* Register offsets (in bytes) for the LowRISC Core */
`define TXBUFF_OFFSET       'H1000          /* Transmit Buffer */

`define MACLO_OFFSET        'H0800          /* MAC address low 32-bits */
`define MACHI_OFFSET        'H0808          /* MAC address high 16-bits and MAC ctrl */
`define TPLR_OFFSET         'H0810          /* Tx packet length */
`define TFCS_OFFSET         'H0818          /* Tx frame check sequence register */
`define MDIOCTRL_OFFSET     'H0820          /* MDIO Control Register */
`define RFCS_OFFSET         'H0828          /* Rx frame check sequence register(read) and last register(write) */
`define RSR_OFFSET          'H0830          /* Rx status and reset register */
`define RBAD_OFFSET         'H0838          /* Rx bad frame and bad fcs register arrays */
`define RPLR_OFFSET         'H0840          /* Rx packet length register array */

`define RXBUFF_OFFSET       'H4000          /* Receive Buffer */
`define MDIORD_RDDATA_MASK    'H0000FFFF    /* Data to be Read */

/* MAC Ctrl Register (MACHI) Bit Masks */
`define MACHI_MACADDR_MASK    'H0000FFFF     /* MAC high 16-bits mask */
`define MACHI_COOKED_MASK     'H00010000     /* obsolete flag */
`define MACHI_LOOPBACK_MASK   'H00020000     /* Rx loopback packets */
`define MACHI_ALLPKTS_MASK    'H00400000     /* Rx all packets (promiscuous mode) */
`define MACHI_IRQ_EN          'H00800000     /* Rx packet interrupt enable */

/* MDIO Control Register Bit Masks */
`define MDIOCTRL_MDIOCLK_MASK 'H00000001    /* MDIO Clock Mask */
`define MDIOCTRL_MDIOOUT_MASK 'H00000002    /* MDIO Output Mask */
`define MDIOCTRL_MDIOOEN_MASK 'H00000004    /* MDIO Output Enable Mask */
`define MDIOCTRL_MDIORST_MASK 'H00000008    /* MDIO Input Mask */
`define MDIOCTRL_MDIOIN_MASK  'H00000008    /* MDIO Input Mask */

/* Transmit Status Register (TPLR) Bit Masks */
`define TPLR_FRAME_ADDR_MASK  'H0FFF0000     /* Tx frame address */
`define TPLR_PACKET_LEN_MASK  'H00000FFF     /* Tx packet length */
`define TPLR_BUSY_MASK        'H80000000     /* Tx busy mask */

/* Receive Status Register (RSR) */
`define RSR_RECV_FIRST_MASK   'H0000000F      /* first available buffer (static) */
`define RSR_RECV_NEXT_MASK    'H000000F0      /* current rx buffer (volatile) */
`define RSR_RECV_LAST_MASK    'H00000F00      /* last available rx buffer (static) */
`define RSR_RECV_DONE_MASK    'H00001000      /* Rx complete */
`define RSR_RECV_IRQ_MASK     'H00002000      /* Rx irq bit */

/* Receive Packet Length Register (RPLR) */
`define RPLR_LENGTH_MASK      'H00000FFF      /* Rx packet length */
`define RPLR_ERROR_MASK       'H40000000      /* Rx error mask */
`define RPLR_FCS_ERROR_MASK   'H80000000      /* Rx FCS error mask */

/* General Ethernet Definitions */
`define HEADER_OFFSET               12      /* Offset to length field */
`define HEADER_SHIFT                16      /* Shift value for length */
`define ARP_PACKET_SIZE             28      /* Max ARP packet size */
`define HEADER_IP_LENGTH_OFFSET     16      /* IP Length Offset */
