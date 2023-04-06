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
	la	a0, buf
	li	a1, 100
	ecall
	
	la	t0, buf
	li	t1, 97		# kod asci ma³ego 'a'
	li	t2, 'z'		# rózniez kod asci, ale ma³ego 'z'
	li	t3, 0x20	# odleg³oœæ miedzy ma³mi a duzymi lietrami w asci
	
loop:
	lb	t4, (t0)	# loadByte do rejestru t4 z pod adresu wskazywanego przez rejestr t0
	beqz	t4, end		# branchIfEqualZero skocz do etykiety end jeœli wartoœæ w t4 jest równa 0x00
	blt	t4, t1, skip	# beanchIfLessThan jesli wartoœæ rej t4 jest mniejsza ni¿ rejestru t0, to skocz do skip
	bgt	t4, t2, skip
	sub	t4, t4, t3	# t4 = t4 - t3 . A w t3 jest 0x20 czyli odlge³oœæ miêdzy ma³ymi a du¿ymi literami asci
	sb	t4, (t0)	# storeByte
skip:
	addi	t0, t0, 1
	b	loop
end:
	li	a7, 4
	la	a0, header
	ecall			# printujemy to co jest w header
	li	a7, 4
	la	a0, buf
	ecall			# printujemy to co jest w buf (czyli zamienione literki)
	li	a7, 10
	ecall			# wychodzimy z programu
	 
	
