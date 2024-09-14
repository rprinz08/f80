                .module crt0
                .globl  _main

                .area   _HEADER (ABS)
                .org    0x8000
init:
                ; Set stack pointer directly above top of memory.
                LD      SP, #0xffff

                ; Initialise global variables
                ; CALL    gsinit

                CALL    _main
                JP      _exit

                ; Ordering of segments for the linker.
                ;.area   _HOME
                .area   _CODE
                ; .area   _INITIALIZER
                ; .area   _GSINIT
                ; .area   _GSFINAL

                .area   _DATA
                ; .area   _INITIALIZED
                ;.area   _BSEG
                .area   _BSS
                ;.area   _HEAP

                .area   _CODE

__clock::
                LD      A, #2
                RST     0x08
                RET

_exit::
                ; Ensure that ROM is enabled after program exists.
                LD     	A, #0
                OUT     (0x02), A
                ; Call exit handler in ROM.
                LD      A, #0
                RST     0x08
                JP      0x0000

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
