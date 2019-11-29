#pragma once

#include <stdint.h>
#include "ariane.h"

#define UART_RBR UART_BASE + 0
#define UART_THR UART_BASE + 0
#define UART_INTERRUPT_ENABLE UART_BASE + 4
#define UART_INTERRUPT_IDENT UART_BASE + 8
#define UART_FIFO_CONTROL UART_BASE + 8
#define UART_LINE_CONTROL UART_BASE + 12
#define UART_MODEM_CONTROL UART_BASE + 16
#define UART_LINE_STATUS UART_BASE + 20
#define UART_MODEM_STATUS UART_BASE + 24
#define UART_DLAB_LSB UART_BASE + 0
#define UART_DLAB_MSB UART_BASE + 4

#define _write_reg_u8(addr, value) *((volatile uint8_t *)addr) = value

#define _read_reg_u8(addr) (*(volatile uint8_t *)addr)

#define _is_transmit_empty() (read_reg_u8(UART_LINE_STATUS) & 0x20)

#define _write_serial(a) \
    while (_is_transmit_empty() == 0) {}; \
    write_reg_u8(UART_THR, a); \

void init_uart(uintptr_t UART_BASE, uint16_t baud);

void print_uart(uintptr_t UART_BASE, const char* str);

void print_uart_short(uintptr_t UART_BASE, uint16_t addr);

void print_uart_int(uintptr_t UART_BASE, uint32_t addr);

void print_uart_addr(uintptr_t UART_BASE, uint64_t addr);

void print_uart_byte(uintptr_t UART_BASE, uint8_t byte);

void write_serial(uintptr_t UART_BASE, char a);

uint8_t uart_line_status(uintptr_t UART_BASE);

int get_uart_byte(uintptr_t UART_BASE);
