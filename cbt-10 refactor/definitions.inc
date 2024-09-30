;definitions

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
.equ SPI_TX = PB3
.equ SPI_TXP = PORTB
.equ SPI_SCK = PB5
.equ SPI_SCKP = PORTB
.equ LCD_LED = PD5
.equ LCD_LEDP = PORTD
.equ LCD_RST = PD7
.equ LCD_RSTP = PORTD

;/* macro definitions */

;------------------------example--------------------
;.MACRO SUBI16 ; Start macro definition
;subi @1,low(@0) ; Subtract low byte
;sbci @2,high(@0) ; Subtract high byte
;.ENDMACRO ; End macro definition
;.CSEG ; Start code segment
;SUBI16 0x1234,r16,r17 ; Sub.0x1234 from r17:r1
;---------------------------------------------------

;/*registers definitions*/

.def tmpl = r16
.def tmph = r17
.def argl = r18
.def argh = r19
.def countl = r20
.def counth = r21 

;/*bits definitions*/

;/*status variable STVAR*/
.equ STNC = 0; SPI transfer is not complete