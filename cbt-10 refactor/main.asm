;
; sandbox_m88pa.asm
;
; Created: 11.10.2024 21:53:36
; Author : inflamer
;

;.equ DBG = 1  ;comment before flash

.include "def.inc"

reset:
/*stackpointer init*/
	clr r0
	out SREG,r0

	ldi		tmpreg, low(RAMEND)
	out		SPL, tmpreg
	ldi		tmpreg, high(RAMEND)
	out		SPH, tmpreg


	; set clock frequency 1 MHz
	;ldi		r24, 0b10000000
	;ldi		r25, 0b00000011		; Clock Division Factor = 8	F = 1 MHz
	;sts		CLKPR, r24
	;sts		CLKPR, r25
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
	
	;===== enable timer0 and configure pwm
	ldi tmpreg, (1<<CS00)
	out TCCR0B,tmpreg
	
	sbi DDRD, PD5 ; set compare output pin as out

	ldi tmpreg,0x1F 
	out OCR0B,tmpreg

	ldi tmpreg, (2<<COM0B0)|(3<<WGM00)
	out TCCR0A, tmpreg



	;======= delays temporary disabled
	.ifndef DBG
	cbi		PORTD,DDD7			; к земле RES
	
	;======= here is time space to do something until display resets
	;
	;
	
	rcall	pause_10ms ;100ms
	rcall	pause_100ms ;uncomment if 10ms is unstable
	sbi		PORTD,DDD7			; подтяжка RES
	rcall	pause_10ms	//delay 2500ns
	
	;======= here is time space to do something until display resets
	;
	;

	.endif


	LCD_cmd LCD_init
	
	/*
	;set ;- inverse display
	clt ;- normal display
	bld controlreg, inv_dis
	*/

	LCD_norm

	LCD_XY 0,0
	LCD_dat LCD_clr



	
	;===========================================
	;test here
	;===========================================
	
	/*
	;set ;- inverse display
	clt ;- normal display
	bld controlreg, inv_dis
	*/
	LCD_norm
	;LCD_inv
	
	
	LCD_XY 0,0
	;.include "digits.inc"
	;.include "big_digits.inc"
	;LCD_dat RAD_BIG
	;LCD_dat RAD_0
	;LCD_dat RAD_1
	;LCD_dat RAD_2
	;LCD_dat RAD_3
	;LCD_dat RODGER
	;LCD_XY 0,4
	;LCD_dat RODGER_inv
	;LCD_dat pausa
	;LCD_dat plav
	;LCD_dat summa
	;LCD_dat cps
	;LCD_dat mkrh
	;------------LCD_dat batter
	LCD_dat batter_cap
	LCD_dat batter_nofill
	LCD_dat batter_fill
	LCD_dat batter_nofill
	LCD_dat batter_fill
	LCD_dat batter_nofill
	LCD_dat batter_fill
	LCD_dat batter_nofill
	LCD_dat batter_fill
	LCD_dat batter_bcap
	;LCD_dat Timer
	;LCD_dat Alfa  
	;LCD_dat  beta
	;LCD_dat gamma
	;LCD_dat summa_ravno
	;LCD_dat result
	;LCD_dat rc
	;LCD_dat grom_shek
	;LCD_dat zvuk_opov ; not displays correctly
	;LCD_dat fon_porog
	;LCD_dat podsvetka ; not displays correctly
	;LCD_dat vkl
	;LCD_dat vblkl
	;LCD_dat mkr
	;LCD_dat minus
	;LCD_dat plus
	;LCD_dat nastroiki_datchika ; needs to be reformated (pack data)
	;LCD_dat strelka






	;===========================================

	loop:
	nop
	rjmp loop


	; Pepare SPI data
	SPI_start:
		lpm TXCount,Z+
		lpm TXRowCount,Z+
		SPI_start_defined: ; if TXCount,TXRowCount preloaded possible reduce size
		clr TXZCount
		lpm arg,Z+

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
		
		
		cp TXZCount, zeroreg
		breq argnz
		dec TXZCount
		breq argnz
		rjmp SPrS_nz

		argnz:
		lpm arg,Z+
		cp arg, zeroreg
		brne SPI_rstart

		lpm TXZCount,Z+
		rjmp SPI_rstart		
		SPrS_nz:
	
		rjmp SPI_rstart


		
	SPI_TX:

	out SPCR, zeroreg		;disable hardware SPI
	sbi PORTB, P_SCK		;pull up SCK to send D/C SPI signal
	out SPCR, spenreg		;enable hardware SPI
	
	sbis PORTB,P_MOSI
	rjmp no_inv
	bst controlreg,inv_dis
	brtc no_inv
	mov tmpreg,arg
	com tmpreg 
	out SPDR,tmpreg ;starting transfer
	rjmp inv_end			

	no_inv:
	out SPDR,arg			;starting transfer
	inv_end:
	cbi PORTB, P_SCK		;release SCK, after start to reduce cpu cycles

	;we can prepare new data here
	dec TXCount
	breq wait_TX_complete
	;=========================

		cpi arg, 0
		breq no_load
		lpm arg, Z+
		cpi arg, 0
		brne transmit
		lpm TXZCount,Z+
		rjmp transmit

		no_load:
		cp TXZCount, zeroreg
		breq preload

		dec TXZCount
		brne transmit 
		preload:
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

	;=== set X
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

	;=== set Y
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
.db 5,0, LC_nallon_dis,LC_pwron,LC_fillall_dis,LC_nor_dis, LC_nrev_dis, 0xFF;5

LCD_sp:
.db 1,0
.db 0x00,1, 0xFF,0xFF; 96 ;96

LCD_clrline:
.db 96,0, 0x00,192

LCD_clr:
.db 96,9
.db 0x00, 192, 0x00, 192, 0x00, 192, 0x00, 192, 0x00, 192, 0x00,192; 96 ;96
;------------- !!!!!!!!!!!!!!!!!!!       need to test with pattern below:
.db 0x00, 255, 0x00, 255, 0x00, 255, 0x00, 255

Pattern:
.db 4, 4
.db 0x01,0x03,0x7,0x0F,0x1F,0x3F,0x7F,0xFF,0x03,0x0F,0x3F,0xFF,0x03,0x0F,0x3F,0xFF
.db 0xFF,0xFF,0xFF,0xFF

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

Pattern5:
.db 4,2
.db 0xFF,0xFF,0x00,2
.db 0xff,0xff,0xff,0xff
.db 0xff,0xff,0x00,2

.include "data.inc"


;==== RAM MEMORY DATA SEGMENT ======================================================================
.DSEG 
TXCountMem: .byte 1 
TXRowCountMem: .byte 1 