;
; sandbox_m88pa.asm
;
; Created: 11.10.2024 21:53:36
; Author : inflamer
;


;Booster timings
;Charge Capacitor 20uS
; test conditions 500Hz


;.equ DBG = 1  ;comment before flash

.include "def.inc"

.include "int.inc"

reset:
/*stackpointer init*/
	cli
	clr r0
	out SREG,r0

	clr tmpcount

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
	ldi tmpreg, (1<<P_LCD_RES)|(1<<P_bDiode)|(1<<P_bCap)|(1<<P_bTrans)|(1<<PD6)
	out DDRD,tmpreg
	sbi PORTD, P_LCD_RES
	cbi PORTD, P_LCD_RES

	out DDRC, zeroreg

	
	
	;----------------- remove this string with booster enabled
	sbi PORTC, P_boostFB ; enable internal pullup for test only
	


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

	ldi tmpreg,0xEF 
	out OCR0B,tmpreg

	ldi tmpreg, (2<<COM0B0)|(3<<WGM00) ; (3<<COM0B0) if out must be inverted
	out TCCR0A, tmpreg

	;===== enable timer1 and configure interrupts
	
	ldi tmpregh, high(DCBoost_period)
	ldi tmpreg, low(DCBoost_period)
	sts OCR1AH, tmpregh
	sts OCR1AL, tmpreg


	ldi tmpregh, high(DCBoost_period-DCBoost_pulse)
	ldi tmpreg, low(DCBoost_period-DCBoost_pulse)
	sts OCR1BH, tmpregh
	sts OCR1BL, tmpreg


	ldi tmpreg, (1<<OCIE1A) | (1<<OCIE1B)
	sts TIMSK1, tmpreg

	ldi tmpreg, (1<<WGM12)|(3<<CS10)
	sts TCCR1B, tmpreg




	;==================  enable timer2 /systick, realtime counter

	;timer configuration counter = 125 (124), prescaller 64 - period = 1/8 seconds
	;need to compensate -73us per second /121
	 ldi tmpreg, 121 ;126=15.34;125=15.46
	 sts OCR2A,tmpreg
	 ldi tmpreg, (1<<WGM21)
	 sts TCCR2A,tmpreg 
	 ldi tmpreg, (6<<CS20) ;1/32 sec
	 sts TCCR2B,tmpreg 
	 ldi tmpreg,(1<<OCIE2A)
	 sts TIMSK2,tmpreg

	 sei ;------------ temporary for test

	; fill pointers
	
	
	set_ST_ptr sm_digits

	ST_ptr MINI_CIFRA_0
	ST_ptr MINI_CIFRA_1
	ST_ptr MINI_CIFRA_2
	ST_ptr MINI_CIFRA_3
	ST_ptr MINI_CIFRA_4
	ST_ptr MINI_CIFRA_5
	ST_ptr MINI_CIFRA_6
	ST_ptr MINI_CIFRA_7
	ST_ptr MINI_CIFRA_8
	ST_ptr MINI_CIFRA_9

	set_ST_ptr digits

	ST_ptr CIFRA_0
	ST_ptr CIFRA_1
	ST_ptr CIFRA_2
	ST_ptr CIFRA_3
	ST_ptr CIFRA_4
	ST_ptr CIFRA_5
	ST_ptr CIFRA_6
	ST_ptr CIFRA_7
	ST_ptr CIFRA_8
	ST_ptr CIFRA_9
	 

	set_ST_ptr rad_anim

	ST_ptr RAD_0
	ST_ptr RAD_1
	ST_ptr RAD_2
	ST_ptr RAD_3

	;saving power, disabling unused periph
	;ldi tmpreg,

	;setup idle mode


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




	clr tmpcount
	
	/*
	LCD_XY 30,0
	ldi tmpreg,8
	push tmpreg
	LCD_datX digits, tmpreg
	LCD_XY 38,0
	pop tmpreg
	inc tmpreg
	push tmpreg

	LCD_datX digits, tmpreg
	pop tmpreg
	inc tmpreg
	push tmpreg
	
	LCD_datX sm_digits, tmpreg
	pop tmpreg
	inc tmpreg
	push tmpreg
	LCD_datX sm_digits, tmpreg
	pop tmpreg
	inc tmpreg
	push tmpreg
	LCD_datX sm_digits, tmpreg
	pop tmpreg
	inc tmpreg
	push tmpreg
	LCD_datX sm_digits, tmpreg
	pop tmpreg
	inc tmpreg
	push tmpreg
	LCD_datX sm_digits, tmpreg
	pop tmpreg
	inc tmpreg
	push tmpreg
	LCD_datX sm_digits, tmpreg
	pop tmpreg
	inc tmpreg
	push tmpreg
	LCD_datX sm_digits, tmpreg
	pop tmpreg
	inc tmpreg
	push tmpreg
	LCD_datX sm_digits, tmpreg
	*/

	;===========================================
	;========= set zeroes at timer positions

	LCD_XY 48,0
	LCD_dat	CIFRA_0
	LCD_XY 40,0
	LCD_dat CIFRA_0
	LCD_XY 56,0
	LCD_dat DDot
	LCD_XY 68,0
	LCD_dat CIFRA_0
	LCD_XY 60,0
	LCD_dat CIFRA_0		
	LCD_XY 76,0
	LCD_dat DDot
	LCD_XY 88,0
	LCD_dat CIFRA_0
	LCD_XY 80,0
	LCD_dat CIFRA_0
	
	
	;===========================================
	loop:
	nop

	sbrs controlreg, sec_tick
	rjmp no_sec
	
	clt 
	bld controlreg, sec_tick
	;increment seconds

	lds argh, rtc_dsec	
	lds arg, rtc_sec
	push argh
	rcall inc_less60
	sts rtc_dsec, argh
	sts rtc_sec, arg
	pop tmpreg
	
	cp argh,tmpreg ; 0 5, 5 5, 5 4 
	brlo sec_ovf
	;increment minutes
	rjmp no_secovf ;brsh cannot jump so far
	sec_ovf:

	lds argh, rtc_dmin	
	lds arg, rtc_min
	push argh
	rcall inc_less60
	sts rtc_dmin, argh
	sts rtc_min, arg
	pop tmpreg

	cp argh,tmpreg 
	brsh no_minovf
	
	;increment hours
	lds tmpregh, rtc_dhour
	lds tmpreg, rtc_hour

	cpi tmpregh, 2
	brlo h_less20
	inc tmpreg
	cpi tmpreg,4
	brlo no_hovf
	clr tmpreg
	clr tmpregh
	rjmp no_hovf

	h_less20:
	inc tmpreg
	cpi tmpreg, 10
	brlo no_hovf
	clr tmpreg
	inc tmpregh
	no_hovf:
	sts rtc_dhour,tmpregh
	sts rtc_hour,tmpreg

	LCD_XY 48,0
	lds tmpreg, rtc_hour
	LCD_datX digits, tmpreg
	LCD_XY 40,0
	lds tmpreg, rtc_dhour
	LCD_datX digits, tmpreg
	
	no_minovf:

	LCD_XY 68,0
	lds tmpreg, rtc_min
	LCD_datX digits, tmpreg
	LCD_XY 60,0
	lds tmpreg, rtc_dmin
	LCD_datX digits, tmpreg


	no_secovf:

		
	LCD_XY 88,0
	lds tmpreg, rtc_sec
	LCD_datX digits, tmpreg
	LCD_XY 80,0
	lds tmpreg, rtc_dsec
	LCD_datX digits, tmpreg


	no_sec:

	sbrs controlreg, qsec_tick
	rjmp loop
	;1 second flag is set
	;reset flag
	clt 
	bld controlreg, qsec_tick
	LCD_XY 0,1
	;LCD_dat RAD_1

	LCD_datX rad_anim, tmpcount
	;set_ST_ptr rad_anim
	;mov tmpreg, tmpcount
	;rol tmpreg
	;add XL,tmpreg
	;adc XH,zeroreg

	;sbi PORTB,P_MOSI
	;ld ZH, X+
	;ld ZL, X+
	;rcall SPI_start

	inc tmpcount
	cpi tmpcount, 4
	brsh clr_tmpcount
	rjmp loop
	clr_tmpcount:
	clr tmpcount
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


	;====================================
	inc_less60:
	clt
	inc arg
	cpi arg,10
	brlo end_inc_less60
	clr arg
	inc argh
	cpi argh, 6
	brlo end_inc_less60
	clr argh
	set
	end_inc_less60:
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
.db 1,0, \
0x00,1, 0xFF,0xFF; 96 ;96

LCD_clrline:
.db 96,0, 0x00,192

LCD_clr:
.db 96,9, \
0x00, 192, 0x00, 192, 0x00, 192, 0x00, 192, 0x00, 192, 0x00,192, \
0x00, 255, 0x00, 255, 0x00, 255, 0x00, 255
/*
Pattern:
.db 4, 4, \
0x01,0x03,0x7,0x0F,0x1F,0x3F,0x7F,0xFF,0x03,0x0F,0x3F,0xFF,0x03,0x0F,0x3F,0xFF, \
0xFF,0xFF,0xFF,0xFF

Pattern1:
.db 5, 4, \
0x03,0x00,0x03,0xFF, \
0x03,0x00,0x03,0xFF, \
0x03,0x00,0x03,0xFF, \
0x03,0x00,0x03,0xFF, \
0xFF,0xFF,0xFF,0xFF

Pattern2:
.db 5, 4, \
0x00,0x03,0xFF,0x03, \
0x00,0x03,0xFF,0x03, \
0x00,0x03,0xFF,0x03, \
0x00,0x03,0xFF,0x03, \
0xFF,0xFF,0xFF,0x03

Pattern3:
.db 5,3, \
0xFF,0xFF ,0x00, 11, 0xFF,0xFF 

Pattern4:
.db 96,3, \
0x00, 93, 0xFF, 0x00, 96, 0xFF,0x00, 96, 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF

Pattern5:
.db 4,2, \
0xFF,0xFF,0x00,2, \
0xff,0xff,0xff,0xff, \
0xff,0xff,0x00,2
*/
.include "data.inc"


;==== RAM MEMORY DATA SEGMENT ======================================================================
.DSEG 
TXCountMem: .byte 1 
TXRowCountMem: .byte 1 

qsecond: .byte 1 ; 1/32 second counter
qqsecond: .byte 1 ; 1/4 second counter

;rtc vars
rtc_sec: .byte 1
rtc_dsec: .byte 1
rtc_min: .byte 1
rtc_dmin: .byte 1
rtc_hour: .byte 1
rtc_dhour: .byte 1

;pointers
sm_digits: .byte 20
digits: .byte 20
rad_anim: .byte 6
