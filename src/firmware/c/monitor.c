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


char* skip_whitespace(char* buffer) {
    if(buffer == NULL)
        return NULL;
    while(*buffer != NULL && isspace(*buffer))
        buffer++;
    if(*buffer == NULL)
        return NULL;
    return buffer;
}


void show_menu(void) {
    printf(CRLF "Z80 C-Monitor" CRLF);

    printf(CRLF "--- Memory ---" CRLF);

    printf("D <addr> <n>          Dump <n> RAM bytes starting @ <addr>" CRLF);
    printf("E <addr> <byte> ...   Writes number of bytes to RAM starting @ <addr>" CRLF);
    printf("F <addr> <n> <byte>   Fill <n> bytes starting @ <addr> with value <byte>" CRLF);
    printf("J <addr>              Start execution jumping to memory <addr>" CRLF);
    printf("T                     Memory test RAM" CRLF);

    printf(CRLF "--- I/O ---" CRLF);

    printf("O <port> <value>      Write 8bit <value> to 8bit <port>" CRLF);
    printf("I <port>              Raed 8bit value from 8bit <port>" CRLF);

    printf(CRLF "--- SD-Card ---" CRLF);

    printf("i                     (Re)initialized SD-Card" CRLF);
    printf("r <block> <addr> <n>  Load <n> blocks starting @ <block> from SD-Card into RAM @ <addr>" CRLF);
    printf("w <addr> <block> <n>  Write <n> 512 byte blocks from RAM @ <addr> to SD-Card @ <block>" CRLF);
    printf("B                     Boot. Read block 0 from SD-Card to RAM @ 0x8000," CRLF);
    printf("                      switch to all RAM memory config and jump to RAM @ 0x8000" CRLF);

    printf(CRLF "--- Misc ---" CRLF);

    printf("H                     This help screen" CRLF);
    printf("V                     Show version and board ID" CRLF CRLF);

    printf(CRLF "All <arguments> in hex (e.g. D 8000 100), except number <n> in dec" CRLF);
}


void show_id(void) {
    printf("Arty-Z80, C-Monitor V:0.1.0 sdcc" CRLF);
}


// =============================================================================
// Memory functions

int fn_memory_dump(uint8_t* buffer) {
    uint8_t* ptr = NULL;
    uint16_t addr = 0;
    uint16_t length = 0;

    // Assume ptr points to first valid char of first argument (Address).
    addr = parse_hex_str(buffer, &ptr);

    // SKip whitespaces to first char of seconf argument (Length).
    ptr = skip_whitespace(ptr);
    if(ptr == NULL)
        return -1;
    length = parse_int_str(ptr, &ptr);

    ptr = (uint8_t*)addr;
    dump_hex(ptr, length, true, addr);

    return 0;
}


int fn_memory_edit(uint8_t* buffer) {
    uint8_t* ptr = NULL;
    uint16_t addr = 0;
    uint8_t value = 0;
    uint8_t* addr_ptr = NULL;
    int i = 0;

    addr = parse_hex_str(buffer, &ptr);

    addr_ptr = (uint8_t*)addr;
    while(ptr != NULL) {
        ptr = skip_whitespace(ptr);
        if(ptr == NULL)
            break;

        value = parse_hex_str(ptr, &ptr);
        *addr_ptr = value;

        i++;
        addr_ptr++;
    }

    if(i < 1)
        return -1;
    printf("CS: %02X\n", chksum8((uint8_t*)addr, i));
    return 0;
}


int fn_memory_fill(uint8_t* buffer) {
    uint8_t* ptr = NULL;
    uint16_t addr = 0;
    uint16_t length = 0;
    uint8_t value = 0;

    addr = parse_hex_str(buffer, &ptr);

    ptr = skip_whitespace(ptr);
    if(ptr == NULL)
        return -1;
    length = parse_int_str(ptr, &ptr);

    ptr = skip_whitespace(ptr);
    if(ptr == NULL)
        return -2;
    value = parse_hex_str(ptr, &ptr);

    ptr = (uint8_t*)addr;
    for(int i=0; i<length; i++)
        *(ptr+i) = value;

    return 0;
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


// =============================================================================
// I/O functions

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


int fn_io_out(uint8_t* buffer) {
    uint8_t* ptr = NULL;
    uint8_t port = 0;
    uint8_t value = 0;

    port = parse_hex_str(buffer, &ptr);

    ptr = skip_whitespace(ptr);
    if(ptr == NULL)
        return -1;

    value = parse_hex_str(ptr, &ptr);

    printf("Port(0x%02x) write(0x%02x)" CRLF, port, value);
    _out_helper(port, value);

    return 0;
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


int fn_io_in(uint8_t* buffer) {
    uint8_t* ptr = NULL;
    uint8_t port = 0;
    uint8_t value = 0;

    port = parse_hex_str(buffer, &ptr);

    value = _in_helper(port);

    printf("Port(0x%02x) read(0x%02x)" CRLF, port, value);

    return 0;
}


// =============================================================================
// SD-Card functions

void _sd_status_info(char* msg, int ok) {
    printf(msg);
    if(!ok)
        printf(" failed" CRLF);
    else
        printf(" OK" CRLF);
}


void fn_sd_init() {
    uint8_t ok = spisdcard_init();
    _sd_status_info("SD-Card init", ok);
}


int fn_sd_load_block(uint8_t* buffer) {
    uint8_t* ptr = NULL;
    uint16_t block = 0;
    uint16_t addr = 0;
    uint16_t num_blocks = 0;
    uint32_t block_addr = 0;

    block = parse_hex_str(buffer, &ptr);

    ptr = skip_whitespace(ptr);
    if(ptr == NULL)
        return -1;
    addr = parse_hex_str(ptr, &ptr);

    ptr = skip_whitespace(ptr);
    if(ptr == NULL)
        return -2;
    num_blocks = parse_int_str(ptr, &ptr);

    printf("Read %d blocks (%d bytes) from SD-Card @ block %d to RAM addr(0x%04x)" CRLF,
        num_blocks, (num_blocks * 512), block, addr);

    // Convert block to byte address, each block is 512 bytes.
    ptr = (uint8_t*)addr;
    block_addr = (uint32_t)(block * 512);

    uint8_t ok = spisdcard_read(ptr, block_addr, num_blocks);
    _sd_status_info("SD-Card read", ok);

    return 0;
}


int fn_sd_write_block(uint8_t* buffer) {
    uint8_t* ptr = NULL;
    uint16_t addr = 0;
    uint16_t block = 0;
    uint16_t num_blocks = 0;
    uint32_t block_addr = 0;

    addr = parse_hex_str(buffer, &ptr);

    ptr = skip_whitespace(ptr);
    if(ptr == NULL)
        return -1;
    block = parse_hex_str(ptr, &ptr);

    ptr = skip_whitespace(ptr);
    if(ptr == NULL)
        return -2;
    num_blocks = parse_int_str(ptr, &ptr);

    printf("Write %d blocks (%d bytes) from RAM @ addr(0x%04x) to SD-Card block(0x%02x)" CRLF,
        num_blocks, (num_blocks * 512), addr, block);

    // Convert block to byte address, each block is 512 bytes.
    ptr = (uint8_t*)addr;
    block_addr = (uint32_t)(block * 512);

    uint8_t ok = spisdcard_write(ptr, block_addr, num_blocks);
    _sd_status_info("SD-Card write", ok);

    return 0;
}


void fn_sd_boot() {
    uint16_t addr = 0x8000;
    uint8_t* ptr = (uint8_t*)addr;

    // Read first block (512 bytes) from SD-Card to RAM @ address 0x8000
    uint8_t ok = spisdcard_read(ptr, 0, 1);
    if(!ok) {
        _sd_status_info("SD-Card read", ok);
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


// =============================================================================
// Main

int main(void) {
    int err = 0;
    uint8_t buffer[600];

    // Init SD Card and do a dummy read of block 0.
    fn_sd_init();
    spisdcard_read(NULL, 0, 1);

    show_menu();

    while(true) {
        if(err < 0)
            printf(MSG_ERR);
        else
            printf(MSG_OK);

        gets2(buffer, sizeof(buffer));
        printf(CRLF);
        err = 0;

        // Strip leading whitespaces.
        char *ptr = skip_whitespace(buffer);
        if(ptr == NULL) {
            err = 0;
            continue;
        }
        // Get first non-whitespace as command character.
        char cmd = *ptr;

        // Perform argument-less commands.
        switch(cmd) {
            case 'i':
                fn_sd_init();
                continue;
            case 'B':
                fn_sd_boot();
                continue;
            case 'T':
                fn_memtest();
                continue;
            case 'H':
            case '?':
                show_menu();
                continue;
            case 'V':
                show_id();
                continue;
        }

        // For commands with arguments, skip whitespaces until
        // first non whitespace character of first argument
        ptr = skip_whitespace(++ptr);
        if(ptr == NULL) {
            err = -2;
            continue;
        }

        switch(cmd) {
            case 'D':
                err = fn_memory_dump(ptr);
                break;
            case 'E':
                err = fn_memory_edit(ptr);
                break;
            case 'F':
                err = fn_memory_fill(ptr);
                break;
            case 'J':
                fn_jump(ptr);
                break;
            case 'O':
                err = fn_io_out(ptr);
                break;
            case 'I':
                err = fn_io_in(ptr);
                break;
            case 'r':
                err = fn_sd_load_block(ptr);
                break;
            case 'w':
                err = fn_sd_write_block(ptr);
                break;
            default:
                err = -3;
                break;
        }
    }
}

