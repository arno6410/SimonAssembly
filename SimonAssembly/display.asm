;
; SimonAssembly.asm
;
; Created: 13/05/2023 15:17:08
; Author : Arno, Rogier
;

; origin
.org 0x000
rjmp init

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

init:
	; init display
	sbi ddrb, 3
	sbi ddrb, 4
	sbi ddrb, 5
	clr r1 ; should always remain cleared
	
main:
	ldi r18, 0x05 ; r18 is the 'level' counter
loop_seq:
	
	ldi xl, low(0x0100)
	ldi xh, high(0x0100)
	ldi zl, low(2*sequence)
	ldi zh, high(2*sequence)
	
	ldi r16, 0x10
loop_load_buffer:
	lpm r17, z+
	
	mov r19, r16
	subi r19, 0x10
	neg r19
	sub r19, r18
	brlt noPad
	
	ldi r21, 0x10 ; char 0x10 is an empty segment
	st x, r21
	rjmp skipp
noPad:
	st x, r17
skipp:

	adiw x, 1
	dec r16
	brne loop_load_buffer
	
loop_show:
push r18
	call show_buffer
	
	pop r18
	; add here the condition of when to go to the next level
	rjmp loop_seq

next_level:
	inc r18
	cpi r18, 0x10
	brne loop_seq
	
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

sequence: .db 0x02, 0x0A, 0x0C, 0x04, 0x00, 0x01, 0x07, 0x0B, 0x03, 0x04, 0x0A, 0x0F, 0x05, 0x0E, 0x01, 0x06

show_buffer:
	ldi r17, 0b00000001
	
	ldi r16, 7
	send8Row:
	ldi yl, low(0x0110) ; end of charbuffer (0x0100 + 16)
	ldi yh, high(0x0110)
	
	ldi r18, 16
loop_block:	
	ldi zh, high(2*char0)
	ldi zl, low(2*char0)
	
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
	dec r21
	brne loop_delay
	
	cbi portb,4
	
	dec r16
	tst r17
	brne send8row
	
ret
