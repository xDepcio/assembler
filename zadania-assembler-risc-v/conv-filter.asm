#	1. Wczytanie podstawowych danych do fileDt
#	2. Wczytanie aktualnych kolorów do heap
#	3. Wczytanie pixel mapy do heap
#	4. zarezerwowanie miejsca w heap memory na pixel mape gdzie s¹ 24 bitowe kolory (width*height*3)
#	5. Wczytanie do filtDt aktualnego filtra konwulucyjnego

				
	.data
fname:	.asciz	"img-32.bmp"
	.align	2
fileDt:	.space	80
filtDt: .byte	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	.align	2
cSave:	.space	64
	.align	2
editedImgData:		# each 4 bytes, in order: colors count;
	.space	64

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
	mv	s5, a0		# save img width in s5
	mv	s6, a1		# save img height in s6
	mul	s9, s5, s6	# save total pixels count to s9

	la	a0, fileDt
	jal	getBitsPerPixels
	mv	s4, a1		# save bits per pixel to s4
	
	la	a0, fileDt
	jal	getColors
	mv	s1, a1		# save address of colors in s1
	mv	s8, a2		# save address reserved for newly created colors in s8
	
	la	a0, fileDt
	jal	getPixles
	mv	s2, a0		# save address of original pixels in s2
	mv	s3, a1		# save address of pixels copy in s3
	#mv	s8, a2		# save pixels size in bytes to s8
	
	li	s7, 0		# pixels offset in s7
	li	s10, 0		# curr pixel X in s10
	li	s11, 0		# curr pixel Y in s11
pixelsLoop:
	bge	s7, s9, exit
	
	mv	a0, s7
	jal	getPixelXY
	mv	s10, a0
	mv	s11, a1
	
	mv	a0, s10
	mv	a1, s11
	jal	convPixel
	
	mv	a1, a0
	mv	a0, s7
	jal	savePixelColor
	
	addi	s7, s7, 1
	b	pixelsLoop

# --------------------------------------------------------------------------
savePixelColor:
	# needs   <- pixel offset in a0, color RGB value in a1
	# returns -> nothing
	mv	a7, ra
	jal	getColorIndex
	mv	ra, a7
	mv	t0, a2		# color index offset in a2
	mv	t1, a3		# whether colors exists in a3 (0 if exists, -1 otherwise)
	
	bnez	t1, saveNewColor
savePixelsColorIndex:
	srli	t0, t0, 2	# index in t0 - index is offset / 4 (each colors takes 4 bytes of space)
	
	mv	t2, s3
	add	t2, t2, a0
	sb	t0, (t2)
	ret
saveNewColor:
	mv	t2, s8
	add	t2, t2, t0
	sw	a1, (t2)
	
	lw	t3, editedImgData	# this part updates colors count
	addi	t3, t3, 1
	sw	t3, editedImgData, t4
	
	b	savePixelsColorIndex
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
convPixel:	# solution only for 8bit colors
	# needs   <- pixel X in a0, pixel Y in a1
	# returns -> conovoluted pixel color value in a0
	mv	a6, a0		# store origin X in a6
	mv	a7, a1		# store origin Y in a7
	li	t0, 0		# R channel total value
	li	t1, 0		# G channel total value
	li	t2, 0		# B channel total value
	li	t3, 25		# default divisor is equal to number of filter cells (5x5)
	li	t4, -2		# starting x offset of filter
	li	t5, -2		# starting y offset of filter
convFiltLoop:
	add	a2, a6, t4	# X pointed by filter in a2
	add	a3, a7, t5	# Y pointed by filter in a3
	bltz	a2, skipPixel
	bltz	a3, skipPixel
	bge	a2, s5, skipPixel
	bge	a3, s6, skipPixel
	
	la	a0, cSave	# save registers
	sw	a2, (a0)
	sw	a3, 4(a0)
	sw	a6, 8(a0)
	sw	a7, 12(a0)
	sw	t0, 16(a0)
	sw	t1, 20(a0)
	sw	t2, 24(a0)
	sw	t3, 28(a0)
	sw	t4, 32(a0)
	sw	t5, 36(a0)
	
	mv	a5, ra
	mv	a0, a2
	mv	a1, a3
	jal	getValAtPixel
	mv	ra, a5
	mv	t6, a0		# load pixel index to t6 - offset accounted
	
	la	a0, cSave	# retrieve registers
	lw	a2, (a0)
	lw	a3, 4(a0)
	lw	a6, 8(a0)
	lw	a7, 12(a0)
	lw	t0, 16(a0)
	lw	t1, 20(a0)
	lw	t2, 24(a0)
	lw	t3, 28(a0)
	lw	t4, 32(a0)
	lw	t5, 36(a0)
	
	slli	a0, t6, 2	# multiply index by 4 to get bytes offset of color, store in a0
	add	a0, s1, a0	# addres of color in a0
	lw	t6, (a0)	# load color RGB values to t6
	
	# Load filter weight of current pixel
	li	a0, 2
	li	a1, 2
	add	a0, a0, t4	# X offset of filter weight
	add	a1, a1, t5	# Y offset of filter weight
	li	a4, 5
	mul	a1, a1, a4
	add	a1, a1, a0	# final offset of filter weight in a1
	
	la	a0, filtDt
	add	a0, a0, a1
	lb	a4, (a0)	# current pixel filter weight in a4
	# ===================================
	
	li	a1, 16711680	# 0b00000000111111110000000000000000 - mask to only get red value
	and	a0, t6, a1
	srli	a0, a0, 16	# normalized red value in a0
	mul	a0, a0, a4	# multiply value by pixel weight
	add	t0, t0, a0	# add pixel red value to total red value
	li	a1, 65280	# 0b00000000000000001111111100000000 - mask to only get green value
	and	a0, t6, a1
	srli	a0, a0, 8	# normalized green value in a0
	mul	a0, a0, a4	# multiply value by pixel weight
	add	t1, t1, a0	# add pixel green value to total green value
	li	a1, 255		# 0b00000000000000000000000011111111 - mask to only get blue value
	and	a0, t6, a1	# normalized blue value in a0
	mul	a0, a0, a4	# multiply value by pixel weight
	add	t2, t2, a0	# add pixel blue value to total blue value
	
	addi	t4, t4, 1
	li	a4, 2
	bgt	t4, a4, newRow
	
	b	convFiltLoop
convFinish:
	div	t0, t0, t3
	div	t1, t1, t3
	div	t2, t2, t3
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
skipPixel:
	addi	t3, t3, -1
	addi	t4, t4, 1
	li	a4, 2
	bgt	t4, a4, newRow
	b	convFiltLoop
	

# --------------------------------------------------------------------------
#setPixelVal:	# cos tu rozjebane jest (nie dzia³a³o dla 8bitowych kolorow). Calculate pixel xy dziala natomiast dobrze
#	# needs   <- newValue (new pixel index) in a1, pixel X in a2, pixel Y in a3
#	# returns -> nothing
#	mul	a0, a3, s5	# calculate pixel offset based on height and width
#	add	a0, a0, a2	# --||--
#	mul	t0, a0, s4	# save pixelOffset * bitsPerPixel to t0
#	srli	t1, t0, 3	# save starting color byte offset to t1 (bitsOffset / 8)
#	andi	t2, t0, 7	# save remainder from dividing bits offset by 8 to t2 (to find starting bit in monochrome palette)
#	mv	t4, s4		# copy bits per pixel to s4
#	li	t5, 8
#	li	t6, 0
#	add	t1, t1, s3	# store address to store pixel in t1 (start address of pixels copy + offset of first byte)
#	
#	li	t0, 1
#	beq	s4, t0, saveBit
#	li	t0, 4
#	beq	s4, t0, save4Bits
#saveByte:
#	sb	a1, (t1)
#	addi	t4, t4, -8
#	blez	t4, retPx
#	srli	a1, a1, 8
#	b	saveByte
#save4Bits:
#	lb	t4, (t1)
#	li	t0, 4
#	sub	t0, t0, t2
#	li	a0, 240
#	srl	a0, a0, t2
#	and	t6, a0, t4
#	
#	sll	a1, a1, t2
#	add	t4, t6, a1
#	sb	t4, (t1)
#	ret
#saveBit:
#	ret
#retPx:
#	ret
	
# --------------------------------------------------
getValAtPixel:
	# needs   <- deprecated(pixel offset in a2) pixel X in a0, pixel Y in a1
	# returns -> color index at pixel in a0
	mul	a2, a1, s5	# Normalize pixels to offset
	add	a2, a2, a0	# --||--
	
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
# --------------------------------------------------
	
# --------------------------------------------------
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
	
	li	a7, 9
	#li	a0, 16777216	# reserve space for 24bit colors space
	li	a0, 256	# reserve space for 8bit colors space
	ecall
	mv	t4, a0		# save address of empy colors start address in t4
	
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
	mv	a2, t4
	ret
# --------------------------------------------------

# --------------------------------------------------
getPixles:
	# needs   <- address to generic image data in a0
	# returns -> address of pixels stored in heap memory in a0,
	#	  -> address of pixels copy in a1,
	#	  -> pixels size in a2
	lhu	t0, 10(a0)	
	lhu	t1, 12(a0)
	slli	t1, t1, 16
	add	t2, t1, t0	# offset to raster data in t2
	
	#lhu	t0, 2(a0)	
	#lhu	t1, 4(a0)
	#slli	t1, t1, 16
	#add	t3, t1, t0	# file size in t3
	#sub	t3, t3, t2	# pixels size in t3 (filesize - offset to raster data)
	
	li	a7, 9		# this part allocates heap memory for pixels
	mul	t3, s9, s4
	srli	t3, t3, 3
	mv	a0, t3
	ecall
	mv	t4, a0		# save addres of pixels to t4
	
	li	a7, 9		# this part allocates heap memory for copy of pixels for 24bit colors (this one will be rewritten and is gargabe at start)
	srli	t1, s9, 1
	add	t1, t1, s9
	mv	a0, t1
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
	
	#li	a7, 62		# this part seeks to start of the file
	#mv	a0, s0
	#li	a1, 0
	#li	a2, 0
	#ecall
	
	mv	a0, t4
	mv	a1, t5
	mv	a2, t3
	ret
# --------------------------------------------------

# --------------------------------------------------
getBitsPerPixels:
	# needs   <- address to generic image data in a0
	# returns -> bits per pixel in a1
	lhu	a1, 28(a0)
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
	# ----------------------- this part sets correct offset to raster data
	li	t0, 54		# offset to raster data (initialy 54 which is constant size of Header+InfoHeader)
	lw	t1, editedImgData	# load colors count to t1
	slli	t2, t1, 2	# each color takes 4 bytes so mul by 4, final colors space taken in t2
	add	t0, t0, t2	# final offset to raster data in t0
	
	la	t3, fileDt	# this part updates offset to raster data after convolution
	sh	t0, 10(t3)
	srli	t0, t0, 16
	sh	t0, 12(t3)
	
	# ----------------------- this part sets correct file size
	li	t0, 54		# constant size of Header+HeaderInfo is 54, store size in t0
	add	t0, t0, t2	# header + colors
	add	t0, t0, s9	# header + colors + pixels(8bit colors), final file size in t0
	
	la	t3, fileDt	# this part updates file size after convolution
	sh	t0, 2(t3)
	srli	t0, t0, 16
	sh	t0, 4(t3)
	
	# ----------------------- this part sets bits per pixel (8bits)
	la	t3, fileDt
	li	a0, 8
	sh	a0, 28(t3)
	
	# ----------------------- this part sets used colors count
	la	t3, fileDt
	sh	t1, 46(t3)
	srli	t1, t1, 16
	sh	t1, 48(t3)
	
	mv	a0, t2
	mv	a1, s9

	ret
# --------------------------------------------------

# --------------------------------------------------
saveImg:
	# needs   <- colorsTable size in a0, rasterData size in a1
	# returns -> NOTHING
	mv	t0, a0
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
	li	a7, 64		# this part writes colors
	mv	a0, s0
	mv	a1, s8
	mv	a2, t0
	ecall
	li	a7, 64		# this part writes rasterData
	mv	a0, s0
	mv	a1, s3
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
