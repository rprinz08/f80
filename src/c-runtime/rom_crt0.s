                .module crt0
                .globl  _main
                ; .globl	l__INITIALIZER
                ; .globl	s__INITIALIZED
                ; .globl	s__INITIALIZER
                .area   _HEADER (ABS)
                .org    0x0000

; RST 00
                DI
                JP      init
                .ds     4

; RST 08
                .org    0x0008
                JP      RST8

; RST 10
                ;.org   0x10
                ;reti
                .ds     8

; RST 18
                ;.org   0x18
                ;reti
                .ds     8

; RST 20
                ;.org   0x20
                ;reti
                .ds     8

; RST 28
                ;.org   0x28
                ;reti
                .ds     8

; RST 30
                ;.org   0x30
                ;reti
                .ds     8

; RST 38 - NMI
                ;.org   0x38
                ;reti

                EI
                RET

ROM_START       .equ    0x0000
ROM_END         .equ    0x7FFF
RAM_START       .equ    0x8000
RAM_END         .equ    0xFFFF

; RST 8 commands.
RST8_EXIT       .equ    0x00
RST8_PUTCHAR    .equ    0x01
RST8_GETCHAR    .equ    0x02
RST8_IOSTATUS   .equ    0x03
RST8_MEMTEST    .equ    0xaa

; The IO port for serial terminal IO
PORT_STM_IO     .equ    0x00
PORT_STM_IO_CTL .equ    0x01
DISP7_PORT      .equ    0xf0

MSG_MAIN_RET:   .asciz "Main returns HL="
MSG_RST8:       .asciz "RST8 A="
MSG_BADRAM:     .asciz "\r\nMem Fault @ "

RST8:
                CP      #RST8_EXIT
                JR      NZ, 1$

                ; --------------------------------------------------------------
                ; 0x00 main function return.
0$:
                PUSH    AF
                PUSH    HL
                LD      HL, #MSG_MAIN_RET
                CALL    Print_String
                POP     HL
                POP     AF
                CALL    Print_Hex16
                CALL    Print_CR

                JP      RST8_Ex

                ; --------------------------------------------------------------
                ; 0x01 put character.
1$:
                CP      #RST8_PUTCHAR
                JR      NZ, 2$

                LD      A, L
                CALL    Print_Char

                JP      RST8_Ex

                ; --------------------------------------------------------------
                ; 0x02 get character.
2$:
                CP      #RST8_GETCHAR
                JR      NZ, 3$
21$:
                ; Check if a byte could be read.
                IN      A, (PORT_STM_IO_CTL)
                AND     #0x01
                JR      Z, 21$

                ; Read a key from the keyboard.
                IN      A, (PORT_STM_IO)

                JP      RST8_Ex

                ; --------------------------------------------------------------
                ; 0x03 return UART status.
3$:
                CP      #RST8_IOSTATUS
                JR      NZ, aa$

                IN      A, (PORT_STM_IO_CTL)

                JP      RST8_Ex

                ; --------------------------------------------------------------
                ; 0xaa perform RAM memory test.
aa$:
                CP      #RST8_MEMTEST
                JR      NZ, RST8_UnS

                CALL    Memtest
                EI
                JP      0x0000

                ; --------------------------------------------------------------
                ; Unsuported RST8 function.
RST8_UnS:
                PUSH    AF
                LD HL,  #MSG_RST8
                CALL    Print_String
                POP     AF
                CALL    Print_Hex8
                CALL    Print_CR
RST8_Ex:
                EI
                RET

; Print a zero terminated string to the terminal port
; HL: Address of the string
Print_String::
                LD      A,(HL)
                OR      A
                RET     Z
                CALL    Print_Char
                INC     HL
                JP      Print_String

; Print a 16-bit HEX number
; HL: Number to print
Print_Hex16:
                LD      A, H
                CALL    Print_Hex8
                LD      A, L

; Print an 8-bit HEX number
; A: Number to print
Print_Hex8::
                LD      C, A
                RRA
                RRA
                RRA
                RRA
                CALL    1$
                LD      A, C
1$:
                AND     #0x0F
                ADD     A, #0x90
                DAA
                ADC     A, #0x40
                DAA
                JR      Print_Char

; Print CR/LF
Print_CR::
                LD      A, #0x0D
                CALL    Print_Char
                LD      A, #0x0A
                JR      Print_Char

; Print a single character
; A: ASCII character
Print_Char:
                OUT     (PORT_STM_IO), A
                RET

; Performs a RAM memory test, possibly corrupting C runtime. At the end of the
; test a result message is shown an a jump to address 0x0000 done.
Memtest:
                LD      HL, #RAM_START
                LD      C, #0b10101010
1$:
                LD      (HL), C
                LD      A, (HL)
                CP      C
                JR      NZ, Memtest_ERR
                INC     HL
                LD      A, L
                OR      A
                JR      NZ, 2$
                LD      A, #"."
                OUT     (PORT_STM_IO), A
2$:
                LD      A, H
                OR      A
                JR      NZ, 1$
Memtest_ERR:
                JR      Z, Memtest_OK
                EX      DE, HL

                LD      HL, #MSG_BADRAM
                CALL    Print_String
                EX      DE, HL
                CALL    Print_Hex16
                CALL    Print_CR

                JR      Memtest_DONE
Memtest_OK:
Memtest_DONE:
                RET

init:
                ; Set stack pointer directly above top of memory.
                LD      SP, #0xffff

                ; Initialise global variables
                ; CALL    gsinit

                CALL    _main
                JP      _exit

                ; Ordering of segments for the linker.
                .area   _HOME
                .area   _CODE
                ; .area   _INITIALIZER
                ; .area   _GSINIT
                ; .area   _GSFINAL

                .area   _DATA
                ; .area   _INITIALIZED
                .area   _BSEG
                .area   _BSS
                .area   _HEAP

                .area   _CODE
__clock::
                LD      A, #2
                RST     0x08
                RET

_exit::
                ; Exit - special code to the emulator
                LD      A, #0
                RST     0x08
1$:
                ; Halt
                ;JR     1$
                ; Instead of halting, jump back to monitor ROM
                JP      0x0000

; Note: Global initialization of C variables not working at the moment.
;                .area   _GSINIT
; gsinit::
;                 ld     bc, #l__INITIALIZER
;                 ld     a, b
;                 or     a, c
;                 jr     Z, gsinit_next
;                 ld     de, #s__INITIALIZED
;                 ld     hl, #s__INITIALIZER
;                 ldir
; gsinit_next:
;                 .area   _GSFINAL
;                 RET
