; Defines

                OUTPUT monitor.bin

ROM_START       EQU     0x0000
ROM_END         EQU     0x7FFF
RAM_START       EQU     0x8000
RAM_END         EQU     0xFFFF

; System variable block
SYS_VARS        EQU     RAM_START + 0x7000
SYS_VARS_RAMTOP EQU     SYS_VARS + 0x00
SYS_VARS_INPUT  EQU     SYS_VARS + 0x02

; The IO port for serial terminal IO
PORT_STM_IO     EQU     0x00
PORT_STM_IO_CTL EQU     0x01
; Diagnostics port - not used yet
PORT_STM_DIAG   EQU     0x07

; Set to 1 to build for ROM, or 0 to build for RAM
BUILD_ROM       EQU     1
; Set to 1 to skip the memtest on boot - leave this until proper clock fitted
SKIP_MEMTEST    EQU     1

            IF BUILD_ROM = 0
                ORG 0x8200
            ELSE
                ORG ROM_START
; RST 00
                DI
                JP Start
                DS 4

; RST 08
                ORG    0x08
                JP RST8_Handler

; RST 10
                DS 8

; RST 18
                DS 8

; RST 20
                DS 8

; RST 28
                DS 8

; RST 30
                DS 8

; RST 38 - NMI
                EI
                RET
            ENDIF

; Start

RST8_Handler:
                ; 0x00 main function return
                CP 0x00
                JR NZ,1F

                PUSH AF
                PUSH HL
                LD HL,MSG_MAIN_RET
                CALL Print_String
                POP HL
                POP AF
                CALL Print_Hex16
                CALL Print_CR

                JP RST8_Handler_Exit

1:
                ; 0x01 put character
                CP 0x01
                JR NZ,RST8_Handler_NotSup

                LD A,L
                OUT (PORT_STM_IO),A
                JP RST8_Handler_Exit

RST8_Handler_NotSup:
                ; Unsupported function.
                PUSH AF
                LD HL,MSG_RST8
                CALL Print_String
                POP AF
                CALL Print_Hex8
                CALL Print_CR

RST8_Handler_Exit:
                EI
                RET

Start:
            IF SKIP_MEMTEST = 1
                ;LD HL,RAM_END
                LD HL,0x0000
                XOR A
                JR 3F
            ENDIF
FN_Memtest:
                LD HL,RAM_START
                LD C,0b10101010
1:
                LD (HL),C
                LD A,(HL)
                CP C
                JR NZ,3F
                INC HL
                LD A,L
                OR A
                JR NZ,2F
                LD A,"."
                OUT (PORT_STM_IO),A
2:
                LD A,H
                OR A
                JR NZ,1B
3:
                ; Store last byte of physical RAM in the system variables
                LD (SYS_VARS_RAMTOP),HL
                ; Set the stack pointer
                LD SP,HL
                JR Z,Memtest_OK
                LD HL,MSG_BADRAM
                JR Ready
Memtest_OK:
                LD HL,MSG_READY

Ready:
                PUSH HL
                LD HL,MSG_STARTUP
                CALL Print_String
                CALL FN_Help
                POP HL
                CALL Print_String

Input:
                ; Input buffer
                LD HL,SYS_VARS_INPUT
                ; Cursor position
                LD B,0
Input_Loop:
                ; Check if a byte could be read
                IN A,(PORT_STM_IO_CTL)
                LD D,1
                AND D
                JR Z,Input_Loop

                ; Read a key from the keyboard
                IN A,(PORT_STM_IO)
                ; Check for zero
                OR A
                ; Loop - no key input yet
                JR Z,Input_Loop

                ; Output the character
                CALL Print_Char

                ; Handle backspace
                CP 0x7F: JR Z,Input_Backspace

                ; Store the character in the buffer
                LD (HL),A
                ; Increment to next character in buffer
                INC HL
                ; Increment the cursor position
                INC B
                ; Check for newline
                CP 0x0D
                ; If not pressed, then loop
                JR NZ,Input_Loop

                ; Output a carriage return
                CALL Print_CR

                ; Check the first character of input
                LD A,(SYS_VARS_INPUT)
                ; Push the return address on the stack
                LD HL,Input_Ret
                PUSH HL
                CP 'H': JP Z,FN_Help
                CP 'D': JP Z,FN_Memory_Dump
                CP 'L': JP Z,FN_Memory_Load
                CP 'J': JP Z,FN_Jump
                CP 'T': JP Z,FN_Memtest
                CP 'V': JP Z,FN_Show_ID
                ; Not jumped to anything, so pop the return address off the stack
                POP HL

Input_Ret:
                ; On return from the function, print a carriage return
                CALL Print_CR
                ; And the ready message
                LD HL,MSG_READY
                CALL Print_String
                ; Loop around for next input line
                JR Input

Input_Backspace:
                ; Are we on the first character?
                LD A,B
                OR A
                JR Z,Input_Loop
                ; Skip back in the buffer
                DEC HL
                DEC B
                LD (HL),0
                JR Input_Loop

FN_Jump:
                LD HL,SYS_VARS_INPUT+1
                CALL Parse_Hex16
                EX DE,HL
                JP (HL)

FN_Memory_Load:
                LD HL,SYS_VARS_INPUT+1
                CALL Parse_Hex16
                LD A,(HL)
                CP ','
                JR NZ,2F
                INC HL
                PUSH DE
                CALL Parse_Hex16
                LD BC,DE
                POP DE
                LD HL,DE
1:
                ; Check if a byte could be read
                IN A,(PORT_STM_IO_CTL)
                LD D,1
                AND D
                JR Z,1B

                ; Read byte
                IN A,(PORT_STM_IO)
                LD (HL),A

                ; Increment pointer and decrement remaining length
                INC HL
                DEC BC

                ; If remaining length is zero = done
                LD A,B
                OR C
                JR NZ,1B
                RET

2:              LD HL,MSG_ERROR
                JP Print_String

FN_Memory_Dump:
                LD HL,SYS_VARS_INPUT+1
                CALL Parse_Hex16
                LD A,(HL)
                CP ','
                JR NZ,2F
                INC HL
                PUSH DE
                CALL Parse_Hex16
                POP HL
                LD A,D
                OR E
                JP NZ,Memory_Dump
2:              LD HL,MSG_ERROR
                JP Print_String

FN_Help:
                LD HL,MSG_HELP1
                CALL Print_String
                LD HL,MSG_HELP2
                CALL Print_String
                LD HL,MSG_HELP3
                CALL Print_String
                LD HL,MSG_HELP4
                CALL Print_String
                LD HL,MSG_HELP5
                CALL Print_String
                LD HL,MSG_HELPx
                JP Print_String

FN_Show_ID:
                LD HL,MSG_ID
                JP Print_String

; Print a zero terminated string to the terminal port
; HL: Address of the string

Print_String:
                LD A,(HL)
                OR A
                RET Z
                CALL Print_Char
                INC HL
                JP Print_String

; Dump some memory out
; HL: Start of memory to dump
; DE: Number of bytes to dump out

Memory_Dump:
                CALL Print_Hex16
                LD A,':'
                CALL Print_Char
                LD A,' '
                CALL Print_Char
                LD B,16
1:              LD A,(HL)
                CALL Print_Hex8
                INC HL
                DEC DE
                LD A,D
                OR E
                RET Z
                IN A,(PORT_STM_IO)
                CP 0x1B
                RET Z
                DJNZ 1B
                CALL Print_CR
                JR Memory_Dump

; Parse a hex string (up to 4 nibbles) to a binary
; HL: Address of hex (ASCII)
; DE: Output

Parse_Hex16:
                LD DE,0     ; Clear the output
1:              LD A,(HL)   ; Get the nibble
                SUB '0'     ; Normalise to 0
                RET C       ; Return if < ASCII '0'
                CP 10       ; Check if >= 10
                JR C,2F
                SUB 7       ; Adjust ASCII A-F to nibble
                CP 16       ; Check for > F
                RET NC      ; Return
2:              SLA DE      ; Shfit DE left 4 times
                SLA DE
                SLA DE
                SLA DE
                OR E        ; OR the nibble into E
                LD E,A
                INC HL      ; Increase pointer to next byte of input
                JR 1B       ; Loop around

; Print a 16-bit HEX number
; HL: Number to print

Print_Hex16:
                LD A,H
                CALL Print_Hex8
                LD A,L

; Print an 8-bit HEX number
; A: Number to print

Print_Hex8:
                LD C,A
                RRA
                RRA
                RRA
                RRA
                CALL 1F
                LD A,C
1:
                AND 0x0F
                ADD A,0x90
                DAA
                ADC A,0x40
                DAA
                JR Print_Char

; Print CR/LF

Print_CR:
                LD A,0x0D
                CALL Print_Char
                LD A,0x0A
                JR Print_Char

; Print a single character
; A: ASCII character

Print_Char:
                PUSH BC
                LD B,A
1:
                ; Check if a byte could be written
                IN A,(PORT_STM_IO_CTL)
                LD C,0x10
                AND C
                JR Z,1B

                LD A,B
                POP BC

                OUT (PORT_STM_IO),A
                RET

; Messages

MSG_STARTUP:    DZ "\n\rBSX Version 0.2\n\r"

MSG_HELP0:      DZ "H                 This help screen\n\r"
MSG_HELP1:      DZ "D<addr>,<length>  Dump <length> memory bytes starting at <addr>\n\r"
MSG_HELP2:      DZ "L<addr>,<length>  Load <length> memory bytes starting at <addr>\n\r"
MSG_HELP3:      DZ "J<addr>           Start execution jumping to memory address <addr>\n\r"
MSG_HELP4:      DZ "T                 Memory test RAM\n\r"
MSG_HELP5:      DZ "V                 Show version and board ID\n\r\n\r"
MSG_HELPx:      DZ "All <arguments> in uppercase hex (e.g. D8000,0100)\n\r"

MSG_READY:      DZ "OK\n\r"
MSG_ERROR:      DZ "Error\n\r"

MSG_BADRAM:     DZ "Mem Fault\n\r"
MSG_RST8:       DZ "RST8 A="
MSG_MAIN_RET:   DZ "Main returns HL="

MSG_ID:         DZ "Arty-Z80, BSX V:0.2.0\n\r"
