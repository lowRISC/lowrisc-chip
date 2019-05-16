#include "uart.h"

#define _write_reg_u8(addr, value) *((volatile uint8_t *)addr) = value

#define _read_reg_u8(addr) (*(volatile uint8_t *)addr)

#define _is_transmit_empty() (read_reg_u8(UART_LINE_STATUS) & 0x20)

#define _write_serial(a) \
    while (_is_transmit_empty() == 0) {}; \
    write_reg_u8(UART_THR, a); \

void write_reg_u8(uintptr_t addr, uint8_t value) { _write_reg_u8(addr, value); }
uint8_t read_reg_u8(uintptr_t addr) { return _read_reg_u8(addr); }
int is_transmit_empty() { return _is_transmit_empty(); }
void write_serial(char a) { _write_serial(a); }

void init_uart()
{
    _write_reg_u8(UART_INTERRUPT_ENABLE, 0x00); // Disable all interrupts
    _write_reg_u8(UART_LINE_CONTROL, 0x80);     // Enable DLAB (set baud rate divisor)
    _write_reg_u8(UART_DLAB_LSB, 0x1B);         // Set divisor to 27 (lo byte) 115200 baud
    _write_reg_u8(UART_DLAB_MSB, 0x00);         //                   (hi byte)
    _write_reg_u8(UART_LINE_CONTROL, 0x03);     // 8 bits, no parity, one stop bit
    _write_reg_u8(UART_FIFO_CONTROL, 0xC7);     // Enable FIFO, clear them, with 14-byte threshold
    _write_reg_u8(UART_MODEM_CONTROL, 0x20);    // Autoflow mode
}

void print_uart(const char *str)
{
    const char *cur = &str[0];
    while (*cur != '\0')
    {
        _write_serial((uint8_t)*cur);
        ++cur;
    }
}

const uint8_t bin_to_hex_table[16] = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

void bin_to_hex(uint8_t inp, uint8_t res[2])
{
    res[1] = bin_to_hex_table[inp & 0xf];
    res[0] = bin_to_hex_table[(inp >> 4) & 0xf];
    return;
}

void print_uart_short(uint16_t addr)
{
    int i;
    for (i = 1; i > -1; i--)
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
        uint8_t hex[2];
        bin_to_hex(cur, hex);
        write_serial(hex[0]);
        write_serial(hex[1]);
    }
}

void print_uart_int(uint32_t addr)
{
    int i;
    for (i = 3; i > -1; i--)
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
        uint8_t hex[2];
        bin_to_hex(cur, hex);
        write_serial(hex[0]);
        write_serial(hex[1]);
    }
}

void print_uart_addr(uint64_t addr)
{
    int i;
    for (i = 7; i > -1; i--)
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
        uint8_t hex[2];
        bin_to_hex(cur, hex);
        write_serial(hex[0]);
        write_serial(hex[1]);
    }
}

void print_uart_byte(uint8_t byte)
{
    uint8_t hex[2];
    bin_to_hex(byte, hex);
    write_serial(hex[0]);
    write_serial(hex[1]);
}

void puthex(uint64_t n, int w)
{
  if (w > 1) puthex(n>>4, w-1);
  write_serial("0123456789ABCDEF"[n&15]);
}

