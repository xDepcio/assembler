# Sample program that writes to a new file.
#   by Kenneth Vollmar and Pete Sanderson

        .data
fname:  .asciz "img.bmp"      # filename for output
buffer: .asciz "The quick brown fox jumps over the lazy dog."
	.align	2
read:	.space	100
	.align	0
colors:	.space	100
        .text
  ###############################################################
  # Open (for writing) a file that does not exist
  li   a7, 1024     # system call for open file
  la   a0, fname    # output file name
  li   a1, 0        # Open for writing (flags are 0: read, 1: write)
  ecall             # open a file (file descriptor returned in a0)
  mv   s6, a0       # save the file descriptor
  ###############################################################
	li	a7, 63
	mv	a0, s6
	la	a1, read
	li	a2, 100
	ecall
 
 	la	t0, read
 	lh	t1, 2(t0)
 readColors:
 	lw	t2, 64(t0)
 	
 
 
  
  
  #li   a7, 64       # system call for write to file
  #mv   a0, s6       # file descriptor
  #la   a1, buffer   # address of buffer from which to write
  #li   a2, 44       # hardcoded buffer length
  #ecall             # write to file
  ###############################################################
  # Close the file
  li   a7, 57       # system call for close file
  mv   a0, s6       # file descriptor to close
  ecall             # close file
  ###############################################################
