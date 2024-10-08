;RAM MODULE FOR BBC BASIC INTERPRETER
;FOR USE WITH VERSION 2.0 OF BBC BASIC
;*STANDARD CP/M DISTRIBUTION VERSION*
;(C) COPYRIGHT R.T.RUSSELL 31-12-1983
;

            MODULE RAM

            IF BUILD_ROM = 0
            ALIGN 256
            ELSE
            DISP RAM_START
            ENDIF
;
;n.b. ACCS, BUFFER & STAVAR must be on page boundaries.
;
@ACCS:      DEFS    256             ;STRING ACCUMULATOR
@BUFFER:    DEFS    256             ;STRING INPUT BUFFER
@STAVAR:    DEFS    27*4            ;STATIC VARIABLES
@OC:        EQU     STAVAR+15*4     ;CODE ORIGIN (O%)
@PC:        EQU     STAVAR+16*4     ;PROGRAM COUNTER (P%)
@DYNVAR:    DEFS    54*2            ;DYN. VARIABLE POINTERS
@FNPTR:     DEFS    2               ;DYN. FUNCTION POINTER
@PROPTR:    DEFS    2               ;DYN. PROCEDURE POINTER
;
@PAGE:      DEFS    2               ;START OF USER PROGRAM
@TOP:       DEFS    2               ;FIRST LOCN AFTER PROG.
@LOMEM:     DEFS    2               ;START OF DYN. STORAGE
@FREE:      DEFS    2               ;FIRST FREE-SPACE BYTE
@HIMEM:     DEFS    2               ;FIRST PROTECTED BYTE
;
@LINENO:    DEFS    2               ;LINE NUMBER
@TRACEN:    DEFS    2               ;TRACE FLAG
@AUTONO:    DEFS    2               ;AUTO FLAG
@ERRTRP:    DEFS    2               ;ERROR TRAP
@ERRTXT:    DEFS    2               ;ERROR MESSAGE POINTER
@DATPTR:    DEFS    2               ;DATA POINTER
@ERL:       DEFS    2               ;ERROR LINE
@ERRLIN:    DEFS    2               ;"ON ERROR" LINE
@RANDOM:    DEFS    5               ;RANDOM NUMBER
@COUNT:     DEFS    1               ;PRINT POSITION
@WIDTH:     DEFS    1               ;PRINT WIDTH
@ERR:       DEFS    1               ;ERROR NUMBER
@LISTON:    DEFS    1               ;LISTO & OPT FLAG
@INCREM:    DEFS    1               ;AUTO INCREMENT
;
; Added by me
;
@FLAGS:     DEFS    1       ; Flags: B7=ESC PRESSED, B6=ESC DISABLED

            ENDMODULE
