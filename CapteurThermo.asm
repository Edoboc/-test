/*
 * Capteurthermo.asm
 *
 *  Created: 15.05.2018 15:37:41
 *   Author: Loïc & Edoardo
 */

 .include "fonction.asm"

 ; === interrupt table
.org 0
		jmp reset
.org INT0addr
		jmp	ext_int0
.org INT1addr
		jmp	ext_int1

; === interrupte service routines

reset:		
			sei
			LDSP RAMEND
			OUTI DDRB,0xff
			cbi DDRE,SPEAKER
			OUTI ADCSR, (1<<ADEN)+(1<<ADIE)+6
			call ws2812b4_init
			call ws2812b4_reset		 
			rcall LCD_init
			rcall wire1_init
			rjmp init

ext_int0:
			
			rjmp reset
			reti

ext_int1:
			
			sbic PIND,1					;boucle pour éviter les rebonds
			rjmp PC-1
			sbis PIND,1
			rjmp PC-1
			in _sreg, SREG

			ldi xl, low(Selection)		;incrementation registre, alternance 0/1 du bit4
			ldi xh, high(Selection)
			ld d2, x
			_ADDI d2, 0b00010000
			st x, d2

			rcall retour
			out SREG,_sreg
			reti

.include "lcd.asm"
.include "printf.asm"
.include "wire1.asm"
.include "math.asm"


; === program start
init:		
			OUTI EIMSK, 0x03
			sei
			rcall LCD_clear

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			_LDI d2, 0b00000000 ; initialisation compteur
			st x, d2

			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ldi b0, 0b10010000 ; Tref LSByte
			ldi b1, 0b00000001 ; Tref MSByte, initialisation à 25°C
			st x+, b1
			st x, b0

			ldi xl, low(Tsup)
			ldi xh, high(Tsup)
			ldi b0,0b00110000	; Tsup LSByte
			ldi b1,0b00000010	; Tsup MSByte, initialisation à 35°C
			st x+, b1
			st x, b0

			ldi xl, low(Tinf)
			ldi xh, high(Tinf)
			ldi b0,0b11110000	; Tinf LSByte
			ldi b1,0b00000000	; Tinf MSByte, initialisation à 15°C
			st x+, b1
			st x, b0

			ldi xl, low(Plage)
			ldi xh, high(Plage)
			ldi b0,0b01000000	; Plage LSByte
			ldi b1,0b00000001	; Plage MSByte, initialisation à 20°C
			st x+, b1
			st x, b0

			rjmp Trefset

retour:		
			rcall LCD_clear
			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld d2,x
			sbrc d2,4

			rjmp Mode_Selection
			
			PRINTF LCD
.db			"Mode Celsius",LF, 0		;affichage temporaire lors de la sélection du mode Celsius via interruption
			WAIT_MS	2000
			ret

Mode_Selection:

			PRINTF LCD
.db "Mode Farenheit",LF, 0				;affichage temporaire lors de la sélection du mode Celsius via interruption
			WAIT_MS 2000
			ret

Trefset:	
			rcall LCD_clear
			WAIT_US 50
			PRINTF LCD
.db "Set Tref", LF, 0

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld d2, x

			sbrc d2,4					;affichage en °C ou en °F selon le choix du mode
			rjmp Mode_F0
					
			LOAD Tref

			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "C", LF, 0
			LED_COLOR 0x05,0x05,0x05	; affiche la couleur blanche

			rjmp Trefinc

Mode_F0:								; Mode_FX (selection mode Farenheit)
			ldi xl, low(Tref)
			ldi xh, high(Tref)
			ld b1, x+
			ld b0, x
			MODE b0,b1
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			LED_COLOR 0x05,0x05,0x05	; affiche la couleur blanche

Trefinc:	
			
			in r16, PIND
			cpi r16, 0b11011111				; increment Tref, Tsup and Tinf if PD5 is pressed
			_BRNE Trefdec					; go to Trefdec if not
			
			LOAD Tref
			INCT b0,b1,1
			STORE Tref
		
			LOAD Tsup
			INCT b0,b1,1
			STORE Tsup
			
			LOAD Tinf
			INCT b0,b1,1
			STORE Tinf

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld d2, x

			LOAD Tref
			sbrc d2,4
			rjmp Mode_F1

			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "C", LF, 0
			WAIT_MS 50
			rjmp Trefdec

Mode_F1:									; Mode_FX (selection mode Farenheit)
			MODE b0,b1						
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 50
			

Trefdec:	
			in r16, PIND
			cpi r16, 0b11101111				; decrement Tref, Tsup and Tinf if PD4 is pressed
			_BRNE Trefnext					; go to Trefnext if not

			LOAD Tref
			DECT b0,b1,1
			STORE Tref

			LOAD Tsup
			DECT b0,b1,1
			STORE Tsup

			LOAD Tinf
			DECT b0,b1,1
			STORE Tinf

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld d2,x

			LOAD Tref
			sbrc d2,4
			rjmp Mode_F2
			
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "C", LF, 0
			WAIT_MS 50
			rjmp Trefnext

Mode_F2:		
			
			MODE b0,b1
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 50

Trefnext:	

			in r16, PIND
			cpi r16, 0b10111111				; clear LCD and go to main if PD6 is pressed
			brne skip1
			BOUTON 6					
			rcall LCD_clear
			rjmp main					
skip1:		cpi r16, 0b11110111				; clear LCD and go to Plageset if PD3 is pressed
			brne skip2
			BOUTON 3					
			rcall LCD_clear
			rjmp Plageset
skip2:		cpi r16, 0b11111011				; clear LCD and go to Plageset if PD2 is pressed
			brne skip3
			BOUTON 2
			rcall LCD_clear
			rjmp Plageset		

skip3:		rjmp Trefset					; if any button is pressed, return to Trefset

Plageset:
			rcall LCD_clear
			WAIT_US 50
			PRINTF LCD
.db "Set Plage", LF, 0

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld d2,x

			LOAD Plage
			sbrc d2,4
			rjmp Mode_F3
			
			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b, 4, $42, "C", LF, 0
			WAIT_MS 50
			rjmp Plageinc

Mode_F3:									; Mode_FX (selection mode Farenheit)
			MODE b0,b1
			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b, 4, $42, "F", LF, 0
			WAIT_MS 50
			


Plageinc:	

			in r16, PIND
			cpi r16, 0b11110111				; increment Plage, Tsup and Tinf if PD4 is pressed
			_BRNE Plagedec					; go to Plagedec if not
			
			LOAD Plage
			INCT b0,b1,1
			STORE Plage

			LOAD Tsup
			INCT b0,b1,0
			STORE Tsup

			LOAD Tinf
			DECT b0,b1,0
			STORE Tinf
			

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld d2,x

			LOAD Plage
			sbrc d2,4
			rjmp Mode_F4

			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b, 4, $42,"C", LF, 0
			WAIT_MS 50
			rjmp Plagenext
Mode_F4:									; Mode_FX (selection mode Farenheit)
			MODE b0,b1
			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b, 4, $42,"F", LF, 0
			WAIT_MS 50
		
Plagedec:	
			in r16, PIND
			cpi r16, 0b11111011				; decrement Tref, Tsup and Tinf if PD1 is pressed
			_BRNE Plagenext					; go to Plagenext if not
			
			LOAD Plage
			DECT b0,b1,1
			STORE Plage

			LOAD Tsup
			DECT b0,b1,0
			STORE Tsup

			LOAD Tinf
			INCT b0,b1,0
			STORE Tinf

			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld d2, x

			LOAD Plage
			sbrc d2,4
			rjmp Mode_F5

			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b, 4, $42,"C", LF, 0
			WAIT_MS 50
			rjmp Plagenext

Mode_F5:									; Mode_FX (selection mode Farenheit)
			MODE b0,b1
			PRINTF LCD
.db "Plage =",FFRAC2+FSIGN, b, 4, $42,"F", LF, 0
			WAIT_MS 50

Plagenext:
			
			in r16, PIND
			cpi r16, 0b10111111				; clear LCD and go to main if PD6 is pressed
			brne skip4
			BOUTON 6						
			call LCD_clear
			rjmp main
skip4:		cpi r16, 0b11011111				; clear LCD and return to Trefset if PD5 is pressed
			brne skip5
			BOUTON 5						
			call LCD_clear
			rjmp Trefset
skip5:		cpi r16, 0b11101111				; clear LCD and return to Trefset if PD4 is pressed
			brne skip6
			BOUTON 4						
			call LCD_clear	
			rjmp Trefset

skip6:		rjmp Plageset					; if any button is pressed, return to Plageset		


main:		
			call LCD_clear
			WAIT_US 100
			sei

			clr a0
			call	lcd_home				; place cursor to home position
			call	wire1_reset				; send a reset pulse
			CA	wire1_write, skipROM		; skip ROM identification
			CA	wire1_write, convertT		; initiate temp conversion
			call	wire1_reset				; send a reset pulse
			CA	wire1_write, skipROM
			CA	wire1_write, readScratchpad
			call	wire1_read				; read temperature LSByte
			mov	c2,a0
			call	wire1_read				; read temperature MSByte
			mov c3,a0

			in r16, PIND
			cpi r16, 0b10111111				; clear LCD and return to Trefset if PD6 is pressed
			brne skip7
			BOUTON 6						
			call LCD_clear
			rjmp main
skip7:		cpi r16, 0b11011111				; clear LCD and return to Trefset if PD5 is pressed
			brne skip8
			BOUTON 5						
			call LCD_clear
			rjmp Trefset
skip8:		cpi r16, 0b11101111				; clear LCD and return to Trefset if PD4 is pressed
			brne skip9
			BOUTON 4						
			call LCD_clear	
			rjmp Trefset
skip9:		cpi r16, 0b11110111				; clear LCD and return to Trefset if PD3 is pressed
			brne skip10
			BOUTON 3						
			call LCD_clear
			rjmp Plageset
skip10:		cpi r16, 0b11111011				; clear LCD and go to Plageset if PD2 is pressed
			brne skip11
			BOUTON 2
			call LCD_clear
			rjmp Plageset
						
skip11:			
			ldi xl, low(Selection)
			ldi xh, high(Selection)
			ld d2,x
			sbrc d2,4
			rjmp Mode_F6
			
			PRINTF LCD
.db			"Temp =",FFRAC2+FSIGN, c+2, 4, $42, "C",LF, 0
			WAIT_MS 50
			rjmp Temp_color

Mode_F6:										; Mode_FX (selection mode Farenheit)
		
			Mode c2,c3
			PRINTF LCD
.db "Temp =",FFRAC2, b, 4, $42, "F",LF, 0
			WAIT_MS 50



Temp_color:									; fonction affichage matrice

		ldi xl, low(Tsup)
		ldi xh, high(Tsup)
		ld a1, x+
		ld a0, x
		ldi xl, low(Tinf)
		ldi xh, high(Tinf)
		ld a3, x+
		ld a2, x
		
		PUSH4 b0,b1,c0,c1					; save registers
		LDI2 b1,b0, 0x0170					; load 23 in b1 b0
		SUB2 a1,a0, a3,a2					; substract Tinf to Tsup, result stored in a1 a0
		rcall div22							; divide previous result by 23, result stored in c1 c0 (format 2 signed bytes, fix point at 4)
		MOV2 b1,b0, c1,c0					; move result to b1 b0
		PUSH4 c3,c2,c0,c1
		SUB2 c3,c2, a3,a2					; Tempeture - Tinf
		brmi Alert_blue 		
		MOV2 a1,a0, c3,c2					; move result to a1 a0
		rcall div22							; previous result/first division result
		mov d0,c0							; move result to d0 and change format
		_ANDI d0,0xf0						
		or d0,c1
		swap d0								
		POP4 b0,b1,c0,c1					; restore rgisters
		rjmp Pure_blue
cli
		
Alert_blue:
		LED_COLOR 0x00,0x00,0x0f
		WAIT_MS 300
		LED_COLOR 0x00,0x00,0x00
		rjmp main
Pure_blue:
		_CPI d0, 0							; compare d0 to various numbers, up to 22
		brne Medium_blue					; branch to next comparison if not equal
		LED_COLOR 0x00,0x00,0x0f			; pure blue							
		rjmp main
Medium_blue:
		_CPI d0, 1
		brne Dodger_blue
		LED_COLOR 0x00,0x01,0x0e				
		rjmp main
Dodger_blue:
		_CPI d0, 2
		brne Deep_sky_blue
		LED_COLOR 0x00,0x03,0x0c
		rjmp main
Deep_sky_blue:
		_CPI d0, 3
		brne Dark_turquoise
		LED_COLOR 0x00,0x05,0x0a
		rjmp main
Dark_turquoise:
		_CPI d0, 4
		brne Turquoise
		LED_COLOR 0x00,0x07,0x08
		rjmp main
Turquoise:
		_CPI d0, 5
		brne Light_turquoise	
		LED_COLOR 0x00,0x09,0x06
		rjmp main
Light_turquoise:
		_CPI d0, 6
		brne Sea_green
		LED_COLOR 0x00,0x0b,0x04
		rjmp main
Sea_green:
		_CPI d0, 7
		brne Marine
		LED_COLOR 0x01,0x0c,0x02			
		rjmp main
Marine:
		_CPI d0, 8
		brne Azure
		LED_COLOR 0x02,0x0a,0x03
		rjmp main
Azure:
		_CPI d0, 9
		brne Ghost_white	
		LED_COLOR 0x03,0x08,0x04
		rjmp main
Ghost_white:
		_CPI d0, 10
		brne White	
		LED_COLOR 0x04,0x06,0x05
		rjmp main
White:
		_CPI d0, 11
		brne Ivory
		LED_COLOR 0x05,0x05,0x05			
		rjmp main
Ivory:
		_CPI d0, 12
		brne Lemon_chiffon
		LED_COLOR 0x06,0x06,0x03
		rjmp main
Lemon_chiffon:
		_CPI d0, 13
		brne Light_yellow
		LED_COLOR 0x07,0x06,0x02
		rjmp main
Light_yellow:
		_CPI d0, 14
		brne Yellow
		LED_COLOR 0x07,0x07,0x01
		rjmp main
Yellow:
		_CPI d0, 15
		brne Gold
		LED_COLOR 0x08,0x07,0x00			
		rjmp main
Gold:
		_CPI d0, 16
		brne Dark_gold
		LED_COLOR 0x09,0x06,0x00
		rjmp main
Dark_gold:
		_CPI d0, 17
		brne Orange
		LED_COLOR 0x0a,0x05,0x00
		rjmp main
Orange:
		_CPI d0, 18
		brne Light_orange_red
		LED_COLOR 0x0b,0x04,0x00			
		rjmp main
Light_orange_red:
		_CPI d0, 19
		brne Orange_red
		LED_COLOR 0x0c,0x03,0x00	
		rjmp main
Orange_red:
		_CPI d0, 20
		brne Dark_orange_red
		LED_COLOR 0x0d,0x02,0x00
		rjmp main
Dark_orange_red:
		_CPI d0, 21
		brne Pure_red
		LED_COLOR 0x0e,0x01,0x00
		rjmp main
Pure_red:
		_CPI d0, 22
		brne Alert_red
		LED_COLOR 0x0f,0x00,0x00			
		rjmp main
Alert_red:
		LED_COLOR 0x0f,0x00,0x00
		WAIT_MS 300
		LED_COLOR 0x00,0x00,0x00
		rjmp main


ws2812b4_reset:
		cbi PORTC, 1
		WAIT_US	50 							; 50 us are required, NO smaller works
		ret					

ws2812b4_init:
		OUTI	DDRE,0x02		
		ret
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
sei

.dseg
.org 0x0100

Selection: .byte 2
Tref: .byte 2
Plage: .byte 2
Tsup: .byte 2
Tinf: .byte 2
