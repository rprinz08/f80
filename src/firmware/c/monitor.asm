;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 4.0.0 #11528 (Linux)
;--------------------------------------------------------
	.module monitor
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _sd_boot
	.globl _sd_write_block
	.globl _sd_load_block
	.globl _sd_init
	.globl _sd_status_info
	.globl _fn_memtest
	.globl _fn_jump
	.globl __jump_helper
	.globl _fn_load
	.globl _fn_io_in
	.globl __in_helper
	.globl _fn_io_out
	.globl __out_helper
	.globl _fn_memory_dump
	.globl _show_id
	.globl _show_menu
	.globl _parse_hex_str
	.globl _dump_hex
	.globl _gets2
	.globl _getchar
	.globl _spisdcard_write
	.globl _spisdcard_read
	.globl _spisdcard_init
	.globl _puts
	.globl _printf
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
_SPI_STATUS_R	=	0x00f2
_SPI_CONTROL_W	=	0x00f2
_SPI_MISO_R	=	0x00f3
_SPI_MOSI_W	=	0x00f3
_SPI_CS_W	=	0x00f4
_SPI_CLK_DIV_LOW_W	=	0x00f5
_SPI_CLK_DIV_HIGH_W	=	0x00f6
_SPI_LENGTH_W	=	0x00f7
_UART_RX_TX	=	0x0000
_UART_STATUS	=	0x0001
_Disp7	=	0x00f0
_TICKS_MS_RD_RST	=	0x00fd
_TICKS_MS	=	0x00fe
_BUTTONS	=	0x00f0
_SWITCHES	=	0x00f1
_LEDS	=	0x00f1
_RGB1_R	=	0x00a0
_RGB1_G	=	0x00a1
_RGB1_B	=	0x00a2
_RGB2_R	=	0x00a3
_RGB2_G	=	0x00a4
_RGB2_B	=	0x00a5
_RGB3_R	=	0x00a6
_RGB3_G	=	0x00a7
_RGB3_B	=	0x00a8
_RGB4_R	=	0x00a9
_RGB4_G	=	0x00aa
_RGB4_B	=	0x00ab
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area _DABS (ABS)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;monitor.c:19: void show_menu(void) {
;	---------------------------------
; Function show_menu
; ---------------------------------
_show_menu::
;monitor.c:38: printf("All <arguments> in hex (e.g. D8000,0100)" CRLF);
	ld	hl, #___str_55
	push	hl
	call	_puts
	pop	af
;monitor.c:39: }
	ret
___str_55:
	.db 0x0d
	.db 0x0a
	.ascii "Z80 C-Monitor"
	.db 0x0d
	.db 0x0a
	.ascii "--- Memory ---"
	.db 0x0d
	.db 0x0a
	.ascii "D<addr>,<length>  Dump <length> RAM bytes starting at <addr>"
	.db 0x0d
	.db 0x0a
	.ascii "L<addr>,<length>  Load <length> RAM bytes starting at <addr>"
	.ascii " via serial"
	.db 0x0d
	.db 0x0a
	.ascii "J<addr>           Start execution jumping to memory <addr>"
	.db 0x0d
	.db 0x0a
	.ascii "--- I/O ---"
	.db 0x0d
	.db 0x0a
	.ascii "O<port>,<value>   Write 8bit <value> to 8bit <port>"
	.db 0x0d
	.db 0x0a
	.ascii "I<port>           Raed 8bit value from 8bit <port>"
	.db 0x0d
	.db 0x0a
	.ascii "--- SD-Card ---"
	.db 0x0d
	.db 0x0a
	.ascii "i                 (Re)initialized SD-Card"
	.db 0x0d
	.db 0x0a
	.ascii "r<block>,<addr>   Load <block> from SD-Card into RAM @ <addr"
	.ascii ">"
	.db 0x0d
	.db 0x0a
	.ascii "w<addr>,<block>   Write 512 byte from RAM @ <addr> to SD-Car"
	.ascii "d <block>"
	.db 0x0d
	.db 0x0a
	.ascii "B                 Boot. Read block 0 from SD-Card to RAM @ 0"
	.ascii "x8000,"
	.db 0x0d
	.db 0x0a
	.ascii "                  switch to all RAM memory config and jump t"
	.ascii "o RAM @ 0x8000"
	.db 0x0d
	.db 0x0a
	.ascii "--- Misc ---"
	.db 0x0d
	.db 0x0a
	.ascii "T                 Memory test RAM"
	.db 0x0d
	.db 0x0a
	.ascii "H                 This help screen"
	.db 0x0d
	.db 0x0a
	.ascii "V                 Show version and board ID"
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.ascii "All <arguments> in hex (e.g. D8000,0100)"
	.db 0x0d
	.db 0x00
;monitor.c:41: void show_id(void) {
;	---------------------------------
; Function show_id
; ---------------------------------
_show_id::
;monitor.c:42: printf("Arty-Z80, C-Monitor V:0.1.0 sdcc" CRLF);
	ld	hl, #___str_57
	push	hl
	call	_puts
	pop	af
;monitor.c:43: }
	ret
___str_57:
	.ascii "Arty-Z80, C-Monitor V:0.1.0 sdcc"
	.db 0x0d
	.db 0x00
;monitor.c:45: void fn_memory_dump(uint8_t* buffer) {
;	---------------------------------
; Function fn_memory_dump
; ---------------------------------
_fn_memory_dump::
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-8
	add	hl, sp
	ld	sp, hl
;monitor.c:47: uint16_t addr = parse_hex_str(buffer, &ptr);
	ld	hl, #0
	add	hl, sp
	ld	-6 (ix), l
	ld	-5 (ix), h
	pop	de
	pop	bc
	push	bc
	push	de
	push	bc
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
	ld	-4 (ix), l
	ld	-3 (ix), h
;monitor.c:50: if(*ptr == ',') {
	ld	a, -8 (ix)
	ld	-2 (ix), a
	ld	a, -7 (ix)
	ld	-1 (ix), a
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	a, (hl)
	sub	a, #0x2c
	jr	NZ,00102$
;monitor.c:51: length = parse_hex_str(++ptr, &ptr);
	pop	de
	pop	bc
	push	bc
	push	de
	ld	a, -2 (ix)
	add	a, #0x01
	ld	-8 (ix), a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	-7 (ix), a
	push	bc
	pop	bc
	pop	hl
	push	hl
	push	bc
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
	ld	c, l
	ld	b, h
;monitor.c:52: ptr = (uint8_t*)addr;
	ld	a, -4 (ix)
	ld	-8 (ix), a
	ld	a, -3 (ix)
	ld	-7 (ix), a
;monitor.c:53: dump_hex(ptr, length, true, addr);
	ld	e, -4 (ix)
	ld	d, -3 (ix)
	ld	hl, #0x0000
	ld	-4 (ix), c
	ld	-3 (ix), b
	xor	a, a
	ld	-2 (ix), a
	ld	-1 (ix), a
	pop	bc
	push	bc
	push	hl
	push	de
	ld	a, #0x01
	push	af
	inc	sp
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	push	hl
	ld	l, -4 (ix)
	ld	h, -3 (ix)
	push	hl
	push	bc
	call	_dump_hex
	ld	hl, #11
	add	hl, sp
	ld	sp, hl
	jr	00104$
00102$:
;monitor.c:56: printf(MSG_ERR);
	ld	hl, #___str_59
	push	hl
	call	_puts
	pop	af
00104$:
;monitor.c:57: }
	ld	sp, ix
	pop	ix
	ret
___str_59:
	.ascii "ERR"
	.db 0x0d
	.db 0x00
;monitor.c:59: void _out_helper(uint8_t port, uint8_t value) __naked {
;	---------------------------------
; Function _out_helper
; ---------------------------------
__out_helper::
;monitor.c:72: __endasm;
;	Bypass the return address of the function.
	LD	IY, #2
	ADD	IY, SP
;	get port argument in reg C and value in A.
	LD	C, (IY)
	LD	A, 1(IY)
	OUT	(C), A
	RET
;monitor.c:73: }
;monitor.c:75: void fn_io_out(uint8_t* buffer) {
;	---------------------------------
; Function fn_io_out
; ---------------------------------
_fn_io_out::
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-7
	add	hl, sp
	ld	sp, hl
;monitor.c:77: uint8_t port = parse_hex_str(buffer, &ptr);
	ld	hl, #0
	add	hl, sp
	ld	-5 (ix), l
	ld	-4 (ix), h
	pop	de
	pop	bc
	push	bc
	push	de
	push	bc
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
	ld	-3 (ix), l
;monitor.c:80: if(*ptr == ',') {
	ld	a, -7 (ix)
	ld	-2 (ix), a
	ld	a, -6 (ix)
	ld	-1 (ix), a
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	a, (hl)
	sub	a, #0x2c
	jr	NZ,00102$
;monitor.c:81: value = parse_hex_str(++ptr, &ptr);
	pop	de
	pop	bc
	push	bc
	push	de
	ld	a, -2 (ix)
	add	a, #0x01
	ld	-7 (ix), a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	-6 (ix), a
	push	bc
	pop	bc
	pop	hl
	push	hl
	push	bc
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
;monitor.c:82: printf("Port(0x%02x) write(0x%02x)" CRLF, port, value);
	ld	-1 (ix), l
	ld	e, l
	ld	d, #0x00
	ld	c, -3 (ix)
	ld	b, #0x00
	push	de
	push	bc
	ld	hl, #___str_60
	push	hl
	call	_printf
	ld	hl, #6
	add	hl, sp
	ld	sp, hl
;monitor.c:83: _out_helper(port, value);
	ld	h, -1 (ix)
	ld	l, -3 (ix)
	push	hl
	call	__out_helper
	pop	af
	jr	00104$
00102$:
;monitor.c:86: printf(MSG_ERR);
	ld	hl, #___str_62
	push	hl
	call	_puts
	pop	af
00104$:
;monitor.c:87: }
	ld	sp, ix
	pop	ix
	ret
___str_60:
	.ascii "Port(0x%02x) write(0x%02x)"
	.db 0x0d
	.db 0x0a
	.db 0x00
___str_62:
	.ascii "ERR"
	.db 0x0d
	.db 0x00
;monitor.c:89: uint8_t _in_helper(uint8_t port) __naked {
;	---------------------------------
; Function _in_helper
; ---------------------------------
__in_helper::
;monitor.c:102: __endasm;
;	Bypass the return address of the function.
	LD	IY, #2
	ADD	IY, SP
;	get port argument in reg C.
	LD	C, (IY)
	IN	A, (C)
	LD	L, A
	RET
;monitor.c:103: }
;monitor.c:105: void fn_io_in(uint8_t* buffer) {
;	---------------------------------
; Function fn_io_in
; ---------------------------------
_fn_io_in::
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;monitor.c:107: uint8_t port = parse_hex_str(buffer, &ptr);
	ld	hl, #0
	add	hl, sp
	push	hl
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
	ld	b, l
;monitor.c:108: uint8_t value = _in_helper(port);
	push	bc
	push	bc
	inc	sp
	call	__in_helper
	inc	sp
	pop	bc
;monitor.c:110: printf("Port(0x%02x) read(0x%02x)" CRLF, port, value);
	ld	h, #0x00
	ld	e, b
	ld	d, #0x00
	ld	bc, #___str_63+0
	push	hl
	push	de
	push	bc
	call	_printf
	ld	hl, #6
	add	hl, sp
	ld	sp, hl
;monitor.c:111: }
	ld	sp, ix
	pop	ix
	ret
___str_63:
	.ascii "Port(0x%02x) read(0x%02x)"
	.db 0x0d
	.db 0x0a
	.db 0x00
;monitor.c:113: void fn_load(uint8_t* buffer) {
;	---------------------------------
; Function fn_load
; ---------------------------------
_fn_load::
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-8
	add	hl, sp
	ld	sp, hl
;monitor.c:115: uint16_t addr = parse_hex_str(buffer, &ptr);
	ld	hl, #0
	add	hl, sp
	ld	-6 (ix), l
	ld	-5 (ix), h
	pop	de
	pop	bc
	push	bc
	push	de
	push	bc
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
	ld	-4 (ix), l
	ld	-3 (ix), h
;monitor.c:118: if(*ptr == ',') {
	ld	a, -8 (ix)
	ld	-2 (ix), a
	ld	a, -7 (ix)
	ld	-1 (ix), a
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	a, (hl)
	sub	a, #0x2c
	jr	NZ,00103$
;monitor.c:119: length = parse_hex_str(++ptr, &ptr);
	pop	de
	pop	bc
	push	bc
	push	de
	ld	a, -2 (ix)
	add	a, #0x01
	ld	-8 (ix), a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	-7 (ix), a
	push	bc
	pop	bc
	pop	hl
	push	hl
	push	bc
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
	ld	c, l
	ld	b, h
;monitor.c:120: printf("Load addr(0x%02x) length(0x%02x)" CRLF, addr, length);
	push	bc
	push	bc
	ld	l, -4 (ix)
	ld	h, -3 (ix)
	push	hl
	ld	hl, #___str_64
	push	hl
	call	_printf
	ld	hl, #6
	add	hl, sp
	ld	sp, hl
	pop	bc
;monitor.c:121: ptr = (uint8_t*)addr;
	ld	a, -4 (ix)
	ld	-8 (ix), a
	ld	a, -3 (ix)
	ld	-7 (ix), a
;monitor.c:122: for(uint16_t i=0; i<length; i++) {
	ld	de, #0x0000
00106$:
	ld	a, e
	sub	a, c
	ld	a, d
	sbc	a, b
	jr	NC,00108$
;monitor.c:123: *(ptr + i) = getchar();
	ld	a, -8 (ix)
	add	a, e
	ld	-2 (ix), a
	ld	a, -7 (ix)
	adc	a, d
	ld	-1 (ix), a
	push	bc
	push	de
	call	_getchar
	pop	de
	pop	bc
	ld	a, l
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	ld	(hl), a
;monitor.c:122: for(uint16_t i=0; i<length; i++) {
	inc	de
	jr	00106$
00103$:
;monitor.c:127: printf(MSG_ERR);
	ld	hl, #___str_66
	push	hl
	call	_puts
	pop	af
00108$:
;monitor.c:128: }
	ld	sp, ix
	pop	ix
	ret
___str_64:
	.ascii "Load addr(0x%02x) length(0x%02x)"
	.db 0x0d
	.db 0x0a
	.db 0x00
___str_66:
	.ascii "ERR"
	.db 0x0d
	.db 0x00
;monitor.c:130: void _jump_helper(uint16_t addr) __naked {
;	---------------------------------
; Function _jump_helper
; ---------------------------------
__jump_helper::
;monitor.c:142: __endasm;
;	Bypass the return address of the function.
	LD	IY, #2
	ADD	IY, SP
;	Get addr argument in reg C.
	LD	L, (IY)
	LD	H, 1(IY)
	LD	SP, #0xffff
	JP	(HL)
;monitor.c:143: }
;monitor.c:145: void fn_jump(uint8_t* buffer) {
;	---------------------------------
; Function fn_jump
; ---------------------------------
_fn_jump::
	push	af
;monitor.c:147: uint16_t addr = parse_hex_str(buffer, &ptr);
	ld	hl, #0
	add	hl, sp
	push	hl
	ld	hl, #6
	add	hl, sp
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	push	bc
	call	_parse_hex_str
	pop	af
;monitor.c:148: _jump_helper(addr);
	ex	(sp),hl
	call	__jump_helper
	pop	af
;monitor.c:149: }
	pop	af
	ret
;monitor.c:151: void fn_memtest() __naked {
;	---------------------------------
; Function fn_memtest
; ---------------------------------
_fn_memtest::
;monitor.c:156: __endasm;
	LD	A, #0xaa
	RST	0x08
	RET
;monitor.c:157: }
;monitor.c:159: void sd_status_info(char* msg, int ok) {
;	---------------------------------
; Function sd_status_info
; ---------------------------------
_sd_status_info::
;monitor.c:160: printf(msg);
	pop	bc
	pop	hl
	push	hl
	push	bc
	push	hl
	call	_printf
	pop	af
;monitor.c:161: if(!ok)
	ld	hl, #4+1
	add	hl, sp
	ld	a, (hl)
	dec	hl
	or	a, (hl)
	jr	NZ,00102$
;monitor.c:162: printf(" failed" CRLF);
	ld	hl, #___str_68
	push	hl
	call	_puts
	pop	af
	ret
00102$:
;monitor.c:164: printf(" OK" CRLF);
	ld	hl, #___str_70
	push	hl
	call	_puts
	pop	af
;monitor.c:165: }
	ret
___str_68:
	.ascii " failed"
	.db 0x0d
	.db 0x00
___str_70:
	.ascii " OK"
	.db 0x0d
	.db 0x00
;monitor.c:167: void sd_init() {
;	---------------------------------
; Function sd_init
; ---------------------------------
_sd_init::
;monitor.c:168: uint8_t ok = spisdcard_init();
	call	_spisdcard_init
;monitor.c:169: sd_status_info("SD-Card init", ok);
	ld	h, #0x00
	ld	bc, #___str_71+0
	push	hl
	push	bc
	call	_sd_status_info
	pop	af
	pop	af
;monitor.c:170: }
	ret
___str_71:
	.ascii "SD-Card init"
	.db 0x00
;monitor.c:172: void sd_load_block(uint8_t* buffer) {
;	---------------------------------
; Function sd_load_block
; ---------------------------------
_sd_load_block::
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-6
	add	hl, sp
	ld	sp, hl
;monitor.c:174: uint16_t block = parse_hex_str(buffer, &ptr);
	ld	hl, #0
	add	hl, sp
	ex	de, hl
	ld	c, e
	ld	b, d
	push	de
	push	bc
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
	pop	de
	ld	-2 (ix), l
	ld	-1 (ix), h
;monitor.c:177: if(*ptr == ',') {
	pop	bc
	push	bc
	ld	a, (bc)
	sub	a, #0x2c
	jr	NZ,00103$
;monitor.c:178: addr = parse_hex_str(++ptr, &ptr);
	inc	bc
	inc	sp
	inc	sp
	push	bc
	push	de
	pop	bc
	pop	hl
	push	hl
	push	bc
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
	ld	c, l
	ld	b, h
;monitor.c:179: printf("Read SD-Card block(0x%02x) to RAM addr(0x%04x)" CRLF,
	push	bc
	push	bc
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	push	hl
	ld	hl, #___str_72
	push	hl
	call	_printf
	ld	hl, #6
	add	hl, sp
	ld	sp, hl
	pop	bc
;monitor.c:181: ptr = (uint8_t*)addr;
	inc	sp
	inc	sp
	push	bc
;monitor.c:184: uint32_t block_addr = (uint32_t)(block * 512);
	ld	a, -2 (ix)
	add	a, a
	ld	d, a
	ld	-4 (ix), #0x00
	ld	-3 (ix), d
	xor	a, a
	ld	-2 (ix), a
	ld	-1 (ix), a
;monitor.c:185: uint8_t ok = spisdcard_read(ptr, block_addr, 1);
	ld	hl, #0x0001
	push	hl
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	push	hl
	ld	l, -4 (ix)
	ld	h, -3 (ix)
	push	hl
	push	bc
	call	_spisdcard_read
	pop	af
	pop	af
	pop	af
	pop	af
;monitor.c:186: sd_status_info("SD-Card read", ok);
	ld	h, #0x00
	ld	bc, #___str_73+0
	push	hl
	push	bc
	call	_sd_status_info
	pop	af
	pop	af
00103$:
;monitor.c:188: }
	ld	sp, ix
	pop	ix
	ret
___str_72:
	.ascii "Read SD-Card block(0x%02x) to RAM addr(0x%04x)"
	.db 0x0d
	.db 0x0a
	.db 0x00
___str_73:
	.ascii "SD-Card read"
	.db 0x00
;monitor.c:190: void sd_write_block(uint8_t* buffer) {
;	---------------------------------
; Function sd_write_block
; ---------------------------------
_sd_write_block::
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-6
	add	hl, sp
	ld	sp, hl
;monitor.c:192: uint16_t addr = parse_hex_str(buffer, &ptr);
	ld	hl, #0
	add	hl, sp
	ex	de, hl
	ld	c, e
	ld	b, d
	push	de
	push	bc
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
	pop	de
	ld	-2 (ix), l
	ld	-1 (ix), h
;monitor.c:195: if(*ptr == ',') {
	pop	bc
	push	bc
	ld	a, (bc)
	sub	a, #0x2c
	jr	NZ,00103$
;monitor.c:196: block = parse_hex_str(++ptr, &ptr);
	inc	bc
	inc	sp
	inc	sp
	push	bc
	push	de
	pop	bc
	pop	hl
	push	hl
	push	bc
	push	hl
	call	_parse_hex_str
	pop	af
	pop	af
;monitor.c:197: printf("Write 512 bytes RAM @ addr(0x%04x) to SD-Card block(0x%02x)" CRLF,
	ld	bc, #___str_74+0
	push	hl
	ld	e, -2 (ix)
	ld	d, -1 (ix)
	push	de
	push	hl
	push	bc
	call	_printf
	ld	hl, #6
	add	hl, sp
	ld	sp, hl
	pop	hl
;monitor.c:199: ptr = (uint8_t*)addr;
	ld	c, -2 (ix)
	ld	b, -1 (ix)
	inc	sp
	inc	sp
	push	bc
;monitor.c:202: uint32_t block_addr = (uint32_t)(block * 512);
	ld	a, l
	add	a, a
	ld	d, a
	ld	-4 (ix), #0x00
	ld	-3 (ix), d
	xor	a, a
	ld	-2 (ix), a
	ld	-1 (ix), a
;monitor.c:203: uint8_t ok = spisdcard_write(ptr, block_addr, 1);
	ld	hl, #0x0001
	push	hl
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	push	hl
	ld	l, -4 (ix)
	ld	h, -3 (ix)
	push	hl
	push	bc
	call	_spisdcard_write
	pop	af
	pop	af
	pop	af
	pop	af
;monitor.c:204: sd_status_info("SD-Card write", ok);
	ld	h, #0x00
	ld	bc, #___str_75+0
	push	hl
	push	bc
	call	_sd_status_info
	pop	af
	pop	af
00103$:
;monitor.c:206: }
	ld	sp, ix
	pop	ix
	ret
___str_74:
	.ascii "Write 512 bytes RAM @ addr(0x%04x) to SD-Card block(0x%02x)"
	.db 0x0d
	.db 0x0a
	.db 0x00
___str_75:
	.ascii "SD-Card write"
	.db 0x00
;monitor.c:208: void sd_boot() {
;	---------------------------------
; Function sd_boot
; ---------------------------------
_sd_boot::
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl, #-9
	add	hl, sp
	ld	sp, hl
;monitor.c:213: uint8_t ok = spisdcard_read(ptr, 0, 1);
	ld	hl, #0x0001
	push	hl
	ld	hl, #0x0000
	push	hl
	ld	hl, #0x0000
	push	hl
	ld	h, #0x80
	push	hl
	call	_spisdcard_read
	pop	af
	pop	af
	pop	af
	pop	af
	ld	c, l
;monitor.c:214: if(!ok) {
	ld	a,c
	ld	e,a
;monitor.c:215: sd_status_info("SD-Card read", ok);
	or	a,a
	jr	NZ,00102$
	ld	d,a
	push	de
	ld	hl, #___str_76
	push	hl
	call	_sd_status_info
	pop	af
;monitor.c:216: printf("Boot aborted" CRLF);
	ld	hl, #___str_78
	ex	(sp),hl
	call	_puts
	pop	af
;monitor.c:217: return;
	jp	00107$
00102$:
;monitor.c:223: uint8_t code[] = {
	ld	hl, #0
	add	hl, sp
	ld	-2 (ix), l
	ld	-1 (ix), h
	ld	(hl), #0xe3
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	inc	hl
	ld	(hl), #0x01
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	inc	hl
	inc	hl
	ld	(hl), #0xd3
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	inc	hl
	inc	hl
	inc	hl
	ld	(hl), #0x02
	ld	a, -2 (ix)
	add	a, #0x04
	ld	l, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h, a
	ld	(hl), #0xc3
	ld	a, -2 (ix)
	add	a, #0x05
	ld	c, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	b, a
	xor	a, a
	ld	(bc), a
	ld	a, -2 (ix)
	add	a, #0x06
	ld	l, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h, a
	ld	(hl), #0x80
;monitor.c:229: for(int i=0; i<sizeof(code); i++) {
	ld	bc, #0x0000
00105$:
	ld	a, c
	sub	a, #0x07
	ld	a, b
	rla
	ccf
	rra
	sbc	a, #0x80
	jr	NC,00103$
;monitor.c:230: *(ptr+i) = code[i];
	ld	hl, #0xfff0
	add	hl, bc
	ex	de, hl
	ld	l, -2 (ix)
	ld	h, -1 (ix)
	add	hl, bc
	ld	a, (hl)
	ld	(de), a
;monitor.c:229: for(int i=0; i<sizeof(code); i++) {
	inc	bc
	jr	00105$
00103$:
;monitor.c:234: _jump_helper(addr);
	ld	hl, #0xfff0
	push	hl
	call	__jump_helper
	pop	af
00107$:
;monitor.c:235: }
	ld	sp, ix
	pop	ix
	ret
___str_76:
	.ascii "SD-Card read"
	.db 0x00
___str_78:
	.ascii "Boot aborted"
	.db 0x0d
	.db 0x00
;monitor.c:237: int main(void) {
;	---------------------------------
; Function main
; ---------------------------------
_main::
	push	ix
	ld	hl, #-600
	add	hl, sp
	ld	sp, hl
;monitor.c:241: sd_init();
	call	_sd_init
;monitor.c:242: spisdcard_read(NULL, 0, 1);
	ld	hl, #0x0001
	push	hl
	ld	hl, #0x0000
	push	hl
	ld	hl, #0x0000
	push	hl
	ld	l, #0x00
	push	hl
	call	_spisdcard_read
	ld	hl, #8
	add	hl, sp
	ld	sp, hl
;monitor.c:244: show_menu();
	call	_show_menu
;monitor.c:246: while(true) {
00116$:
;monitor.c:247: printf(MSG_OK);
	ld	hl, #___str_80
	push	hl
	call	_puts
	pop	af
;monitor.c:248: gets2(buffer, sizeof(buffer));
	ld	hl, #0
	add	hl, sp
	ld	c, l
	ld	b, h
	push	hl
	ld	de, #0x0258
	push	de
	push	bc
	call	_gets2
	pop	af
	pop	af
	pop	hl
;monitor.c:249: printf(CRLF);
	ld	bc, #___str_82+0
	push	hl
	push	bc
	call	_puts
	pop	af
	pop	hl
;monitor.c:251: char cmd = buffer[0];
	ld	a, (hl)
;monitor.c:252: uint8_t* args = buffer + 1;
	inc	hl
;monitor.c:253: switch(cmd) {
	cp	a, #0x42
	jr	Z,00109$
	cp	a, #0x44
	jr	Z,00101$
	cp	a, #0x48
	jr	Z,00111$
	cp	a, #0x49
	jr	Z,00105$
	cp	a, #0x4a
	jr	Z,00103$
	cp	a, #0x4c
	jr	Z,00102$
	cp	a, #0x4f
	jr	Z,00104$
	cp	a, #0x54
	jr	Z,00110$
	cp	a, #0x56
	jr	Z,00112$
	cp	a, #0x69
	jr	Z,00106$
	cp	a, #0x72
	jr	Z,00107$
	sub	a, #0x77
	jr	Z,00108$
	jr	00116$
;monitor.c:254: case 'D':
00101$:
;monitor.c:255: fn_memory_dump(args);
	push	hl
	call	_fn_memory_dump
	pop	af
;monitor.c:256: break;
	jr	00116$
;monitor.c:257: case 'L':
00102$:
;monitor.c:258: fn_load(args);
	push	hl
	call	_fn_load
	pop	af
;monitor.c:259: break;
	jr	00116$
;monitor.c:260: case 'J':
00103$:
;monitor.c:261: fn_jump(args);
	push	hl
	call	_fn_jump
	pop	af
;monitor.c:262: break;
	jr	00116$
;monitor.c:263: case 'O':
00104$:
;monitor.c:264: fn_io_out(args);
	push	hl
	call	_fn_io_out
	pop	af
;monitor.c:265: break;
	jp	00116$
;monitor.c:266: case 'I':
00105$:
;monitor.c:267: fn_io_in(args);
	push	hl
	call	_fn_io_in
	pop	af
;monitor.c:268: break;
	jp	00116$
;monitor.c:269: case 'i':
00106$:
;monitor.c:270: sd_init();
	call	_sd_init
;monitor.c:271: break;
	jp	00116$
;monitor.c:272: case 'r':
00107$:
;monitor.c:273: sd_load_block(args);
	push	hl
	call	_sd_load_block
	pop	af
;monitor.c:274: break;
	jp	00116$
;monitor.c:275: case 'w':
00108$:
;monitor.c:276: sd_write_block(args);
	push	hl
	call	_sd_write_block
	pop	af
;monitor.c:277: break;
	jp	00116$
;monitor.c:278: case 'B':
00109$:
;monitor.c:279: sd_boot();
	call	_sd_boot
;monitor.c:280: break;
	jp	00116$
;monitor.c:281: case 'T':
00110$:
;monitor.c:282: fn_memtest();
	call	_fn_memtest
;monitor.c:283: break;
	jp	00116$
;monitor.c:284: case 'H':
00111$:
;monitor.c:285: show_menu();
	call	_show_menu
;monitor.c:286: break;
	jp	00116$
;monitor.c:287: case 'V':
00112$:
;monitor.c:288: show_id();
	call	_show_id
;monitor.c:289: break;
;monitor.c:292: }
;monitor.c:294: }
	jp	00116$
___str_80:
	.db 0x0d
	.db 0x0a
	.ascii "OK"
	.db 0x0d
	.db 0x00
___str_82:
	.db 0x0d
	.db 0x00
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)
