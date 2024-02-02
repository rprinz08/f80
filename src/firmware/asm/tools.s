                .module monitor
                .globl  Print_String, Print_Hex8, Print_CR
                .area   _CODE (REL,CON)

DISP7_PORT              .gblequ 0xF0
BUTTONS_PORT            .gblequ 0xF0
SWITCHES_PORT           .gblequ 0xF1
LEDS_PORT               .gblequ 0xF1
TICKS_MS_PORT_RD_RST    .gblequ 0xFD
TICKS_MS_PORT           .gblequ 0xFE

delay::
                ; reset ticker
                IN      A,(TICKS_MS_PORT_RD_RST)
                LD      D,#0
                LD      C,#TICKS_MS_PORT_RD_RST
wait$:
                IN      E,(C)
                SBC     HL,DE
                JR      Z, done$
                JR      NC, wait$
done$:
                RET


; delay::
;                 ; (HL) wait_ms = input arg
;                 ; D=0, E=diff_ms
;                 ; B=last_ms, C=ms

;                 ; last_ms = TICKS_MS;
;                 IN      A,(TICKS_MS_PORT)
;                 LD      B,A

;                 LD      D,#0
; wait$:
;                 ; while(wait_ms > 0)
;                 LD      A,L
;                 OR      A
;                 JR      NZ,wait_2$
;                 LD      A,H
;                 OR      A
;                 JR      Z,done$
; wait_2$:
;                 ; ms = TICKS_MS;
;                 IN      A,(TICKS_MS_PORT)
;                 LD      C,A

;                 ; if(ms < last_ms)
;                 ;LD      A,C
;                 CP      B
;                 JR      NC,wait_3$

;                 ; diff_ms = (0xff - last_ms) + ms;
;                 LD      A,#0xff
;                 SUB     A,B
;                 ADD     A,C
;                 ;LD      E,A
;                 JR      wait_4$
; wait_3$:
;                 ; else
;                 ; diff_ms = ms - last_ms;
;                 ;LD      A,C
;                 SUB     A,B
;                 ;LD      E,A
; wait_4$:
;                 LD      E,A

;                 ; last_ms = ms;
;                 LD      B,C

;                 ; wait_ms -= diff_ms;
;                 OR      A ; reset carry flag
;                 SBC     HL,DE
;                 JR      NC, wait$
; done$:
;                 RET