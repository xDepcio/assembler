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
	mv	s1, a1		# save address of colors in s1
	
	la	a0, fileDt
	jal	getPixles
	mv	s2, a0		# save address of pixels
	mv	s3, a1		# save address of pixels copy
	mv	s8, a2		# save pixels size in bytes to s8
	
	la	a0, fileDt
	jal	getBitsPerPixels
	mv	s4, a1		# save bits per pixel to s4
	
	la	a0, fileDt
	jal	getImgWidthHeight
	mv	s5, a0		# save img width in s5
	mv	s6, a1		# save img height in s6
	mul	s9, s5, s6	# save total pixels count to s9
	
	li	s7, 0		# pixels offst in s7
pixelsLoop:
	bge	s7, s9, exit

	mv	a0, s7
	jal	getPixelXY
	
	addi	s7, s7, 1
	b	pixelsLoop
	
	b	exit

getPixelXY:
	# needs   <- offset of pixels in a0
	# returns -> pixel X in a0, pixel Y in a1
	divu	t0, a0, s5	# Y in t0
	remu	t1, a0, s5	# X in t1
	
	mv	a0, t1
	mv	a1, t0
	ret

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
	
	li	a7, 9		# this part allocates heap memory to store colors
	slli	t2, t2, 2	# multiply t2 by 4 (each colors takes 4 bytes) - final colours length in t2
	mv	a0, t2
	ecall
	mv	t3, a0		# save address of colors heap start address in t3
	
	li	a7, 62		# This part seeks to the start of colors in BMP file
	mv	a0, s0
	li	a1, 54
	li	a2, 0
	ecall
	
	li	a7, 63		# This part reads colors from BMP file
	mv	a0, s0
	mv	a1, t3
	mv	a2, t2
	ecall
	
	li	a7, 62		# This part seeks back to the start of BMP file
	mv	a0, s0
	li	a1, 0
	li	a2, 0
	ecall
	
	mv	a1, t3
	ret

getPixles:
	# needs   <- address to generic image data in a0
	# returns -> address of pixels stored in heap memory in a0,
	#	  -> address of pixels copy in a1,
	#	  -> pixels size in a2
	lhu	t0, 10(a0)	
	lhu	t1, 12(a0)
	slli	t1, t1, 16
	add	t2, t1, t0	# offset to raster data in t2
	
	lhu	t0, 2(a0)	
	lhu	t1, 4(a0)
	slli	t1, t1, 16
	add	t3, t1, t0	# file size in t3
	sub	t3, t3, t2	# pixels size in t3 (filesize - offset to raster data)
	
	li	a7, 9		# this part allocates heap memory for pixels
	mv	a0, t3
	ecall
	mv	t4, a0		# save addres of pixels to t4
	
	li	a7, 9		# this part allocates heap memory for copy of pixels (this one will be rewritten)
	mv	a0, t3
	ecall
	mv	t5, a0		# save addres of copy of pixels to t5
	
	li	a7, 62		# this part seeks to start of raster data
	mv	a0, s0
	mv	a1, t2
	li	a2, 0
	ecall
	
	li	a7, 63		# read pixels to heap memory pointed by t4
	mv	a0, s0
	mv	a1, t4
	mv	a2, t3
	ecall
	
	li	a7, 62		# this part seeks to start of raster data
	mv	a0, s0
	mv	a1, t2
	li	a2, 0
	ecall
	
	li	a7, 63		# read pixels to heap memory pointed by t5
	mv	a0, s0
	mv	a1, t5
	mv	a2, t3
	ecall
	
	li	a7, 62		# this part seeks to start of the file
	mv	a0, s0
	li	a1, 0
	li	a2, 0
	ecall
	
	mv	a0, t4
	mv	a1, t5
	mv	a2, t3
	ret

getBitsPerPixels:
	# needs   <- address to generic image data in a0
	# returns -> bits per pixel in a1
	lhu	a1, 28(a0)
	ret

getImgWidthHeight:
	# needs   <- address to generic image data in a0
	# returns -> width in a0, height in a1
	lhu	t0, 18(a0)
	lhu	t1, 20(a0)
	slli	t1, t1, 16
	add	t2, t1, t0	# store img width in t2
	
	lhu	t0, 22(a0)
	lhu	t1, 24(a0)
	slli	t1, t1, 16
	add	t3, t1, t0	# store img height in t3
	
	mv	a0, t2
	mv	a1, t3
	ret

exit:
	li	a7, 10
	ecall
