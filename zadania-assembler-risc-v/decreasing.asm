	.data
prompt:	.asciz	"Input your string:\n"
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
	jal	decrease
	
	li	a7, 1
	ecall
	li	a7, 4
	la	a0, buf
	ecall
	li	a7, 10
	ecall
	
decrease:
	li	t0, 200		# 200 is bigger than any ASCI character
	mv	t2, a0		# t2 is writing pointer
	li	t3, 0		# number of deleted chars
loop:
	lb	t1, (a0)
	beqz	t1, end
	bge	t1, t0, skip
	
	mv	t0, t1
	sb	t1, (t2)
	addi	t2, t2, 1
	addi	a0, a0, 1
	b	loop
skip:
	addi	a0, a0, 1
	addi	t3, t3, 1
	b	loop
end:
	sb	zero, (t2)
	mv	a0, t3
	ret
	
	
	