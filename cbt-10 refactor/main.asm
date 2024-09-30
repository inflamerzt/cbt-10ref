;
; cbt-10 refactor.asm
;
; Created: 28.09.2024 18:18:26
; Author : inflamer
;

.include "m88PAdef.inc"

;/* macro definitions */

;------------------------example--------------------
;.MACRO SUBI16 ; Start macro definition
;subi @1,low(@0) ; Subtract low byte
;sbci @2,high(@0) ; Subtract high byte
;.ENDMACRO ; End macro definition
;.CSEG ; Start code segment
;SUBI16 0x1234,r16,r17 ; Sub.0x1234 from r17:r1
;---------------------------------------------------

;/* periphery definitions */
.equ LEDP = PORTB; LED PORT
.equ LED = PB6; LED PIN, high inactive
.equ BUZP = PORTB; BUZZER PORT
.equ BUZ = PB7; BUZZER PIN

.equ DRVMOS = PD2 ; Mosfet drives power mosfet IRF...
.equ DRVMOSP = PORTD 
.equ BSTC = PD1 ; Boost capacitor
.equ BSTCP = PORTD 
.equ BSTD = PD0 ; Boost diode
.equ BSTDP = PORTD 
.equ BTN1 = PC2 ; Button 1
.equ BTN1P = PORTC
.equ BTN2 = PC3 ; Button2
.equ BTN2P = PORTC
.equ SENSOR = PD3 ; Radiation sensor
.equ SENSORP = PORTD

;/*registers definitions*/

.def tmpl = r16
.def tmph = r17

;/*bits definitions*/

;/*status variable STVAR*/
.equ STNC = 0; SPI transfer is not complete


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
	ldi		tmpl, (1<<MSTR)|(1<<SPE);0b01010000		; Master Mode(MSTR), Enable SPI(SPE)
	out		SPCR, tmpl
	; Set spid 2X
	ldi		tmpl, (1<<SPI2X) ;0b00000001		; double speed bit(SPI2X)
	out		SPSR, tmpl


	

	;initial settings

/*test section*/
	lds tmpl, STVAR
	sbr tmpl, (1<<STNC)
	sts STVAR, tmpl




	;/* spi transfer example from datasheet */
	/*
		SPI_MasterInit:
			; Set MOSI and SCK output, all others input
			ldi r17,(1<<DD_MOSI)|(1<<DD_SCK)
			out DDR_SPI,r17
			; Enable SPI, Master, set clock rate fck/16
			ldi r17,(1<<SPE)|(1<<MSTR)|(1<<SPR0)
			out SPCR,r17
			ret
		SPI_MasterTransmit:
			; Start transmission of data (r16)
			out SPDR,r16
		Wait_Transmit:
			; Wait for transmission complete
			in r16, SPSR
			sbrs r16, SPIF
			rjmp Wait_Transmit
			ret
	*/
	;/****************************************/




; Replace with your application code
main:



    inc r16
    rjmp main



;--------------- end main --------------------- 
/* functions prototypes */

SPI_TX:
	out SPDR,r16
Wait_SPI_TX:
	;Wait for transmission complete
	in r16, SPSR
	sbrs r16, SPIF
	rjmp Wait_SPI_TX
	in r16, SPDR
	ret
	



;/* flash memory data */
;/* program memory is word addressed: ldi ZL,LOW(2*var)
.CSEG
ctest: .dw 1

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