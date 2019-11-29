#include "uart.h"

void write_reg_u8(uintptr_t addr, uint8_t value) { _write_reg_u8(addr, value); }
uint8_t read_reg_u8(uintptr_t addr) { return _read_reg_u8(addr); }
int is_transmit_empty(uintptr_t UART_BASE) { return _is_transmit_empty(); }
uint8_t uart_line_status(uintptr_t UART_BASE) { return _read_reg_u8(UART_LINE_STATUS); }
void write_serial(uintptr_t UART_BASE, char a) { _write_serial(a); }

void init_uart(uintptr_t UART_BASE, uint16_t baud)
{
    _write_reg_u8(UART_INTERRUPT_ENABLE, 0x00); // Disable all interrupts
    _write_reg_u8(UART_LINE_CONTROL, 0x80);     // Enable DLAB (set baud rate divisor)
    _write_reg_u8(UART_DLAB_LSB, baud & 0xFF);  // Set divisor to 50M/16/baud (lo byte) 115200 baud => 27
    _write_reg_u8(UART_DLAB_MSB, baud >> 8);    //                   (hi byte)
    _write_reg_u8(UART_FIFO_CONTROL, 0xE7);     // Enable FIFO64
    _write_reg_u8(UART_LINE_CONTROL, 0x03);     // 8 bits, no parity, one stop bit
    _write_reg_u8(UART_FIFO_CONTROL, 0xC7);     // Enable FIFO, clear them, with 14-byte threshold
    _write_reg_u8(UART_MODEM_CONTROL, 0x2);     // flow control disabled
}

void print_uart(uintptr_t UART_BASE, const char *str)
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

void print_uart_short(uintptr_t UART_BASE, uint16_t addr)
{
    int i;
    for (i = 1; i > -1; i--)
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
        uint8_t hex[2];
        bin_to_hex(cur, hex);
        write_serial(UART_BASE, hex[0]);
        write_serial(UART_BASE, hex[1]);
    }
}

void print_uart_int(uintptr_t UART_BASE, uint32_t addr)
{
    int i;
    for (i = 3; i > -1; i--)
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
        uint8_t hex[2];
        bin_to_hex(cur, hex);
        write_serial(UART_BASE, hex[0]);
        write_serial(UART_BASE, hex[1]);
    }
}

void print_uart_addr(uintptr_t UART_BASE, uint64_t addr)
{
    int i;
    for (i = 7; i > -1; i--)
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
        uint8_t hex[2];
        bin_to_hex(cur, hex);
        write_serial(UART_BASE, hex[0]);
        write_serial(UART_BASE, hex[1]);
    }
}

void print_uart_byte(uintptr_t UART_BASE, uint8_t byte)
{
    uint8_t hex[2];
    bin_to_hex(byte, hex);
    write_serial(UART_BASE, hex[0]);
    write_serial(UART_BASE, hex[1]);
}

int get_uart_byte(uintptr_t UART_BASE)
{
  return read_reg_u8(UART_LINE_STATUS) & 0x1 ? read_reg_u8(UART_RBR) : -1;
}
