#ifndef _SDCARD_H_
#define _SDCARD_H_

#include <stdint.h>

#ifndef SPISDCARD_CLK_FREQ_INIT
#define SPISDCARD_CLK_FREQ_INIT     400000
#endif
#ifndef SPISDCARD_CLK_FREQ
#define SPISDCARD_CLK_FREQ          20000000
#endif


//-----------------------------------------------------------------------
// SPI SDCard Commands
//-----------------------------------------------------------------------

#define CMD0            ((uint8_t)(0))            // GO_IDLE_STATE
#define CMD1            ((uint8_t)(1))            // SEND_OP_COND
#define ACMD41          ((uint8_t)(0x80 + 41))    // SEND_OP_COND (SDC)
#define CMD8            ((uint8_t)(8))            // SEND_IF_COND
#define CMD9            ((uint8_t)(9))            // SEND_CSD
#define CMD10           ((uint8_t)(10))           // SEND_CID
#define CMD12           ((uint8_t)(12))           // STOP_TRANSMISSION
#define CMD13           ((uint8_t)(13))           // SEND_STATUS
#define ACMD13          ((uint8_t)(0x80 + 13))    // SD_STATUS (SDC)
#define CMD16           ((uint8_t)(16))           // SET_BLOCKLEN
#define CMD17           ((uint8_t)(17))           // READ_SINGLE_BLOCK
#define CMD18           ((uint8_t)(18))           // READ_MULTIPLE_BLOCK
#define CMD23           ((uint8_t)(23))           // SET_BLOCK_COUNT
#define ACMD23          ((uint8_t)(0x80 + 23))    // SET_WR_BLK_ERASE_COUNT (SDC)
#define CMD24           ((uint8_t)(24))           // WRITE_BLOCK
#define CMD25           ((uint8_t)(25))           // WRITE_MULTIPLE_BLOCK
#define CMD32           ((uint8_t)(32))           // ERASE_ER_BLK_START
#define CMD33           ((uint8_t)(33))           // ERASE_ER_BLK_END
#define CMD38           ((uint8_t)(38))           // ERASE
#define CMD55           ((uint8_t)(55))           // APP_CMD
#define CMD58           ((uint8_t)(58))           // READ_OCR


//-----------------------------------------------------------------------
// Function prototypes
//-----------------------------------------------------------------------

extern void spisdcard_deselect(void);
extern uint8_t spisdcard_select(void);
extern void spisdcardwrite_bytes(uint8_t* buf, uint16_t n);
extern void spisdcardread_bytes(uint8_t* buf, uint16_t n);
extern uint8_t spisdcardreceive_block(uint8_t *buf);
extern uint8_t spisdcardsend_cmd(uint8_t cmd, uint32_t arg);
extern uint8_t spisdcard_init(void);
extern uint8_t spisdcard_read(uint8_t *buf, uint32_t block, unsigned int count);
extern uint8_t spisdcard_write(uint8_t *buf, uint32_t block, unsigned int count);

#endif
