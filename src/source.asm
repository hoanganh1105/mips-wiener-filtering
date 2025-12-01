.data
# read_input + store
#desired_signal:   .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
#input_signal:     .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0


# test
desired_signal:   .float 0.2, 0.8, 1.2, 0.4, -0.1, -0.8, -1.1, -0.4, 0.3, 0.7
input_signal:     .float 0.0, 0.6, 1.0, 0.6, 0.0, -0.6, -1.0, -0.6, 0.0, 0.6

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


# I/O
space:    .asciiz " "
newline:  .asciiz "\n"

# Debug messages
gamma_xx_msg: .asciiz "gamma_xx: "
gamma_dx_msg: .asciiz "gamma_dx: "

.text
.globl main

main: # call procedure
    jal autoCorrelation      # 1. Tính γₓₓ
    jal crossCorrelation     # 2. Tính γₓd  
    
    jal print_debug          # ← DEBUG: xem correlation tính đúng không
    
    jal build_R_matrix       # 3. Xây ma trận R
    jal solve_wiener_hopf    # 4. Giải hệ phương trình
    jal print_optimize_coefficient  # 5. In kết quả
    
    # Kết thúc
    li $v0, 10
    syscall
		
		
		
				
# autoCorrelation -> cal_gamma_xx
	
autoCorrelation:
	li $t0, 0       		# k
    	lw $t1, M
    	lw $t2, N
autoCorr_outer:
    	bge     $t0, $t1, autoCorr_done   # k >= M ?

    	li      $t3, 0                     # i = 0
   	l.s     $f4, float_zero                   # sum = 0.0

autoCorr_inner:
    	sub     $t4, $t2, $t0              # N - k
    	bge     $t3, $t4, autoCorr_inner_done

    # load x[i]
    	sll     $t5, $t3, 2
    	la 		$t9,input_signal 
    	add     $t6, $t5, $t9
    	l.s     $f0, 0($t6)

    # load x[i+k]
    	add     $t7, $t3, $t0
    	sll     $t7, $t7, 2
    	la 		$t9, input_signal
    	add     $t8, $t7, $t9
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
    la $t9, R_matrix
    s.s $f0, 0($t9)      # R[0,0]
    s.s $f0, 16($t9)     # R[1,1]
    s.s $f0, 32($t9)     # R[2,2]

    # R[0,1] = R[1,0] = R[1,2] = R[2,1] = gamma_xx_1
    l.s $f1, gamma_xx_1
    s.s $f1, 4($t9)      # R[0,1]
    s.s $f1, 12($t9)     # R[1,0]
    s.s $f1, 20($t9)     # R[1,2]
    s.s $f1, 28($t9)     # R[2,1]

    # R[0,2] = R[2,0] = gamma_xx_2
    l.s $f2, gamma_xx_2
    s.s $f2, 8($t9)      # R[0,2]
    s.s $f2, 24($t9)     # R[2,0]

    jr $ra



#crossCorrelation
crossCorrelation:
    li $t0, 0               # k
    lw $t1, M
    lw $t2, N
    
crossCorr_outer:
    bge $t0, $t1, crossCorr_done
    
    li $t3, 0               # i = 0
    l.s $f4, float_zero     # sum = 0.0
    
crossCorr_inner:
    sub $t4, $t2, $t0       # N - k
    bge $t3, $t4, crossCorr_inner_done
    
    # Load d[i]
    sll $t5, $t3, 2
    la $t6, desired_signal
    add $t6, $t6, $t5
    l.s $f0, 0($t6)
    
    # Load x[i+k]
    add $t7, $t3, $t0
    sll $t7, $t7, 2
    la $t8, input_signal
    add $t8, $t8, $t7
    l.s $f1, 0($t8)
    
    mul.s $f2, $f0, $f1     # d[i]*x[i+k]
    add.s $f4, $f4, $f2     # sum +=
    
    addi $t3, $t3, 1
    j crossCorr_inner
    
crossCorr_inner_done:
    # sum / N
    mtc1 $t2, $f5
    cvt.s.w $f5, $f5
    div.s $f4, $f4, $f5
    
    # store to gamma
    beq $t0, 0, store_gamma_dx0
    beq $t0, 1, store_gamma_dx1
    beq $t0, 2, store_gamma_dx2
    j cross_skip_store
    
store_gamma_dx0:
    s.s $f4, gamma_dx_0
    la $t9, gamma_vector
    s.s $f4, 0($t9)
    j cross_skip_store
store_gamma_dx1:
    s.s $f4, gamma_dx_1 
    la $t9, gamma_vector
    s.s $f4, 4($t9)
    j cross_skip_store
store_gamma_dx2:
    s.s $f4, gamma_dx_2
    la $t9, gamma_vector
    s.s $f4, 8($t9)
    
    
cross_skip_store:
    addi $t0, $t0, 1
    j crossCorr_outer
    
crossCorr_done:
    jr $ra
# solve weinerHopf
solve_wiener_hopf:
    
    # Load các phần tử (R là ma trận đối xứng)
    la $t9, R_matrix
    l.s $f0, 0($t9)     # a = R[0,0]
    l.s $f1, 4($t9)     # b = R[0,1] 
    l.s $f2, 8($t9)     # c = R[0,2]
    l.s $f3, 16($t9)    # d = R[1,1] (a)
    l.s $f4, 20($t9)    # e = R[1,2] (b)  
    l.s $f5, 32($t9)    # f = R[2,2] (a)
    
    # Load vector γ
    la $t9, gamma_vector    
    l.s $f6, 0($t9) # γ0
    l.s $f7, 4($t9) # γ1  
    l.s $f8, 8($t9) # γ2
    

    # det = a(df - e²) - b(bf - ce) + c(be - dc)
    # d = a, e = b, f = a
    # => det = a(a*a - b²) - b(b*a - b*c) + c(b*b - a*c)
    # => det = a³ - ab² - ab² + b²c + b²c - ac²
    # => det = a³ - 2ab² + 2b²c - ac²
    
    # det
    mul.s $f9, $f0, $f0      # a²
    mul.s $f9, $f9, $f0      # a³
    
    mul.s $f10, $f0, $f1     # a*b
    mul.s $f10, $f10, $f1    # a*b²
    add.s $f10, $f10, $f10   # 2ab²
    
    mul.s $f11, $f1, $f1     # b²
    mul.s $f11, $f11, $f2    # b²*c
    add.s $f11, $f11, $f11   # 2b²c
    
    mul.s $f12, $f0, $f2     # a*c
    mul.s $f12, $f12, $f2    # a*c²
    
    # det = a³ - 2ab² + 2b²c - ac²
    sub.s $f13, $f9, $f10    # a³ - 2ab²
    add.s $f13, $f13, $f11   # + 2b²c
    sub.s $f13, $f13, $f12   # - ac²
    
    # Lưu định thức
    mov.s $f30, $f13         # det = $f30
    
    # det = 0 ?
    l.s $f14, float_zero
    c.eq.s $f30, $f14
    bc1t singular_det
    
    # adj matrix
    # adj[0,0] = (d*f - e*e) = (a*a - b*b) = a² - b²
    mul.s $f15, $f3, $f5     # d*f = a*a
    mul.s $f16, $f4, $f4     # e*e = b*b  
    sub.s $f17, $f15, $f16   # adj00 = a² - b²
    
    # adj[0,1] = -(b*f - c*e) = -(b*a - c*b) = -ab + bc
    mul.s $f15, $f1, $f5     # b*f = b*a
    mul.s $f16, $f2, $f4     # c*e = c*b
    sub.s $f18, $f16, $f15   # adj01 = -(b*f - c*e) = bc - ab
    
    # adj[0,2] = (b*e - c*d) = (b*b - c*a) = b² - ac
    mul.s $f15, $f1, $f4     # b*e = b*b
    mul.s $f16, $f2, $f3     # c*d = c*a
    sub.s $f19, $f15, $f16   # adj02 = b² - ac
    
    # adj[1,0] = -(b*f - c*e) = bc - ab (adj01)
    mov.s $f20, $f18         # adj10 = adj01
    
    # adj[1,1] = (a*f - c*c) = (a*a - c*c) = a² - c²
    mul.s $f15, $f0, $f5     # a*f = a*a
    mul.s $f16, $f2, $f2     # c*c
    sub.s $f21, $f15, $f16   # adj11 = a² - c²
    
    # adj[1,2] = -(a*e - b*c) = -(a*b - b*c) = -ab + bc
    mul.s $f15, $f0, $f4     # a*e = a*b
    mul.s $f16, $f1, $f2     # b*c
    sub.s $f22, $f16, $f15   # adj12 = -(a*e - b*c) = bc - ab
    
    # adj[2,0] = (b*e - c*d) = b² - ac (adj02)
    mov.s $f23, $f19         # adj20 = adj02
    
    # adj[2,1] = -(a*e - b*c) = bc - ab (adj12)  
    mov.s $f24, $f22         # adj21 = adj12
    
    # adj[2,2] = (a*d - b*b) = (a*a - b*b) = a² - b²
    mov.s $f25, $f17         # adj22 = adj00
    
    # R⁻¹
    div.s $f17, $f17, $f30   # adj00 / det
    div.s $f18, $f18, $f30   # adj01 / det
    div.s $f19, $f19, $f30   # adj02 / det
    div.s $f20, $f20, $f30   # adj10 / det
    div.s $f21, $f21, $f30   # adj11 / det
    div.s $f22, $f22, $f30   # adj12 / det
    div.s $f23, $f23, $f30   # adj20 / det
    div.s $f24, $f24, $f30   # adj21 / det
    div.s $f25, $f25, $f30   # adj22 / det
    
    # h_opt
    # h0 = R⁻¹[0,0]*γ0 + R⁻¹[0,1]*γ1 + R⁻¹[0,2]*γ2
    mul.s $f26, $f17, $f6    # R⁻¹00 * γ0
    mul.s $f27, $f18, $f7    # R⁻¹01 * γ1
    add.s $f26, $f26, $f27
    mul.s $f27, $f19, $f8    # R⁻¹02 * γ2
    add.s $f26, $f26, $f27
    la $t9, optimize_coefficient
    s.s $f26, 0($t9)  # h[0]
    
    # h1 = R⁻¹[1,0]*γ0 + R⁻¹[1,1]*γ1 + R⁻¹[1,2]*γ2
    mul.s $f26, $f20, $f6    # R⁻¹10 * γ0
    mul.s $f27, $f21, $f7    # R⁻¹11 * γ1
    add.s $f26, $f26, $f27
    mul.s $f27, $f22, $f8    # R⁻¹12 * γ2
    add.s $f26, $f26, $f27
    s.s $f26, 4($t9)  # h[1]
    
    # h2 = R⁻¹[2,0]*γ0 + R⁻¹[2,1]*γ1 + R⁻¹[2,2]*γ2
    mul.s $f26, $f23, $f6    # R⁻¹20 * γ0
    mul.s $f27, $f24, $f7    # R⁻¹21 * γ1
    add.s $f26, $f26, $f27
    mul.s $f27, $f25, $f8    # R⁻¹22 * γ2
    add.s $f26, $f26, $f27
    s.s $f26, 8($t9)  # h[2]
    
    j solve_done

singular_det:
    # det = 0
    # pseudo-inverse
    
    la $t9, optimize_coefficient
    
    l.s $f14, float_zero
    c.eq.s $f0, $f14
    bc1t no_solution
    
    # h[k] = γ_dx[k] / R[0,0] (approximation)
    div.s $f15, $f6, $f0
    s.s $f15, 0($t9)
    div.s $f15, $f7, $f0
    s.s $f15, 4($t9)
    div.s $f15, $f8, $f0
    s.s $f15, 8($t9)
    j solve_done

no_solution:
    # Default: identity filter
    l.s $f15, float_one
    s.s $f15, 0($t9)
    l.s $f15, float_zero
    s.s $f15, 4($t9)
    s.s $f15, 8($t9)

solve_done:
    jr $ra
	
	
	

# check code ___ print
print_optimize_coefficient:
    la $t0, optimize_coefficient   # địa chỉ mảng
    li $t1, 3                      # số phần tử
    li $t2, 0                      # index = 0

print_loop:
    bge $t2, $t1, print_done

    sll $t3, $t2, 2                # offset = index * 4
    add $t4, $t0, $t3
    l.s $f12, 0($t4)               # load float
    li $v0, 2                       # syscall print float
    syscall

    # in space
    li $v0, 4
    la $a0, space
    syscall

    addi $t2, $t2, 1
    j print_loop

print_done:
    # in newline
    li $v0, 4
    la $a0, newline
    syscall
    jr $ra
    
    
    
# ========== DEBUG PRINT ==========
print_debug:
    # In gamma_xx
    la $a0, gamma_xx_msg
    li $v0, 4
    syscall
    
    l.s $f12, gamma_xx_0
    li $v0, 2
    syscall
    la $a0, space
    li $v0, 4
    syscall
    
    l.s $f12, gamma_xx_1
    li $v0, 2
    syscall
    la $a0, space
    li $v0, 4
    syscall
    
    l.s $f12, gamma_xx_2
    li $v0, 2
    syscall
    la $a0, newline
    li $v0, 4
    syscall
    
    # In gamma_dx
    la $a0, gamma_dx_msg
    li $v0, 4
    syscall
    
    l.s $f12, gamma_dx_0
    li $v0, 2
    syscall
    la $a0, space
    li $v0, 4
    syscall
    
    l.s $f12, gamma_dx_1
    li $v0, 2
    syscall
    la $a0, space
    li $v0, 4
    syscall
    
    l.s $f12, gamma_dx_2
    li $v0, 2
    syscall
    la $a0, newline
    li $v0, 4
    syscall
    
    jr $ra