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
	la	a0, buf
	li	a1, 100
	ecall
	
	la	a0, buf
	jal	remInBrackets
	
	li	a7, 1
	ecall
	li	a7, 4
	la	a0, header
	ecall
	li	a7, 4
	la	a0, buf
	ecall
	li	a7, 10
	ecall
	
	
remInBrackets:
	li	s0, '['		# number of '[' in ASCI
	li	s1, ']'		# number of '[' in ASCI
	li	t0, 0		# should remove = 1, shouldn't remove = 0
	li	t3, 0		# removing finsihed
	mv	t2, a0		# writing address
	li	t4, 0		# final chars length
	li	s3, 10		# ASCI line feed
loop:
	lb	t1, (a0)	# load char pointed by a0 to t1
	beq	t1, s3, end
	#beqz	t1, end
	bnez	t3, write
	beq	t1, s0, startRemChar	# if(t1(char) == s0('[')) goto startRem
	beqz	t0, write
	beq	t1, s1, stopRemChar
skip:
	addi	a0, a0, 1
	b	loop

write:
	sb	t1, (t2)
	addi	t2, t2, 1
	addi	a0, a0, 1
	addi	t4, t4, 1
	b	loop

startRemChar:
	bnez	t0, skip
	li	t0, 1
	b	write
	
stopRemChar:
	li	t3, 1
	b	write
end:
	sb	zero, (t2)
	mv	a0, t4
	ret
	
	
	
	
	
	
	
	
	
	