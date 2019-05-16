/*
 * LEDs.asm
 *
 *  Created: 5/15/2019 5:25:28 PM
 *   Author: bocchiot
 */ 
 /*
 * LEDs.asm
 *
 *  Created: 07.05.2019 10:33:52
 *   Author: Loicc
 */
; file	ws2812b_4MHz_demo03_S.asm   target ATmega128L-4MHz-STK300
; purpose send data to ws2812b using 4 MHz MCU and standard I/O port
;         display 
; usage: ws2812 on PORTE (data, bit 1)
; warnings: 1/2 timings of pulses in the macros are sensitive
;			2/2 intensity of LEDs is high, thus keep intensities
;				within the range 0x00-0x0f, and do not look into
;				LEDs
; 20180926 AxS

;.include "macros.asm"			; include macro definitions
;.include "definitions.asm"		; include register/constant definitions



; WS2812b4_WR0	; macro ; arg: void; used: void
; purpose: write an active-high zero-pulse to PE1
; PORTE is assumed only used for the purpose
.macro	WS2812b4_WR0
		clr	u
		sbi PORTE, 1
		out PORTE, u
		nop
		nop
		;nop
		;nop
		.endmacro

; WS2812b4_WR1	; macro ; arg: void; used: void
; purpose: write an active-high one-pulse to PE1
.macro	WS2812b4_WR1
		sbi PORTE, 1
		nop
		nop
		cbi PORTE, 1
		;nop
		;nop
		.endmacro

.org 0

/*reset:
		LDSP RAMEND
		rcall ws2812b4_init
		*/
;.equ	PAS = 0b00011111
/*main:
		clr b0
		ldi _w, 0b00111111
		rcall ws2812b4_reset
		rcall White
		rcall Red
		rcall Blue
		rcall Green
		rcall end
		*/
		
.macro	OFF		
		ldi a0,0x00		;zero-intensity, pixel is off
		ldi a1,0x00
		ldi a2,0x00
		rcall ws2812b4_byte3wr
		.endmacro

.macro	WHITE
		cpc b2,_w
		breq PC+7
		inc b2
		ldi a0,0x05		;low-intensity pure white
		ldi a1,0x05
		ldi a2,0x05
		rcall ws2812b4_byte3wr
		rcall White
		.endmacro

Green:
		ldi a0,0x0f		;low-intensity pure green
		ldi a1,0x00
		ldi a2,0x00
		rcall ws2812b4_byte3wr
		rcall Green
		ret

Red:
		ldi a0,0x00		;low-intensity pure red
		ldi a1,0x0f
		ldi a2,0x00
		rcall ws2812b4_byte3wr
		rcall Red
		ret

Blue:
		ldi a0,0x00		;low-intensity pure blue
		ldi a1,0x00
		ldi a2,0x0f	
		rcall ws2812b4_byte3wr
		rcall Blue
		ret
		 

/*
.macro	INIT_COLOR
		rcall ws2812b4_reset
		cpi w,PAS
		breq PC+4
		inc w
.endmacro

.macro	COLOR
		rcall ws2812b4_reset
		push w
		push b3
		ldi w,PASLSB
		ldi b3,PASMSB
		CP2	@1,@0,b3,w
		breq PC+4
		subi @0, incr
		brcc PC+2
		dec @1
		pop _w
		pop w
.endmacro
		*/
end:
		rjmp end
		

; ws2812b4_init		; arg: void; used: r16 (w)
; purpose: initialize AVR to support ws2812b
ws2812b4_init:
		OUTI	DDRE,0x02
		ret

; ws2812b4_byte3wr	; arg: a0,a1,a2 ; used: r16 (w)
; purpose: write contents of a0,a1,a2 (24 bit) into ws2812, 1 LED configuring
;     GBR color coding, LSB first
ws2812b4_byte3wr:

		ldi w,8
ws2b3_starta0:
		sbrc a0,7
		rjmp	ws2b3w1
		WS2812b4_WR0		
		rjmp	ws2b3_nexta0
ws2b3w1:
		WS2812b4_WR1
ws2b3_nexta0:
		lsl a0
		dec	w
		brne ws2b3_starta0

		ldi w,8
ws2b3_starta1:
		sbrc a1,7
		rjmp	ws2b3w1a1
		WS2812b4_WR0		
		rjmp	ws2b3_nexta1
ws2b3w1a1:
		WS2812b4_WR1
ws2b3_nexta1:
		lsl a1
		dec	w
		brne ws2b3_starta1

		ldi w,8
ws2b3_starta2:
		sbrc a2,7
		rjmp	ws2b3w1a2
		WS2812b4_WR0		
		rjmp	ws2b3_nexta2
ws2b3w1a2:
		WS2812b4_WR1
ws2b3_nexta2:
		lsl a2
		dec	w
		brne ws2b3_starta2
	
		ret

; ws2812b4_reset	; arg: void; used: r16 (w)
; purpose: reset pulse, configuration becomes effective
ws2812b4_reset:
		cbi PORTE, 1
		WAIT_US	50 	; 50 us are required, NO smaller works
		ret