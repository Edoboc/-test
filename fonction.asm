/*
 * fonction.asm
 *
 *  Created: 5/15/2019 8:14:54 PM
 *   Author: shobayashi
 */ 
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
 .equ tmax0 = 0b01100000
 .equ tmax1 = 0b00000100		; tmax = 70C
 .equ tmin0 = 0b00100000
 .equ tmin1 = 0b11111110		; tmin = -30C
 .equ compteur = 0b01000000

; === macros declarations

.macro LOAD

		ldi xl, low(@0)
		ldi xh, high(@0)
		ld b1, x+
		ld b0, x
.endmacro

.macro STORE

		ldi xl, low(@0)
		ldi xh, high(@0)
		st x+,b1
		st x, b0
.endmacro


.macro 	INCT ; incrémente @0,@1 tant que < 70 (format 2 bytes signé, point fixe à 4)
		PUSH4 c0, c1, c2, c3
		 
		_LDI c0,tmax0
		_LDI c1,tmax1

		ldi xl, low(Tsup)
		ldi xh, high(Tsup)
		ld c3, x+
		ld c2, x

		CP2 c1,c0,c3,c2
		breq nope


		_LDI c0,tmin0
		_LDI c1,tmin1

		ldi xl, low(Tinf)
		ldi xh, high(Tinf)
		ld c3, x+
		ld c2, x
		CP2 c1,c0,c3,c2
		breq nope

		ldi w,@2

		_CPI w,1
		breq PC+3
		ldi w, incr0
		rjmp PC+2
		ldi w, incr1
		add @0,w
		brcc PC+2
		inc @1
nope:	
		POP4 c0, c1, c2, c3

	.endmacro


.macro 	DECT ; décrémente @0,@1 tant que > -30 (format 2 bytes signé, point fixe à 4)
		PUSH4 c0, c1, c2, c3
		ldi w,@2

		_LDI c0,tmin0
		_LDI c1,tmin1

		ldi xl, low(Tinf)
		ldi xh, high(Tinf)
		ld c3, x+
		ld c2, x
		CP2 c1,c0,c3,c2
		breq nope2

		_LDI c1,0
		_LDI c0,0b00000100

		ldi xl, low(Plage)
		ldi xh, high(Plage)
		ld c3, x+
		ld c2, x
		CP2 c1,c0,c3,c2
		breq nope2

		_CPI w,1
		breq PC+3
		subi @0, incr0
		rjmp PC+2
		subi @0, incr1
		brcc PC+2
		dec @1
nope2:
		POP4 c0, c1, c2, c3
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
.endmacro

.macro	WS2812b4_WR0
		clr	u
		sbi PORTE, 1
		out PORTE, u
		nop
		nop
		
.endmacro

.macro	WS2812b4_WR1
		sbi PORTE, 1
		nop
		nop
		cbi PORTE, 1
		
.endmacro

.macro	LED_COLOR				; Affiche la couleur qu'on envoie comme argument 							
		clr	d3					; in: a0, a1, a2, b3, d3
		_LDI d1, compteur
		cp d3, d1
		breq PC+7
		inc d3
		ldi a0,@1		
		ldi a1,@0
		ldi a2,@2
		rcall ws2812b4_byte3wr	
		rjmp PC-7
.endmacro

.macro MODE
	
		PUSH3 c0,c1,c2
		PUSH4 a0,a1,b0,d1
		PUSH2 d2,d3
		mov d2,@0
		mov d3,@1
		LDI2 a1,a0,0x500
		LDI2 b1,b0,0x900
		rcall div22
		mov a0,d2
		mov a1,d3
		mov b0,c0
		mov b1,c1
		rcall div22
		POP2 d2,d3
		POP4 a0,a1,b0,d1
		_ADDI c1, 0b00000010
		mov b1,c1
		mov b0,c0
		POP3 c0,c1,c2
.endmacro

.macro BOUTON
		
		sbic PIND,@0
		rjmp PC-1
		sbis PIND,@0
		rjmp PC-1

.endmacro