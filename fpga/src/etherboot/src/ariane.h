#ifndef __ARIANE_H
#define __ARIANE_H

typedef enum {
        DebugBase    = 0x00000000,
        ROMBase      = 0x00010000,
        CLINTBase    = 0x02000000,
        PLICBase     = 0x0C000000,
        UARTBase     = 0x41000000,
        SPIBase      = 0x42000000,
        EthernetBase = 0x43000000,
        GPIOBase     = 0x44000000,
        DRAMBase     = 0x80000000
    } soc_bus_start_t;

enum {
    DebugLength    = 0x1000,
    ROMLength      = 0x10000,
    CLINTLength    = 0xC0000,
    PLICLength     = 0x4000000,
    UARTLength     = 0x1000,
    SPILength      = 0x800000,
    EthernetLength = 0x10000,
    GPIOLength     = 0x1000,
    DRAMLength     = 0x40000000, // 1GByte of DDR (split between two chips on Genesys2)
};

void eth_main(void);
void sd_main(int sw);
void dram_main(void);
void cache_main(void);
uint32_t hwrnd(void);
void gpio_leds(uint32_t arg);
uint32_t gpio_sw(void);

#endif
