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
	
	
	
	ldi xl,0x00
	ldi xh,0x01
	ldi zl, low(2*sequence)
	ldi zh, high(2*sequence)
	
	ldi r16, 0x10
loop_load_buffer:
	lpm r17, z+
	st x+, r17
	
	dec r16
	brne loop_load_buffer
	
	call show_buffer

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

sequence: .db 0x02, 0x0A, 0x0C, 0x09, 0x00, 0x01, 0x07, 0x0B, 0x03, 0x04, 0x0A, 0x0F, 0x05, 0x0E, 0x01, 0x06

select_row:
	push r20
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
	ldi r20, 255
delayloop1:
	subi r20, 1
	breq enddelayloop1
	nop
	rjmp delayloop1
enddelayloop1:
	cbi portb, 4
	
	pop r20
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

show_buffer:
	ldi r21, 7
	ldi r20, 0b00000001

	send8Row:
		;send column data
		ldi r22,16 ;#block
		ldi yl, low(0x0110) ; end of charbuffer (0x0100 + 16)
		ldi yh, high(0x0110)
		blockloop:	
			ldi zh, high(2*char0)
			ldi zl, low(2*char0)
			
			clr r6
			add zl,r21 ;+(rownumber-1)
			adc zh, r6 ;(adc is add with carry or zh + r6 + carry bit)

			ld r23,-y

			ldi r19,8
			loop:
				add zl,r23
				adc zh,r6
				dec r19
			brne loop

			lpm
			ldi r16,5
			

			blockcolloop:
				;send 5 bits of loaded byte to the screen
				cbi portb,3
				ror r0
				brcc carryis0
					sbi portb,3
				carryis0:
				cbi portb,5
				sbi portb,5

				dec r16
				brne blockcolloop

			dec r22
			brne blockloop

		ldi r19,8
		clc

		rowloop:
				cbi portb,3 ;init pb=0
			ror r20
			brcc carryis1
				sbi portb,3
			carryis1:
			cbi portb,5
			sbi portb,5 ;create rising edge of pb5 to shift

			dec r19 ;loop 8 times
			brne rowloop

;	rcall select_row

		rcall enable
		dec r21
		tst r20
		brne send8row
		
ret

enable:
	sbi portb,4
	rcall delay
	cbi portb,4
ret

delay:
	ldi r16,0xff
	delayloop1_:
		nop
		ldi r17,4
		delayloop2:
			nop
			dec r17
			brne delayloop2
		dec r16
		brne delayloop1_
ret

COMB_ADDRESS: .dw 0x0500 ;?


