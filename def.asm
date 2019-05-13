/*
 * def+.asm
 *
 *  Created: 29.05.2018 16:55:35
 *   Author: Loic
 */
 .include "definitions.asm"
 .include "macros.asm"

; === constants definition
 .equ incr1 = 0b0100
 .equ incr0 = 0b0010
 .equ tmax0 = 0b10000000
 .equ tmax1 = 0b00000100		; tmax = 70C
 .equ tmin0 = 0b00100000
 .equ tmin1 = 0b11111110		; tmin = -30C
 .equ openp = 1000			; openp(ulse) = 1000
 .equ closep = 2000			; closep(ulse) = 2000
 .equ proche = 950
 .equ compteur = 0b01000000

; === macros declarations
.macro 	INCT ; incr�mente @0,@1 tant que < 60 (format 2 bytes sign�, point fixe � 4)
		PUSH2 c0, c1
		_LDI c1,@2
		ldi w,tmax0
		_LDI c0,tmax1
		CP2 @1,@0,r25,w
		breq PC+5
		_CPI c1,1
		breq PC+3
		ldi w, incr0
		rjmp PC+2
		ldi w, incr1
		add @0,w
		brcc PC+2
		inc @1
		pop c0
		pop c1
	.endmacro


.macro 	DECT ; d�cr�mente @0,@1 tant que > -30 (format 2 bytes sign�, point fixe � 4)
		PUSH2 c0, c1
		_LDI c1, @2
		ldi w,tmin0
		_LDI c0,tmin1
		CP2 @1,@0,r25,w
		breq PC+8
		_CPI c1,1
		breq PC+3
		subi @0, incr0
		rjmp PC+2
		subi @0, incr1
		brcc PC+2
		dec @1
		pop c0
		pop c1
.endmacro

.macro	WS2812b4_WR0
		clr	u
		sbi PORTE, 1
		out PORTE, u
		nop
		nop
		;nop
		;nop
.endmacro

.macro	WS2812b4_WR1
		sbi PORTE, 1
		nop
		nop
		cbi PORTE, 1
		;nop
		;nop
.endmacro

.macro	LED_COLOR
		PUSH4 a0,a1,a2,b3
		clr	d3
		ldi b3, compteur
		cp d3, b3
		breq PC+7
		inc d3
		ldi a0,@1		
		ldi a1,@0
		ldi a2,@2
		rcall ws2812b4_byte3wr
		rjmp PC-7
		POP4 a0,a1,a2,b3
.endmacro

