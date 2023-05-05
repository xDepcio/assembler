#	(0, 0) of image is in its bottom left
#	filter traverses the image from left to right and bottom to top
#	filter values are written from left to right and from bottom to top. Tm. (0, 0) of filter is its bottom left

	.data
fname:	.asciz	"ein24.bmp"
	.align	2
fileDt:	.space	54
#filtDt:	.half	0, 0, 0xff00, 0, 0, 0, 0xff00, 0xfd80, 0xff00, 0, 0xff00, 0xfd80, 0x2b00, 0xfd80, 0xff00, 0, 0xff00, 0xfd80, 0xff00, 0, 0, 0, 0xff00, 0, 0
# ^	| 0.0  0.0  -1.0  0.0  0.0 |
# |	| 0.0 -1.0  -2.5 -1.0  0.0 |
# |	|-1.0 -2.5  43.0 -2.5 -1.0 |  Image sharpening example
# |	| 0.0 -1.0  -2.5 -1.0  0.0 |
# |	| 0.0  0.0  -1.0  0.0  0.0 |

#filtDt:	.half	0, 0, 0, 0, 0, 0, 0xff00, 0xfffe, 0xff00, 0, 0, 0, 0, 0, 0, 0, 0x0100, 0x0200, 0x0100, 0, 0, 0, 0, 0, 0
#filtDt:	.half	0, 0, 0, 0, 0, 0, 0x0100, 0x0100, 0x0100, 0, 0, 0, 0, 0, 0, 0, 0xff00, 0xff00, 0xff00, 0, 0, 0, 0, 0, 0
#filtDt:	.half	0, 0, 0, 0, 0, 0, 0xff00, 0, 0x0100, 0, 0, 0xfe00, 0, 0x0200, 0, 0, 0xff00, 0, 0x0100, 0, 0, 0, 0, 0, 0
filtDt:	.half	0, 0, 0, 0, 0, 0, 0xf700, 0, 0x0900, 0, 0, 0xee00, 0, 0x1200, 0, 0, 0xf700, 0, 0x0900, 0, 0, 0, 0, 0, 0  

#filtDt: .half	0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100, 0x0100 # each filter value is 2 bytes U2 number with first byte for whole part and 2nd byte for fractions

		.align	2
cSave:	.space	64

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
	
	la	a0, fileDt
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
	
	mv	a1, a0
	mv	a0, s6
	jal	savePixelColor24bit
	
	addi	s6, s6, 1
	b	pixelsLoop


# --------------------------------------------------------------------------
savePixelColor24bit:
	# needs   <- pixel offset in a0, color RGB value in a1
	# returns -> nothing
	slli	t0, a0, 1
	add	t0, t0, a0	# bytes offset in t0 (each pixel takes 3 bytes in 24 bit space)
	add	t0, s5, t0	# memory address of start of pixel in t0
	
	sb	a1, (t0)	# store Blue channel
	srli	a1, a1, 8
	addi	t0, t0, 1
	sb	a1, (t0)	# store Green channel
	srli	a1, a1, 8
	addi	t0, t0, 1
	sb	a1, (t0)	# store Red channel
	
	ret
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
getColorIndex:
	# needs   <- color RGB value in a1
	# returns -> color index offset in a2 (or index offset of where to write new color when a3 is set to -1, normaly it is 0)
	li	a3, 0
	mv	t3, s8
	li	t4, 0		# offset in t4
colorsLoop:
	lw	t0, (t3)
	
	beq	t0, a1, colorFound
	
	srli	t1, t0, 24
	li	t2, 0xff	# 11111111
	bne	t1, t2, newColor
	
	addi	t3, t3, 4
	addi	t4, t4, 4
	b	colorsLoop
newColor:
	li	a3, -1
	mv	a2, t4
	ret
colorFound:
	mv	a2, t4
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
	#
	#li	t3, 256
	li	t3, 2304
	#li	t3, 6400	# default divisor is equal to number of filter cells (5x5=25) shifted left by 8 bits (1 byte for whole, 1 byte for fractions)
	#
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
	# ===================================
	
	bltz	a2, skipPixel
	bltz	a3, skipPixel
	bge	a2, s1, skipPixel
	bge	a3, s2, skipPixel
	
#	la	a0, cSave	# save registers
#	sw	a2, (a0)
#	sw	a3, 4(a0)
#	sw	a6, 8(a0)
#	sw	a7, 12(a0)
#	sw	t0, 16(a0)
#	sw	t1, 20(a0)
#	sw	t2, 24(a0)
#	sw	t3, 28(a0)
#	sw	t4, 32(a0)
#	sw	t5, 36(a0)
	
	mv	a5, ra
	mv	s9, a2
	mv	s10, a3
	jal	getValAtPixel
	mv	ra, a5
	mv	t6, s9		# load pixel RGB value to t6
	
#	la	a0, cSave	# retrieve registers
#	lw	a2, (a0)
#	lw	a3, 4(a0)
#	lw	a6, 8(a0)
#	lw	a7, 12(a0)
#	lw	t0, 16(a0)
#	lw	t1, 20(a0)
#	lw	t2, 24(a0)
#	lw	t3, 28(a0)
#	lw	t4, 32(a0)
#	lw	t5, 36(a0)
	
#	# Load filter weight of current pixel
#	li	a0, 2
#	li	a1, 2
#	add	a0, a0, t4	# X offset of filter weight
#	add	a1, a1, t5	# Y offset of filter weight
#	li	a4, 5
#	mul	a1, a1, a4
#	add	a1, a1, a0
#	slli	a1, a1, 1	# each filter value takes 2 bytes so mul by 2. final offset of filter weight in a1	
#	
#	la	a0, filtDt
#	add	a0, a0, a1
#	lh	a4, (a0)	# current pixel filter weight in a4
#	# ===================================
	
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
#	addi	t3, t3, -1
	addi	t4, t4, 1
	li	a4, 2
	bgt	t4, a4, newRow
	b	convFiltLoop
# --------------------------------------------------------------------------

# --------------------------------------------------
getValAtPixel:		# only modifies (s9-s11) registers
	# needs   <- pixel X in s9, pixel Y in s10
	# returns -> color RGB value in s9
	mul	s10, s10, s1
	add	s10, s10, s9	# pixel offset in s10
	
	slli	s11, s10, 1	# mul by 3 (each pixel is 3 bytes)
	add	s11, s11, s10	# cd...
	add	s10, s11, s4	# final address of pixel in s10

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
	# needs   <- address to generic image data in a0
	# returns -> address of pixels stored in heap memory in a0,
	li	a7, 9		# this part allocates heap memory for pixels
	slli	t3, s3, 1	# mul by 3 (each pixel takes 3 bytes)
	add	t3, t3, s3	# cd...
	mv	a0, t3
	ecall
	mv	t4, a0		# save addres of pixels to t4
	
	li	a7, 9		# this part allocates heap memory for copy of pixels for 24bit colors (this one will be rewritten and is gargabe at start)
	slli	t1, s3, 1
	add	t1, t1, s3	# in t1 space in bytes for 24bit colors
	mv	a0, t1
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
	mv	a2, t3
	ecall
	
	mv	a0, t4
	mv	a1, t5
	mv	a2, t3
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
formatStaticImgData:
	# needs   <- nothing
	# returns -> colorsTable size in a0, rasterData size in a1
	li	t0, 54		# offset to raster data (initialy 54 which is constant size of Header+InfoHeader)
	
	la	t3, fileDt	# this part updates offset to raster data after convolution
	sh	t0, 10(t3)
	srli	t0, t0, 16
	sh	t0, 12(t3)
	
	# ----------------------- this part sets correct file size
	li	t0, 54		# constant size of Header+HeaderInfo is 54, store size in t0
	slli	a0, s3, 1
	add	a0, a0, s3
	add	t0, t0, a0	# header + colors + pixels(24bit colors), final file size in t0
	
	la	t3, fileDt	# this part updates file size after convolution
	sh	t0, 2(t3)
	srli	t0, t0, 16
	sh	t0, 4(t3)
	
	# ----------------------- this part sets bits per pixel (24bits)
	la	t3, fileDt
	li	a0, 24
	sh	a0, 28(t3)
	
	mv	a1, s3	
	slli	a1, a1, 1	# mul pixel by 3 (each pixel takes 3 bytes in 24bit color space)
	add	a1, a1, s3	# --||--

	ret
# --------------------------------------------------
# --------------------------------------------------
saveImg:
	# needs   <- rasterData size in a1
	# returns -> NOTHING
	mv	t1, a1

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
	jal	formatStaticImgData
	jal	saveImg

	li	a7, 10
	ecall
# --------------------------------------------------
