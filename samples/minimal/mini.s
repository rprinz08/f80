                .module mini
                .area	_MAIN (ABS)
                .org    0x8000

; A simple hello-world example in pure assembler. Uses direct console I/O
; function so does not rely on ROM bios functions. On exit ensures that ROM
; is enabled and calls ROM monitor.

; The IO port for serial terminal IO
PORT_STM_IO     .equ    0x00
PORT_STM_IO_CTL .equ    0x01
PORT_MEM_CFG    .equ    0x02

main:
                ; Set stack pointer directly above top of memory.
                LD      SP, #0xffff

                LD      HL, #MSG_HELLO
                CALL    Print_String

exit:
                ; Ensure that ROM is enabled after program exists.
                LD      A, #0
                OUT     (PORT_MEM_CFG), A

                ; Call exit handler in ROM, return code value in HL.
                LD      HL, #0x1234
                LD      A, #0
                RST     0x08
                JP      0x0000

Print_String:
                LD      A, (HL)
                OR      A
                RET     Z
                CALL    Print_Char
                INC     HL
                JP      Print_String

Print_Char:
                PUSH    BC
                LD      B, A
1$:
                ; Check if a byte could be written
                IN      A, (PORT_STM_IO_CTL)
                LD      C, #0x10
                AND     C
                JR      Z, 1$

                LD      A, B
                POP     BC

                OUT     (PORT_STM_IO), A
                RET

MSG_HELLO:      .asciz  "\n\rHello World from f80\n\r"
