;
; SimonAssembly.asm
;
; Created: 13/05/2023 15:17:08
; Author : Arno, Rogier
;

.include "m328pdef.inc"		;Load addressess of IO registers

; boot
.org 0x000
rjmp init
.org 0x0020
rjmp Timer1OverflowInterrupt

.macro shift_reg
	sbrc r16, @0 ; bit # of 16 to shift into register
	sbi portb, 3
	cbi portb, 5
	sbi portb, 5
	cbi portb, 3
.endmacro

init:
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

	/*	ldi r16,0x00 ;To ensure 4Hz with prescaler 64
	sts TCNT1L,r16
	ldi r16,0X00 ;1011 1101 1100 is 3036 in decimal
	sts TCNT1H,r16*/

	ldi r17,0b11011100 ;To ensure 1Hz with prescaler 256
	sts TCNT1L,r17
	ldi r16,0b00001011 ;1011 1101 1100 is 3036 in decimal
	sts TCNT1H,r16

	ldi r16, 0b00000100
	sts timsk1, r16 ;Set toie0 bit to 1, to enable timer/counter0 overflow
	sei ;Turn on timer (always on?)
	;====================

	;Put correct combination into memory
	ldi zh, high(COMB_ADDRESS)
	ldi zl, low(COMB_ADDRESS)
	ldi r28, 0x01
	st Z+, r28 ;Post increment!
	ldi r28, 0x02
	st Z+, r28
	ldi r28, 0x03
	st Z+, r28
	ldi r28, 0x04
	st Z+, r28
	ldi r28, 0x05
	st Z+, r28
	ldi r28, 0x06
	st Z+, r28
	;...
	;First correct one put into r24
	ldi yh, high(COMB_ADDRESS)
	ldi yl, low(COMB_ADDRESS)
	ld	r24,Y+
	;Put combination size in r25
	ldi r25,0x01
	mov r26,r25 ;r26 will be used to keep track of the combination
	
main:
	
	rjmp main

	/*cli*/
	
	/*call show_msg
	
	ldi r20, 0b11100101
	
	call lfsr_r20
	
loop:
	call show_r20
	rjmp loop*/
	
	
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
;========================
DELAY:
	push r16
	push r17
	LDI R16,0xFF
	Delayloop1_:
		NOP
		LDI R17,4
		DelayLoop2:
			NOP
			DEC R17
			BRNE DelayLoop2
		DEC R16
		BRNE DelayLoop1_
	pop r17
	pop r16
RET
;========================

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

	ret ;from rcall CheckButtons

Correct:
	; Jump here when correct button is pressed

	; Load next correct combination from memory
	ld r24,Y+
	dec r26	
	breq Win ;Reset if combination finished

	/*cbi portc,2*/

	ret ;from rcall CheckButtons

NotCorrect:
	ldi r25,0x01 ;Reset combination to length = 1
	rjmp Reset

Win:
	cbi portc,3
	inc r25 ;Make the combination one letter longer

Reset:
	;When wrong combination 
	ldi yh, high(COMB_ADDRESS)
	ldi yl, low(COMB_ADDRESS)
	ld	r24,Y+
	mov r26,r25

	ret ;from rcall CheckButtons


.equ msg_length = 6
row1:	.db		0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000
row2:	.db		0b11100, 0b11110, 0b01110, 0b01100, 0b01100, 0b11100
row3:	.db		0b10010, 0b10000, 0b00100, 0b10010, 0b10010, 0b10010
row4:	.db		0b10010, 0b11100, 0b00100, 0b10000, 0b10010, 0b10010
row5:	.db		0b11100, 0b10000, 0b00100, 0b10110, 0b10010, 0b11100
row6:	.db		0b10010, 0b10000, 0b00100, 0b10010, 0b10010, 0b10010
row7:	.db		0b10010, 0b11110, 0b01110, 0b01100, 0b01100, 0b10010

msg: .dw charR, charO, charG, charI, charE, charR
charR: .db 0b00000, 0b11100, 0b10010, 0b10010, 0b11100, 0b10010, 0b10010
charO: .db 0b00000, 0b01100, 0b10010, 0b10010, 0b10010, 0b10010, 0b01100
charG: .db 0b00000, 0b01100, 0b10010, 0b10000, 0b10110, 0b10010, 0b01100
charI: .db 0b00000, 0b01110, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110
charE: .db 0b00000, 0b11110, 0b10000, 0b11100, 0b10000, 0b10000, 0b11110



show_msg:
	ldi r18, 7 ; # rows 
	ldi r16, 0b0000001 ; initial row selection (row 1)
loop_show_next_row:
	push r16 ; save row selection
	
	; padding
	ldi r16, 0b00000
	ldi r17, 16-msg_length ; # segments to pad
loop_padding:
	call show_row_segment5
	dec r17
	brne loop_padding
	
	ldi yh, high(2*msg)
	ldi yl, low(2*msg)
	
	ldi r17, msg_length
loop_row:
	
	ld zh, y+
	ld zl, y+
	
	sbiw z, 1
	push r18
	subi r18, 8
	neg r18
loop_z:
	adiw z, 1
	dec r18
	brne loop_z
	pop r18
	
	lpm	r16, z ; load segment from program memory
	call show_row_segment5
	dec r17
	brne loop_row
	
	pop r16
	call select_row
	lsl r16 ; select next row
	
	dec r18
	brne loop_show_next_row
ret



select_row:
	push r16
	cbi portb, 3

	shift_reg 7
	shift_reg 6
	shift_reg 5
	shift_reg 4
	shift_reg 3
	shift_reg 2
	shift_reg 1
	shift_reg 0
	
	; latch to show row on display
	sbi portb, 4
	ldi r16, 255
delayloop1:
	subi r16, 1
	breq enddelayloop1
	nop
	rjmp delayloop1
enddelayloop1:
	cbi portb, 4
	
	pop r16
ret
	
; show a row segment (5 pixels wide)
show_row_segment5:
	cbi portb, 3
	
	shift_reg 0 ; pixel 0
	shift_reg 1
	shift_reg 2
	shift_reg 3
	shift_reg 4 ; pixel 4	
ret

; show a row segment (8 pixels wide)
show_row_segment8:
	cbi portb, 3
	
	shift_reg 0 ; pixel 0
	shift_reg 1
	shift_reg 2
	shift_reg 3
	shift_reg 4
	shift_reg 5
	shift_reg 6
	shift_reg 7	
ret

Timer1OverflowInterrupt:
	push r16
	push r17

	;====1HZ: 49911, prescaler 1024====
	ldi r17,0b11110111 ; low byte
	sts TCNT1L,r17
	ldi r16,0b11000010 ;1100 0010 1111 0111 is 49911 in decimal
	sts TCNT1H,r16	

/*	;====0.5Hz: 34286, prescaler 1024====
	ldi r17,0b10000101 ; low byte
	sts TCNT1L,r17
	ldi r16,0b11101110 ;1110 1110 1000 0101 is 34286 in decimal
	sts TCNT1H,r16*/

	pop r17
	pop r16

	sbi pinc,2 ;Flips the value
	sbi portc,3 ;Turn of LED 2

	rcall CheckButtons

	reti


;Definition of memory address of start and end of charbuffer
CHARBUFFER_START: .dw	0x0100
CHARBUFFER_END:  .dw	0x010F

CharTable:
.db 0b00000, 0b01100, 0b10010, 0b10010, 0b10010, 0b10010, 0b01100, 0b00000 ;0
.db 0b00000, 0b00100, 0b01100, 0b10100, 0b00100, 0b00100, 0b11111, 0b00000 ;1

COMB_ADDRESS: .dw 0x0500 ;?


