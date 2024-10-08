;
; Title:    BBC Basic for BSX
; Author:   Dean Belfield
; Created:  16/05/2020
; Last Updated: 08/10/2020
;
; Modinfo:
; 20/05/2020:   Added minimal OSCLI command (*BYE)
;       Uses RST instructions in latest ROM for I/O
; 10/06/2020:   Fixed COLOUR to use EXPRI instead of ITEMI so that calculations work without brackets, i.e. COLOUR 1+128
; 08/10/2020:   Minor mods to support UART
;

        MODULE PATCH

; CLRSCN: clears the screen.
;
@CLRSCN:    CALL    TELL
            DEFB    0x1B,0x5B,"2J",0x1B,0x5B,"1;1H",0
            RET

; PUTIME: set current time to DE:HL, in centiseconds.
;
@PUTIME:    RET

; GETIME: return current time in DE:HL, in centiseconds.
;
@GETIME:    LD      DE, 0
            LD      HL, 0
            RET

; PUTCSR: move to cursor to x=DE, y=HL
;
@PUTCSR:    RET

; GETCSR: return cursor position in x=DE, y=HL
;
@GETCSR:    LD      DE,0
            LD      HL,0
            RET

; OSRDCH: read a character in from the keyboard (non-blocking)
;
@OSRDCH:
;            RST     8

            IN A,(PORT_STM_IO)
            RET

; PROMPT: output the input prompt
;
@PROMPT:    LD      A,'>'

; OSWRCH: write a character out to the serial port
;
@OSWRCH:
;            RST     16

            OUT (PORT_STM_IO),A
            RET

;OSKEY - Read key with time-limit, test for ESCape.
;Main function is carried out in user patch.
;   Inputs: HL = time limit (centiseconds)
;  Outputs: Carry reset if time-out
;           If carry set A = character
; Destroys: A,H,L,F
;
@OSKEY:     DEC     HL
            LD      A,H
            OR      L
            RET     Z

;            RST     8

;            IN      A,(PORT_STM_IO)
;            JR      NC,OSKEY

            IN      A,(PORT_STM_IO)
            JR      Z,OSKEY

            CP      0x1B        ; ESC
            SCF
            RET     NZ
ESCSET:     PUSH    HL
            LD      HL,FLAGS
            BIT     6,(HL)      ; ESC DISABLED?
            JR      NZ,ESCDIS
            SET     7,(HL)      ; SET ESCAPE FLAG
ESCDIS:     POP     HL
            RET

ESCTEST:
;            RST     8

;            IN      A,(PORT_STM_IO)
;            RET     NC

            IN      A,(PORT_STM_IO)
            OR      A
            RET     Z

            CP      0x1B        ; ESC
            JR      Z,ESCSET
            RET

@TRAP:      CALL    ESCTEST
@LTRAP:     LD      A,(FLAGS)
            OR      A
            RET     P
            LD      HL,FLAGS
            RES     7,(HL)
            JP      ESCAPE

;OSINIT - Initialise RAM mapping etc.
;If BASIC is entered by BBCBASIC FILENAME then file
;FILENAME.BBC is automatically CHAINed.
;   Outputs: DE = initial value of HIMEM (top of RAM)
;            HL = initial value of PAGE (user program)
;            Z-flag reset indicates AUTO-RUN.
;  Destroys: A,D,E,H,L,F
;
@OSINIT:    XOR     A
            LD      (@FLAGS),A  ;Clear flags
            LD      DE,0x0000   ;DE = HIMEM
            LD      E,A         ;PAGE BOUNDARY
            LD      HL,@USER
            RET

;
;OSLINE - Read/edit a complete line, terminated by CR.
;   Inputs: HL addresses destination buffer.
;           (L=0)
;  Outputs: Buffer filled, terminated by CR.
;           A=0.
; Destroys: A,B,C,D,E,H,L,F
;

@OSLINE:
;            RST     8

            IN      A,(PORT_STM_IO)

            OR      A
            JR      Z,OSLINE

            CP      0x0D        ; CR
            JR      Z,KEYCR

            CP      0x7F        ; Backspace
            JR      Z,KEYBS

            LD      (HL),A      ; Save the character in the buffer
            INC     HL
            CALL    OSWRCH      ; Echo character back to terminal
            JR      OSLINE      ; Loop

KEYCR:      LD      (HL),A      ; Write final CR
            CALL    @CRLF       ; Print CR
            AND     A
            RET

KEYBS:      INC     L           ; Check for beginning of line
            DEC     L
            JR      Z,OSLINE

            LD      A,0x08
            CALL    OSWRCH
            LD      A,0x20
            CALL    OSWRCH
            LD      A,0x08

            CALL    OSWRCH
            DEC     L
            JR      OSLINE


;
;OSCLI - Process an "operating system" command
;
@OSCLI:     CALL    SKIPSP
            CP      CR
            RET     Z
            CP      '|'
            RET     Z
            CP      '.'
            JP      Z,STARDOT   ; *.
            EX      DE,HL
            LD      HL,COMDS
OSCLI0:     LD      A,(DE)
            CALL    UPPRC
            CP      (HL)
            JR      Z,OSCLI2
            JR      C,HUH
OSCLI1:     BIT     7,(HL)
            INC     HL
            JR      Z,OSCLI1
            INC     HL
            INC     HL
            JR      OSCLI0
;
OSCLI2:     PUSH    DE
OSCLI3:     INC     DE
            INC     HL
            LD      A,(DE)
            CALL    UPPRC
            CP      '.'     ; ABBREVIATED?
            JR      Z,OSCLI4
            XOR     (HL)
            JR      Z,OSCLI3
            CP      80H
            JR      Z,OSCLI4
            POP     DE
            JR      OSCLI1
;
OSCLI4:     POP     AF
            INC     DE
OSCLI5:     BIT     7,(HL)
            INC     HL
            JR      Z,OSCLI5
            LD      A,(HL)
            INC     HL
            LD      H,(HL)
            LD      L,A
            PUSH    HL
            EX      DE,HL
            JP      SKIPSP

HUH:        LD      A,254
            CALL    EXTERR
            DEFM    'Bad command'
            DEFB    0

SKIPSP:     LD      A,(HL)
            CP      ' '
            RET     NZ
            INC     HL
            JR      SKIPSP

UPPRC:      AND     7FH
            CP      '`'
            RET     C
            AND     5FH     ; CONVERT TO UPPER CASE
            RET
; OSCLI - *BYE
;
BYE:        JP      0

; OSCLI - *CAT / *.
;
STARDOT:
CAT:        LD      A,0x02
            OUT     (PORT_STM_FILE),A
            RET

; OSCLI - *DIR
;
DIR:        LD      A,(HL)
            CP      0x22        ; Quote
            JR      NZ,HUH
            INC     HL
            LD      A,0x01
            OUT     (PORT_STM_FILE),A
1:          LD      A,(HL)
            CP      0x22
            JR      Z,2F
            CP      CR
            JR      Z,2F
            OUT     (PORT_STM_FILE),A
            INC     HL
            JR      1B
2:          XOR     A
            OUT     (PORT_STM_FILE),A
            RET

; Each command has bit 7 of the last character set, and is followed by the
; address of the handler
;
COMDS:      DC      'BYE':  DEFW BYE    ; JP 0
            DC      'CAT':  DEFW CAT    ; Catalogue SD Card
            DC      'DIR':  DEFW DIR    ; Change directory
            DEFB    0FFH

; COLOUR: change text colour using ANSI ESC sequence.
; see https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
;
@COLOUR:    CALL    EXPRI
            CALL    TELL
            DEFB    0x1B,0x5B,0
            EXX
            LD      A,'3'
            BIT     7,L
            JR      Z,1F
            INC     A
1:          CALL    OSWRCH
            LD      A,L
            AND     7
            ADD     A,'0'
            CALL    OSWRCH
            LD      A,"m"
            CALL    OSWRCH
            JP      XEQ

; Stuff not implemented yet
;
@OSBPUT:
@OSBGET:
@OSSTAT:
@OSSHUT:
@OSOPEN:
@OSCALL:
@OSSAVE:
@OSLOAD:
@GETPTR:
@PUTPTR:
@GETEXT:
@RESET:
            RET

        ENDMODULE

