	.data
prompt:	.asciz	"Enter your numbers:\n"
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
	
	li	t0, 57		# numer '9' w tabeli asci
	li	t4, 48		# numer '0' w tabeli asci
	la	t1, buf		# adres gdzie mamy pocz¹tek ci¹gu znaków
	
	
loop:
	lb	t2, (t1)	# za³aduj znak na który wksazuje adres w t1
	beqz	t2, end
	blt	t2, t4, skip
	bgt	t2, t0, skip
	
	sub	t3, t2, t4	# do t3 wpisz odleg³oœæ przesuniêcia dope³anienia od '9' ({aktualna} - '0')
	sub	t2, t0, t3	# odejmij od '9' odleg³oœæ od dope³nienia i wyjdzie dope³nienie
	sb	t2, (t1)

skip:
	addi	t1, t1, 1
	b	loop

end:
	li	a7, 4
	la	a0, header
	ecall
	li	a7, 4
	la	a0, buf
	ecall
	li	a7, 10
	ecall
	