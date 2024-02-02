#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "runtime.h"


#ifdef USE_BIOS_RST_FUNCTIONS
bool char_can_be_sent(void) __naked {
    __asm

    LD      A, #0x03
    RST     0x08

    AND     #0x10
    JR      Z, 1$
    LD      L, #1
    RET
1$:
    LD      L, #0
    RET

    __endasm;
}

bool char_available(void) __naked {
    __asm

    LD      A, #0x03
    RST     0x08

    AND     A, #0x01
    JR      Z, 1$
    LD      L, #1
    RET
1$:
    LD      L, #0
    RET

    __endasm;
}

int putchar(int c) __naked {
    c;
    __asm

    ; Bypass the return address of the function.
    LD      IY, #2
    ADD     IY, SP

    ; get value argument in reg A and output to SPI MOSI port.
    LD      A, (IY)
    LD      L, A
    PUSH    HL
    LD      A, #0x01
    RST     0x08

    ; Return as char value in reg L.
    POP     HL
    RET

    __endasm;
}

int getchar(void) __naked {
    __asm

    LD      A, #0x02
    RST     0x08

    LD      L, A
    RET

    __endasm;
}
#else
bool char_can_be_sent(void) {
    return (UART_STATUS & 0x10) == 0x10;
}

bool char_available(void) {
    return (UART_STATUS & 0x01) == 0x01;
}

int putchar(int c) {
    while(!char_can_be_sent());
    UART_RX_TX = c;
    return c;
}

int getchar(void) {
    char c;

    while(!char_available());
    c = UART_RX_TX;

    return c;
}
#endif

char* gets2(char *buf, unsigned int len) {
    unsigned char temp;
    unsigned char i;
    bool done;

    done = false;
    i = 0;

    // Clear buffer.
    memset(buf, 0, len);

    while(done == false) {
        temp = getchar();

        if(temp == '\b') {
            if(i != 0) {            // backspace if possible
                i = i - 1;
                putchar('\b');
                putchar(' ');
                putchar('\b');
            }
        }
        else
            if(temp == '\r') {      // handle newline
                buf[i] = '\0';      // add null terminator to string
                done = true;
            }
            else
                if(temp == '\0') {  // handle EOF
                    buf[i] = '\0';  // add null terminator to string
                }
                else {              // handle new character
                    buf[i] = temp;
                    putchar(temp);  // echo character
                    i = i + 1;
                    if(i == (len-1)) {
                        buf[i] = '\0';
                        done = true;
                    }
                }
    }

    // Ensure that last byte of buffer is always 0.
    buf[len-1] = 0;
    return buf;
}

// Waits the provided number of milliseconds by constantly reading the
// millisecond ticker register.
int delay(int wait_ms) {
    int ms = 0;
    int diff_ms = 0;
    int last_ms = 0;

    last_ms = TICKS_MS;
    while(wait_ms > 0) {
        ms = TICKS_MS;
        if(ms < last_ms)
            diff_ms = (0xff - last_ms) + ms;
        else
            diff_ms = ms - last_ms;

        last_ms = ms;

        wait_ms -= diff_ms;
    }
    return 0;
}

void display(int value) {
    Disp7 = value;
}

void leds(int value) {
    LEDS = value;
}

void rgb_led(int led, int r, int g, int b) {
    switch(led) {
        case 0:
            RGB1_R = r;
            RGB1_G = g;
            RGB1_B = b;
            break;
        case 1:
            RGB2_R = r;
            RGB2_G = g;
            RGB2_B = b;
            break;
        case 2:
            RGB3_R = r;
            RGB3_G = g;
            RGB3_B = b;
            break;
        case 3:
            RGB4_R = r;
            RGB4_G = g;
            RGB4_B = b;
            break;
    }
}

int get_buttons(void) {
    return BUTTONS;
}

int get_switches(void) {
    return SWITCHES;
}

void dump_hex(const void* data, uint32_t size,
    bool show_addr, uint32_t start_addr) {

#define MAX_LINE_LEN    128
    char ascii[17] = {0};
    int line_len = MAX_LINE_LEN;
    int line_ptr = 0;
    uint32_t i = 0;
    uint32_t addr = start_addr;
    int m8 = 0, m16 = 0;

    for(i = 0; i < size; i++) {
        m8 = i % 8;
        m16 = i % 16;

        if(i == 0 && show_addr)
            printf("%08lx : ", addr);

        if(i > 0 && (m16) == 0) {
            printf(" |  %s\r\n", ascii);
            addr += 16;
            printf("%08lx : ", addr);
        }
        else if(i > 0 && (m8) == 0) {
            printf("-- ");
        }

        uint8_t byte = ((uint8_t*)data)[i];
        printf("%02x ", byte);

		if (byte >= ' ' && byte <= '~')
			ascii[m16] = byte;
		else
			ascii[m16] = '.';
        ascii[m16 + 1] = '\0';
    }

    if(i > 0) {
        m16 = i % 16;
        if(m16 > 0) {
            int w = (51 - ((m16 + (m16 > 8 ? 1 : 0)) * 3));
            for(i = 0; i < w; i++)
                printf(" ");
        }
        printf(" |  %s\r\n", ascii);
    }
}

uint16_t parse_hex_str(uint8_t* hex, uint8_t** ptr) {
    uint16_t ret = 0;
    while (*hex) {
        int c = *hex;
        if(c >= 'a' && c <= 'f')
            c -= 32;
        if( !((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F')) )
            goto DONE;
        c -= '0';
        if(c > 10)
            c -= 7;
        ret = (ret << 4) | (uint16_t)c;
        hex++;
    }
DONE:
    if(ptr != NULL)
        *ptr = hex;
    return ret;
}
