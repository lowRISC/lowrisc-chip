// QSPI commands
#define CMD_RDID 0x9F
#define CMD_MIORDID 0xAF
#define CMD_RDSR 0x05
#define CMD_RFSR 0x70
#define CMD_RDVECR 0x65
#define CMD_WRVECR 0x61
#define CMD_WREN 0x06
#define CMD_SE 0xD8
#define CMD_BE 0xC7
#define CMD_PP 0x02
#define CMD_QCFR 0x0B
#define CMD_OTPR 0x4B
#define CMD_BRWR 0x17
#define CMD_READ 0x03
#define CMD_4READ 0x13

uint32_t qspistatus(void);
uint64_t qspi_send(uint8_t cmd, uint8_t len, uint8_t quad, uint32_t *data);
void just_jump (void);
void gpio_leds(uint32_t arg);
uint32_t gpio_sw(void);
uint32_t hwrnd(void);
