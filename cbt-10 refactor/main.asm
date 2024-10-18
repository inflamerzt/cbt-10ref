;
; sandbox_m88pa.asm
;
; Created: 11.10.2024 21:53:36
; Author : inflamer
;

;.equ DBG = 1  ;comment before flash

.include "def.inc"
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

	ldi		tmpreg, low(RAMEND)
	out		SPL, tmpreg
	ldi		tmpreg, high(RAMEND)
	out		SPH, tmpreg

	;sei
	
	;=init predefined registers
	clr zeroreg
	ldi r16,(1<<MSTR)|(1<<SPE)
	mov spenreg, tmpreg
	
	ldi Zl,low(wait_TX_complete)
	ldi Zh,high(wait_TX_complete)
	movw TXC_ptrl,Zl


	;--------------------------
	;=GPIO init
	ldi tmpreg, (1<<P_LCD_RES)
	out DDRD,tmpreg
	sbi PORTD, P_LCD_RES
	cbi PORTD, P_LCD_RES

	;delay for LCD reset must be implemented 2500ns pull low, 2500ns after reset
	; 10 - 100ms hx1230 recomendation 

	;=SPI init
	ldi tmpreg, (1<<P_SS)|(1<<P_SCK)|(1<<P_MOSI)
	out DDR_SPI,tmpreg
	cbi DDR_SPI,P_MISO

	sbi PORTD,P_LCD_RES

	;ldi r16,(1<<MSTR)|(1<<SPE);|(1<<SPR0)
	;out SPCR, spenreg

	in tmpreg, SPSR
	ori tmpreg, (1<<SPI2x)
	out SPSR, tmpreg
	;--------------------------------
	;======= delays temporary disabled
	.ifndef DBG
	cbi		PORTD,DDD7			; к земле RES
	rcall	pause_10ms ;100ms
	;rcall	pause_100ms ;uncomment if 10ms is unstable
	sbi		PORTD,DDD7			; подтяжка RES
	rcall	pause_10ms	//delay 2500ns
	.endif


	LCD_cmd LCD_init
	

	;== clear screen loop 9 lines
	LCD_XY 0,0
	;ldi tmpreg, 5
	;sbi PORTB,P_MOSI
	;clr_scr:
	;push tmpreg
	
	;LCD_dat LCD_clr
	LCD_dat LCD_clrline
	LCD_dat LCD_clrline
	LCD_dat LCD_clrline
	LCD_dat LCD_clrline
	LCD_dat LCD_clrline
	LCD_dat LCD_clrline
	LCD_dat LCD_clrline
	LCD_dat LCD_clrline
	LCD_dat LCD_clrline
	;pop tmpreg
	;dec tmpreg
	;brne clr_scr
	/*
	LCD_XY 0,0
	LCD_dat MINI_CIFRA_0
	LCD_dat MINI_CIFRA_0


	LCD_XY 0,1
	LCD_dat CIFRA_8
	LCD_XY 8,1
	LCD_dat ZAPITAY
	LCD_XY 10,1
	LCD_dat CIFRA_0
	*/
	/*
	LCD_XY 30,0
	LCD_dat Pattern

	
	LCD_XY 20,8
	LCD_dat Pattern1
	
	LCD_XY 30,7
	LCD_dat Pattern3
	

	LCD_XY 0,5
	LCD_dat Pattern4
	;LCD_dat Pattern4
	;LCD_dat Pattern4
	*/
	;===========================================
	;test here
	;===========================================
	
	LCD_XY 0,0
	.include "test.inc"

	;===========================================

	loop:
	nop
	rjmp loop
/*
	unpack_zeroes:
		cpi arg, 0
		breq no_load
		lpm arg, Z+
		cpi arg, 0
		brne transmit
		lpm TXZCount,Z+
		rjmp transmit

		no_load:
		dec TXZCount
		brne transmit 
		lpm arg,Z+
		transmit:
	ret
	*/

	; Pepare SPI data
	SPI_start:
		clr TXZCount
		lpm TXCount,Z+
		lpm TXRowCount,Z+
		SPI_start_defined: ; if TXCount,TXRowCount preloaded possible reduce size
		lpm arg,Z+
		;rcall unpack_zeroes
		cp arg,zeroreg
		brne SPSnz
		lpm TXZCount,Z+
		SPSnz:

		cp TXRowCount,zeroreg
		breq SPI_TX
		;IF not save parameters to memory
		sts TXCountMem, TXCount
		sts TXRowCountMem, TXRowCount
	
		
	SPI_rstart:
		dec TXRowCount
		cp TXRowCount,zeroreg
		breq SPI_TX		
		rcall SPI_TX
		inc TXYpos
		rcall LCD_goto_XY
		sbi PORTB,P_MOSI
		lds TXCount, TXCountMem
		
		;if arg != 0
		;cpi arg,0   ;zero check
		;breq zero_arg ;zero check
		cp TXZCount, zeroreg
		brne SPrS_nz
		lpm arg,Z+
		cp arg, zeroreg
		brne SPI_rstart

		lpm TXZCount,Z+
		rjmp SPI_rstart		
		SPrS_nz:
		dec TXZCount		
		rjmp SPI_rstart


		
	SPI_TX:

	out SPCR, zeroreg		;disable hardware SPI
	sbi PORTB, P_SCK		;pull up SCK to send D/C SPI signal
	out SPCR, spenreg		;enable hardware SPI
	out SPDR,arg			;starting transfer
	cbi PORTB, P_SCK		;release SCK, after start to reduce cpu cycles

	;we can prepare new data here
	dec TXCount
	breq wait_TX_complete
	;=========================

	;rcall unpack_zeroes
		cpi arg, 0
		breq no_load
		lpm arg, Z+
		cpi arg, 0
		brne transmit
		lpm TXZCount,Z+
		rjmp transmit

		no_load:
		dec TXZCount
		brne transmit 
		lpm arg,Z+
		transmit:


	;lpm arg,Z+
	
	wait_TX_complete:
	in tmpreg, SPSR
	sbrs tmpreg,SPIF
	rjmp wait_TX_complete
	cp TXCount, zeroreg
	brne SPI_TX
	ret


	;=================

	;=================
	LCD_goto_XY:
	;.def TXXpos = r10
	;.def TXYpos = r11

	;=== set 
	;=== low 4 bits
	;load position
	push arg
	push TXRowCount
	clr TXRowCount
	cbi PORTB,P_MOSI
	mov arg, TXXpos
	andi arg, 0x0F
	inc TXCount
	rcall SPI_TX
	;=== high 3 bits
	mov arg, TXXpos
	swap arg
	andi arg, 0x0F
	ori arg,0x10
	inc TXCount
	rcall SPI_TX

	;=== set 
	mov arg,TXYpos //load position
	ori arg,0xB0 ; y2..0 (0..7)
	inc TXCount
	rcall SPI_TX
	pop TXRowCount
	pop arg
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

;==== PROGRAM FLASH MEMORY DATA SEGMENT =======================================
.CSEG
LCD_init:
.db 4,0, LC_nallon_dis,LC_pwron,LC_fillall_dis,LC_nor_dis;5

Pattern:
.db 4, 4
.db 0x01,0x03,0x7,0x0F,0x1F,0x3F,0x7F,0xFF,0x03,0x0F,0x3F,0xFF,0x03,0x0F,0x3F,0xFF
.db 0xFF,0xFF,0xFF,0xFF
/*
Pattern1:
.db 5, 4
.db 0x03,0x00,0x03,0xFF
.db 0x03,0x00,0x03,0xFF
.db 0x03,0x00,0x03,0xFF
.db 0x03,0x00,0x03,0xFF
.db 0xFF,0xFF,0xFF,0xFF

Pattern2:
.db 5, 4
.db 0x00,0x03,0xFF,0x03
.db 0x00,0x03,0xFF,0x03
.db 0x00,0x03,0xFF,0x03
.db 0x00,0x03,0xFF,0x03
.db 0xFF,0xFF,0xFF,0x03

Pattern3:
.db 5,3
.db 0xFF,0xFF ,0x00, 11, 0xFF,0xFF 

Pattern4:
.db 96,3
.db 0x00, 93, 0xFF, 0x00, 96, 0xFF,0x00, 96, 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
*/

LCD_sp:
.db 1,0
.db 0x00,1, 0xFF,0xFF; 96 ;96

LCD_clrline:
.db 96,0, 0x00,192

LCD_clr:
.db 96,8
.db 0x00, 192, 0x00, 192, 0x00, 192, 0x00, 192, 0x00, 192, 0xFF,0xFF; 96 ;96

.include "data_fm.inc"

;==== RAM MEMORY DATA SEGMENT ======================================================================
.DSEG 
TXCountMem: .byte 1 
TXRowCountMem: .byte 1 