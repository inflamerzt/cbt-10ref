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
/*
	ldi		r24, (1<<CLKPCE)
	sts		CLKPR, r24
	ldi		r25, (1<<CLKPS1)|(1<<CLKPS0); 0b00000011 Clock Division Factor = 8	F = 1 MHz
	sts		CLKPR, r25
	*/
	sei

;/*init section */

	;GPIO init

	;PORTB init

	;ldi tmpl, (1<<DDB6)|(1<<DDB7) ; set output: LED, BUZZER, SPI_MOSI, SPI_SCK
	ldi tmpl, (1<<LED) | (1<<BUZ) | (1<<SPI_TX) | (1<<SPI_SCK) ;DDB equals PB
	; set high: LED, BUZZER, SPI_MOSI, SPI_SCK
	ldi tmph, (1<<LED) | (1<<BUZ) | (1<<SPI_TX) | (1<<SPI_SCK) 
	out PORTB, tmph
	out DDRB, tmpl

	;PORTC init

	clr tmpl
	clr tmph
	out DDRC,tmpl
	out PORTC,tmph

	;PORTD init
	
	ldi tmpl, (1<<LCD_LED)
	ldi tmph, (1<<LCD_LED)
	out DDRD, tmpl
	out LCD_LEDP,tmph

	;/*Periph init*/

	;SPI init
	; Set MOSI and SCK output, all others input
	;ldi		tmph, (1<<DDB3)|(1<<DDB5) ; set MOSI and SCK as out
	;out		DDRB,tmph
	; Enable SPI, Master
	;ldi		tmpl, (1<<MSTR);|(1<<SPE);0b01010000		; Master Mode(MSTR), Enable SPI(SPE)
	;out		SPCR, tmpl
	; Set spid 2X
	;ldi		tmpl, (1<<SPI2X) ;0b00000001		; double speed bit(SPI2X)
	;out		SPSR, tmpl

	;/* create constants in registers  */

	clr zero

	ldi tmpl, 1
	mov one, tmpl

	;initial settings




/*test section*/
	lds tmpl, STVAR
	sbr tmpl, (1<<STNC)
	sts STVAR, tmpl


	rcall	SPI_init
	rcall	LCD_init

	rcall	ZASTAVKA

;
;	ldi argl, 0x55
;	rcall SPI_TXC
;	ldi argl, 0x55
;	rcall SPI_TXD

	


;/*		init_LCD  */
/*	cbi		LCD_RSTP,LCD_RST			; ? ????? RES
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

	*/


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

	cbi SPI_TXP, SPI_TX

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
	
;------------------------функции отображения анимаций----------------------

ZASTAVKA:
	ldi		r16, 1
	ldi		r17, 0
	ldi		r18, 1
zastava:
;	rcall	Toko_mer
	ldi		r30, low(RAD_BIG*2)
	ldi		r31, high(RAD_BIG*2)
	ldi		r20, 0xB0			; Y
	ldi		r21, 9
cikle_zasY:
	ldi		r24, 0x10			; X
	rcall	SPI_Write_CMD
	ldi		r24, 0x00			; X
	rcall	SPI_Write_CMD
	mov		r24, r20
	inc		r20
	rcall	SPI_Write_CMD
	ldi		r22, 96


	ser		r24
	
	block:
	rcall	SPI_Write_DATA
	rjmp block

cikle_zasX:
	dec		r18
	brne	hello_nuli_Z
	ldi		r18, 1
	lpm		r24, Z+
	cpi		r24, 0
	brne	ne_nuli_Z
	lpm		r18, Z+
hello_nuli_Z:
	clr		r24
ne_nuli_Z:
	lsr		r16
	rol		r17
	eor		r16, r17
	or		r24, r16
	rcall	SPI_Write_DATA
	dec		r22
	brne	cikle_zasX
	dec		r21
	brne	cikle_zasY
	dec		r18
	brne	zastava
	ret

shym:
	ldi		r16, 1
	ldi		r17, 0
cikl_slychaino:
;	rcall	Toko_mer
	ldi		r19, 40
slychaino:
	lsr		r16
	rol		r17
	eor		r16, r17
	mov		r24, r16
	rcall	SPI_Write_DATA
	dec		r19
	brne	slychaino
	dec		r18
	brne	cikl_slychaino
	ret

Alfa_Zabelenie:
	ldi		r19, 0
	ldi		r20, 2
	ldi		r21, 96
	ldi		r22, 7
	rcall	clear_lcd
	ret

Zabelenie:
	ldi		r19, 0
	ldi		r20, 0
	ldi		r21, 96
	ldi		r22, 9
	rcall	clear_lcd
	ret

;	r19 - X
;	r20 - Y
;	r21 - nширина X
;	r22 - высота Y
clear_lcd:
	push	r20
	push	r21
	push	r22
	push	r23
	ori		r20, 0xB0			; Y
cikle_clearY:
	mov		r24, r19			; X high
	swap	r24
	andi	r24, 0b00001111
	ori		r24, 0x10
	rcall	SPI_Write_CMD
	mov		r24, r19			; X low
	andi	r24, 0b00001111
	rcall	SPI_Write_CMD
	mov		r24, r20			; Y
	inc		r20
	rcall	SPI_Write_CMD
	mov		r23, r21
cikle_clearX:
	clr		r24
	rcall	SPI_Write_DATA
	dec		r23
	brne	cikle_clearX
	dec		r22
	brne	cikle_clearY
	pop		r23
	pop		r22
	pop		r21
	pop		r20
	ret


;--------------------Настройка экранчика----------------------

LCD_init:
	cbi		PORTD,DDD7			; к земле RES
	rcall	pause_100ms
	sbi		PORTD,DDD7			; подтяжка RES
	rcall	pause_10ms

	ldi		r30, low(LCD_init_data*2)
	ldi		r31, high(LCD_init_data*2)
	ldi		r16, 5
cikl_lcd_init:
	lpm		r24, Z+
	rcall	SPI_Write_CMD
	dec		r16
	brne	cikl_lcd_init
;	ldi		r24, 0xC8			; mirror Y axis (about X axis)
;	rcall	SPI_Write_CMD
;	ldi		r24, 0xA0			; Инвертировать экран по горизонтали
;	rcall	SPI_Write_CMD
	ret

LCD_init_data:
.db 0xA4, 0x2F, 0xAF, 0xA6, 0xA0, 0xC8, 0xA0, 0x00

;------------------------SPI------------------------

SPI_init:
	ldi		r24, 0b01010000		; Master Mode(MSTR), Enable SPI(SPE)
	out		SPCR, r24
	mov		r2, r24
	ldi		r24, 0b00000001		; double speed bit(SPI2X)
	out		SPSR, r24
	ret

;------------------Отправка байта по SPI----------------------

; r24-передоваемый байт

SPI_Write_CMD:
	out		SPCR, r0
	cbi		PORTB,DDB3			; к земле DO
	sbi		PORTB,DDB5			; подтяжка CLK
	cbi		PORTB,DDB5			; к земле CLK
	out		SPCR, r2			; Master Mode(MSTR), Enable SPI(SPE)
	out		SPDR, r24
	rcall	clk_18
	in		r24, SPSR
	ret

SPI_Write_DATA:
	out		SPCR, r0
	sbi		PORTB,DDB3			; подтяжка DO
	sbi		PORTB,DDB5			; подтяжка CLK
	cbi		PORTB,DDB5			; к земле CLK
	out		SPCR, r2			; Master Mode(MSTR), Enable SPI(SPE)
	out		SPDR, r24
	rcall	clk_18
	in		r24, SPSR
	ret

pause_20mksec:
	rjmp	clk_18
clk_18:
	sts		NOP_byte, r0
	sts		NOP_byte, r0
	rjmp	pause_10mksec
pause_10mksec:
	sts		NOP_byte, r0
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

NOP_byte:		.byte	1


.ESEG
;/* eeprom variables */
eetest:
.db 0x55