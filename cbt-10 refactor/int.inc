EXT_INT1:
;sensor pulse
push tmpreg
in tmpreg, SREG
push tmpreg




pop tmpreg
out SREG,tmpreg
pop tmpreg
reti

PCINT1_int:
;buttons pressed/released 
push tmpreg
in tmpreg, SREG
push tmpreg


sbis PINC, PC2
rcall backlight_off

sbis PINC, PC3
rcall backlight_on


pop tmpreg
out SREG,tmpreg
pop tmpreg
reti


ADC_compl:
	push tmpreg
	in tmpreg, SREG
	push tmpreg
	push tmpregh
	push r1
	push r0

	cbi Vmeas_port, P_Vmeas

	lds tmpreg, ADCH
	lsr tmpreg
	lsr tmpreg
	dec tmpreg ; 0.1 volt correction
	mov tmpregh, tmpreg
	push tmpregh
	ldi tmpregh, 0xCD
	mul tmpregh,tmpreg
	mov tmpreg, r1
	lsr tmpreg
	lsr tmpreg
	lsr tmpreg
	ldi tmpregh,10
	mul tmpregh,tmpreg
	pop tmpregh
	sub tmpregh, r0

	sts bat_volt, tmpreg
	sts bat_tenthvolt, tmpregh

	sts ADCSRA, zeroreg
	
	pop r0
	pop r1
	pop tmpregh
	pop tmpreg
	out SREG,tmpreg
	pop tmpreg
reti

TIM1_COMPA: ; Timer1 Compare A Handler
;nop
;discharge cap
;sbi transistor
;delay
;cbi transistor 
;check feedback and manipulate frequency
cbi PORT_booster, P_bCap
sbi PORT_booster, P_bTrans
; 0us
push tmpregh ;2
push tmpreg ;2
in tmpreg, SREG ;1 - 5us
push tmpreg ;2 - 7us
push  XL ;2 - 9us
push XH ;2 - 11us
ldi tmpregh, DCboost_period;1 -12us
lds XH,OCR1AH ;2 - 14us
lds XL,OCR1AL;2 - 16us
push tmpreg; 2 - 18us
pop tmpreg; 2 - 20us
;20us
;check feedback if suppressor opened 
sbis PINC,P_boostFB
rjmp freq_up
;freq_down
; multiply opened period on 2
cpi XL,0x00
cpc XH,tmpregh
breq end_TIM1COMPA
clc
rol XL
rol XH

rjmp end_TIM1COMPA
freq_up:
;divide opened period by 2
cpi XL,DCboost_period
cpc XH,zeroreg
breq end_TIM1COMPA
clc
ror XH
ror XL

;cbi PORT_booster, P_bTrans
;wait 20 us = 20 cycles cpu

;cbi PORTD, PD1
end_TIM1COMPA:

sts OCR1AH, XH
sts OCR1AL, XL
sbiw XL,8
sts OCR1BH, XH
sts OCR1BL, XL
pop XH ;2
pop  XL ;2
pop tmpreg ;2
out SREG, tmpreg;1
pop tmpreg ;2
pop tmpregh ;2

cbi PORT_booster, P_bTrans
reti

TIM1_COMPB: ; Timer1 Compare B Handler
;charge capacitor and shift to open IRF840
;------------------------------------------
;sbic suppressor pin
sbic PINC,P_boostFB
reti

;cbi transistor
;sbi diod
;cbi capacitor

cbi PORT_booster, P_bTrans
sbi PORT_booster, P_bDiode
cbi PORT_booster, P_bCap

;do anything minimum 6 cpu cycles to charge cap

push tmpreg ;2
in tmpreg, SREG ;1
out SREG,tmpreg ;1
pop tmpreg ;2

;sbi capacitor
;cbi diod
sbi PORT_booster, P_bCap
cbi PORT_booster, P_bDiode

reti



TIM2_COMPA: ; Timer2 Compare A Handler
; 1/4 second timer

push tmpreg
in tmpreg, SREG
push tmpreg

lds tmpreg, qsecond
inc tmpreg
sbrs tmpreg, 3
rjmp end_qsecond
clr tmpreg
set
bld controlreg,qsec_tick
end_qsecond:
sts qsecond,tmpreg

lds tmpreg, qqsecond
inc tmpreg
sbrs tmpreg, 5
rjmp end_TIM2_COMPA
;every second tick
clr tmpreg
push tmpregh
;seconds manipulation
set
bld controlreg, sec_tick

in tmpreg, PORTD
ldi tmpregh, (1<<PD6)
eor tmpreg, tmpregh
out PORTD, tmpreg
pop tmpregh

end_TIM2_COMPA:
sts qqsecond,tmpreg

pop tmpreg
out SREG,tmpreg
pop tmpreg
reti
