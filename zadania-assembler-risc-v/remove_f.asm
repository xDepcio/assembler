	.data
prompt:	.asciz	"Enter your input:\n"
header:	.asciz	"\nOutput:\n"
buf:	.space	100

	.text
	.globl	main
main:
	li	a7, 4
	la	a0, prompt
	ecall
	li	a7, 8
	li	a1, 100
	la	a0, buf
	ecall
	
	la	a0, buf		# w a0 zapisaujemy pocz¹tek bufoora input
	jal	remove
	
	li	a7, 1
	ecall
	li	a7, 4
	la	a0, buf
	ecall
	li	a7, 10
	ecall

remove:
	li	s0, 'a'		# w s0 numer 'a' w ASCI 
	li	s1, 'z'		# w 11 numer 'z' w ASCI
	mv	t1, a0		# do t1 kopiujemy pocz¹tek ci¹gu, czyli a0
	li	t2, 0		# iloœc ma³ych liter w s³owie

loop:
	lb	t0, (a0)	# do t0 ³adujemy to na co wskazuje a0
	
	beqz	t0, end
	bgt	t0, s1, skip	# if(t0 > 'z'): skip
	blt	t0, s0, skip	# if(t0 < 'a'): skip
	
	sb	t0, (t1)
	addi	t1, t1, 1
	addi	t2, t2, 1

skip:
	addi	a0, a0, 1
	b	loop
	
end:
	sb	zero, (t1)
	mv	a0, t2
	ret
	


	