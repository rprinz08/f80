#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include "runtime.h"


int main(void) {
    long int seconds = 0;
    char c = 0;

    printf("Arty-80 Clock\r");
    printf("Press (q) to quit.\r\n");
    display(0);

    while(true) {
        printf("Seconds: (%8ld)\r", seconds);
        display(seconds);

        if(char_available()) {
            c = getchar();
            if(c == 'q')
                break;
        }

        delay(1000);
        seconds++;
    }

    return 0x0042;
}
