/*
 * Capteurthermo.asm
 *
 *  Created: 15.05.2018 15:37:41
 *   Author: Loïc
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
			call ws2812b4_init
			call ws2812b4_reset		 
			rcall LCD_init
			rcall wire1_init
			sei
			rjmp init

ADDCint:
			push w
			in w,PIND
			cpi w,0b11111110
			breq reset
			pop w
			reti
		

.include "lcd.asm"
.include "printf.asm"
.include "wire1.asm"
.include "math.asm"

; === program start
init:
			rcall LCD_clear
			ldi b0,0b10010000	; Tref LSByte
			ldi b1,0b00000001	; Tref MSByte : Tref (initialement) = 25C
			ldi a0,0b00110000	; Tsup LSByte
			ldi a1,0b00000010	; Tsup MSByte : Tsup (initialement) = 35C
			ldi a2,0b11110000	; Tinf LSByte
			ldi a3,0b00000000	; Tinf MSByte : Tinf (initialement) = 15C
			ldi b2,0b01000000	; Table LSByte
			ldi b3,0b00000001	; Table MSByte : Table (initialement) = 20C

Trefset:	
			rcall LCD_clear
			WAIT_MS 200
			PRINTF LCD
.db "Set Tref", LF, 0
			PRINTF LCD
.db "Tref =",FFRAC2+FSIGN, b, 4, $42, LF, 0
			LED_COLOR 0x05,0x05,0x05

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

main:
			/*LDSP RAMEND
			OUTI DDRB,0xff
			OUTI DDRE,0xff
			OUTI ADCSR, (1<<ADEN)+(1<<ADIE)+6*/
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
			mov	c2,a0
			rcall	wire1_read			; read temperature MSByte
			mov c3,a0
			pop a0
			
			PRINTF	LCD
.db	"Temp=",FFRAC2+FSIGN,c+2,4,$42,"C",LF,0
			

			in r16,PIND
			cpi r16,0b11111110
			brne PC+2
			rjmp reset
			cpi r16,0b10111111
			brne PC+2
			rjmp Trefset				

Temp_color:	
		PUSH4 a0,a1,a2,a3
		PUSH4 b0,b1,c0,c1
		LDI2 b1,b0, 0x0170
		SUB2 a1,a0, a3,a2
		rcall div22
		MOV2 b1,b0, c1,c0
		SUB2 c3,c2, a3,a2
		MOV2 a1,a0, c3,c2
		rcall div22
		mov d0,c0
		_ANDI d0,0xf0
		or d0,c1
		swap d0
		POP4 b0,b1,c0,c1
		POP4 a0,a1,a2,a3
		_CPI d0, 0
		brne PC+20
		LED_COLOR 0x00,0x00,0x0f	;pure blue							
		rjmp main
		_CPI d0, 1
		brne PC+20
		LED_COLOR 0x00,0x01,0x0e				
		rjmp main
		_CPI d0, 2
		brne PC+20
		LED_COLOR 0x00,0x03,0x0c
		rjmp main
		_CPI d0, 3
		brne PC+20
		LED_COLOR 0x00,0x05,0x0a
		rjmp main
		_CPI d0, 4
		brne PC+20
		LED_COLOR 0x00,0x07,0x08
		rjmp main
		_CPI d0, 5
		brne PC+20	
		LED_COLOR 0x00,0x09,0x06
		rjmp main
		_CPI d0, 6
		brne PC+20
		LED_COLOR 0x00,0x0b,0x04
		rjmp main
		_CPI d0, 7
		brne PC+20
		LED_COLOR 0x01,0x0c,0x02	;green-ish
		rjmp main
		_CPI d0, 8
		brne PC+20
		LED_COLOR 0x02,0x0a,0x03
		rjmp main
		_CPI d0, 9
		brne PC+20	
		LED_COLOR 0x03,0x08,0x04
		rjmp main
		_CPI d0, 10
		brne PC+20	
		LED_COLOR 0x04,0x06,0x05
		rjmp main
		_CPI d0, 11
		brne PC+20
		LED_COLOR 0x05,0x05,0x05	;pure white
		rjmp main
		_CPI d0, 12
		brne PC+20
		LED_COLOR 0x06,0x06,0x03
		rjmp main
		_CPI d0, 13
		brne PC+20
		LED_COLOR 0x07,0x06,0x02
		rjmp main
		_CPI d0, 14
		brne PC+20
		LED_COLOR 0x07,0x07,0x01
		rjmp main
		_CPI d0, 15
		brne PC+20
		LED_COLOR 0x08,0x07,0x00	;yellow
		rjmp main
		_CPI d0, 16
		brne PC+20
		LED_COLOR 0x09,0x06,0x00
		rjmp main
		_CPI d0, 17
		brne PC+20
		LED_COLOR 0x0a,0x05,0x00
		rjmp main
		_CPI d0, 18
		brne PC+20
		LED_COLOR 0x0b,0x04,0x00	;orange
		rjmp main
		_CPI d0, 19
		brne PC+20
		LED_COLOR 0x0c,0x03,0x00	
		rjmp main
		_CPI d0, 20
		brne PC+20
		LED_COLOR 0x0d,0x02,0x00
		rjmp main
		_CPI d0, 21
		brne PC+20
		LED_COLOR 0x0e,0x01,0x00
		rjmp main
		LED_COLOR 0x0f,0x00,0x00	;pure red
		rjmp main

ws2812b4_reset:
		cbi PORTE, 1
		WAIT_US	50 	; 50 us are required, NO smaller works
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