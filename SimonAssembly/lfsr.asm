;
; SimonAssembly.asm
;
; Created: 13/05/2023 15:17:08
; Author : ArnoD
;

.include "m328pdef.inc"		; load addresses of IO registers

; boot
.org 0x000
rjmp init

init:
	; init display
	sbi ddrb, 3
	sbi ddrb, 4
	sbi ddrb, 5

main:
	ser r19		; set all bits in this register
	
	ldi r20, 0b11010011
ldi r17, 3
loop:
push r17
	call lfsr_r20
	cbr r19, 0
	sbrc r20, 7
	sbr r19, 0
	lsl r19
	
	pop r17
	dec r17
brne loop

	loop_sh:
	call show_r20
	rjmp loop_sh
; loop:
; 	call show_r19
; 	rjmp loop
	
	
	
jmp main

lfsr_r20:	; uses r20 (input/output), r21, r22
	; 8 bit lfsr, 4 taps (8,6,5,4)
	; r20 contains initial value
	.equ mask = 0b01110000 ; positions 7,6,5
	
	clr r21 ; clear r21
	sbrc r20, 0 ; skip next line if bit 0 of r20 is 0
	ser r21 ; set r21 (0b11111111)
	; now r21 contains bit 0 of r20 repeated
	
	eor r21, r20 ; xor
	andi r21, mask
	; now r21 contains the xorred bits at the right positions
	
	ldi r22, mask
	com r22 ; one's complement
	and r20, r22 ; set all masked bits in r20 to 0
	
	or r20, r21 ; move masked bits from r21 to r20

	clr r21 ; clear r21
	sbrc r20, 0 ; skip next line if bit 0 of r20 is 0
	ser r21 ; set r21 (0b11111111)
	; now r21 contains bit 0 of r20 repeated

	lsr	r20 ; shift right
	
	cbr r20, 7
	sbrc r21, 0
	sbr r20, 7
ret

show_r19:
	ldi r18, 7 ; # rows 
	ldi r16, 0b0000001 ; initial row selection (row 1)
loop_show_next_row_:
	push r16 ; save row selection
	
	; padding
	clr r16
	ldi r17, 9 ; # segments to pad
loop_padding_:
	call show_row_segment8
	dec r17
	brne loop_padding_
	
	ldi r17, 1
loop_row_:
	mov	r16, r19 ; copy r19 into r16
	call show_row_segment8
	dec r17
	brne loop_row_
	
	pop r16
	call select_row
	lsl r16 ; select next row
	
	dec r18
	brne loop_show_next_row_
ret

show_r20:
	ldi r18, 7 ; # rows 
	ldi r16, 0b0000001 ; initial row selection (row 1)
loop_show_next_row:
	push r16 ; save row selection
	
	; padding
	clr r16
	ldi r17, 9 ; # segments to pad
loop_padding:
	call show_row_segment8
	dec r17
	brne loop_padding
	
	ldi r17, 1
loop_row:
	mov	r16, r20 ; copy r19 into r16
	call show_row_segment8
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


