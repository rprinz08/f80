#ifndef _SPI_H_
#define _SPI_H_

#include <stdint.h>


//-----------------------------------------------------------------------
// Hardware I/O registers.
//-----------------------------------------------------------------------

#define SPI_STATUS_PORT             0xF2
#define SPI_CONTROL_PORT            0xF2
#define SPI_MISO_PORT               0xF3
#define SPI_MOSI_PORT               0xF3
#define SPI_CS_PORT                 0xF4
#define SPI_CLK_DIV_LOW_PORT        0xF5
#define SPI_CLK_DIV_HIGH_PORT       0xF6
#define SPI_LENGTH_PORT             0xF7

__sfr __at SPI_STATUS_PORT SPI_STATUS_R;
__sfr __at SPI_CONTROL_PORT SPI_CONTROL_W;
__sfr __at SPI_MISO_PORT SPI_MISO_R;
__sfr __at SPI_MOSI_PORT SPI_MOSI_W;
__sfr __at SPI_CS_PORT SPI_CS_W;
__sfr __at SPI_CLK_DIV_LOW_PORT SPI_CLK_DIV_LOW_W;
__sfr __at SPI_CLK_DIV_HIGH_PORT SPI_CLK_DIV_HIGH_W;
__sfr __at SPI_LENGTH_PORT SPI_LENGTH_W;

// SPI @ 400 kHz at a system clock of 100MHz
// ((100000000/400000)+1)
// If not defined allows dynamic SPI clock selection during runtime.
#define SPI_CLK_FIXED               251


//-----------------------------------------------------------------------
// SPI Flags
//-----------------------------------------------------------------------

#define SPI_CS_HIGH     (0)
#define SPI_CS_LOW      (1)
#define SPI_START       (1)
#define SPI_DONE        (1)
#define SPI_LENGTH      (8)


//-----------------------------------------------------------------------
// Function prototypes
//-----------------------------------------------------------------------

#ifdef SPI_CLK_FIXED
extern void spi_set_clk_freq(void);
#else
extern void spi_set_clk_freq(uint32_t clk_freq);
#endif
extern uint8_t spi_xfer(uint8_t byte);

#endif
