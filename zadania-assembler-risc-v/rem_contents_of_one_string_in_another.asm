	.data
filt_p:	.asciz	"Enter filtering sequence:\n"
prompt:	.asciz	"Enter your combination:\n"
header:	.asciz	"\nOutput:\n"
buf_in:	.space	100
filt_b:	.space	100
out_b:	.space	100

	.text
	.globl	main
main:
	li	a7, 4
	la	a0, filt_p
	ecall
	li	a7, 8
	la	a0, filt_b
	li	a1, 100
	ecall
	
	li	a7, 4
	la	a0, prompt
	ecall
	li	a7, 8
	la	a0, buf_in
	li	a1, 100
	ecall
	
	la	t0, filt_b	# w t0 wskaznik na pocz¹tek buffora filtru
	mv	s0, t0		# na amen zapamietany wskaznik na poczatek bufora filtra
	la	t1, buf_in	# w t1 wskaznik na pocz¹tek bufora inputa
	la	t4, out_b	# w t4 wskaznik na pocztek bufora outputa
	mv	s1, t4		# w s1 na amen wkaznik na pocz¹tek bufora wynikowego
	li	t5, 1		# 0 - char should not be saved, 1 - char should be saved
	
loop_out:
	lb	t2, (t1)
	li	t5, 1		# reset t5 to init. val.
	beqz	t2, end
	b	loop_inn

loop_inn:			# loop przez elementy do zakazane
	lb	t3, (t0)
	beqz	t3, endInn
	beq	t3, t2, notSave		# jesli t3(el. inputa) == t2(el. filtra) to ten element powinien zostac usuniety
	#beq	t3, t2, toRem		# jesli t3(el. inputa) == t2(el. filtra) to ten element powinien zostac usuniety
	addi	t0, t0, 1		# zwiekszamy wskaznik na bufor filtra
	b	loop_inn
	
endInn:
	mv	t0, s0		# restujemy wskaznik na bufor filtra (na pocz¹tek)
	addi	t1, t1, 1	# zwiekszamy wskaznik na bufor wejsciowy
	bnez	t5, saveC	# save char to output
	b	loop_out

saveC:
	sb	t2, (t4)
	addi	t4, t4, 1
	b	loop_out

notSave:
	li	t5, 0		# say that this cahr should not be saved
	#sb	t2, (t4)
	#addi	t4, t4, 1	# zwiekszamy wksaznik na bufora wynikowy
	#addi	t0, t0, 1	# zwiekszamy wskaznik na bufor filtra
	addi	t0, t0, 1		# zwiekszamy wskaznik na bufor filtra
	b	loop_inn

end:
	li	a7, 4
	la	a0, header
	ecall
	
	li	a7, 4
	mv	a0, s1
	ecall
	
	li	a7, 10
	ecall
	
	