; cps 00.000
; uR/h 00.00

.equ meas_pin_vcc = 1 ; pull measuring pin to vss to measure, comment othervise

.equ LC_pwroff = 0x20
.equ LC_pwron = 0x2F
.equ LC_nallon_dis = 0xA4 ;normal display
.equ LC_allon_dis = 0xA5 ;all segments disabled ?standby mode
.equ LC_nor_dis = 0xA6 ;normal display
.equ LC_inv_dis = 0xA7 ;inverted display
.equ LC_nfillall_dis = 0xAE ;display ram
.equ LC_fillall_dis = 0xAF ;hide ram

;original display settings
.equ LC_nrev_dis = 0xA0
.equ LC_rev_dis = 0xA1

; TIM1 prescaller x/16
;160 ms must be 5ms to 1s count 90...16000 0x50...0x5000
 
.equ DCboost_period = 0x50 ;small timing = fast boost  
.equ DCboost_pulse = 8 ;512us - 22us (interrupt delay)

;set quantity bytes to cleear on startup (.DSEG)
.equ clrb_onreset = 11

;timer position
.equ timer_posx = 28 ;40 - max
.equ timer_posy = 0

;rad_anim_position
.equ rad_an_posx = 0
.equ rad_an_posy = 2


;icons shift values
.equ scount_pic = 2
.equ salarm_pic = 0
.equ sthreshold_pic = 2
.equ sclk_vol_pic = 2
.equ sbright_pic = 0
.equ ssen_set_pic = 0
.equ sbat_cal_pic = 6
.equ scontr_pic = 0

;voltage measure pin
.equ Vmeas_DDR = DDRC
.equ Vmeas_port = PORTC
.equ P_Vmeas = PC0


;buttons
.equ button1 = PC1
.equ button2 = PC2
.equ button3 = PC3





	;Установка линии начала сканирования 0 1 S5 S4 S3 S2 S1 S0 
	;Установка линии начала сканирования S:0?Y?63

	;=== set start scan number S:0?Y?63 shift dram LCD
	;ldi tmpreg,0 //load position
	;andi tmpreg,0x3F
	;ori tmpreg,0x40 ; y2..0 (0..7)
	;inc TXCount
	;rcall SPI_TX_cmd



.equ DDR_SPI = DDRB
.equ P_SS = PB2
.equ P_MOSI = PB3
.equ P_MISO = PB4
.equ P_SCK = PB5

.equ DDR_booster = DDRD
.equ PORT_booster = PORTD
.equ P_bDiode = PD0
.equ P_bCap = PD1
.equ P_bTrans = PD2

.equ DDR_LCD_RST = DDRD
.equ P_LCD_RES = PD7

.equ P_boostFB = PC5



; controlreg (r4) flags
.equ inv_dis =0
.equ sec_tick= 1
.equ qsec_tick = 2
.equ alarm = 3
;============

.def zeroreg = r2
.def spenreg = r3
.def controlreg = r4
.def TXZCount = r5
.def tmpZl = r6
.def tmpZh = r7
.def TXC_ptrl = r8
.def TXC_ptrh = r9



.def tmpreg = r16
.def tmpregh = r17 

.def TXCount = r18
.def TXRowCount = r19

.def tmpcount = r20

.def TXXpos = r22
.def TXYpos = r23
; probably use r24,r25 as function operands such as input variables
.def arg = r24
.def argh = r25

.macro LCD_cmd 
	cbi PORTB,P_MOSI
	ldi Zl,low(@0*2)
	ldi Zh,high(@0*2)
	rcall SPI_start
.endmacro

.macro LCD_dat
	sbi PORTB,P_MOSI
	ldi Zl,low(@0*2)
	ldi Zh,high(@0*2)
	rcall SPI_start
.endmacro

.macro LCD_spX ;clears X pixels in rows (erase objects in string(s))
	sbi PORTB,P_MOSI
	ldi Zl,low(LCD_clr*2+2)
	ldi Zh,high(LCD_clr*2+2)
	ldi TXCount, @0
	ldi TXRowCount, @1
	rcall SPI_start_defined
.endmacro


.macro LCD_datX ;display data from pointer address @0 = array_pointer, @1 = shift(reg)
	;set_ST_ptr rad_anim
	ldi XH,high(@0)
	ldi XL,low(@0)

	mov tmpreg, @1
	rcall LCD_datX_func
	rcall SPI_start
.endmacro

.macro LCD_rep
	ldi Zl,low(@0*2)
	ldi Zh,high(@0*2)
	rcall SPI_start
.endmacro

.macro LCD_XY ;x = 0..95  y = 0..7
	ldi TXXpos, @0
	ldi TXYpos, @1
	rcall LCD_goto_XY
.endmacro

.macro LCD_XY_shift ;x = 0..95  y = 0..7
	ldi TXXpos, @0
	ldi tmpreg, @2
	add TXXpos,tmpreg
	ldi TXYpos, @1
	rcall LCD_goto_XY
.endmacro

.macro LCD_XY_shifttr ;x = 0..95  y = 0..7
	ldi TXXpos, @0
	add TXXpos,tmpreg
	ldi TXYpos, @1
	rcall LCD_goto_XY
.endmacro

.macro LCD_norm ; put symbols on LCD normal
	clt ;- normal display
	bld controlreg, inv_dis
.endmacro

.macro LCD_inv ; put symbols on LCD inverted
	set ;- inverse display
	bld controlreg, inv_dis
.endmacro

.macro set_ST_ptr ;sets X regs for ST_ptr
	ldi XH,high(@0)
	ldi XL,low(@0)
.endmacro

.macro ST_ptr ;X must be set before
	ldi tmpregh,high(@0*2)
	ldi tmpreg,low(@0*2)
	;st X+,tmpregh
	;st X+,tmpreg
	;make stxw procedure to reduce size of code
	rcall stxw
.endmacro

;.CSEG
;.ORG $0000
	rjmp	reset				;rjmp RESET ; Reset Handler
		reti ;rjmp EXT_INT0 ; IRQ0 Handler
		rjmp EXT_INT1 ; IRQ1 Handler
		reti ;rjmp PCINT0 ; PCINT0 Handler
		rjmp PCINT1_int ; PCINT1 Handler
		reti ;rjmp PCINT2 ; PCINT2 Handler
		reti ;rjmp WDT ; Watchdog Timer Handler
		rjmp TIM2_COMPA ; Timer2 Compare A Handler
		reti ;rjmp TIM2_COMPB ; Timer2 Compare B Handler
		reti ;rjmp	buzz_beep			;rjmp TIM2_OVF ; Timer2 Overflow Handler
		reti ;rjmp TIM1_CAPT ; Timer1 Capture Handler
		rjmp TIM1_COMPA ; Timer1 Compare A Handler
		rjmp TIM1_COMPB ; Timer1 Compare B Handler
		reti ;rjmp TIM1_OVF ; Timer1 Overflow Handler
		reti ;rjmp TIM0_COMPA ; Timer0 Compare A Handler
		reti ;rjmp TIM0_COMPB ; Timer0 Compare B Handler
		reti ;rjmp TIM0_OVF ; Timer0 Overflow Handler
		reti ;rjmp SPI_STC ; SPI Transfer Complete Handler
		reti ;rjmp USART_RXC ; USART, RX Complete Handler
		reti ;rjmp USART_UDRE ; USART, UDR Empty Handler
		reti ;rjmp USART_TXC ; USART, TX Complete Handler
		rjmp ADC_compl ; ADC Conversion Complete Handler
		reti ;rjmp EE_RDY ; EEPROM Ready Handler
		reti ;rjmp ANA_COMP ; Analog Comparator Handler
		reti ;rjmp TWI ; 2-wire Serial Interface Handler
		reti ;rjmp SPM_RDY ; Store Program Memory Ready Handler

stxw: 
	st X+,tmpregh
	st X+,tmpreg
ret

LCD_datX_func:
	rol tmpreg
	add XL,tmpreg
	adc XH,zeroreg

	sbi PORTB,P_MOSI
	ld ZH, X+
	ld ZL, X+
ret


