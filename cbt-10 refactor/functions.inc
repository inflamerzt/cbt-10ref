;===================================
;implement used functions (rcall)
;===================================



;==========================================================================
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

		;prepare new data before byte transmit complete
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

	wait_TX_complete:
		in tmpreg, SPSR
		sbrs tmpreg,SPIF
		rjmp wait_TX_complete
		cp TXCount, zeroreg
		brne SPI_TX
		ret


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

;=====================================

	;===== rtc increment and put on screen
	rtc:
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

		LCD_XY timer_posx+8,timer_posy
		lds tmpreg, rtc_hour
		LCD_datX sm_digits, tmpreg
		LCD_XY timer_posx,timer_posy
		lds tmpreg, rtc_dhour
		LCD_datX sm_digits, tmpreg
	
	no_minovf:
		LCD_XY timer_posx+28,timer_posy
		lds tmpreg, rtc_min
		LCD_datX sm_digits, tmpreg
		LCD_XY timer_posx+20,timer_posy
		lds tmpreg, rtc_dmin
		LCD_datX sm_digits, tmpreg
	
	no_secovf:
		LCD_XY timer_posx+48,timer_posy
		lds tmpreg, rtc_sec
		LCD_datX sm_digits, tmpreg
		LCD_XY timer_posx+40,timer_posy
		lds tmpreg, rtc_dsec
		LCD_datX sm_digits, tmpreg

	ret

	;====================================================
	;=== increment seconds or minutes
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

;====================================
	;=== calculate next frame position
	nxt_an_frame:
	lds tmpreg, anim_count
	inc tmpreg
	cpi tmpreg, 4
	brlo st_an_cnt
	clr tmpreg
	st_an_cnt:
	sts anim_count, tmpreg
	ret



;==================================================

	backlight_on:
		;===== enable timer0 and configure pwm LED_backlight
		ldi tmpreg, (1<<CS00)
		out TCCR0B,tmpreg
	
		sbi DDRD, PD5 ; set compare output pin as out

		ldi tmpreg,0xEF 
		;ldi tmpreg, 0x00
		out OCR0B,tmpreg

		ldi tmpreg, (2<<COM0B0)|(3<<WGM00) ; (3<<COM0B0) if out must be inverted
		out TCCR0A, tmpreg
	
		ret


;==================================================

	backlight_off:
		;===== enable timer0 and configure pwm LED_backlight
		ldi tmpreg, (1<<CS00)
		out TCCR0B,tmpreg
	
		sbi DDRD, PD5 ; set compare output pin as out

		;ldi tmpreg,0xEF 
		ldi tmpreg, 0x00
		out OCR0B,tmpreg

		ldi tmpreg, (2<<COM0B0)|(3<<WGM00) ; (3<<COM0B0) if out must be inverted
		out TCCR0A, tmpreg
	
		ret


;===== enable timer1 and configure interrupts  = enable 400V booster
	
enable_booster:
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
ret

;========================================================================

	;==================  enable timer2 /systick, realtime counter

	;timer configuration counter = 125 (124), prescaller 64 - period = 1/8 seconds
	;need to compensate -73us per second /121
enable_systick:
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
	ret
