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
	;=================================================
	;testing
	





	;=================================================

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

	ldi tmpreg, (1<<P_Vmeas)

	out Vmeas_DDR, tmpreg

	sbi Vmeas_port, P_Vmeas

	sei

	;delay for LCD reset must be implemented 2500ns pull low, 2500ns after reset
	; 10 - 100ms hx1230 recomendation 
	;use timer+idle sleep to reduce power consumption.  LCD backlight  (timer0)
	; clr TIFR0
	out TIFR0, zeroreg
	; TIFR0 <- OCF0A - set interrupt to wake cpu
	ldi tmpreg, (1<<OCIE0A)
	sts TIMSK0, tmpreg
	; out OCR0A, 10  - 10ms period or other stable reset timeout ex 100ms * 8 (1->8MHz)
	ldi tmpreg, 80
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

	set_ST_ptr icons

	ST_ptr count_pic
	ST_ptr alarm_pic
	ST_ptr threshold_pic
	ST_ptr clk_vol_pic
	ST_ptr bright_pic
	ST_ptr sen_set_pic
	ST_ptr bat_cal_pic
	ST_ptr contr_pic

	ldi XH,high(icons_shifts)
	ldi XL,low(icons_shifts) 

	ldi tmpreg, scount_pic
	st X+, tmpreg
	ldi tmpreg, salarm_pic
	st X+, tmpreg
	ldi tmpreg, sthreshold_pic
	st X+, tmpreg
	ldi tmpreg, sclk_vol_pic
	st X+, tmpreg
	ldi tmpreg, sbright_pic
	st X+, tmpreg
	ldi tmpreg, ssen_set_pic
	st X+, tmpreg
	ldi tmpreg, sbat_cal_pic
	st X+, tmpreg
	ldi tmpreg, scontr_pic
	st X+, tmpreg
	;-----------------------
	;setup cps buffer
	ldi tmpreg, cps_buf_size
	sts cps_buf_counter, tmpreg
	ldi tmpregh, high(cps_buffer)
	ldi tmpreg, low(cps_buffer)
	sts cps_wr_ptr,tmpregh
	sts cps_rd_ptr, tmpregh
	sts cps_wr_ptr+1,tmpreg
	sts cps_rd_ptr+1, tmpreg


	ldi tmpreg, clr_data_size
	clr_loop:
	ldi XH, high(TXCountMem)
	ldi XL, low(TXCountMem)
	dec tmpreg
	brne clr_loop
	

	
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

	rcall enable_booster

	rcall enable_systick

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


	;pciint 9,10,11 - buttons
	ldi tmpreg, (1<<PCIE1)
	sts PCICR, tmpreg
	ldi tmpreg, (1<<PCINT9)|(1<<PCINT10)|(1<<PCINT11)
	sts PCMSK1, tmpreg


	;====== enable ADC
	; DIDR0  ADC5D ADC4D ADC3D ADC2D ADC1D ADC0D - disable digital inputs on used adc channels
	; ADC6 - noise
	; ADC7 - vcc


	;ldi		r24, 0b11000111		; ADC7 1.1V ADLAR = 0
	;sts		ADMUX, r24
	;ldi		r24, 0b11000100		; 62,5 kHz	однократное преобразование
	;sts		ADCSRA, r24

	.ifdef meas_pin_vcc
	sbi Vmeas_port, P_Vmeas
	.else
	cbi Vmeas_port, P_Vmeas
	.endif

	ldi tmpreg, (1<<REFS1)|(1<<REFS0)|(1<<ADLAR)|(7<<MUX0)
	sts	ADMUX, tmpreg
	ldi tmpreg, (1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(2<<ADPS0)
	sts ADCSRA, tmpreg


	LCD_cmd LCD_init
	
	LCD_norm
	;LCD_inv

	LCD_XY 0,0
	LCD_dat LCD_clr



	
	;===========================================
	;test here
	;===========================================
	
	LCD_norm
	;LCD_inv
	
	
	rcall test_primitive
	rcall test_screen

	clr tmpcount

	;LCD_XY 40,3
	;ldi tmpreg, 2
	;LCD_datX icons, tmpreg
	
	;===========================================



	
	
	;===========================================
	;	main loop idle and wait for interrupt
	;===========================================
	loop:
		sleep

	;rjmp loop ; for temporary disable main loop

		;check seconds flag
		sbrs controlreg, sec_tick
		rjmp no_sec ; not second
		;------------------------------------------
		;every second
		;1 second flag is set
		clt 
		bld controlreg, sec_tick ;reset flag
	
		rcall rtc
		/*
		LCD_XY 15,4
		LCD_spX 32,4	
		
		ldi XH,high(icons_shifts)
		ldi XL,low(icons_shifts)
		add XL,tmpcount
		adc XH,zeroreg
		ld tmpreg,X
		LCD_XY_shifttr 15,4,tmpreg
		;LCD_XY 40,3
		;ldi tmpreg, 0
		LCD_datX icons, tmpcount
		inc tmpcount
		cpi tmpcount,8
		brlo no_clr
		clr tmpcount
		*/
		no_clr:

		cli
		; atomic operation read and clear CPS count
		lds tmpregh, cps_counth
		lds tmpreg, cps_count
		sts cps_counth, zeroreg
		sts cps_count, zeroreg
		sei

		; convert 16bit to bcd




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

		/*
		LCD_XY rad_an_posx,rad_an_posy

		lds tmpreg, anim_count
		LCD_datX rad_anim, tmpreg

		rcall nxt_an_frame
		*/


		;adc test section

		.ifdef meas_pin_vcc
		sbi Vmeas_port, P_Vmeas
		.else
		cbi Vmeas_port, P_Vmeas
		.endif

		/*
		LCD_XY 0,2
		lds tmpreg, bat_volt
		LCD_datX sm_digits, tmpreg
		LCD_spX 1,1
		LCD_dat MINI_dot
		lds tmpreg, bat_tenthvolt
		LCD_datX sm_digits, tmpreg
		*/
		ldi tmpreg, (1<<REFS1)|(1<<REFS0)|(1<<ADLAR)|(7<<MUX0)
		sts	ADMUX, tmpreg
		ldi tmpreg, (1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(2<<ADPS0)
		sts ADCSRA, tmpreg

		;----------------------------------------------------

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

;battery voltage storage
bat_volt: .byte 1
bat_tenthvolt: .byte 1

;rtc vars
rtc_sec: .byte 1
rtc_dsec: .byte 1
rtc_min: .byte 1
rtc_dmin: .byte 1
rtc_hour: .byte 1
rtc_dhour: .byte 1

;cps count
cps_counth: .byte 1
cps_count: .byte 1
;CPS FIFO BUFFER
cps_buf_counter: .byte 1
cps_wr_ptr: .byte 2
cps_rd_ptr: .byte 2
cps_buffer: .byte cps_buf_size


;pointers
sm_digits: .byte 20
digits: .byte 20
rad_anim: .byte 8
icons: .byte 16
icons_shifts: .byte 8

;==== EEPROM MEMORY DATA SEGMENT ======================================================================
.ESEG
size: .byte  1
nsise: .byte 1