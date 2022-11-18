	.module crt0
	.globl	_main

	.area	_HEADER (ABS)
	;; Reset vector
	;.org	0
	;jp		init

	;.org	0x08
	;reti
	;.org	0x10
	;reti
	;.org	0x18
	;reti
	;.org	0x20
	;reti
	;.org	0x28
	;reti
	;.org	0x30
	;reti
	;.org	0x38
	;reti

	.org	0x8000
init:
	;; Set stack pointer directly above top of memory.
	ld		sp, #0xffff

	;; Initialise global variables
	call	gsinit
	call	_main
	jp		_exit

	;; Ordering of segments for the linker.
	;.area	_HOME
	.area	_CODE
	;.area	_INITIALIZER
	.area   _GSINIT
	.area   _GSFINAL

	.area	_DATA
	;.area	_INITIALIZED
	;.area	_BSEG
	.area   _BSS
	;.area   _HEAP

	.area   _CODE

__clock::
	ld		a,#2
	rst		0x08
	ret

_exit::
	; Exit - special code to the emulator
	ld		a,#0
	rst		0x08
1$:
	;halt
	;jr		1$
	; Instead of halting, jump back to monitor ROM
	jp		0x0000

	.area   _GSINIT
gsinit::
	;ld		bc, #l__INITIALIZER
	;ld		a, b
	;or		a, c
	;jr		Z, gsinit_next
	;ld		de, #s__INITIALIZED
	;ld		hl, #s__INITIALIZER
	;ldir
gsinit_next:

	.area   _GSFINAL
	ret
