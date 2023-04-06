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
	
	li	t0, '9'		# numer '9' w asci (57)
	li	t1, '0'		# numer '0' w asci (48)
	la	t2, buf		# wskazanie (adres) pocz¹tku buf
	li	t5, 0		# 0 - ostatnie nie by³a liczba, 1 - ostatnie by³a liczba
	li	s11, 0		# ustawiamy pocz¹tkow¹ najd³. d³ugoœæ na 0
	la	s1, buf		# ustawiamy pocz¹tkowy pocz¹tek ci¹gu na pocz¹tek buff
	mv	s2, s1		# ustawiamy pocz¹tkowy koniec ci¹gu na pocz¹tek buff
	
loop:
	lb	t3, (t2)	# do t3 ³adujemy to na co wskazuje t2
	beqz	t3, end
	bgt	t3, t0, notN
	blt	t3, t1, notN
	b	isN

isN:
	beqz	t5, sStart
	addi	t2, t2, 1
	b	loop

notN:
	bnez	t5, sEnd
	addi	t2, t2, 1
	b	loop

sStart:	
	mv	t4, t2		# zapisujemy do t4 adres pocz¹teku ci¹gu liczb
	li	t5, 1
	addi	t2, t2, 1
	b	loop
sEnd:
	mv	t6, t2		# zapisujemy do t6 adres koñca ci¹gu
	sub	s10, t6, t4	# zapisujemy d³ugoœæ ci¹gu
	bgt	s10, s11, newMax# jak d³uoœæ jest wiêksza ni¿ póki co najwiêksza to skaczemy do newMax
	addi	t2, t2, 1
	li	t5, 0		# zapisz ¿e ostatni znak to nie liczba
	b	loop
newMax:
	mv	s1, t4		# zapamietujemy do s1 adres pocz¹teu ci¹gu 
	mv 	s2, t6		# zapamietujemy do s2 adres koñca ci¹gu
	mv	s11, s10	# zapisujemy do s11 now¹ najwiêksz¹ d³ugoœæ
	addi	t2, t2, 1
	li	t5, 0		# zapisz ¿e ostatni znak to nie liczba
	b	loop

end:
	li	a7, 4
	la	a0, header
	ecall
	
	sb	zero, (s2)	# na koñcu ci¹gu wpisujemy 0x00 aby na tym elemencie skoñczyæ
	
	li	a7, 4
	mv	a0, s1
	ecall
	li	a7, 10
	ecall
	
	
	