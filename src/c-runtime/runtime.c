#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include "runtime.h"


bool char_can_be_sent(void) {
    return (UART_STATUS & 0x10) == 0x10;
}


bool char_available(void) {
    return (UART_STATUS & 0x01) == 0x01;
}


void putchar(char c) {
    while(!char_can_be_sent());
    UART_RX_TX = c;
}


char getchar(void) {
    char c;

    while(!char_available());
    c = UART_RX_TX;

    return c;
}


char* gets2(char *buf, unsigned int len) {
    unsigned char temp;
    unsigned char i;
    bool done;

    done = false;
    i = 0;

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