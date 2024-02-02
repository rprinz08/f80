#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "runtime.h"


int main(void) {
    uint8_t ok = 0;
    uint8_t buffer[600];

    printf("SD-Card Test\r\n");

    ok = spisdcard_init();
    printf("SD init(%d)\r\n", ok);

    if(!ok)
        return 0;

    while(true) {
        printf("read(r), write(w), quit(q): ");
        char c = getchar();

        if(c == 'q')
            break;

        if(c == 'r') {
            while(true) {
                printf("\r\nEnter block to read: ");
                gets2(buffer, sizeof(buffer));
                printf("\r\n");
                if(buffer[0] == 'q' || buffer[0] == 'Q')
                    break;
                uint32_t block = atoi(buffer);

                // Convert block to byte address, each block is 512 bytes.
                uint32_t addr = (uint32_t)(block * 512);
                printf("Read Block (%ld) @ address (0x%08lx)\r\n\r\n", block, addr);
                ok = spisdcard_read(buffer, addr, 1);
                printf("SD read returns (%d)\r\n", ok);

                if(ok)
                    dump_hex(buffer, 512, true, addr);
            }
        }

        if(c == 'w') {
            while(true) {
                printf("\r\nEnter block to write: ");
                gets2(buffer, sizeof(buffer));
                printf("\r\n");
                if(buffer[0] == 'q' || buffer[0] == 'Q')
                    break;
                uint32_t block = atoi(buffer);

                // Convert block to byte address, each block is 512 bytes.
                uint32_t addr = (uint32_t)(block * 512);

                // Clear block to write.
                memset(buffer, 0x00, sizeof(buffer));
                // Test end block marker.
                buffer[510] = 0x22;
                buffer[511] = 0xf0;
                printf("Enter data to write: ");
                gets2(buffer, sizeof(buffer));
                printf("\r\n");

                ok = spisdcard_write(buffer, addr, 1);
                printf("SD write returns (%d)\r\n", ok);
            }
        }
    }

    // // Write test sector 1
    // memset(buffer, 0xaa, sizeof(buffer));
    // buffer[0] = 0x11;
    // buffer[510] = 0x22;
    // buffer[511] = 0xf0;
    // ok = spisdcard_write(buffer, 1*512, 1);
    // printf("SD write returns (%d)\r\n", ok);

    return 0;
}
