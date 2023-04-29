\ f80 with 64K of onboard RAM
\ Memory register at the end of RAM. Must not overwrite
5 CONSTS $dd00 RS_ADDR
         $ddca PS_ADDR
		 $c000 HERESTART
		 $00 UART_DATA
		 $01 UART_STATUS

RS_ADDR $90 - VALUE SYSVARS

ARCHM XCOMP
Z80A XCOMPC Z80C COREL

: INIT (im1) ;

\ 7.373MHz target: 737t. outer: 37t inner: 16t
\ tickfactor = (737 - 37) / 16
\ 44 VALUE tickfactor

\ Base word to check if char can be read from UART
CODE RX<? BC push,
	BC 0 i) ld,
	A UART_STATUS i) in, A $01 i) and, ( char available in hw RX queue? )
	IFNZ,
		A UART_DATA i) in, A>HL, HL push, C inc, ( read char )
	THEN,
	;CODE
ALIAS RX<? (key?)

\ Base word to send one char to UART
CODE TX>
	A UART_STATUS i) in, A $10 i) and, ( space in hw TX queue for char? )
	IFNZ,
		A C ld, UART_DATA i) A out, ( send char )
		BC pop,
	THEN,
;CODE
ALIAS TX> (emit)



\ Define constants here again to be available in
\ generated binary
20 CONSTS $00 IO_UART_DATA
		 $01 IO_UART_STATUS
		 $a0 IO_RGB_LED1_R_PWM
		 $a1 IO_RGB_LED1_G_PWM
		 $a2 IO_RGB_LED1_B_PWM
		 $a3 IO_RGB_LED2_R_PWM
		 $a4 IO_RGB_LED2_G_PWM
		 $a5 IO_RGB_LED2_B_PWM
		 $a6 IO_RGB_LED3_R_PWM
		 $a7 IO_RGB_LED3_G_PWM
		 $a8 IO_RGB_LED3_B_PWM
		 $a9 IO_RGB_LED4_R_PWM
		 $aa IO_RGB_LED4_G_PWM
		 $ab IO_RGB_LED4_B_PWM
		 $f0 IO_DISP_DATA
		 $f0 IO_BUTTONS
		 $f1 IO_LEDS
		 $f1 IO_SWITCHES
		 $fe IO_TICKS_MS
		 $ff IO_TICKS_SYS

\ Read system clock ticks
( -- t )
: CLK_SYS@ IO_TICKS_SYS PC@ ;
\ Read millisecond clock ticks
( -- t )
: CLK_MS@ IO_TICKS_MS PC@ ;
\ Send 8bit value c to 7segment display
( c -- )
: DISP> IO_DISP_DATA PC! ;
\ Send lower 4bits of c to LEDs. Each bit represents one LED
\ where LED0 is bit 0
( l -- )
: LEDS> IO_LEDS PC! ;
\ Read current state of buttons into c. Lower 4bit represent
\ button state where Button0 is bit 0
( -- b )
: BUTTONS@ IO_BUTTONS PC@ ;
\ Read current state of witchesinto c. Lower 4bit represent
\ switch state where Switch0 is bit 0
( -- s )
: SWITCHES@ IO_SWITCHES PC@ ;

\ Turn RGB LED1 on - bright white
: RGB1-ON
	IO_RGB_LED1_R_PWM $ff PC!
	IO_RGB_LED1_G_PWM $ff PC!
	IO_RGB_LED1_B_PWM $ff PC! ;
\ Turn RGB LED1 off
: RGB1-OFF
	IO_RGB_LED1_R_PWM $00 PC!
	IO_RGB_LED1_G_PWM $00 PC!
	IO_RGB_LED1_B_PWM $00 PC! ;
\ Turn RGB LED1 on with explicit values for
\ colors red, green and blue
( r g b -- )
: RGB1>
	IO_RGB_LED1_R_PWM PC!
	IO_RGB_LED1_G_PWM PC!
	IO_RGB_LED1_B_PWM PC! ;

\ Turn RGB LED2 on - bright white
: RGB2-ON
	IO_RGB_LED2_R_PWM $ff PC!
	IO_RGB_LED2_G_PWM $ff PC!
	IO_RGB_LED2_B_PWM $ff PC! ;
\ Turn RGB LED2 off
: RGB2-OFF
	IO_RGB_LED2_R_PWM $00 PC!
	IO_RGB_LED2_G_PWM $00 PC!
	IO_RGB_LED2_B_PWM $00 PC! ;
\ Turn RGB LED2 on with explicit values for
\ colors red, green and blue
( r g b -- )
: RGB2>
	IO_RGB_LED2_R_PWM PC!
	IO_RGB_LED2_G_PWM PC!
	IO_RGB_LED2_B_PWM PC! ;

\ Turn RGB LED3 on - bright white
: RGB3-ON
	IO_RGB_LED3_R_PWM $ff PC!
	IO_RGB_LED3_G_PWM $ff PC!
	IO_RGB_LED3_B_PWM $ff PC! ;
\ Turn RGB LED3 off
: RGB3-OFF
	IO_RGB_LED3_R_PWM $00 PC!
	IO_RGB_LED3_G_PWM $00 PC!
	IO_RGB_LED3_B_PWM $00 PC! ;
\ Turn RGB LED3 on with explicit values for
\ colors red, green and blue
( r g b -- )
: RGB3>
	IO_RGB_LED3_R_PWM PC!
	IO_RGB_LED3_G_PWM PC!
	IO_RGB_LED3_B_PWM PC! ;

\ Turn RGB LED4 on - bright white
: RGB4-ON
	IO_RGB_LED4_R_PWM $ff PC!
	IO_RGB_LED4_G_PWM $ff PC!
	IO_RGB_LED4_B_PWM $ff PC! ;
\ Turn RGB LED4 off
: RGB4-OFF
	IO_RGB_LED4_R_PWM $00 PC!
	IO_RGB_LED4_G_PWM $00 PC!
	IO_RGB_LED4_B_PWM $00 PC! ;
\ Turn RGB LED4 on with explicit values for
\ colors red, green and blue
( r g b -- )
: RGB4>
	IO_RGB_LED4_R_PWM PC!
	IO_RGB_LED4_G_PWM PC!
	IO_RGB_LED4_B_PWM PC! ;

XWRAP
$4000 OALLOT XORG 1 ( 16K )
