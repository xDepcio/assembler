	.data
fname:	.asciz	"img.bmp"
	.align	2
fileDt:	.space	80

	.text
	.globl	main
main:
	li	a7, 1024
	la	a0, fname
	li	a1, 0
	ecall
	
	mv	s0, a0		# save file decriptor in s0
	la	a3, fileDt
	jal	readHeader
	la	a0, fileDt
	jal	getColors
	mv	s1, s1		# save address of colors in s1
	
	
	b	exit
readHeader:
	# buf to save to in a3
	li	a7, 63
	mv	a0, s0
	mv	a1, a3
	li	a2, 54
	ecall
	ret

getColors:
	# needs   <- address of imageData buffer in a0
	# returns -> address of used colors list stored in heap memory in a1
	lh	t0, 46(a0)	# lower half of colors count (32 bit)
	lh	t1, 48(a0)	# upper half od colours count (32 bit)
	slli	t1, t1, 16
	add	t2, t1, t0	# final colors count in t2
	
	li	a7, 9
	slli	t2, t2, 2	# multiply t2 by 4 (each colors takes 4 bytes) - final colours length in t2
	mv	a0, t2
	ecall
	mv	t3, a0		# save address of colors heap start address in t3
	
	li	a7, 62
	mv	a0, s0
	li	a1, 54
	li	a2, 0
	ecall
	
	li	a7, 63
	mv	a0, s0
	mv	a1, t3
	mv	a2, t2
	ecall
	
	mv	a1, t3
	ret
	

exit:
	li	a7, 10
	ecall