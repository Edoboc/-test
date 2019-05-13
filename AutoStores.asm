/*
 * IphoneXI.asm
 *
 *  Created: 15.05.2018 15:37:41
 *   Author: Loicchau & Edoboc
 */ 
 .include "def.asm"

 ; === interrupt table
.org 0
		jmp reset
.org ADCCaddr
		jmp ADDCint

; === interrupte service routines
 reset:	
			LDSP RAMEND
			OUTI DDRB,0xff
			OUTI DDRE,0xff
			OUTI ADCSR, (1<<ADEN)+(1<<ADIE)+6
			rcall LCD_init
			rcall wire1_init
			sei
			rjmp init

ADDCint:
			push w
			in w,PIND
			cpi w,0b11111110
			breq reinitiate
			pop w
			reti

reinitiate:
			ldi b0,low(openp)
			ldi b1,high(openp)
			;rcall moveservo
			rjmp reset
			

.include "lcd.asm"
.include "printf.asm"
.include "wire1.asm"


; === program start
init:
			rcall LCD_clear
			ldi b0,0b01000000	; Tref LSByte
			ldi b1,0b00000001	; Tref MSByte : Tref (initialement) = 20C
			ldi a0,0b10010000	; Tsup LSByte
			ldi a1,0b00000001	; Tsup MSByte : Tsup (initialement) = 25C
			ldi a2,0b10100000	; Tinf LSByte
			ldi a3,0b00000000	; Tinf MSByte : Table (initialement) = 15C
			ldi b2,0b10100000	; Table LSByte
			ldi b3,0b00000000	; Table MSByte : Table (initialement) = 10C
				
Trefset:	
			rcall LCD_clear
			WAIT_MS 200
			PRINTF LCD
.db "Set Tref", LF, 0
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, LF, 0

Trefinc:
			in r16, PIND
			cpi r16, 0b11101111
			_BRNE Trefdec
			INCT b0,b1,1
			INCT a0,a1,1
			INCT a2,a3,1
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, LF, 0
			WAIT_MS 200
Trefdec:
			cpi r16, 0b11110111
			_BRNE Trefnext
			DECT b0,b1,1
			DECT a0,a1,1
			DECT a2,a3,1
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, LF, 0
			WAIT_MS 200
Trefnext:
			cpi r16, 0b10111111
			brne PC+3
			rcall LCD_clear
			rjmp main	
			cpi r16, 0b11111011
			brne PC+3
			rcall LCD_clear
			rjmp Tableset
			cpi r16, 0b11111101
			brne PC+3
			rcall LCD_clear
			rjmp Tableset		
			rjmp Trefinc

Tableset:
			rcall LCD_home
			WAIT_MS 200
			PRINTF LCD
.db "Table =",FFRAC2+FSIGN, b+2, 4, $42, LF, 0
			PRINTF LCD
.db "Tinf =",FFRAC2+FSIGN, a+2, 4, $42, LF, 0


Tableinc:
			in r16, PIND
			cpi r16, 0b11111011
			_BRNE Tabledec
			INCT b2,b3,1
			INCT a0,a1,0
			DECT a2,a3,0
			PRINTF LCD
.db "Table =",FFRAC2+FSIGN, b+2, 4, $42, LF, 0
			PRINTF LCD
.db "Tinf =",FFRAC2+FSIGN, a+2, 4, $42, LF, 0
			WAIT_MS 200
Tabledec:
			cpi r16, 0b11111101
			_BRNE Tablenext
			DECT b2,b3,1
			DECT a0,a1,0
			INCT a2,a3,0
			PRINTF LCD
.db "Table =",FFRAC2+FSIGN, b+2, 4, $42, LF, 0
			PRINTF LCD
.db "Tinf =",FFRAC2+FSIGN, a+2, 4, $42, LF, 0

			WAIT_MS 200
Tablenext:
			cpi r16, 0b10111111
			brne PC+3
			rcall LCD_clear
			breq main
			cpi r16, 0b11101111
			brne PC+3
			rcall LCD_clear
			rjmp Trefset
			cpi r16, 0b11110111
			brne PC+3
			rcall LCD_clear
			rjmp Trefset		
			rjmp Tableinc


							

/*Tsupset:
			rcall LCD_home
			WAIT_MS 200
			PRINTF LCD
.db "Set Tsup", LF, 0
			PRINTF LCD
.db "Tsup =",FFRAC2+FSIGN, a+2, 4, $42, LF, 0

Tsupinc:
			in r16, PIND
			cpi r16, 0b11101111
			brne Tsupdec
			INCT a2,a3
			PRINTF LCD
.db "Tsup =",FFRAC2+FSIGN, a+2, 4, $42, LF, 0
			WAIT_MS 200
Tsupdec:
			cpi r16, 0b11110111
			brne Tsupnext
			DECTsup a2,a3,a0,a1
			PRINTF LCD
.db "Tsup =",FFRAC2+FSIGN, a+2, 4, $42, LF, 0
			WAIT_MS 200
Tsupnext:
			cpi r16, 0b10111111
			brne PC+3
			rcall LCD_clear
			breq Tinfset	
			rjmp Tsupinc

Tinfset:
			rcall LCD_home
			WAIT_MS 200
			PRINTF LCD
.db "Set Tinf", LF, 0
			PRINTF LCD
.db "Tinf =",FFRAC2+FSIGN, b, 4, $42, LF, 0

Tinfinc :
			in r16, PIND
			cpi r16, 0b11101111
			brne Tinfdec
			INCTinf b0,b1,a0,a1
			PRINTF LCD
.db "Tinf =", FFRAC2+FSIGN, b, 4, $42, LF, 0
			WAIT_MS 200
Tinfdec:
			cpi r16, 0b11110111
			brne Tinfnext
			DECT b0,b1
			PRINTF LCD
.db "Tinf =", FFRAC2+FSIGN, b, 4, $42, LF, 0
			WAIT_MS 200
Tinfnext:
			cpi r16, 0b10111111
			brne PC+3
			rcall LCD_clear
			breq main
			rjmp Tinfinc*/

main:
			WAIT_MS 200
			
			push a0
			rcall	lcd_home			; place cursor to home position

			rcall	wire1_reset			; send a reset pulse
			CA	wire1_write, skipROM	; skip ROM identification
			CA	wire1_write, convertT	; initiate temp conversion
			rcall	wire1_reset			; send a reset pulse
			CA	wire1_write, skipROM
			CA	wire1_write, readScratchpad
		
			rcall	wire1_read			; read temperature LSByte
			mov	c0,a0
			rcall	wire1_read			; read temperature MSByte
			mov c1,a0
			pop a0
			
			PRINTF	LCD
.db	"Temp=",FFRAC2+FSIGN,c,4,$42,"C",LF,0
			
			
			in r16,PIND
			cpi r16,0b11111110
			brne PC+2
			rjmp reinitiate
			cpi r16,0b11101111
			brne PC+3
			rcall LCD_clear
			rjmp Trefset
			cpi r16,0b11110111
			brne PC+3
			rcall LCD_clear
			rjmp Trefset
			cpi r16,0b11111011
			brne PC+3
			rcall LCD_clear
			rjmp Tableset
			cpi r16,0b11111101
			brne PC+3
			rcall LCD_clear
			rjmp Tableset
			rjmp main
							
			/*cpi r16,0b10111111
			brne notog
			TOGGLEBIT r17,0b1
notog:
			sbrs r17,0
			rjmp manuel*/
auto:	
			PRINTF LCD
.db "     Automatique",CR,0
			/*CP2 a1,a0,c1,c0			; Compare T avec Tsup, si T < Tsup : ne rentre pas dans pre_servo
			brge nothot
			ldi b0,low(closep)
			ldi b1,high(closep)
			rjmp pre_servo
nothot:		CP2 a3,a2,c1,c0			; Compare Tinf avec T, si Tinf < T : ne rentre pas dans pre-servo
			brlt notcold
			ldi b0,low(closep)
			ldi b1,high(closep)
			rjmp pre_servo
notcold:	ldi b0,low(openp)
			ldi b1,high(openp)
			rjmp pre_servo*/
			rjmp main

		
manuel:
			/*PRINTF LCD
.db "          Manuel",CR,0
			in r16,PIND
			cpi r16,0b11101111
			brne PC+4
			ldi b0,low(closep)
			ldi b1,high(closep)
			rjmp pre_servo
			cpi r16,0b11011111
			brne PC+4
			ldi b0,low(openp)
			ldi b1,high(openp)
			rjmp pre_servo
			rjmp main
		

pre_servo:
baisser:	cpi b1,high(closep)			; Si pulseh = high(closep), pre_servo doit baisser les stores [closep], sinon pre_servo doit les monter [openp]
			brne monter
			bst r17,1					; Store r17(1) dans T
			brts return					; Si r17(1) = 1, les stores sont déjà baissés : retour à main
			rcall moveservo
			sbr r17,0b10
			rjmp return
monter :	bst r17,1					; Store r17(1) dans T
			brtc return					; Si r17(1) = 0, les stores sont déjà ouverts : retour à main
			rcall moveservo
			cbr r17,0b10
return:		rjmp main

moveservo:
			WAIT_MS	10
			
			OUTI ADMUX,3				
			sbi ADCSR, ADSC
			WP1 ADCSR, ADSC
			in c2,ADCL					; LSByte distance
			in c3,ADCH					; MSByte distance
			
			ldi b2,low(proche)
			ldi b3,high(proche)
			CP2 c3,c2,b3,b2
			brge stop					; Stores stop
			
			mov b2,b0					
			mov b3,b1
			P1	PORTE,SERVO1			; pin=1	
pulse:		DEC2	b3,b2
			brne	pulse
			P0	PORTE,SERVO1			; pin=0
			rjmp moveservo
stop:		ret*/
