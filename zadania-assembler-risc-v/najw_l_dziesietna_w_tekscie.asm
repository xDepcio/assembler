# '\0' == 0x00 != '0'
	.data
prompt:	.asciz	"Enter string: :\n"	# prompt to etykieta (adres w pamiêci)
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
	
	li	s0, '0'
	li	s1, '9'
	la	t0, buf		# adres pocz¹tku buffera (tekstu)
	li	t2, 0		# najwieksza liczba (na pocz¹tek najwieksza liczba to 0)
	li	t4, 0		# current number
	li	t5, 0		# adres koñca cigu najd³u¿szej liczby
	li	t6, 0		# d³ugoœæ aktualnej liczby
	li	s3, 0		# dlugoœæ najd³u¿szej liczby
	li	s4, 10
	
loop:
	lb	t1, (t0)	# do t1 zapisujemy aktualny znak
	beqz	t1, end
	blt	t1, s0, skip
	bgt	t1, s1, skip
	b	isNum
	
isNum:
	addi	t1, t1, -48	# normalizuje numer do NKB
	mul	t4, t4, s4	# t4 = t4*t3 (mnozymy razy 10^n)
	add	t4, t4, t1	# dodaj do t4 aktualnie odczytan¹ liczbê
	addi	t6, t6, 1	# zwieksz info o dluogsci aktualnej liczby o 1
	
	addi	t0, t0, 1
	bgt	t4, t2, newMax
	b	loop

newMax:
	mv	t2, t4		# zapisz do t2 nowa najiweksza liczbe
	mv	s3, t6		# zapisz info o dlugosci najwiekszej liczby
	mv	t5, t0		# zapisz adres aktualnej liczby jako koniec ciagu najd³u¿szej liczby (o 1 wiêcej)
	b	loop
	
skip:
	addi	t0, t0, 1
	li	t4, 0
	li	t6, 0
	b	loop
	
end:
	li	a7, 4
	la	a0, header
	ecall
	
	sb	zero, (t5)
	sub	t5, t5, s3
	
	li	a7, 4
	mv	a0, t5
	ecall
	li	a7, 10
	ecall	
	
	
	
	
	