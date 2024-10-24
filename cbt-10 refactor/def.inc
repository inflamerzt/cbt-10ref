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
.equ DCboost_period = 2500  ;160 ms
.equ DCboost_pulse = 8 ;512us - 22us (interrupt delay)

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

.equ P_LCD_RES = PD7

; controlreg
.equ inv_dis =0
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

.macro LCD_norm ; put symbols on LCD normal
	clt ;- normal display
	bld controlreg, inv_dis
.endmacro

.macro LCD_inv ; put symbols on LCD inverted
	set ;- inverse display
	bld controlreg, inv_dis
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
		reti ;rjmp ADC ; ADC Conversion Complete Handler
		reti ;rjmp EE_RDY ; EEPROM Ready Handler
		reti ;rjmp ANA_COMP ; Analog Comparator Handler
		reti ;rjmp TWI ; 2-wire Serial Interface Handler
		reti ;rjmp SPM_RDY ; Store Program Memory Ready Handler


TIM1_COMPA: ; Timer1 Compare A Handler
nop
;discharge cap
;sbi transistor
;small delay
;cbi transistor or keep transistor opened to keep mosfet closed in noisy environment
reti

TIM1_COMPB: ; Timer1 Compare B Handler
;sbis suppressor pin

;cbi transistor
;cbi capacitor
;sbi diod


push tmpreg
in tmpreg, SREG
push tmpreg

;charge cap 20us and pull up
ldi tmpreg, 4; make X additional cycles to get 20us delay
wait_charge:
dec tmpreg
brne wait_charge

pop tmpreg
out SREG,tmpreg
pop tmpreg
nop
;cbi diod
;sbi capacitor

reti