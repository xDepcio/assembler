	.data
prompt:	.asciz	"Enter your combination:\n"
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
	
	li	s0, '0'
	li	s1, '9'
	la	t0, buf
	li	t2, 0		# 1 - last was number, 0 - last wasn't number 
	li	t3, 0		# count of numbers in sequence

loop:
	lb	t1, (t0)

	beqz	t1, end
	bgt	t1, s1, skip
	blt	t1, s0, skip
	b	isNum

skip:
	li	t2, 0		# set t2 to: last one wasn't a number
	addi	t0, t0, 1
	b	loop


isNum:
	beqz	t2, inc_nums
	addi	t0, t0, 1
	b	loop

inc_nums:
	li	t2, 1		# set t2 to: last one was a number
	addi	t3, t3, 1
	addi	t0, t0, 1
	b	loop
	
end:
	li	a7, 4
	la	a0, header
	ecall
	
	li	a7, 36
	mv	a0, t3
	ecall
	
	li	a7, 10
	ecall
	
	
	
	