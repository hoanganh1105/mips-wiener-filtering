.data
# 
desired_signal:   .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
input_signal:     .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
optimize_coefficient: .float 0.0, 0.0, 0.0  # h_opt với M=3
mmse:             .float 0.0
output_signal:    .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

# helper val
M:          .word 3      # filter's size      
N:          .word 10     # input's size

# Autocorrelation
gamma_xx_0: .float 0.0
gamma_xx_1: .float 0.0  
gamma_xx_2: .float 0.0

# Cross-correlation
gamma_dx_0: .float 0.0
gamma_dx_1: .float 0.0
gamma_dx_2: .float 0.0

# Rh_matrix
R_matrix:   .float 0.0, 0.0, 0.0
            .float 0.0, 0.0, 0.0
            .float 0.0, 0.0, 0.0

# Vector gamma
gamma_vector: .float 0.0, 0.0, 0.0

# constance
float_zero: .float 0.0
float_one:  .float 1.0

.globl main

main: # call procedure 
	
# autoCorrelation -> cal_gamma_xx
	
autoCorrelation:
	li $t0, 0       		# k
    	lw $t1, M
    	lw $t2, N
autoCorr_outer:
    	bge     $t0, $t1, autoCorr_done   # k >= M ?

    	li      $t3, 0                     # i = 0
   	l.s    $f4, 0.0                   # sum = 0.0

autoCorr_inner:
    	sub     $t4, $t2, $t0              # N - k
    	bge     $t3, $t4, autoCorr_inner_done

    # load x[i]
    	sll     $t5, $t3, 2
    	add     $t6, $t5, input_signal
    	l.s     $f0, 0($t6)

    # load x[i+k]
    	add     $t7, $t3, $t0
    	sll     $t7, $t7, 2
    	add     $t8, $t7, input_signal
    	l.s     $f1, 0($t8)

    	mul.s   $f2, $f0, $f1               # x[i]*x[i+k]
    	add.s   $f4, $f4, $f2               # sum +=

    	addi    $t3, $t3, 1
    	j       autoCorr_inner

autoCorr_inner_done:
    # sum / N
    	mtc1    $t2, $f5                     # N → float
    	cvt.s.w $f5, $f5
    	div.s   $f4, $f4, $f5

    # sum -> gamma_xx
    	beq     $t0, 0, store_gamma0
    	beq     $t0, 1, store_gamma1
    	beq     $t0, 2, store_gamma2
    	j       skip_store

store_gamma0:
    	s.s     $f4, gamma_xx_0
    	j       skip_store
store_gamma1:
    	s.s     $f4, gamma_xx_1
    	j       skip_store
store_gamma2:
    	s.s     $f4, gamma_xx_2

skip_store:
    	addi    $t0, $t0, 1
    	j       autoCorr_outer

autoCorr_done:
    	jr $ra

# build R_matrix	
build_R_matrix:
    # R[0,0] = R[1,1] = R[2,2] = gamma_xx_0
    l.s $f0, gamma_xx_0
    s.s $f0, 0(R_matrix)      # R[0,0]
    s.s $f0, 16(R_matrix)     # R[1,1]
    s.s $f0, 32(R_matrix)     # R[2,2]

    # R[0,1] = R[1,0] = R[1,2] = R[2,1] = gamma_xx_1
    l.s $f1, gamma_xx_1
    s.s $f1, 4(R_matrix)      # R[0,1]
    s.s $f1, 12(R_matrix)     # R[1,0]
    s.s $f1, 20(R_matrix)     # R[1,2]
    s.s $f1, 28(R_matrix)     # R[2,1]

    # R[0,2] = R[2,0] = gamma_xx_2
    l.s $f2, gamma_xx_2
    s.s $f2, 8(R_matrix)      # R[0,2]
    s.s $f2, 24(R_matrix)     # R[2,0]

    jr $ra

	
	
	
	
	


