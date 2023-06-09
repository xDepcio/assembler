#	(0, 0) of image is in its bottom left
#	filter traverses the image from left to right and bottom to top
#	filter values are written from left to right and from bottom to top. Tm. (0, 0) of filter is its bottom left
#	filter accepts .bmp with 24bit colors and produces .bmp image with 24bit colors
#	filter values are 16bit U2 numbers with 1st byte for whole part and 2nd byte for fraction
#	when filter values add up to 25.0 (filter area), pixel brightness is preserved. This allows for easy brightness changes.

	.data
fname:	.asciz	"63x64ein.bmp"
	.align	2
fileDt:	.space	54

#filtDt:	.half	0, 0, 0xff00, 0, 0, 0, 0xff00, 0xfd80, 0xff00, 0, 0xff00, 0xfd80, 0x2b00, 0xfd80, 0xff00, 0, 0xff00, 0xfd80, 0xff00, 0, 0, 0, 0xff00, 0, 0
# ^	| 0.0  0.0  -1.0  0.0  0.0 |
# |	| 0.0 -1.0  -2.5 -1.0  0.0 |
# |	|-1.0 -2.5  43.0 -2.5 -1.0 |  Image sharpening example
# |	| 0.0 -1.0  -2.5 -1.0  0.0 |
# |	| 0.0  0.0  -1.0  0.0  0.0 |

#filtDt:	.half	0, 0, 0, 0, 0, 0, 0x0c00, 0x0c00, 0x0c00, 0, 0, 0, 0, 0, 0, 0, 0xf400, 0xf400, 0xf400, 0, 0, 0, 0, 0, 0
# ^	| 0.0   0.0   0.0   0.0  0.0 |
# |	| 0.0 -12.0 -12.0 -12.0  0.0 |
# |	| 0.0   0.0   0.0   0.0  0.0 |  Horizontal edge detection
# |	| 0.0  12.0  12.0  12.0  0.0 |
# |	| 0.0   0.0   0.0   0.0  0.0 |

#filtDt:	.half	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x3200, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
# ^	| 0.0  0.0  0.0  0.0  0.0 |
# |	| 0.0  0.0  0.0  0.0  0.0 |
# |	| 0.0  0.0 50.0  0.0  0.0 |  Image brightener
# |	| 0.0  0.0  0.0  0.0  0.0 |
# |	| 0.0  0.0  0.0  0.0  0.0 |

filtDt:	.half	0, 0, 0, 0, 0, 0, 0xf700, 0, 0x0900, 0, 0, 0xee00, 0, 0x1200, 0, 0, 0xf700, 0, 0x0900, 0, 0, 0, 0, 0, 0  
# ^	| 0.0   0.0  0.0  0.0  0.0 |
# |	| 0.0  -9.0  0.0  9.0  0.0 |
# |	| 0.0 -18.0  0.0 18.0  0.0 |  Sobel filter. X - direction
# |	| 0.0  -9.0  0.0  9.0  0.0 |
# |	| 0.0   0.0  0.0  0.0  0.0 |

#filtDt:	.half	0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100
# ^	| 1.0  1.0  1.0  1.0  1.0 |
# |	| 1.0  1.0  1.0  1.0  1.0 |
# |	| 1.0  1.0  1.0  1.0  1.0 |  Basic image blurr example
# |	| 1.0  1.0  1.0  1.0  1.0 |
# |	| 1.0  1.0  1.0  1.0  1.0 |

	.text
	.globl	main
main:
	la	a0, fname
	jal	openFile
	mv	s0, a0		# save file descriptor to s0

	la	a3, fileDt
	jal	readHeader
	
	la	a0, fileDt
	jal	getImgWidthHeight
	mv	s1, a0		# save img width in s1
	mv	s2, a1		# save img height in s2
	mul	s3, s1, s2	# save total pixels count to s3
	
	jal	getPixles
	mv	s4, a0		# save address of original pixels in s4
	mv	s5, a1		# save address of pixels copy in s5
	
	li	s6, 0		# pixels offset in s6
	li	s7, 0		# curr pixel X in s7
	li	s8, 0		# curr pixel Y in s8
pixelsLoop:
	bge	s6, s3, exit
	
	mv	a0, s6
	jal	getPixelXY
	mv	s7, a0
	mv	s8, a1
	
	mv	a0, s7
	mv	a1, s8
	jal	convPixel
	
	mv	a2, a0
	mv	a0, s7
	mv	a1, s8
	jal	savePixelColor24bit
	
	addi	s6, s6, 1
	b	pixelsLoop


# --------------------------------------------------------------------------
savePixelColor24bit:
	# needs   <- pixel X in a0, pixel Y in a1, color RGB value in a2
	# returns -> nothing
	
	mul	t0, a1, s1
	add	t0, t0, a0	# pixel offset in t0
	
	li	a0, 3		# mask to get modulo 4 (0b011)
	and	a0, a0, s1	# (width % 4) in a0
	mul	a0, a0, a1	# padding up to current pixel in a0
	
	slli	a1, t0, 1	# mul offset by 3 (each pixel is 3 bytes)
	add	a1, a1, t0	# --||--
	add	a1, a1, a0	# add padding to bytes offset
	add	t0, a1, s5	# final address of pixel in t0
	
	sb	a2, (t0)	# store Blue channel
	srli	a2, a2, 8
	addi	t0, t0, 1
	sb	a2, (t0)	# store Green channel
	srli	a2, a2, 8
	addi	t0, t0, 1
	sb	a2, (t0)	# store Red channel
	
	ret
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
convPixel:
	# needs   <- pixel X in a0, pixel Y in a1
	# returns -> conovoluted pixel color value in a0
	mv	a6, a0		# store origin X in a6
	mv	a7, a1		# store origin Y in a7
	li	t0, 0		# R channel total value
	li	t1, 0		# G channel total value
	li	t2, 0		# B channel total value
	li	t3, 6400	# default divisor is equal to number of filter cells (5x5=25) shifted left by 8 bits (1 byte for whole, 1 byte for fractions)
	li	t4, -2		# starting x offset of filter
	li	t5, -2		# starting y offset of filter
convFiltLoop:
	add	a2, a6, t4	# X pointed by filter in a2
	add	a3, a7, t5	# Y pointed by filter in a3
	
	# Load filter weight of current pixel
	li	a0, 2
	li	a1, 2
	add	a0, a0, t4	# X offset of filter weight
	add	a1, a1, t5	# Y offset of filter weight
	li	a4, 5
	mul	a1, a1, a4
	add	a1, a1, a0
	slli	a1, a1, 1	# each filter value takes 2 bytes so mul by 2. final offset of filter weight in a1	
	
	la	a0, filtDt
	add	a0, a0, a1
	lh	a4, (a0)	# current pixel filter weight in a4
	
	bltz	a2, skipPixel
	bltz	a3, skipPixel
	bge	a2, s1, skipPixel
	bge	a3, s2, skipPixel
	
	mv	a5, ra
	mv	s9, a2
	mv	s10, a3
	jal	getValAtPixel
	mv	ra, a5
	mv	t6, s9		# load pixel RGB value to t6
	
	li	a1, 16711680	# 0b00000000111111110000000000000000 - mask to only get red value
	and	a0, t6, a1
	srli	a0, a0, 16	# normalized red value in a0
	mul	a0, a0, a4	# multiply value by pixel weight
	srai	a0, a0, 8	# normalize (because each filter value is split in the middle for 1 byte for whole numbers and 1 for fractions)
	add	t0, t0, a0	# add pixel red value to total red value
	li	a1, 65280	# 0b00000000000000001111111100000000 - mask to only get green value
	and	a0, t6, a1
	srli	a0, a0, 8	# normalized green value in a0
	mul	a0, a0, a4	# multiply value by pixel weight
	srai	a0, a0, 8	# normalize (because each filter value is split in the middle for 1 byte for whole numbers and 1 for fractions)
	add	t1, t1, a0	# add pixel green value to total green value
	li	a1, 255		# 0b00000000000000000000000011111111 - mask to only get blue value
	and	a0, t6, a1	# normalized blue value in a0
	mul	a0, a0, a4	# multiply value by pixel weight
	srai	a0, a0, 8	# normalize (because each filter value is split in the middle for 1 byte for whole numbers and 1 for fractions)
	add	t2, t2, a0	# add pixel blue value to total blue value
	
	addi	t4, t4, 1
	li	a4, 2
	bgt	t4, a4, newRow
	
	b	convFiltLoop
convFinish:
	srli	t3, t3, 8	# normalize to whole number
	div	t0, t0, t3	# divide by accounted weight
	div	t1, t1, t3
	div	t2, t2, t3
colorsScaling:
	li	a0, 255		# max 40 stages in 16 bit red channel, 6 space betwwen (36 * 7 = 252). Max 6 stages in G and B (42 * 6 = 252)
	bgt	t0, a0, limitChannelRed		# red channel min(value, 255)
	bgt	t1, a0, limitChannelGreen	# grren channel min(value, 255)
	bgt	t2, a0, limitChannelBlue	# blue channel min(value, 255)
	
	bltz	t0, zeroChannelRed	# red channel max(value, 0)
	bltz	t1, zeroChannelGreen	# green channel max(value, 0)
	bltz	t2, zeroChannelBlue	# blue channel max(value, 0)

	li	a0, 0
	addi	a0, a0, 255	# add 0b0...11111111 (FF)
	slli	a0, a0, 8
	add	a0, a0, t0	# set read value
	slli	a0, a0, 8
	add	a0, a0, t1	# set green value
	slli	a0, a0, 8
	add	a0, a0, t2	# set blue value
	ret
newRow:
	li	t4, -2
	addi	t5, t5, 1
	li	a4, 2
	bgt	t5, a4, convFinish
	b	convFiltLoop
limitChannelRed:
	li	t0, 255
	b	colorsScaling
limitChannelGreen:
	li	t1, 255
	b	colorsScaling
limitChannelBlue:
	li	t2, 255
	b	colorsScaling
zeroChannelRed:	
	li	t0, 0
	b	colorsScaling
zeroChannelGreen:	
	li	t1, 0
	b	colorsScaling
zeroChannelBlue:	
	li	t2, 0
	b	colorsScaling
skipPixel:
	sub	t3, t3, a4
	addi	t4, t4, 1
	li	a4, 2
	bgt	t4, a4, newRow
	b	convFiltLoop
# --------------------------------------------------------------------------
# --------------------------------------------------
getValAtPixel:		# only modifies (s9-s11) registers
	# needs   <- pixel X in s9, pixel Y in s10
	# returns -> color RGB value in s9
	mul	s11, s10, s1
	add	s11, s11, s9	# pixel offset in s11
	
	li	s9, 3		# mask to get modulo 4 (0b011)
	and	s9, s9, s1	# (width % 4) in s11
	mul	s9, s9, s10	# padding up to current pixel in s9
	
	slli	s10, s11, 1	# mul offset by 3 (each pixel is 3 bytes)
	add	s10, s10, s11	# --||--
	add	s10, s10, s9	# add padding to bytes offset
	add	s10, s10, s4	# final address of pixel in s10

	lbu	s9, 2(s10)	# load R
	slli	s9, s9, 8
	lbu	s11, 1(s10)	# load G
	add	s9, s9, s11
	slli	s9, s9, 8
	lbu	s11, 0(s10)	# loab B
	add	s9, s9, s11	# final RGB value in s9
	
	ret
# --------------------------------------------------
# --------------------------------------------------
getPixelXY:
	# needs   <- offset of pixels in a0
	# returns -> pixel X in a0, pixel Y in a1
	divu	t0, a0, s1	# Y in t0
	remu	t1, a0, s1	# X in t1
	
	mv	a0, t1
	mv	a1, t0
	ret
# --------------------------------------------------
# --------------------------------------------------
readHeader:
	# buf to save to in a3
	li	a7, 63
	mv	a0, s0
	mv	a1, a3
	li	a2, 54
	ecall
	ret
# --------------------------------------------------
# --------------------------------------------------
getPixles:
	# needs   <- nothing
	# returns -> address of pixels stored in heap memory in a0, address of space reserved for new pixels in a1
	la	a0, fileDt
	
	lhu	t0, 2(a0)
	lhu	t1, 4(a0)
	slli	t1, t1, 16
	add	t0, t0, t1	# file size in t0
	addi	t0, t0, -54	# pixels size in bytes in t0
	
	li	a7, 9
	mv	a0, t0
	ecall
	mv	t4, a0		# save addres of pixels to t4
	
	li	a7, 9
	mv	a0, t0
	ecall
	mv	t5, a0		# save addres of copy of pixels to t5
	
	li	a7, 62		# this part seeks to start of raster data
	mv	a0, s0
	li	a1, 54
	li	a2, 0
	ecall
	
	li	a7, 63		# read pixels to heap memory pointed by t4
	mv	a0, s0
	mv	a1, t4
	mv	a2, t0
	ecall
	
	li	a7, 62		# this part seeks to start of raster data
	mv	a0, s0
	li	a1, 54
	li	a2, 0
	ecall
	
	li	a7, 63		# read pixels to heap memory pointed by t4
	mv	a0, s0
	mv	a1, t5
	mv	a2, t0
	ecall
	
	mv	a0, t4
	mv	a1, t5
	ret
# --------------------------------------------------
# --------------------------------------------------
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
# --------------------------------------------------
# --------------------------------------------------
saveImg:
	# needs   <- nothing
	# returns -> nothing
	la	a0, fileDt
	
	lhu	t0, 2(a0)
	lhu	t1, 4(a0)
	slli	t1, t1, 16
	add	t0, t0, t1	# file size in t0
	addi	t1, t0, -54	# pixels map size in bytes in t1

	li	a7, 57		# this part closes read-only file
	mv	a0, s0
	ecall
	
	li	a7, 1024	# this part opens file in write mode
	la	a0, fname
	li	a1, 1
	ecall
	mv	s0, a0
	
	li	a7, 64		# this part writes header+headerInfo
	mv	a0, s0
	la	a1, fileDt
	li	a2, 54
	ecall

	li	a7, 64		# this part writes rasterData
	mv	a0, s0
	mv	a1, s5
	mv	a2, t1
	ecall
	
	li	a7, 57		# this part closes write-only file
	mv	a0, s0
	ecall
	ret
# --------------------------------------------------
# --------------------------------------------------
openFile:
	# needs   <- filneName in a0
	# returns -> fileDescriptor in a0
	li	a7, 1024	# opens file
	la	a0, fname
	li	a1, 0
	ecall
	ret
# --------------------------------------------------
# --------------------------------------------------
exit:
	jal	saveImg

	li	a7, 10
	ecall
# --------------------------------------------------
