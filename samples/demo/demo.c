#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include "runtime.h"


// Hardware I/O registers.
__sfr __at 0x42 NON_EXISTING;


/*
 * Converts a HUE to r, g or b.
 * returns float in the set [0, 1].
 */
float hue2rgb(float p, float q, float t) {
    if (t < 0)
        t += 1;
    if (t > 1)
        t -= 1;
    if (t < 1./6)
        return p + (q - p) * 6 * t;
    if (t < 1./2)
        return q;
    if (t < 2./3)
        return p + (q - p) * (2./3 - t) * 6;

    return p;
}


/*
 * Converts an HSL color value to RGB. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
 * Assumes h, s, and l are contained in the set [0, 1] and
 * returns RGB in the set [0, 255].
 * If lightness is equal to 1, then the RGB LED will be white
 */
void hsl2rgb(float h, float s, float l, float* r, float* g, float* b) {
    if(0 == s) {
        *r = *g = *b = l; // achromatic
    }
    else {
        float q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        float p = 2 * l - q;
        *r = hue2rgb(p, q, h + 1./3) * 255;
        *g = hue2rgb(p, q, h) * 255;
        *b = hue2rgb(p, q, h - 1./3) * 255;
    }
}


int main(void) {
    int w = 0;
    unsigned long int cnt = 0;
    int buttons;
    int switches;

    float r = 0;
    float g = 0;
    float b = 0;
    float _hue = 0.0;
    float _step = 0.01f;
    int rgb_cnt = 0;

    printf("Arty-80 Demo\r\n");
    display(0);
    leds(0);

    while(true) {
        display(cnt);
        leds(cnt);
        cnt++;

        buttons = get_buttons();
        switches = get_switches();

        // Note: long types (e.g. counter) need to be explicitly defined
        // in printf, otherwise following values will be shifted which
        // could lead to hard to track bugs.
        printf("Counter: (%6ld), Buttons: (0x%02x), "
            "Switches: (0x%02x), w: (0x%02x)   \r",
                cnt, buttons, switches, w);


        // Try to write and read non existing I/O port.
        // Should do nothing.
        NON_EXISTING = 42;
        w = NON_EXISTING;

        // Update RGB LED light show.
        hsl2rgb(_hue, 1.0f, 0.5f, &r, &g, &b);
        rgb_led(rgb_cnt, r, g, b);

        // Update hue based on step size.
        _hue += _step;

        // Hue ranges between 0-1, so if > 1, reset to 0.
        if(_hue > 1.0) {
            _hue = 0.0;
            rgb_led(rgb_cnt, 0, 0, 0);
            // Select next RGB LED.
            rgb_cnt++;
            if(rgb_cnt > 3)
                break;
        }
    }

    display(0);
    leds(0);

    printf("\r\nDone!\r\n");
    return 0xabcd;
}
