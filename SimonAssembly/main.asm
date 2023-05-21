;
; SimonAssembly.asm
;
; Created: 13/05/2023 15:17:08
; Author : ArnoD
;

.include "m328pdef.inc"		;Load addressess of IO registers

; boot
.org 0x000
rjmp init

init:
	; init display
	sbi ddrb, 3
	sbi ddrb, 4
	sbi ddrb, 5

main:
	; set Z register to memory address of beginning of message 
	ldi yh, high(2*msg)
	ldi yl, low(2*msg)
	
	call show_msg
	
	jmp main

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

.macro shift_reg
	sbrc r16, @0 ; bit # of r16 to shift into register
	sbi portb, 3
	cbi portb, 5
	sbi portb, 5
	cbi portb, 3
.endmacro

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


