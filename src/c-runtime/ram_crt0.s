	.module crt0
	.globl	_main

	.area	_HEADER (ABS)

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
	ld		a,#0
	rst		0x08
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
