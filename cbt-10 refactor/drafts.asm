;------------------------SPI------------------------

SPI_init:
	ldi		r24, 0b01010000		; Master Mode(MSTR), Enable SPI(SPE)
	out		SPCR, r24
	mov		r2, r24
	ldi		r24, 0b00000001		; double speed bit(SPI2X)
	out		SPSR, r24
	ret

;------------------Îòïðàâêà áàéòà ïî SPI----------------------

; r24-ïåðåäîâàåìûé áàéò

SPI_Write_CMD:
	cli
	out		SPCR, r0
	cbi		PORTB,DDB3			; ê çåìëå DO
	sbi		PORTB,DDB5			; ïîäòÿæêà CLK
	cbi		PORTB,DDB5			; ê çåìëå CLK
	out		SPCR, r2			; Master Mode(MSTR), Enable SPI(SPE)
	out		SPDR, r24
	sei
	rcall	clk_18
	in		r24, SPSR
	ret

SPI_Write_DATA:
	cli
	out		SPCR, r0
	sbi		PORTB,DDB3			; ïîäòÿæêà DO
	sbi		PORTB,DDB5			; ïîäòÿæêà CLK
	cbi		PORTB,DDB5			; ê çåìëå CLK
	out		SPCR, r2			; Master Mode(MSTR), Enable SPI(SPE)
	out		SPDR, r24
	sei
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

;--------------------Íàñòðîéêà ÀÖÏ----------------------