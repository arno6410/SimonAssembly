;
; SimonAssembly.asm
;
; Created: 13/05/2023 15:17:08
; Author : Arno, Rogier
;

; origin
.org 0x000
rjmp init
.org 0x0020
rjmp TimerOverflowInterrupt

.include "m328pdef.inc"		;Load addresses of IO registers
;.include "test.asm"

.macro shift_reg
	cbi portb,3
	ror @0
	brcc carry_cleared
	sbi portb,3
carry_cleared:
	cbi portb,5
	sbi portb,5
.endmacro

.def showDisplay = r3

init:
	clr showDisplay
	com showDisplay
	; init display
	sbi ddrb, 3
	sbi ddrb, 4
	sbi ddrb, 5
	
	;Configure output pin PC2 (LED1)
	sbi ddrc,2					;Pin PC2 is an ouput, set to 1
	sbi portc,2					;Output Vcc => LED2 is turned off!

	;Configure output pin PC3 (LED2)
	sbi ddrc,3					;Pin PC3 is an ouput, set to 1
	sbi portc,3					;Output Vcc => LED1 is turned off!

	;Configure input pin PB0 (switch)
	cbi ddrb,0					;Pin PB0 is an input, CBI (clear bit i/o) sets DDRB bit 2 to 0	
	sbi portb,0					;Enables the pull-up resistor (to avoid floating)

	;Configure input pins PD (keyboard)
	ldi r16, 0b00001111			;Do it this way, the excel says that you should use in/out, use ldi first to put the address in a register
	out ddrd, r16				;Pins PD 3-0 are input set to 0, 7-4 are output set to 1
	ldi r16, 0b11110000			;Enable pull up resistors for 7 downto 4, these are the rows and will be the input pins
	out portd, r16				;The columns will be the output pins

	;==========TIMER 1: 16 bit==========

	ldi r20, 0b00000000 ; CTC mode, int clk; not necessary?
	sts tccr1a, r20     
	ldi r20, 0b00000101 ; prescaler /1024
	sts tccr1b, r20
	
	ldi r16,0b01100001 ; low byte
	sts TCNT1L,r16
	ldi r16,0b11011011 ;1101 1011 0110 0001 is 56161 in decimal
	sts TCNT1H,r16

	ldi r16, 0b00000100
	sts timsk1, r16 ;Set toie0 bit to 1, to enable timer/counter0 overflow
	sei ;Turn on timer (always on?)
	;====================

	;First correct one put into r24
	ldi zh, high(2*sequence)
	ldi zl, low(2*sequence)
	lpm	r24,z+
	;Put combination size in r25
	ldi r25,0x01
	mov r6,r25 ;r6 will be used to keep track of the combination
	mov r18, r6
	/*mov r9,r25	;r9 stores the current winning combination length*/
	rcall load_buffer
	
	
main:
	sbrc showDisplay, 1
	rcall show_buffer
	
	rjmp main
	
char0: .db 0b00000, 0b01100, 0b10010, 0b10110, 0b11010, 0b10010, 0b01100, 0
char1: .db 0b00000, 0b00100, 0b01100, 0b10100, 0b00100, 0b00100, 0b01110, 0
char2: .db 0b00000, 0b01100, 0b10010, 0b00010, 0b00100, 0b01000, 0b11110, 0
char3: .db 0b00000, 0b01100, 0b10010, 0b00100, 0b00010, 0b10010, 0b01100, 0
char4: .db 0b00000, 0b00100, 0b01100, 0b10100, 0b11110, 0b00100, 0b00100, 0
char5: .db 0b00000, 0b11110, 0b10000, 0b11100, 0b00010, 0b10010, 0b01100, 0
char6: .db 0b00000, 0b01100, 0b10000, 0b11100, 0b10010, 0b10010, 0b01100, 0
char7: .db 0b00000, 0b11110, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000, 0
char8: .db 0b00000, 0b01100, 0b10010, 0b01100, 0b10010, 0b10010, 0b01100, 0
char9: .db 0b00000, 0b01100, 0b10010, 0b10010, 0b01110, 0b00010, 0b01100, 0
charA: .db 0b00000, 0b01100, 0b10010, 0b10010, 0b11110, 0b10010, 0b10010, 0
charB: .db 0b00000, 0b11100, 0b10010, 0b11100, 0b10010, 0b10010, 0b11100, 0
charC: .db 0b00000, 0b01100, 0b10010, 0b10000, 0b10000, 0b10010, 0b01100, 0
charD: .db 0b00000, 0b11100, 0b10010, 0b10010, 0b10010, 0b10010, 0b11100, 0
charE: .db 0b00000, 0b11110, 0b10000, 0b11100, 0b10000, 0b10000, 0b11110, 0
charF: .db 0b00000, 0b11110, 0b10000, 0b11100, 0b10000, 0b10000, 0b10000, 0
empty: .db 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0

;uncomment to select a combination
;sequence: .db 0x02, 0x0A, 0x0C, 0x04, 0x00, 0x01, 0x07, 0x0B, 0x03, 0x04, 0x0A, 0x0F, 0x05, 0x0E, 0x01, 0x06
;sequence: .db 0x01, 0x09, 0x0A, 0x0C, 0x03, 0x05, 0x0E, 0x01, 0x00, 0x09, 0x0C, 0x0D, 0x04, 0x0F, 0x00, 0x01
sequence: .db 0x0D, 0x0A, 0x0B, 0x05, 0x02, 0x0D, 0x09, 0x0D, 0x04, 0x0D, 0x0D, 0x0C, 0x0B, 0x0E, 0x09, 0x06

show_buffer: ; uses r1, r2, r16, 17, 18, 21
	push r16
	push r17
	push r18
	push r21
	
	ldi r17, 0b00000001
	
	ldi r16, 7
loop_row:
	ldi yl, low(0x0110) ; end of charbuffer (0x0100 + 16)
	ldi yh, high(0x0110)
	
	ldi r18, 16
loop_block:	
	ldi zh, high(2*char0)
	ldi zl, low(2*char0)
	
	clr r1
	add zl, r16
	adc zh, r1
	
	ld r2, -y
	lsl r2
	lsl r2
	lsl r2
	add zl, r2 
	adc zh, r1

	lpm ; loads (z) into r0
	
	ldi r21,5
loop_segment5:
	shift_reg r0
	dec r21
	brne loop_segment5

	dec r18
	brne loop_block

	clc
	ldi r21,8
loop_select_row:
	shift_reg r17
	dec r21
	brne loop_select_row

; enter into display

	sbi portb,4
	
	ldi r21,0xff
loop_delay:
	nop
	nop
	nop
	nop
	nop
	dec r21
	brne loop_delay
	
	cbi portb,4
	
	dec r16
	brne loop_row
	
	pop r21
	pop r18
	pop r17
	pop r16
ret






CheckButtons:

	ldi r20, 0b11110111			;low,high,high,high to see the first row
	ldi r21, 0b11111011			;high,low,high,high to see the second row
	ldi r22, 0b11111101			;high,high,low,high to see the third row
	ldi r23, 0b11111110			;high,high,high,low to see the fourth row
	
	out portd, r20
	nop
	nop

	sbis pind,7					;Skip next instruction if the most significant bit of pin D is set.
	rjmp K7Pressed
	sbis pind,6					;Skip next if bit 6 of pin D is 1
	rjmp K4Pressed
	sbis pind,5					;Skip next if bit 5 of pin D is 1
	rjmp K1Pressed
	sbis pind,4					;Skip next if bit 4 of pin D is 1
	rjmp KAPressed

	out portd, r21
	nop
	nop

	sbis pind,7					;Skip next instruction if the most significant bit of pin D is set.
	rjmp K8Pressed		
	sbis pind,6					;Skip next if bit 6 of pin D is 1
	rjmp K5Pressed
	sbis pind,5					;Skip next if bit 5 of pin D is 1
	rjmp K2Pressed
	sbis pind,4					;Skip next if bit 4 of pin D is 1
	rjmp K0Pressed	
	
	out portd, r22
	nop
	nop

	sbis pind,7					;Skip next instruction if the most significant bit of pin D is set.
	rjmp K9Pressed		
	sbis pind,6					;Skip next if bit 6 of pin D is 1
	rjmp K6Pressed
	sbis pind,5					;Skip next if bit 5 of pin D is 1
	rjmp K3Pressed
	sbis pind,4					;Skip next if bit 4 of pin D is 1
	rjmp KBPressed		
	
	out portd, r23
	nop
	nop

	sbis pind,7					;Skip next instruction if the most significant bit of pin D is set.
	rjmp KFPressed		
	sbis pind,6					;Skip next if bit 6 of pin D is 1
	rjmp KEPressed
	sbis pind,5					;Skip next if bit 5 of pin D is 1
	rjmp KDPressed
	sbis pind,4					;Skip next if bit 4 of pin D is 1
	rjmp KCPressed			

	rjmp nokeyspressed

K7Pressed:
	cpi	r24,0x07 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect

K4Pressed:
	cpi	r24,0x04 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect

K1Pressed:
	cpi	r24,0x01 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect

KAPressed:
	cpi	r24,0x0A ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect

K8Pressed:
	cpi	r24,0x08 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect

K5Pressed:
	cpi	r24,0x05 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect

K2Pressed:
	cpi	r24,0x02 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect

K0Pressed:
	cpi	r24,0x00 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect

;==========To avoid Relative Branch Out of Reach error==========
Jump2C:
	jmp Correct

K9Pressed:
	cpi	r24,0x09 ;Compare with immediate
	breq Correct
	rjmp NotCorrect

K6Pressed:
	cpi	r24,0x06 ;Compare with immediate
	breq Correct
	rjmp NotCorrect

K3Pressed:
	cpi	r24,0x03 ;Compare with immediate
	breq Correct
	rjmp NotCorrect

KBPressed:
	cpi	r24,0x0B ;Compare with immediate
	breq Correct
	rjmp NotCorrect

KFPressed:
	cpi	r24,0x0F ;Compare with immediate
	breq Correct
	rjmp NotCorrect

KEPressed:
	cpi	r24,0x0E ;Compare with immediate
	breq Correct
	rjmp NotCorrect

KDPressed:
	cpi	r24,0x0D ;Compare with immediate
	breq Correct
	rjmp NotCorrect

KCPressed:
	cpi	r24,0x0C ;Compare with immediate
	breq Correct
	rjmp NotCorrect

KOtherPressed:
	rjmp NotCorrect

nokeyspressed:
	in r4,pinb					;Put value of PINB in R0 (entire byte)
	bst r4,0	;Copy PB0 (bit 0 of PINB) to the T flag (single bit)
	;The switch is high if the T flag is cleared
	brts NotCorrect				;Branch of the T flag is cleared
	rjmp finishCheckButtons

Correct:
	; Jump here when correct button is pressed

	cbi portc,3
	; Load next correct combination from memory
	ldi zh, high(2*sequence)
	ldi zl, low(2*sequence)
	
	add zl, r6 ;add r6 since this is the current amount of correct symbols in a row
	adc zh, r1
	lpm r24, z
	cp r6,r25 ; check to see if nth correct button == total correct length	
	breq Win ;Reset if combination finished
	inc r6

	/*cbi portc,2*/

	rjmp finishCheckButtons

NotCorrect:
	ldi r25,0x01 ;Reset combination to length = 1
	sbi portc,3 ;Turn off LED 2
	rjmp Reset

Win:
	cbi portc,3
	inc r25 ;Make the combination one letter longer

Reset:
	;When wrong combination 
	com showDisplay ; invert r3 -> make display visible
	ldi zh, high(2*sequence)
	ldi zl, low(2*sequence)
	lpm	r24,z+
	push r25
	ldi r25,0x01
	mov r6,r25
	pop r25
	
finishCheckButtons:
	ret ;from rcall CheckButtons

TimerOverflowInterrupt:
	push r16
	

	;====1HZ: 49911, prescaler 1024====
	ldi r16,0b11110111 ; low byte
	sts TCNT1L,r16
	ldi r16,0b11000010 ;1100 0010 1111 0111 is 49911 in decimal
	sts TCNT1H,r16	
;	rjmp OFContinue

OFContinue:
	pop r16

	clr showDisplay
	
	
	sbi pinc,2 ;Flips the value
	sbi portc,3 ;Turn off LED 2
	
	sbis portc,2 ; only check buttons on rising edge
	rcall CheckButtons

	rcall load_buffer
reti
	
load_buffer:
	
	ldi yl, low(0x0100)
	ldi yh, high(0x0100)
	ldi zl, low(2*sequence)
	ldi zh, high(2*sequence)
	
	ldi r16, 0x10
loop_load_buffer2:
	lpm r17, z+
	
	mov r19, r16
	subi r19, 0x10
	neg r19
	sub r19, r25
	brlt noPad2
	
	ldi r21, 0x10 ; char 0x10 is an empty segment
	st y, r21
	rjmp skipp2
noPad2:
	st y, r17
skipp2:

	adiw y, 1
	dec r16
	brne loop_load_buffer2
	
	ret
