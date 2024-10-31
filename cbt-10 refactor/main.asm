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
	clr zeroreg
	out SREG,zeroreg

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
	

	;saving power, disabling unused periph
	ldi tmpreg,(1<<PRTWI)|(1<<PRUSART0)
	sts PRR, tmpreg

	;setup idle mode
	ldi tmpreg, (1<<SE);|(2<<SM0) ; idle sm=000
	out SMCR, tmpreg
	
	;--------------------------
	;=GPIO init
	ldi tmpreg, (1<<P_LCD_RES)|(1<<P_bDiode)|(1<<P_bCap)|(1<<P_bTrans)|(1<<PD6)
	out DDRD,tmpreg
	;sbi PORTD, P_LCD_RES
	;cbi PORTD, P_LCD_RES

	;=SPI init
	ldi tmpreg, (1<<P_SS)|(1<<P_SCK)|(1<<P_MOSI)
	out DDR_SPI,tmpreg
	cbi DDR_SPI,P_MISO

	out DDRC, zeroreg

	sei

	;delay for LCD reset must be implemented 2500ns pull low, 2500ns after reset
	; 10 - 100ms hx1230 recomendation 
	;use timer+idle sleep to reduce power consumption.  LCD backlight  (timer0)
	; clr TIFR0
	out TIFR0, zeroreg
	; TIFR0 <- OCF0A - set interrupt to wake cpu
	ldi tmpreg, (1<<OCIE0A)
	sts TIMSK0, tmpreg
	; out OCR0A, 10  - 10ms period or other stable reset timeout ex 100ms
	ldi tmpreg, 10
	out OCR0A, tmpreg
	; configure prescaller 1024
	ldi tmpreg, (5<<CS00)
	out TCCR0B, tmpreg
	; out TCNT0, zeroreg -  resets timer0 count
	out TCNT0, zeroreg
	; PULL LCD_reset to 0
	cbi PORTD, P_LCD_RES
	; 10ms is a long time do something before sleep and release reset
	; code injection under LCD reset
	;==============================================
	;==============================================

	;=init predefined registers
	;clr zeroreg ;--------- defined at reset
	ldi r16,(1<<MSTR)|(1<<SPE)
	mov spenreg, tmpreg
	
	ldi Zl,low(wait_TX_complete)
	ldi Zh,high(wait_TX_complete)
	movw TXC_ptrl,Zl

	;ldi r16,(1<<MSTR)|(1<<SPE);|(1<<SPR0)
	;out SPCR, spenreg

	in tmpreg, SPSR
	ori tmpreg, (1<<SPI2x)
	out SPSR, tmpreg


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


	;==============================================
	;==============================================
	; sleep
	sleep
	; PULL LCD_reset to 1
	sbi PORTD, P_LCD_RES
	; out OCR0A, 10  - 10ms period uncoment 2 lines below if previous period is differ
		;ldi tmpreg, 10
		;out OCR0A, tmpreg
	; out TCNT0, zeroreg -  resets timer0 count
		;out TCNT0, zeroreg
	; sleep
	sleep
	; disable timer (or reconfigure for backlight)
	sts TCCR0B, zeroreg
	sts TIMSK0, zeroreg
	cli

	
	;----------------- remove this string with booster enabled
	sbi PORTC, P_boostFB ; enable internal pullup for test only

	;--------------------------------
	
	rcall backlight_on

	;===== enable timer1 and configure interrupts  = enable 400V booster
	
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
	 ldi tmpreg, 121 ;126=15.34;125=15.46 different in real system, need to check on hardware
	 sts OCR2A,tmpreg
	 ldi tmpreg, (1<<WGM21)
	 sts TCCR2A,tmpreg 
	 ldi tmpreg, (6<<CS20) ;1/32 sec
	 sts TCCR2B,tmpreg 
	 ldi tmpreg,(1<<OCIE2A)
	 sts TIMSK2,tmpreg

	;clear ram storage defined bytes in .DSEG
	ldi XH,high(TXCountMem)
	ldi XL,low(TXCountMem)
	ldi tmpreg, clrb_onreset
	clr_mem:
	st X+,zeroreg
	dec tmpreg
	brne clr_mem

	sei ;------------ temporary for test

	;====== enable external interrupts

	/*
	EICRA (1<<ISC11)|(1<<ISC10) rising edge need to check maybe other variant
	EIMSK (1<<INT1) enable interrupt 1 to get data from sensor

	PCICR look at Pins and enable only what need 3 buttons
	PCIE2 ;---------PCINT[23:16] PCMSK2
	PCIE1 ;---------PCINT[14:8] PCMSK1
	PCIE0 ;---------PCINT[7:0] PCMSK0
	*/

	;====== enable ADC
	; DIDR0  ADC5D ADC4D ADC3D ADC2D ADC1D ADC0D - disable digital inputs on used adc channels
	; ADC6 - noise
	; ADC7 - vcc


	;ldi		r24, 0b11000111		; ADC7 1.1V ADLAR = 0
	;sts		ADMUX, r24
	;ldi		r24, 0b11000100		; 62,5 kHz	однократное преобразование
	;sts		ADCSRA, r24



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

	;LCD_dat RAD_BIG

	;LCD_XY 0,4
	;LCD_dat pausa
	;LCD_dat plav
	;LCD_dat summa
	;LCD_dat cps
	;LCD_dat mkrh
	/*
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
	LCD_dat batter_nofill
	LCD_dat batter_fill
	LCD_dat batter_bcap
	*/
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
	/*

	
	;===========================================

	;LCD_XY_shift 0,4,20 ; uses tmpreg and 2 more instructions
	LCD_XY 20,3
	
	LCD_dat RODGER
	
	; half rodger
	LCD_XY 30,3
	;LCD_inv
	LCD_spX 10,2
	;LCD_norm

	*/

	rcall test_screen
	
	
	;===========================================
	;	main loop idle and wait for interrupt
	;===========================================
	loop:
		sleep

	rjmp loop ; for temporary disable main loop

		;check seconds flag
		sbrs controlreg, sec_tick
		rjmp no_sec ; not second
		;------------------------------------------
		;every second
		;1 second flag is set
		clt 
		bld controlreg, sec_tick ;reset flag
	
		rcall rtc
	no_sec:
		; check 1/4 second flag animation is here
		sbrs controlreg, qsec_tick
		rjmp no_qsec
		;-----------------------------------------
		;every 1/4 second
		;1/4 second flag is set
		;reset flag
		clt 
		bld controlreg, qsec_tick
		LCD_XY rad_an_posx,rad_an_posy

		lds tmpreg, anim_count

		LCD_datX rad_anim, tmpreg

		rcall nxt_an_frame
	no_qsec:
		rjmp loop




	;=====================================================
	;function prototypes for testing purposes
	; move to functions inc after complete and test
	;=====================================================


	;====================================

	write_ee:

	ret

	read_ee:

	ret

	;======================================


	;=======================================
	.include "functions.inc"

	;========================================
	; include functions to build primitives

	.include "glib.inc"

	;========================================

;==== PROGRAM FLASH MEMORY DATA SEGMENT =======================================
.CSEG
LCD_init:
.db 5,0, LC_nallon_dis,LC_pwron,LC_fillall_dis,LC_nor_dis, LC_nrev_dis, \
0xFF; padding byte

LCD_clr:
.db 96,9, \
0x00, 192, 0x00, 192, 0x00, 192, 0x00, 192, 0x00, 192

.include "data.inc"


;==== RAM MEMORY DATA SEGMENT ======================================================================
.DSEG 
TXCountMem: .byte 1 
TXRowCountMem: .byte 1 

qsecond: .byte 1 ; 1/32 second counter
qqsecond: .byte 1 ; 1/4 second counter

anim_count: .byte 1

samples_count: .byte 1 ;catched samples counter  
pulses: .byte 1 ; count pulses from sensor

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

;==== EEPROM MEMORY DATA SEGMENT ======================================================================
.ESEG
size: .byte  1
nsise: .byte 1