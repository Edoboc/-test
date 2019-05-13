/*
 * def+.asm
 *
 *  Created: 29.05.2018 16:55:35
 *   Author: Lucas
 */
 .include "definitions.asm"
 .include "macros.asm"

; === constants definition
 .equ incr1 = 0b0100
 .equ incr0 = 0b0010
 .equ tmax0 = 0b11000000
 .equ tmax1 = 0b00000011		; tmax = 60C
 .equ tmin0 = 0b00100000
 .equ tmin1 = 0b11111110		; tmin = -30C
 .equ openp = 1000			; openp(ulse) = 1000
 .equ closep = 2000			; closep(ulse) = 2000
 .equ proche = 950

; === macros declarations
.macro 	INCT ; incrémente @0,@1 tant que < 60 (format 2 bytes signé, point fixe à 4)
		push w
		ldi w,tmax0
		ldi r25,tmax1
		CP2 @1,@0,r25,w
		breq PC+5
		CP @2,1
		breq PC+3
		ldi w, incr0
		rjmp PC+2
		ldi w, incr1
		add @0,w
		brcc PC+2
		inc @1
		pop w
	.endmacro


.macro 	INCTinf ; incrémente Tinf tant que < Tref (format 2 bytes signé, point fixe à 4)
		push w
		CP2 @1,@0,@3,@2
		breq PC+5
		ldi w,incr
		add @0,w
		brcc PC+2
		inc @1
		pop w
	.endmacro

.macro 	DECT ; décrémente @0,@1 tant que > -30 (format 2 bytes signé, point fixe à 4)
		push w
		ldi w,tmin0
		ldi r25,tmin1
		CP2 @1,@0,r25,w
		breq PC+8
		CP @2,1
		breq PC+3
		subi @0, incr0
		rjmp PC+2
		subi @0, incr1
		brcc PC+2
		dec @1
		pop w
	.endmacro

	.macro 	DECTsup ; décrémente Tsup tant que > Tref (format 2 bytes signé, point fixe à 4)
		push w
		CP2 @1,@0,@3,@2
		breq PC+4
		subi @0, incr
		brcc PC+2
		dec @1
		pop w
	.endmacro

.macro TOGGLEBIT ; in r,b : out r(a=/=b) inchangé, r(b) inversé
		push w
		clr w
		sbr w,@1
		eor @0,w
		pop w
		.endmacro