#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "runtime.h"

#define CR              "\r"
#define LF              "\n"
#define CRLF            CR LF

// Note: Global initialization of C variables not working at the moment.
// const char* MSG_OK = (CRLF "OK" CRLF);
// const char* MSG_ERR = "ERR" CRLF;

#define MSG_OK          (CRLF "OK" CRLF)
#define MSG_ERR         ("ERR" CRLF)

void show_menu(void) {
    printf(CRLF "Z80 C-Monitor" CRLF);
    printf("--- Memory ---" CRLF);
    printf("D<addr>,<length>  Dump <length> RAM bytes starting at <addr>" CRLF);
    printf("L<addr>,<length>  Load <length> RAM bytes starting at <addr> via serial" CRLF);
    printf("J<addr>           Start execution jumping to memory <addr>" CRLF);
    printf("--- I/O ---" CRLF);
    printf("O<port>,<value>   Write 8bit <value> to 8bit <port>" CRLF);
    printf("I<port>           Raed 8bit value from 8bit <port>" CRLF);
    printf("--- SD-Card ---" CRLF);
    printf("i                 (Re)initialized SD-Card" CRLF);
    printf("r<block>,<addr>   Load <block> from SD-Card into RAM @ <addr>" CRLF);
    printf("w<addr>,<block>   Write 512 byte from RAM @ <addr> to SD-Card <block>" CRLF);
    printf("B                 Boot. Read block 0 from SD-Card to RAM @ 0x8000," CRLF);
    printf("                  switch to all RAM memory config and jump to RAM @ 0x8000" CRLF);
    printf("--- Misc ---" CRLF);
    printf("T                 Memory test RAM" CRLF);
    printf("H                 This help screen" CRLF);
    printf("V                 Show version and board ID" CRLF CRLF);
    printf("All <arguments> in hex (e.g. D8000,0100)" CRLF);
}

void show_id(void) {
    printf("Arty-Z80, C-Monitor V:0.1.0 sdcc" CRLF);
}

void fn_memory_dump(uint8_t* buffer) {
    uint8_t* ptr;
    uint16_t addr = parse_hex_str(buffer, &ptr);
    uint16_t length = 0;

    if(*ptr == ',') {
        length = parse_hex_str(++ptr, &ptr);
        ptr = (uint8_t*)addr;
        dump_hex(ptr, length, true, addr);
    }
    else
        printf(MSG_ERR);
}

void _out_helper(uint8_t port, uint8_t value) __naked {
    port; value;    // Get rid of unused variable compiler warning.
    __asm
    ; Bypass the return address of the function.
    LD      IY, #2
    ADD     IY, SP

    ; get port argument in reg C and value in A.
    LD      C, (IY)
    LD      A, 1(IY)
    OUT     (C), A

    RET
    __endasm;
}

void fn_io_out(uint8_t* buffer) {
    uint8_t* ptr;
    uint8_t port = parse_hex_str(buffer, &ptr);
    uint8_t value = 0;

    if(*ptr == ',') {
        value = parse_hex_str(++ptr, &ptr);
        printf("Port(0x%02x) write(0x%02x)" CRLF, port, value);
        _out_helper(port, value);
    }
    else
        printf(MSG_ERR);
}

uint8_t _in_helper(uint8_t port) __naked {
    port;   // Get rid of unused variable compiler warning.
    __asm
    ; Bypass the return address of the function.
    LD      IY, #2
    ADD     IY, SP

    ; get port argument in reg C.
    LD      C, (IY)
    IN      A, (C)

    LD      L, A
    RET
    __endasm;
}

void fn_io_in(uint8_t* buffer) {
    uint8_t* ptr;
    uint8_t port = parse_hex_str(buffer, &ptr);
    uint8_t value = _in_helper(port);

    printf("Port(0x%02x) read(0x%02x)" CRLF, port, value);
}

void fn_load(uint8_t* buffer) {
    uint8_t* ptr;
    uint16_t addr = parse_hex_str(buffer, &ptr);
    uint16_t length = 0;

    if(*ptr == ',') {
        length = parse_hex_str(++ptr, &ptr);
        printf("Load addr(0x%02x) length(0x%02x)" CRLF, addr, length);
        ptr = (uint8_t*)addr;
        for(uint16_t i=0; i<length; i++) {
            *(ptr + i) = getchar();
        }
    }
    else
        printf(MSG_ERR);
}

void _jump_helper(uint16_t addr) __naked {
    addr;   // Get rid of unused variable compiler warning.
    __asm
    ; Bypass the return address of the function.
    LD      IY, #2
    ADD     IY, SP

    ; Get addr argument in reg C.
    LD      L, (IY)
    LD      H, 1(IY)
    LD      SP, #0xffff
    JP      (HL)
    __endasm;
}

void fn_jump(uint8_t* buffer) {
    uint16_t* ptr;
    uint16_t addr = parse_hex_str(buffer, &ptr);
    _jump_helper(addr);
}

void fn_memtest() __naked {
    __asm
    LD      A, #0xaa
    RST     0x08
    RET
    __endasm;
}

void sd_status_info(char* msg, int ok) {
    printf(msg);
    if(!ok)
        printf(" failed" CRLF);
    else
        printf(" OK" CRLF);
}

void sd_init() {
    uint8_t ok = spisdcard_init();
    sd_status_info("SD-Card init", ok);
}

void sd_load_block(uint8_t* buffer) {
    uint8_t* ptr;
    uint16_t block = parse_hex_str(buffer, &ptr);
    uint16_t addr = 0;

    if(*ptr == ',') {
        addr = parse_hex_str(++ptr, &ptr);
        printf("Read SD-Card block(0x%02x) to RAM addr(0x%04x)" CRLF,
            block, addr);
        ptr = (uint8_t*)addr;

        // Convert block to byte address, each block is 512 bytes.
        uint32_t block_addr = (uint32_t)(block * 512);
        uint8_t ok = spisdcard_read(ptr, block_addr, 1);
        sd_status_info("SD-Card read", ok);
    }
}

void sd_write_block(uint8_t* buffer) {
    uint8_t* ptr;
    uint16_t addr = parse_hex_str(buffer, &ptr);
    uint16_t block = 0;

    if(*ptr == ',') {
        block = parse_hex_str(++ptr, &ptr);
        printf("Write 512 bytes RAM @ addr(0x%04x) to SD-Card block(0x%02x)" CRLF,
            block, addr);
        ptr = (uint8_t*)addr;

        // Convert block to byte address, each block is 512 bytes.
        uint32_t block_addr = (uint32_t)(block * 512);
        uint8_t ok = spisdcard_write(ptr, block_addr, 1);
        sd_status_info("SD-Card write", ok);
    }
}

void sd_boot() {
    uint16_t addr = 0x8000;
    uint8_t* ptr = (uint8_t*)addr;

    // Read first block (512 bytes) from SD-Card to RAM @ address 0x8000
    uint8_t ok = spisdcard_read(ptr, 0, 1);
    if(!ok) {
        sd_status_info("SD-Card read", ok);
        printf("Boot aborted" CRLF);
        return;
    }

    // Write change memory to all RAM code to end of RAM and a jump to RAM @ 0x8000
    addr = 0xfff0;
    ptr = (uint8_t*)addr;
    uint8_t code[] = {
            0xe3, 0x01,         // LD A, #0x01
            0xd3, 0x02,         // OUT (0x02), A
            0xc3, 0x00, 0x80    // JP 0x8000
        };

    for(int i=0; i<sizeof(code); i++) {
        *(ptr+i) = code[i];
    }

    // Jump to code at end of RAM.
    _jump_helper(addr);
}

int main(void) {
    uint8_t buffer[600];

    // INit SD Card and do a dummy read of block 0.
    sd_init();
    spisdcard_read(NULL, 0, 1);

    show_menu();

    while(true) {
        printf(MSG_OK);
        gets2(buffer, sizeof(buffer));
        printf(CRLF);

        char cmd = buffer[0];
        uint8_t* args = buffer + 1;
        switch(cmd) {
            case 'D':
                fn_memory_dump(args);
                break;
            case 'L':
                fn_load(args);
                break;
            case 'J':
                fn_jump(args);
                break;
            case 'O':
                fn_io_out(args);
                break;
            case 'I':
                fn_io_in(args);
                break;
            case 'i':
                sd_init();
                break;
            case 'r':
                sd_load_block(args);
                break;
            case 'w':
                sd_write_block(args);
                break;
            case 'B':
                sd_boot();
                break;
            case 'T':
                fn_memtest();
                break;
            case 'H':
                show_menu();
                break;
            case 'V':
                show_id();
                break;
            default:
                break;
        }
    }
}

