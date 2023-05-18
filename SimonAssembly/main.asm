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

	;Put correct combination into memory
	ldi zh, high(COMB_ADDRESS)
	ldi zl, low(COMB_ADDRESS)
	ldi r28, 0x0F
	st Z+, r28 ;Post increment!
	ldi r28, 0x05
	st Z, r28
	;...
	;First correct one put into r24
	ldi yh, high(COMB_ADDRESS)
	ldi yl, low(COMB_ADDRESS)
	ld	r24,Y+
	;Put combination size in r25
	/*ldi r25,0x02*/

main:
	
	
	/*call show_msg
	
	ldi r20, 0b11100101
	
	call lfsr_r20
	
loop:
	call show_r20
	rjmp loop*/
	
	
	
	/*jmp main*/

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
/*	cbi portc,2
	cbi portc,3*/
	cpi	r24,0x07 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect
	rjmp main

K4Pressed:
	cpi	r24,0x04 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect
	rjmp main

K1Pressed:
	cpi	r24,0x01 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect
	rjmp main

KAPressed:
	cpi	r24,0x0A ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect
	rjmp main

K8Pressed:
	cpi	r24,0x08 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect
	rjmp main

K5Pressed:
	cpi	r24,0x05 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect
	rjmp main

K2Pressed:
	cpi	r24,0x02 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect
	rjmp main

K0Pressed:
	cpi	r24,0x00 ;Compare with immediate
	breq Jump2C
	rjmp NotCorrect
	rjmp main

;To avoid Relative Branch Out of Reach error=================
Jump2C:
	jmp Correct
;========================

K9Pressed:
	cpi	r24,0x09 ;Compare with immediate
	breq Correct
	rjmp NotCorrect
	rjmp main

K6Pressed:
	cpi	r24,0x06 ;Compare with immediate
	breq Correct
	rjmp NotCorrect
	rjmp main

K3Pressed:
	cpi	r24,0x03 ;Compare with immediate
	breq Correct
	rjmp NotCorrect
	rjmp main

KBPressed:
	cpi	r24,0x0B ;Compare with immediate
	breq Correct
	rjmp NotCorrect
	rjmp main

KFPressed:
	cpi	r24,0x0F ;Compare with immediate
	breq Correct
	rjmp NotCorrect
	rjmp main

KEPressed:
	cpi	r24,0x0E ;Compare with immediate
	breq Correct
	rjmp NotCorrect
	rjmp main

KDPressed:
	cpi	r24,0x0D ;Compare with immediate
	breq Correct
	rjmp NotCorrect
	rjmp main

KCPressed:
	cpi	r24,0x0C ;Compare with immediate
	breq Correct
	rjmp NotCorrect
	rjmp main

KOtherPressed:
	/*sei							;Enable the buzzer*/
	rjmp NotCorrect
	rjmp main

nokeyspressed:
/*	sbi portc,2
	sbi portc,3*/
	cli
	rjmp main

Correct:
	; Jump here when correct button is pressed

	; Load next correct combination from memory
/*	ldi yh, high(COMB_ADDRESS)
	ldi yl, low(COMB_ADDRESS)*/
	ld	r24,Y
	dec r25
	sbrs r25, 0 ; skip next line if bit 0 of r20 is 0
	cbi portc,3

	cbi portc,2
	rjmp main

NotCorrect:
	sbi portc,2
	rjmp main

.equ msg_length = 6
row1:	.db		0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000
row2:	.db		0b11100, 0b11110, 0b01110, 0b01100, 0b01100, 0b11100
row3:	.db		0b10010, 0b10000, 0b00100, 0b10010, 0b10010, 0b10010
row4:	.db		0b10010, 0b11100, 0b00100, 0b10000, 0b10010, 0b10010
row5:	.db		0b11100, 0b10000, 0b00100, 0b10110, 0b10010, 0b11100
row6:	.db		0b10010, 0b10000, 0b00100, 0b10010, 0b10010, 0b10010
row7:	.db		0b10010, 0b11110, 0b01110, 0b01100, 0b01100, 0b10010

charR: .db 0b00000, 0b11100, 0b10010, 0b10010, 0b11100, 0b10010, 0b10010
charO: .db 0b00000, 0b01100, 0b10010, 0b10010, 0b10010, 0b10010, 0b01100




lfsr_r20:	; uses r20 (input/output), r21, r22
	; 8 bit lfsr, 4 taps (8,6,5,4)
	; r20 contains initial value
	.equ mask = 0b01110000 ; positions 7,6,5
	
	clr r21 ; clear r21
	sbrc r20, 0 ; skip next line if bit 0 of r20 is 0
	ser r21 ; set r21 (0b11111111)
	; now r21 contains bit 0 of r20 repeated
	
	clc
	sbrc r20, 0 ; skip next line if bit 0 of r20 is 0
	sec
	; now carry is bit 0 of r20
	
	eor r21, r20 ; xor
	andi r21, mask
	; now r21 contains the xorred bits at the right positions
	
	ldi r22, mask
	com r22
	and r20, r22 ; set all masked bits in r20 to 0
	
	or r20, r21 ; move masked bits from r21 to r20
	ror	r20 ; shift right (through carry, that's why we needed to set carry)
ret

show_r20:
	ldi r18, 7 ; # rows 
	ldi r16, 0b0000001 ; initial row selection (row 1)
loop_show_next_row_:
	push r16 ; save row selection
	
	; padding
	ldi r16, 0b00000
	ldi r17, 9 ; # segments to pad
loop_padding_:
	call show_row_segment8
	dec r17
	brne loop_padding_
	
	ldi r17, 1
loop_row_:
	mov	r16, r20 ; copy r20 into r16
	call show_row_segment8
	dec r17
	brne loop_row_
	
	pop r16
	call select_row
	lsl r16 ; select next row
	
	dec r18
	brne loop_show_next_row_
ret

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
	
	ldi r17, msg_length
loop_row:
	lpm	r16, Z+ ; load segment from program memory
	call show_row_segment8
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


;Definition of memory address of start and end of charbuffer
CHARBUFFER_START: .dw	0x0100
CHARBUFFER_END:  .dw	0x010F

CharTable:
.db 0b00000, 0b01100, 0b10010, 0b10010, 0b10010, 0b10010, 0b01100, 0b00000 ;0
.db 0b00000, 0b00100, 0b01100, 0b10100, 0b00100, 0b00100, 0b11111, 0b00000 ;1

COMB_ADDRESS: .dw 0x0500 ;?


