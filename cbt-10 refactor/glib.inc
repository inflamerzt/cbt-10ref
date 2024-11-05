;=============================================================
;   Graphics primitives function library
;	Compose elements appears on screen, timers, menu, etc...
;=============================================================

test_primitive:
;====================================
; testing graphics primitives
;====================================
	LCD_XY 0,0

	;LCD_dat RAD_BIG

	;LCD_XY 0,4
	;LCD_dat pausa
	;LCD_dat plav
	;LCD_dat summa
	;LCD_dat cps
	;LCD_dat mkrh
	;/*
	;------------LCD_dat batter
	LCD_dat batter_cap
	LCD_dat batter_nofill
	LCD_dat batter_fill
	LCD_dat batter_nofill
	LCD_dat batter_fill
	LCD_dat batter_nofill
	LCD_dat batter_fill
	LCD_dat batter_nofill
	LCD_dat batter_fill
	LCD_dat batter_nofill
	LCD_dat batter_fill
	LCD_dat batter_bcap
	;*/
	;LCD_dat Alfa  
	;LCD_dat  beta
	;LCD_dat gamma
	;LCD_dat summa_ravno
	;LCD_dat result
	;LCD_dat rc
	;LCD_dat grom_shek
	;LCD_dat zvuk_opov ; not displays correctly
	;LCD_dat fon_porog
	;LCD_dat podsvetka ; not displays correctly
	;LCD_dat vkl
	;LCD_dat vblkl
	;LCD_dat mkr
	;LCD_dat minus
	;LCD_dat plus
	;LCD_dat nastroiki_datchika ; needs to be reformated (pack data)
	;LCD_dat strelka
	
	;LCD_XY_shift 0,4,20 ; uses tmpreg and 2 more instructions
	/*
	LCD_XY 20,3
	
	LCD_dat RODGER
	
	; half rodger
	LCD_XY 30,3
	;LCD_inv
	LCD_spX 10,2
	;LCD_norm
	*/


	;==========================================================

LCD_XY 20,3

LCD_XY 0,1
LCD_dat MINI_CIFRA_0
LCD_spX 1,1
LCD_dat MINI_dot
LCD_dat MINI_CIFRA_0
LCD_dat volt
;LCD_dat MINI_CIFRA_1
;LCD_dat MINI_CIFRA_2
;LCD_dat MINI_CIFRA_3
;LCD_dat MINI_CIFRA_4
;LCD_dat MINI_CIFRA_5
;LCD_dat MINI_CIFRA_6
;LCD_dat MINI_CIFRA_7
;LCD_dat MINI_CIFRA_8
;LCD_dat MINI_CIFRA_9
;LCD_dat ne_CIFRA
;LCD_dat MINI_dot
;LCD_dat CIFRA_0
;LCD_dat CIFRA_1
;LCD_dat CIFRA_2
;LCD_dat CIFRA_3
;LCD_dat CIFRA_4
;LCD_dat CIFRA_5
;LCD_dat CIFRA_6
;LCD_dat CIFRA_7
;LCD_dat CIFRA_8
;LCD_dat CIFRA_9
;LCD_dat ZAPITAY
;LCD_dat RAD_BIG ;possible to cut spaces
;LCD_dat RAD_0
;LCD_dat RAD_1
;LCD_dat RAD_2
;LCD_dat RAD_3
;LCD_dat RODGER
;LCD_dat PAUSA
;LCD_dat PLAV
;LCD_dat SUMMA
;LCD_dat CPS
;LCD_dat MkrH ; reduce size
;LCD_dat Batter ; remove zeroes from below
;LCD_dat Batter_fill
;LCD_dat Batter_nofill
;LCD_dat Batter_cap
;LCD_dat Batter_bcap
;LCD_dat DDot
;LCD_dat Alfa
;LCD_dat Beta
;LCD_dat Gamma
;LCD_dat Equal
;LCD_dat Summa_ravno ; separate "=" and maybe reduce to 1 line
;LCD_dat Result ; reduce spaces and maybe reduce to 1 line
;LCD_dat On
;LCD_dat Off
;LCD_dat Minus
;LCD_dat Plus
;LCD_dat Strelka
;--------------------
LCD_XY 16,0
;LCD_dat soundOFF
LCD_dat soundON
LCD_XY 17,1
;LCD_dat alarmOFF
LCD_dat alarmON
;LCD_XY 11,1

;LCD_dat count_menu
;LCD_dat alarm_menu
;LCD_dat threshold_menu
;LCD_dat volume_menu
;LCD_dat bright_menu
;LCD_dat senset_menu
;LCD_dat batcal_menu
;LCD_dat contrast_menu
;LCD_dat count_pic
;LCD_dat alarm_pic
;LCD_dat threshold_pic
;LCD_dat clk_vol_pic
;LCD_dat bright_pic
;LCD_dat sen_set_pic
;LCD_dat bat_cal_pic
;LCD_dat contr_pic

;==========================================================


ret
;================================================================
; Testing screens settings menu, modes, etc
;================================================================
test_screen:
	;========= fill zeroes at timer positions
	
	LCD_XY timer_posx,timer_posy
	LCD_dat CIFRA_0
	LCD_XY timer_posx+8,timer_posy
	LCD_dat	CIFRA_0
	LCD_XY timer_posx+16,timer_posy
	LCD_dat DDot
	LCD_XY timer_posx+20,timer_posy
	LCD_dat CIFRA_0
	LCD_XY timer_posx+28,timer_posy
	LCD_dat CIFRA_0		
	LCD_XY timer_posx+36,timer_posy
	LCD_dat DDot
	LCD_XY timer_posx+40,timer_posy
	LCD_dat CIFRA_0
	LCD_XY timer_posx+48,timer_posy
	LCD_dat CIFRA_0
	LCD_XY 96-10,0
	LCD_dat SUMMA
ret

;===============================================================