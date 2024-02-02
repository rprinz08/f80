#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include "runtime.h"
#include "spi.h"


//-----------------------------------------------------------------------
// SPI clock functions
//-----------------------------------------------------------------------

/*
#ifdef SPI_CLK_FIXED
void spi_set_clk_freq_c(void)
#else
void spi_set_clk_freq_c(uint32_t clk_freq)
#endif
{
    uint32_t divider;

#ifndef SPI_CLK_FIXED
    // Assuming a given system clock of 100Mhz and an SPI clock of 400kHz
    // (which both normally do not change), a fixed divider can be used
    // without the need to include complex (and big in size) math functions.
    // So instead of writing this function dynamic like:

    divider = (SYS_CLK_FREQ_HZ/clk_freq) + 1;
    divider = max(divider, 2);
    divider = min(divider, 256);
#else
    // Instead use a fixed divider for clock speeds above:

    divider = SPI_CLK_FIXED;
#endif

    // Write divider value to HW registers.
    SPI_CLK_DIV_LOW_W = divider & 0x000000FF;
    SPI_CLK_DIV_HIGH_W = (divider & 0x0000FF00) >> 8;
}
*/

void spi_set_clk_freq(void) __naked {
    __asm

    PUSH    BC
    LD      BC, #SPI_CLK_FIXED

    LD      A, C
    OUT     (SPI_CLK_DIV_LOW_PORT), A

    LD      A, B
    OUT     (SPI_CLK_DIV_HIGH_PORT), A

    POP     BC

    __endasm;
}


//-----------------------------------------------------------------------
// SPI low-level functions
//-----------------------------------------------------------------------

/*
uint8_t spi_xfer_c(uint8_t value) {
    // Write byte on MOSI
    SPI_MOSI_W = (int)value;
    SPI_LENGTH_W = (int)SPI_LENGTH;

    // Initiate SPI Xfer
    SPI_CONTROL_W = (int)SPI_START;

    // Wait for SPI Xfer to be done
    int status = (int)SPI_STATUS_R;
    while((status & SPI_DONE) != SPI_DONE) {
        status = (int)SPI_STATUS_R;
    }

    // Read MISO and return it
    int miso = (int)SPI_MISO_R;
    return miso;
}
*/

// Embedded ASM see also:
// https://gist.github.com/Konamiman/af5645b9998c802753023cf1be8a2970


uint8_t spi_xfer(uint8_t value) __naked {
    value;
    __asm

    ; Bypass the return address of the function.
    LD      IY, #2
    ADD     IY, SP

    ; get value argument in reg A and output to SPI MOSI port.
    LD      A, (IY)
    OUT     (SPI_MOSI_PORT), A

    ; Set transfer length.
    LD      A, #SPI_LENGTH
    OUT     (SPI_LENGTH_PORT), A

    ; Start transfer.
    LD      A, #SPI_START
    OUT     (SPI_CONTROL_PORT), A

    ; Wait until transfer complete.
wait$:
    IN      A, (SPI_STATUS_PORT)
    AND     A, #SPI_DONE
    JR      Z, wait$

    ; Read back MISO from SPI.
    IN      A, (SPI_MISO_PORT)

    ; Return as char value in reg L.
    LD      L, A
    RET

    __endasm;
}

