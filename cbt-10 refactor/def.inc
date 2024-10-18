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

;.CSEG
;.ORG $0000
