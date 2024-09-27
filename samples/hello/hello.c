#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include "runtime.h"


int main(void) {
    char buffer[255];

    printf("\r\nEnter your name: ");
    gets2(buffer, sizeof(buffer), NULL);
    printf("\n\r\n");
    printf("Hello (%s)\r\n\r\n", buffer);

    return 0;
}
