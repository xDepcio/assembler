	.data
fname:	.asciz	"img-med-c.bmp"
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
	li	s10, 0		# curr pixel X in s10
	li	s11, 0		# curr pixel Y in s11
pixelsLoop:
	bge	s7, s9, exit

	mv	a0, s7
	jal	getPixelXY
	mv	s10, a0
	mv	s11, a1
	
	mv	a2, s7
	jal	getValAtPixel
	mv	a7, a0		# save color index to a7
	
	mv	a0, s10
	mv	a1, s11
	jal	calcPixelRotate
	
	bltz	a0, skip
	bltz	a1, skip
	addi	t0, s6, -1
	bgt	a1, t0, skip
	
	mv	a2, a0
	mv	a3, a1
	mv	a0, s7
	mv	a1, a7
	jal	setPixelVal
skip:
	addi	s7, s7, 1
	b	pixelsLoop
	
	b	exit

setPixelVal:
	# needs   <- pixel offset in a0, newValue (new pixel index) in a1, pixel X in a2, pixel Y in a3
	# returns -> nothing
	mul	a0, a3, s5
	add	a0, a0, a2
	mul	t0, a0, s4	# save pixelOffset * bitsPerPixel to t0
	srli	t1, t0, 3	# save starting color byte offset to t1 (bitsOffset / 8)
	andi	t2, t0, 7	# save remainder from dividing bits offset by 8 to t2 (to find starting bit in monochrome palette)
	mv	t4, s4
	li	t5, 8
	li	t6, 0
	add	t1, t1, s3
	
	li	t0, 1
	ble	s4, t0, saveBit
	li	t0, 4
	ble	s4, t0, save4Bits
saveByte:
	sb	a2, (t1)
	ret
save4Bits:
	lb	t4, (t1)
	li	t0, 4
	sub	t0, t0, t2
	li	a0, 240
	srl	a0, a0, t2
	and	t6, a0, t4
	
	sll	a1, a1, t2
	add	t4, t6, a1
	sb	t4, (t1)
	ret
saveBit:
	ret
	

calcPixelRotate:
	# needs   <- pixel X in a0, pixel Y in a1
	# returns -> new pixel X in a0, new pixel Y in a1
	# 0.11001001000011110101 - pi/4 (0.78539...)
	# 0.10110101000001001111 - sqrt(2)/2 (0.7071067...)
	li	t0, 741455	# pierw(2)/2 in t0 (20 - biotwe, bez 0)
	li	t5, -741455	# pierw(2)/2 in t0 (20 - biotwe, bez 0)
	mul	t1, a0, t0
	mul	t2, a1, t5	# t5/t0
	add	t3, t1, t2
	srai	t3, t3, 20	# newX in t3
	
	mul	t1, a0, t0	#t0/t5
	mul	t2, a1, t0
	add	t4, t1, t2
	srai	t4, t4, 20	# newY in t4
	
	mv	a0, t3
	mv	a1, t4
	ret
	
	

getValAtPixel:
	# needs   <- pixel offset in a2
	# returns -> color index at pixel in a0
	mul	t0, a2, s4	# save pixelOffset * bitsPerPixel to t0
	srli	t1, t0, 3	# save starting color byte offset to t1 (bitsOffset / 8)
	andi	t2, t0, 7	# save remainder from dividing bits offset by 8 to t2 (to find starting bit in monochrome palette)
	mv	t4, s4
	li	t5, 8
	li	t6, 0
	add	t1, t1, s2
loadColorByte:
	lb	t3, (t1)
	add	t6, t6, t3
	addi	t4, t4, -8
	addi	t1, t1, 1
	blt	s4, t5, getColorBits
	ble	t4, zero, retVal
	slli	t6, t6, 8
	b	loadColorByte
getColorBits:
	li	t0, 1
	beq	s4, t0, retMono
	b	ret4bits
retMono:
	li	t0, 8
	sub	t0, t0, t2
	srl	t6, t6, t0
	andi	t6, t6, 1
	b	retVal
ret4bits:
	li	t0, 4
	sub	t0, t0, t2
	srl	t6, t6, t0
	andi	t6, t6, 15
	b	retVal
retVal:
	mv	a0, t6
	ret

	

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
	
	#li	a7, 63		# read pixels to heap memory pointed by t5
	#mv	a0, s0
	#mv	a1, t5
	#mv	a2, t3
	#ecall
	
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

saveImg:
	la	a0, fileDt
	lhu	t0, 10(a0)	
	lhu	t1, 12(a0)
	slli	t1, t1, 16
	add	t2, t1, t0	# offset to raster data in t2
	
	li	a7, 57		# this part closes read-only file
	mv	a0, s0
	ecall
	
	li	a7, 1024	# this part opens file in write mode
	la	a0, fname
	li	a1, 1
	ecall
	mv	s0, a0
	
	li	a7, 62		# this part seeks to start of raster data
	mv	a0, s0
	mv	a1, t2
	li	a2, 0
	ecall
	
	li	a7, 64		# this part write to file
	mv	a0, s0
	la	a1, fileDt
	li	a2, 54
	ecall
	li	a7, 64		# this part write to file
	mv	a0, s0
	mv	a1, s1
	addi	t3, t2, -54
	mv	a2, t3
	ecall
	li	a7, 64		# this part write to file
	mv	a0, s0
	mv	a1, s3
	mv	a2, s8
	ecall
	
	li	a7, 57		# this part closes write-only file
	mv	a0, s0
	ecall
	ret

exit:
	jal	saveImg

	li	a7, 10
	ecall
