;
; cbt-10 refactor.asm
;
; Created: 28.09.2024 18:18:26
; Author : inflamer
;

.include "m88PAdef.inc"
.include "definitions.inc"

;/*interrupt vector routine*/

.CSEG
.ORG $0000

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
	cli ;disable interrupts until mcu init process

	ldi		tmpl, low(RAMEND)
	out		SPL, tmpl
	ldi		tmpl, high(RAMEND)
	out		SPH, tmpl

/*clock setup*/
	ldi		r24, (1<<CLKPCE)
	sts		CLKPR, r24
	ldi		r25, (1<<CLKPS1)|(1<<CLKPS0); 0b00000011 Clock Division Factor = 8	F = 1 MHz
	sts		CLKPR, r25

	sei

;/*init section */

	;GPIO init

	;/*Periph init*/
	;SPI init
	; Set MOSI and SCK output, all others input
	ldi		tmph, (1<<DDB3)|(1<<DDB5) ; set MOSI and SCK as out
	out		DDRB,tmph
	; Enable SPI, Master
	;ldi		tmpl, (1<<MSTR);|(1<<SPE);0b01010000		; Master Mode(MSTR), Enable SPI(SPE)
	;out		SPCR, tmpl
	; Set spid 2X
	ldi		tmpl, (1<<SPI2X) ;0b00000001		; double speed bit(SPI2X)
	out		SPSR, tmpl


	

	;initial settings

/*test section*/
	lds tmpl, STVAR
	sbr tmpl, (1<<STNC)
	sts STVAR, tmpl


;
;	ldi argl, 0x55
;	rcall SPI_TXC
;	ldi argl, 0x55
;	rcall SPI_TXD

	


;/*		init_LCD  */
	cbi		LCD_RSTP,LCD_RST			; ? ????? RES
	;rcall	pause_100ms
	sbi		LCD_RSTP,LCD_RST			; ???????? RES
	;rcall	pause_10ms

	ldi countl, 8 ;5 in original version
	ldi Zl,low(LCD_init_data*2)
	ldi Zh,high(LCD_init_data*2)
LCD_init:
	lpm argl,Z+
	rcall SPI_TXC
	dec countl
	brne LCD_init

	


; Replace with your application code
main:



    inc r16
    rjmp main



;--------------- end main --------------------- 
/* functions prototypes */

SPI_TXC:
	;disable SPI
	ldi tmph, (1<<MSTR)|(1<<SPE)
	clr tmpl
	out SPCR, tmpl

	;cbi SPI_TXP, (1<<SPI_TX)
	in tmpl ,SPI_TXP
	cbr tmpl, (1<<SPI_TX) | (1<<SPI_SCK)
	out SPI_TXP, tmpl
	sbr tmpl, (1<<SPI_SCK)
	out SPI_TXP,tmpl
	cbr tmpl, (1<<SPI_SCK) | (1<<SPI_TX)
	out SPI_TXP,tmpl
	out SPCR,tmph
	rjmp SPI_Transmit	
SPI_TXD:
	;disable SPI
	ldi tmph, (1<<MSTR)|(1<<SPE)
	clr tmpl
	out SPCR, tmpl

	;cbi SPI_TXP, (1<<SPI_TX)
	in tmpl ,SPI_TXP
	cbr tmpl, (1<<SPI_SCK)
	sbr tmpl, (1<<SPI_TX)
	out SPI_TXP, tmpl
	sbr tmpl, (1<<SPI_SCK)
	out SPI_TXP,tmpl
	cbr tmpl, (1<<SPI_SCK)
	out SPI_TXP,tmpl
	out SPCR,tmph
	rjmp SPI_Transmit	



	;ldi tmpl, (1<<SPIT)
SPI_Transmit:	
		out SPDR,argl
Wait_SPI_TX:
	;Wait for transmission complete
	in tmpl, SPSR
	sbrs tmpl, SPIF
	rjmp Wait_SPI_TX
	in tmpl, SPDR ; flush data register as trash data, maybe use as charger detect
	ret
	



;/* flash memory data */
;/* program memory is word addressed: ldi ZL,LOW(2*var)
.CSEG
ctest: .dw 1

.include "data_fm.inc"

.DSEG
;/* data variables */
;dtest:
STVAR: .db 1; status variable
dtest: .db 1 ;8
dtestw: .dw 1 ;16
dtestdw: .dd 1;32
dtestdq: .dq 1;64


.ESEG
;/* eeprom variables */
eetest:
.db 0x55