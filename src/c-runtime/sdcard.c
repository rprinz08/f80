#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include "runtime.h"
#include "spi.h"
#include "sdcard.h"


//-----------------------------------------------------------------------
// SPI SDCard Select/Deselect functions
//-----------------------------------------------------------------------

uint8_t spisdcard_select(void) {
    uint16_t timeout;

    // Set SPI CS Low
    SPI_CS_W = SPI_CS_LOW;

    // Generate 8 dummy clocks
    spi_xfer(0xff);

    // Wait 500ms for the card to be ready
    timeout = 500;
    while(timeout > 0) {
        if (spi_xfer(0xff) == 0xff)
            return 1;
        delay(1);
        timeout--;
    }

    // Deselect card on error
    spisdcard_deselect();

    return 0;
}

void spisdcard_deselect(void) {
    // Set SPI CS High
    SPI_CS_W = SPI_CS_HIGH;

    // Generate 8 dummy clocks
    spi_xfer(0xff);
}


//-----------------------------------------------------------------------
// SPI SDCard bytes Xfer functions
//-----------------------------------------------------------------------

void spisdcardwrite_bytes(uint8_t* buf, uint16_t n) {
    uint16_t i;
    for (i=0; i<n; i++)
        spi_xfer(buf[i]);

    // printf("Send:\r\n");
    // dump_hex(buf, n, true, 0);
}


void spisdcardread_bytes(uint8_t* buf, uint16_t n) {
    uint16_t i;
    for (i=0; i<n; i++)
        buf[i] = spi_xfer(0xff);
}


//-----------------------------------------------------------------------
// SPI SDCard blocks Xfer functions
//-----------------------------------------------------------------------

uint8_t spisdcardreceive_block(uint8_t *buf) {
    uint16_t i;
    uint32_t timeout;

    // Wait 100ms for a start of block
    timeout = 100000;
    while(timeout > 0) {
        if (spi_xfer(0xff) == 0xfe)
            break;
        delay(1);
        timeout--;
    }
    if (timeout == 0)
        return 0;

    // Receive block
    SPI_MOSI_W = 0xff;
    for (i=0; i<512; i++) {
        SPI_LENGTH_W = (int)SPI_LENGTH;
        SPI_CONTROL_W = (int)SPI_START;
        while (SPI_STATUS_R != SPI_DONE);
        if(buf != NULL)
            *buf++ = (SPI_MISO_R & 0xff);
    }

    // Discard CRC
    spi_xfer(0xff);
    spi_xfer(0xff);

    return 1;
}


//-----------------------------------------------------------------------
// SPI SDCard Command functions
//-----------------------------------------------------------------------

uint8_t spisdcardsend_cmd(uint8_t cmd, uint32_t arg) {
    uint8_t byte = 0;
    uint8_t buf[6];
    uint8_t timeout = 0;

    // Send CMD55 for ACMD
    if(cmd & 0x80) {
        cmd &= 0x7f;
        byte = spisdcardsend_cmd(CMD55, 0);
        if (byte > 1)
            return byte;
    }

    /*
        Select the card and wait for it, except for:
        - CMD12: STOP_TRANSMISSION.
        - CMD0 : GO_IDLE_STATE.
    */
    if(cmd != CMD12 && cmd != CMD0) {
        spisdcard_deselect();
        if(spisdcard_select() == 0)
            return 0xff;
    }

    // Send Command
    buf[0] = 0x40 | cmd;                // Start + Command
    buf[1] = (uint8_t)(arg >> 24);      // Argument[31:24]
    buf[2] = (uint8_t)(arg >> 16);      // Argument[23:16]
    buf[3] = (uint8_t)(arg >> 8);       // Argument[15:8]
    buf[4] = (uint8_t)(arg >> 0);       // Argument[7:0]
    if(cmd == CMD0)
        buf[5] = 0x95;                  // Valid CRC for CMD0
    else if(cmd == CMD8)
        buf[5] = 0x87;                  // Valid CRC for CMD8 (0x1AA)
    else
        buf[5] = 0x01;                  // Dummy CRC + Stop
    spisdcardwrite_bytes(buf, 6);

    // Receive Command response
    if(cmd == CMD12)
        spisdcardread_bytes(&byte, 1);  // Read stuff byte
    timeout = 10;   // Wait for a valid response (up to 10 attempts)
    while(timeout > 0) {
        spisdcardread_bytes(&byte, 1);
        if((byte & 0x80) == 0)
            break;

        timeout--;
    }
    return byte;
}


//-----------------------------------------------------------------------
// SPI SDCard Initialization functions
//-----------------------------------------------------------------------

uint8_t spisdcard_init(void) {
    uint8_t  i;
    uint8_t  buf[4];
    uint16_t timeout;

    // Set SPI clk freq to initialization frequency
#ifndef SPI_CLK_FIXED
    spi_set_clk_freq(SPISDCARD_CLK_FREQ_INIT);
#else
    spi_set_clk_freq();
#endif

    timeout = 1000;
    while(timeout) {
        // Set SDCard in SPI Mode (generate 80 dummy clocks)
        SPI_CS_W = (int)SPI_CS_HIGH;
        for(i=0; i<10; i++)
            spi_xfer(0xff);
        SPI_CS_W = (int)SPI_CS_LOW;

        // Set SDCard in Idle state
        if(spisdcardsend_cmd(CMD0, 0) == 0x1)
            break;

        timeout--;
    }

    if (timeout == 0)
        return 0;

    // Set SDCard voltages, only supported by ver2.00+ SDCards
    if(spisdcardsend_cmd(CMD8, 0x1AA) != 0x1)
        return 0;
    spisdcardread_bytes(buf, 4); // Get additional bytes of R7 response

    // Set SDCard in Operational state (1s timeout)
    timeout = 1000;
    while(timeout > 0) {
        dbg_printf("-");
        if(spisdcardsend_cmd(ACMD41, (uint32_t)((uint32_t)1 << 30)) == 0)
            break;
        delay(1);
        timeout--;
    }
    if(timeout == 0)
        return 0;
    // Set SPI clk freq to operational frequency
#ifndef SPI_CLK_FIXED
    spi_set_clk_freq(SPISDCARD_CLK_FREQ);
#else
    spi_set_clk_freq();
#endif
    return 1;
}


//-----------------------------------------------------------------------
// SPI SDCard Read functions
//-----------------------------------------------------------------------

uint8_t spisdcard_read(uint8_t *buffer, uint32_t block, unsigned int count) {
    uint8_t cmd;
    if(count > 1)
        // READ_MULTIPLE_BLOCK
        cmd = CMD18;
    else
        // READ_SINGLE_BLOCK
        cmd = CMD17;
    if(spisdcardsend_cmd(cmd, block) == 0) {
        while(count > 0) {
            if (spisdcardreceive_block(buffer) == 0)
                break;
            if(buffer != NULL)
                buffer += 512;
            count--;
        }
        if(cmd == CMD18)
            // STOP_TRANSMISSION
            spisdcardsend_cmd(CMD12, 0);
    }
    spisdcard_deselect();

    if(count)
        return 0;

    return 1;
}


//-----------------------------------------------------------------------
// SPI SDCard Write functions
//-----------------------------------------------------------------------

uint8_t spisdcard_write(uint8_t *buffer, uint32_t block, unsigned int count) {
    uint8_t cmd;
    uint8_t byte;
    uint8_t timeout;

    if(count > 1)
        // WRITE_MULTIPLE_BLOCK
        cmd = CMD25;
    else
        // WRITE_SINGLE_BLOCK
        cmd = CMD24;
    if(spisdcardsend_cmd(cmd, block) == 0) {
        spi_xfer(0xff);
        spi_xfer(0xfe);
        while(count > 0) {
            spisdcardwrite_bytes(buffer, 512);
            buffer += 512;
            count--;

            // Write CRC
            spi_xfer(0x00);
            spi_xfer(0x00);

            spi_xfer(0xff);

            // Wait busy
            timeout = 100;
            do {
                spisdcardread_bytes(&byte, 1);
                timeout--;
            } while(((byte & 0x11) != 0x01) || timeout == 0);
            if(timeout == 0)
                break;

            timeout = 100;
            do {
                spisdcardread_bytes(&byte, 1);
                timeout--;
            } while(((byte & 0xff) != 0xff) || timeout == 0);
            if(timeout == 0)
                break;
        }

        if(cmd == CMD25)
            // STOP_TRANSMISSION
            spisdcardsend_cmd(CMD12, 0);
    }
    spisdcard_deselect();

    if(count)
        return 0;

    return 1;
}
