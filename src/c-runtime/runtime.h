#ifndef _RUNTIME_H_
#define _RUNTIME_H_

#include "spi.h"
#include "sdcard.h"

//#define dbg_printf(...)  printf(__VA_ARGS__)
#define dbg_printf(...)

#define SYS_CLK_FREQ_HZ             100e6

//-----------------------------------------------------------------------
// Hardware I/O registers.
//-----------------------------------------------------------------------

__sfr __at 0x00 UART_RX_TX;
__sfr __at 0x01 UART_STATUS;
__sfr __at 0xF0 Disp7;
__sfr __at 0xFD TICKS_MS_RD_RST;
__sfr __at 0xFE TICKS_MS;

__sfr __at 0xF0 BUTTONS;
__sfr __at 0xF1 SWITCHES;
__sfr __at 0xF1 LEDS;

__sfr __at 0xA0 RGB1_R;
__sfr __at 0xA1 RGB1_G;
__sfr __at 0xA2 RGB1_B;

__sfr __at 0xA3 RGB2_R;
__sfr __at 0xA4 RGB2_G;
__sfr __at 0xA5 RGB2_B;

__sfr __at 0xA6 RGB3_R;
__sfr __at 0xA7 RGB3_G;
__sfr __at 0xA8 RGB3_B;

__sfr __at 0xA9 RGB4_R;
__sfr __at 0xAA RGB4_G;
__sfr __at 0xAB RGB4_B;


// Uncomment to use bios HW access functions.
#define USE_BIOS_RST_FUNCTIONS

//-----------------------------------------------------------------------
// Helpers
//-----------------------------------------------------------------------

#define max(x, y)       (((x) > (y)) ? (x) : (y))
#define min(x, y)       (((x) < (y)) ? (x) : (y))

#define SWAP_UINT16(x)  (((uint16_t)(x) >> 8) | \
                         ((uint16_t)(x) << 8))

#define SWAP_UINT32(x)  (( (uint32_t)(x) >> 24) | \
                         (((uint32_t)(x) & 0x00FF0000) >> 8) | \
                         (((uint32_t)(x) & 0x0000FF00) << 8) | \
                         ( (uint32_t)(x) << 24))


//-----------------------------------------------------------------------
// Function prototypes
//-----------------------------------------------------------------------

extern bool char_can_be_sent(void);
extern bool char_available(void);
extern int putchar(int c);
extern int getchar(void);
extern char* gets2(char *buf, unsigned int len);
extern int delay(int wait_ms);
extern void display(int value);
extern void leds(int value);
extern void rgb_led(int led, int r, int g, int b);
extern int get_buttons(void);
extern int get_switches(void);

extern void dump_hex(const void* data, uint32_t size,
    bool show_addr, uint32_t start_addr);

extern uint16_t parse_hex_str(uint8_t* hex, uint8_t** ptr);

#endif
