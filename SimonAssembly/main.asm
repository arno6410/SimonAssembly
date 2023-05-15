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

main:
	; set Z register to memory address of beginning of message 
	ldi zh, high(2*row1)
	ldi zl, low(2*row1)
	
	call show_msg
	
	ldi r20, 0b11100101
	
	call lfsr_r20
	
loop:
	call show_r20
	rjmp loop
	
	
	
	jmp main

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


