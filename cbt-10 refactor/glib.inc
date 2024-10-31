;=============================================================
;   Graphics primitives function library
;	Compose elements appears on screen, timers, menu, etc...
;=============================================================

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
	LCD_XY 96-14,0
	LCD_dat SUMMA
ret