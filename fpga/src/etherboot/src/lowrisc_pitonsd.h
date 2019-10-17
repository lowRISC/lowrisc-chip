/* LowRISC_piton_sd register definitions */

#define _piton_sd_ADDR_SD     (0x00)
#define _piton_sd_ADDR_DMA    (0x01)
#define _piton_sd_BLKCNT      (0x02)
#define _piton_sd_REQ_RD      (0x03)
#define _piton_sd_REQ_WR      (0x04)
#define _piton_sd_IRQ_EN      (0x05)
#define _piton_sd_SYS_RST     (0x06)

#define _piton_sd_ADDR_SD_F   (0x00)
#define _piton_sd_ADDR_DMA_F  (0x01)
#define _piton_sd_STATUS      (0x02)
#define _piton_sd_ERROR       (0x03)
#define _piton_sd_INIT_STATE  (0x04)
#define _piton_sd_COUNTER     (0x05)
#define _piton_sd_INIT_FSM    (0x06)
#define _piton_sd_TRAN_STATE  (0x07)
#define _piton_sd_TRAN_FSM    (0x08)

#define _piton_sd_STATUS_REQ_RD       (0x00000001)
#define _piton_sd_STATUS_REQ_WR       (0x00000002)
#define _piton_sd_STATUS_IRQ_EN       (0x00000004)
#define _piton_sd_STATUS_SD_IRQ       (0x00000008)
#define _piton_sd_STATUS_REQ_RDY      (0x00000010)
#define _piton_sd_STATUS_INIT_DONE    (0x00000020)
#define _piton_sd_STATUS_HCXC         (0x00000040)
#define _piton_sd_STATUS_SD_DETECT    (0x00000080)

#define _piton_sd_NUM_MINORS 16

/* FSM state definitions */
#define _piton_sd_FSM_STATE_IDLE               0
#define _piton_sd_FSM_STATE_WAIT_TRANSFER      2
#define _piton_sd_FSM_STATE_WAIT_CFREADY       3
#define _piton_sd_FSM_STATE_REQ_PREPARE        6
#define _piton_sd_FSM_STATE_REQ_NEXT           7
#define _piton_sd_FSM_STATE_REQ_TRANSFER       8
#define _piton_sd_FSM_STATE_REQ_COMPLETE       9
#define _piton_sd_FSM_STATE_ERROR             10
#define _piton_sd_FSM_NUM_STATES              11
