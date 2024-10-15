;
; sandbox_m88pa.asm
;
; Created: 11.10.2024 21:53:36
; Author : inflamer
;

;.equ DBG = 1  ;comment before flash

.equ LC_pwroff = 0x20
.equ LC_pwron = 0x2F
.equ LC_nallon_dis = 0xA4 ;normal display
.equ LC_allon_dis = 0xA5 ;all segments disabled ?standby mode
.equ LC_nor_dis = 0xA6 ;normal display
.equ LC_inv_dis = 0xA7 ;inverted display
.equ LC_nfillall_dis = 0xAE ;display ram
.equ LC_fillall_dis = 0xAF ;hide ram


	;Установка линии начала сканирования 0 1 S5 S4 S3 S2 S1 S0 
	;Установка линии начала сканирования S:0?Y?63

	;=== set start scan number S:0?Y?63 shift dram LCD
	;ldi tmpregl,0 //load position
	;andi tmpregl,0x3F
	;ori tmpregl,0x40 ; y2..0 (0..7)
	;inc TXCount
	;rcall SPI_TX_cmd



.equ DDR_SPI = DDRB
.equ P_SS = PB2
.equ P_MOSI = PB3
.equ P_MISO = PB4
.equ P_SCK = PB5

.equ P_LCD_RES = PD7



.def zeroreg = r2
.def spenreg = r3
.def TXCount = r4
.def TXZCount = r5
.def tmpZl = r6
.def tmpZh = r7
.def TXC_ptrl = r8
.def TXC_ptrh = r9
.def TXXpos = r10
.def TXYpos = r11
.def TXRowCount = r12
.def TXCountDupl = r13


.def tmpregl = r16
.def tmpregh = r17 

; probably use r24,r25 as function operands such as input variables
.def varregl = r24
.def varregh = r25





.macro loadTXdata
; @0 - data address ex: LCD_init, 
; @1 transmit data or command (SPI_TX_cmd/SPI_TX_data), 
; @2 - tmpreg
	
	clr TXZCount
	ldi Zl,low(@0*2)
	ldi Zh,high(@0*2)
	lpm @2,Z+
	mov TXCount,@2
	mov TXCountdupl,TXCount
	lpm @2,Z+
	mov TXRowCount,@2
	lpm @2,Z+
	cpse @2,zeroreg
	rjmp mnz
	lpm TXZCount,Z+
	mnz:
	movw tmpZl,Zl
	rcall @1


.endmacro

.macro LCD_gotoXY 
;@0 - X (integers) 
;@1 - Y (integer)
	ldi tmpregl,@0
	mov TXXpos, tmpregl
	ldi tmpregl,0
	mov TXYpos, tmpregl
	rcall Goto_XY_LCD
.endmacro

.macro LCD_incY
	inc TXYpos
	rcall Goto_XY_LCD
.endmacro

;.CSEG
;.ORG $0000

	rjmp	reset				;rjmp RESET ; Reset Handler
		reti ;rjmp EXT_INT0 ; IRQ0 Handler
		reti ;rjmp	INT_Shelchok		;rjmp EXT_INT1 ; IRQ1 Handler
		reti ;rjmp PCINT0 ; PCINT0 Handler
		reti ;rjmp PCINT1 ; PCINT1 Handler
		reti ;rjmp PCINT2 ; PCINT2 Handler
		reti ;rjmp WDT ; Watchdog Timer Handler
		reti ;rjmp buzz_switch ;rjmp TIM2_COMPA ; Timer2 Compare A Handler
		reti ;rjmp TIM2_COMPB ; Timer2 Compare B Handler
		reti ;rjmp	buzz_beep			;rjmp TIM2_OVF ; Timer2 Overflow Handler
		reti ;rjmp TIM1_CAPT ; Timer1 Capture Handler
		reti ;rjmp TIM1_COMPA ; Timer1 Compare A Handler
		reti ;rjmp	Dergati_IRF840		;rjmp TIM1_COMPB ; Timer1 Compare B Handler
		reti ;rjmp TIM1_OVF ; Timer1 Overflow Handler
		reti ;rjmp TIM0_COMPA ; Timer0 Compare A Handler
		reti ;rjmp TIM0_COMPB ; Timer0 Compare B Handler
		reti ;rjmp TIM0_OVF ; Timer0 Overflow Handler
		reti ;rjmp SPI_STC ; SPI Transfer Complete Handler
		reti ;rjmp USART_RXC ; USART, RX Complete Handler
		reti ;rjmp USART_UDRE ; USART, UDR Empty Handler
		reti ;rjmp USART_TXC ; USART, TX Complete Handler
		reti ;rjmp ADC ; ADC Conversion Complete Handler
		reti ;rjmp EE_RDY ; EEPROM Ready Handler
		reti ;rjmp ANA_COMP ; Analog Comparator Handler
		reti ;rjmp TWI ; 2-wire Serial Interface Handler
		reti ;rjmp SPM_RDY ; Store Program Memory Ready Handler



reset:
/*stackpointer init*/
	clr r0
	out SREG,r0

	ldi		tmpregl, low(RAMEND)
	out		SPL, tmpregl
	ldi		tmpregl, high(RAMEND)
	out		SPH, tmpregl

	;sei
	
	;=init predefined registers
	clr zeroreg
	ldi r16,(1<<MSTR)|(1<<SPE)
	mov spenreg, tmpregl
	
	ldi Zl,low(wait_TX_complete)
	ldi Zh,high(wait_TX_complete)
	movw TXC_ptrl,Zl


	;--------------------------
	;=GPIO init
	ldi tmpregl, (1<<P_LCD_RES)
	out DDRD,tmpregl
	sbi PORTD, P_LCD_RES
	cbi PORTD, P_LCD_RES

	;delay for LCD reset must be implemented 2500ns pull low, 2500ns after reset
	; 10 - 100ms hx1230 recomendation 

	;=SPI init
	ldi tmpregl, (1<<P_SS)|(1<<P_SCK)|(1<<P_MOSI)
	out DDR_SPI,tmpregl
	cbi DDR_SPI,P_MISO

	sbi PORTD,P_LCD_RES

	;ldi r16,(1<<MSTR)|(1<<SPE);|(1<<SPR0)
	;out SPCR, spenreg

	in tmpregl, SPSR
	ori tmpregl, (1<<SPI2x)
	out SPSR, tmpregl
	;--------------------------------
	;======= delays temporary disabled
	.ifndef DBG
	cbi		PORTD,DDD7			; к земле RES
	rcall	pause_10ms ;100ms
	;rcall	pause_100ms ;uncomment if 10ms is unstable
	sbi		PORTD,DDD7			; подтяжка RES
	rcall	pause_10ms	//delay 2500ns
	.endif




	loadTXdata LCD_init,SPI_TX_cmd,tmpregl			;macro to preload data from pointer to tmp register
	
	;== clear screen loop 9 lines

	ldi tmpregl, 9
	clr_scr:
	push tmpregl
	loadTXdata LCD_nop,SPI_TX_data,r16
	pop tmpregl
	dec tmpregl
	brne clr_scr
	;-------------------------------


	LCD_gotoXY 20,3
	loadTXdata Strelka,SPI_TX_data,r16

	LCD_incY
	loadTXdata Strelka1,SPI_TX_data,r16


	loop:

	rjmp loop




	; Pepare SPI data
	SPI_prep:
		clr TXZCount
		;ldi Zl,low(@0*2)
		;ldi Zh,high(@0*2)
		;lpm @2,Z+
		;mov TXCount,@2
		;mov TXCountdupl,TXCount
		;lpm @2,Z+
		;mov TXRowCount,@2
		;lpm @2,Z+
		;cpse @2,zeroreg
		;rjmp mnz
		;lpm TXZCount,Z+
		mnz:
		movw tmpZl,Zl
		;rcall @1
	ret


	; SPI_Transmit reassembly as function using r16 as data to transmit
	SPI_TX_cmd:
	cbi PORTB,P_MOSI
	rjmp SPI_TX
	SPI_TX_data:
	sbi PORTB,P_MOSI
	SPI_TX:

	out SPCR, zeroreg		;disable hardware SPI
	sbi PORTB, P_SCK		;pull up SCK to send D/C SPI signal
	out SPCR, spenreg		;enable hardware SPI
	out SPDR,r16			;starting transfer
	cbi PORTB, P_SCK		;release SCK, after start to reduce cpu cycles

	;we can prepare new data here
	dec TXCount
	breq wait_TX_complete

		movw Zl,tmpZl
		
		cpi r16, 0
		breq no_load
		lpm r16, Z+
		cpi r16, 0
		brne transmit
		lpm TXZCount,Z+
		;inc TXZCount
		rjmp transmit

		no_load:
		dec TXZCount
		brne transmit 
		lpm r16,Z+
		transmit:
		
		movw tmpZl,Zl 

	;ldi Zl,low(wait_TX_complete)
	;ldi Zh,high(wait_TX_complete)
	movw Zl,TXC_ptrl
	icall
	rjmp SPI_TX 
	

	;=================
	wait_TX_complete:
	in r0, SPSR
	sbrs r0,SPIF
	rjmp wait_TX_complete
	ret

	;=================
	Goto_XY_LCD:
	;.def TXXpos = r10
	;.def TXYpos = r11

	;=== set x position 0..95
	;=== low 4 bits
	;load position
	mov tmpregl, TXXpos
	andi tmpregl, 0x0F
	inc TXCount
	rcall SPI_TX_cmd
	;=== high 3 bits
	mov tmpregl, TXXpos
	swap tmpregl
	andi tmpregl, 0x07
	ori tmpregl,0x10
	inc TXCount
	rcall SPI_TX_cmd

		;=== set y position 0..7
	mov tmpregl,TXYpos //load position
	andi tmpregl,0x07
	ori tmpregl,0xB0 ; y2..0 (0..7)
	inc TXCount
	rcall SPI_TX_cmd 

	ret



	;------------------задержка ~0,01 сек------------------

pause_100ms:
	ldi		r23, 10
	rjmp	pause

pause_10ms:
	ldi		r23, 1
	rjmp	pause

pause_1ms:
	push	r24
	push	r25
	ldi		r23, 1
	ldi		r24, low(1000)
	ldi		r25, high(1000)
	rjmp	cikl_pause_t

pause:
	push	r24
	push	r25
cikl_pause_10ms:
	ldi		r24, low(2500)
	ldi		r25, high(2500)
cikl_pause_t:
	sbiw	r24, 1
	brne	cikl_pause_t
	dec		r23
	brne	cikl_pause_10ms
	pop		r25
	pop		r24
	ret


.CSEG
LCD_init:
.db 4,0, LC_nallon_dis,LC_fillall_dis,LC_nor_dis,LC_pwron;5

LCD_data:
.db 8,0, 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ;9

LCD_nop:
.db 96,4, 0, 96 ;96

LCD_full:
.db 5,0, 0x55,0xAA,0x55,0xAA,0x55,0xAA,0x55,0xAA,0x55,0xAA,0x55,0xAA,0x55,0xAA,0x55,0xAA,0x55,0xAA,0x55,0xAA


LCD_prim:
.db 8,0, 0xFF,0x00,1,0xFF,0x00,4,0xFF,0xFF,0xFF,0xFF

Strelka:
.db 4, 2 
.db 0x00, 1, 0x80, 0xC0, 0xE0
Strelka1:
.db 4, 2
.db 0x01, 0x03, 0x07, 0x0F
