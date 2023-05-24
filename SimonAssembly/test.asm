
delay:
push r20
	ldi r21,0xff
loop_delay1_:
	nop
	ldi r20,4
loop_delay2_:
	nop
	dec r20
	brne loop_delay2_
	dec r21
	brne loop_delay1_
	pop r20
ret

