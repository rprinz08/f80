;
; Title:    BBC Basic for BSX - Main build file
; Author:   Dean Belfield
; Created:  16/05/2020
; Last Updated: 08/10/2020
;
; Modinfo:
;
; 08/10/2020:   Minor mods to support UART

        OUTPUT  build.bin

ROM_START   EQU     0x0000
RAM_START   EQU     0x8000

PORT_STM_IO     EQU     0x00
PORT_STM_IO_CTL EQU     0x01
PORT_STM_FILE   EQU     0x42        ; The IO port for the SD card filing system

        MACRO sorry
            XOR     A
            CALL    EXTERR
            DEFM    'Sorry'
            DEFB    0
        ENDM

BUILD_ROM   EQU     0           ; Set to 1 to build for ROM, or 0 to build for RAM

        MODULE BUILD

        IF BUILD_ROM == 0
            ORG     RAM_START
        ELSE
            ORG     ROM_START+0x4000
        ENDIF

            CALL    TELL
            DEFM    "BSX Breadboard Computer 0.1\n\r"
            DEFM    "\n\r"
            DEFB    0

            include "main.s"
            include "exec.s"
            include "eval.s"
            include "fpp.s"
            include "sorry.s"
            include "patch.s"
            include "ram.s"

@USER:  ENDMODULE
