;definitions

;/* periphery definitions */
;PB0
;PB1
;PB2
.equ SPI_TX = PB3 ; SPI MOSI
.equ SPI_TXP = PORTB
;PB4
.equ SPI_SCK = PB5 ; SPI clock
.equ SPI_SCKP = PORTB
.equ LED = PB6; LED PIN, high inactive
.equ LEDP = PORTB; 
.equ BUZ = PB7; BUZZER
.equ BUZP = PORTB;


;PC0
;PC1
.equ BTN1 = PC2 ; Button 1
.equ BTN1P = PORTC
.equ BTN2 = PC3 ; Button2
.equ BTN2P = PORTC
;PC4
;PC5
;PC6 - RESET

.equ BSTD = PD0 ; Boost diode
.equ BSTDP = PORTD 
.equ BSTC = PD1 ; Boost capacitor
.equ BSTCP = PORTD 
.equ DRVMOS = PD2 ; Mosfet drives power mosfet IRF...
.equ DRVMOSP = PORTD
.equ SENSOR = PD3 ; Radiation sensor
.equ SENSORP = PORTD
;PD4
.equ LCD_LED = PD5 ; LCD backlight
.equ LCD_LEDP = PORTD
;PD6
.equ LCD_RST = PD7 ; LCD reset 
.equ LCD_RSTP = PORTD

;/*registers definitions*/


.def zero = r2 ; used as zero constant
.def one = r3 ; only example must be removed in future !!!!!!

.def tmpl = r16
.def tmph = r17
.def argl = r18
.def argh = r19
.def countl = r20
.def counth = r21 


;/*bits definitions*/

;/*status variable STVAR*/
.equ STNC = 0; SPI transfer is not complete

;/* macro definitions */

;------------------------example--------------------
;.MACRO SUBI16 ; Start macro definition
;subi @1,low(@0) ; Subtract low byte
;sbci @2,high(@0) ; Subtract high byte
;.ENDMACRO ; End macro definition
;.CSEG ; Start code segment
;SUBI16 0x1234,r16,r17 ; Sub.0x1234 from r17:r1
;---------------------------------------------------


.MACRO SET_BAT 
.IF @0>0x3F 
.MESSAGE "Address larger than 0x3f" 
lds @2, @0 
sbr @2, (1<<@1) 
sts @0, @2 
.ELSE 
.MESSAGE "Address less or equal 0x3f" 
.ENDIF 
.ENDMACRO