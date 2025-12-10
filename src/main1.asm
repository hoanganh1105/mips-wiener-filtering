.data
# ---------------- CONFIG & DATA ----------------
N: .word 10                  # Kích thước bắt buộc
M: .word 10                  # Filter order

# --- FILE PATHS ---
fn_input:     .asciiz "input.txt"
.align 2 
fn_desired:   .asciiz "desired.txt"
.align 2
filename:     .asciiz "output.txt"

# --- DATA BUFFERS ---
.align 2 
input_signal:   .space 40          # 10 float * 4 bytes
.align 2
desired_signal: .space 40

# --- RESULT VARIABLES ---
.align 2
optimize_coefficient: .space 40    
.align 2
output_signal:        .space 400
.align 2
mmse:                 .float 0.0

# --- INTERMEDIATE VARIABLES ---
.align 2
gamma_xx:   .float 0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
gamma_dx:   .float 0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0

.align 2
R_matrix:   .space 400

.align 2
gamma_vector: .space 40

# --- CONSTANTS & STRINGS ---
.align 2
float_zero:   .float 0.0
float_one:    .float 1.0
ten_f:        .float 10.0
half_f:       .float 0.5
neg_one_f:    .float -1.0

.align 2
file_buffer:  .space 2048 

filtered_msg: .asciiz "Filtered output: "
mmse_msg:     .asciiz "MMSE: "
space:        .asciiz " "
nl:           .asciiz "\n"
minus:        .asciiz "-"
dot:          .asciiz "."

# --- ERROR MESSAGES ---
err_msg:      .asciiz "Error: cannot open output file\n"
err_read_msg: .asciiz "Error: cannot open input/desired file\n"
# Chuỗi lỗi này dài 21 ký tự
err_size_msg: .asciiz "Error: size not match" 

int_buf:      .space 20

.text
.globl main

# =========================================================================
# MAIN
# =========================================================================
main:
    # Load N (Expected Size) into $s5
    lw $s5, N

    # 1. Read Input File
    la $a0, fn_input
    la $a1, input_signal
    jal read_file_proc
    move $s6, $v0           # $s6 = Actual size of Input

    # Check Input Size: Must equal N (10)
    bne $s6, $s5, size_mismatch_error

    # 2. Read Desired File
    la $a0, fn_desired
    la $a1, desired_signal
    jal read_file_proc
    move $s7, $v0           # $s7 = Actual size of Desired

    # Check Desired Size: Must equal N (10)
    bne $s7, $s5, size_mismatch_error

    # --- Calculation Start (Only if sizes match) ---
    jal autoCorrelation
    jal crossCorrelation
    jal build_R_matrix
    jal solve_wiener_hopf

    # Open output file for Result Writing
    la $a0, filename
    li $a1, 1
    li $a2, 0
    li $v0, 13
    syscall
    move $s7, $v0
    blt $s7, 0, file_error

    jal filter_and_mmse
    lw $s1, N
    la $s5, output_signal

    # Print filtered header
    la $a0, filtered_msg
    li $v0, 4
    syscall
    move $a0, $s7
    la $a1, filtered_msg
    li $a2, 17
    li $v0, 15
    syscall

    li $s6, 0

loop_print:
    bge $s6, $s1, end_print
    sll $t0, $s6, 2
    add $t0, $t0, $s5
    lwc1 $f12, 0($t0)

    # Rounding for Console (Syscall 2)
    la $t0, ten_f
    lwc1 $f14, 0($t0)
    mul.s $f16, $f12, $f14
    lwc1 $f30, float_zero
    la $t0, half_f
    lwc1 $f14, 0($t0)
    c.lt.s $f16, $f30
    bc1f pos_round_y
    sub.s $f16, $f16, $f14
    j done_round_y
pos_round_y:
    add.s $f16, $f16, $f14
done_round_y:
    cvt.w.s $f16, $f16
    cvt.s.w $f12, $f16
    la $t0, ten_f
    lwc1 $f14, 0($t0)
    div.s $f12, $f12, $f14

    li $v0, 2
    syscall
    la $a0, space
    li $v0, 4
    syscall

    # Write to File
    jal write_float_proc
    move $a0, $s7
    la $a1, space
    li $a2, 1
    li $v0, 15
    syscall

    addi $s6, $s6, 1
    j loop_print

end_print:
    la $a0, nl
    li $v0, 4
    syscall
    move $a0, $s7
    la $a1, nl
    li $a2, 1
    li $v0, 15
    syscall

    la $a0, mmse_msg
    li $v0, 4
    syscall
    move $a0, $s7
    la $a1, mmse_msg
    li $a2, 6
    li $v0, 15
    syscall

    la $t0, mmse
    lwc1 $f12, 0($t0)
    la $t0, ten_f
    lwc1 $f14, 0($t0)
    mul.s $f16, $f12, $f14
    la $t0, half_f
    lwc1 $f14, 0($t0)
    add.s $f16, $f16, $f14
    cvt.w.s $f16, $f16
    cvt.s.w $f12, $f16
    la $t0, ten_f
    lwc1 $f14, 0($t0)
    div.s $f12, $f12, $f14

    li $v0, 2
    syscall
    jal write_float_proc

    move $a0, $s7
    li $v0, 16
    syscall

    li $v0, 10
    syscall

# --- ERROR HANDLERS ---

# Xử lý khi kích thước file không đúng (ghi ra cả Console và File)
size_mismatch_error:
    # 1. In lỗi ra Console
    la $a0, err_size_msg
    li $v0, 4
    syscall
    
    # 2. Mở file output.txt để ghi lỗi
    la $a0, filename
    li $a1, 1      # Flag 1: Write only (Create/Truncate)
    li $a2, 0
    li $v0, 13
    syscall
    move $s7, $v0  # Lưu file descriptor vào $s7
    
    # Nếu không mở được file thì chỉ thoát
    blt $s7, 0, exit_mismatch

    # 3. Ghi chuỗi lỗi vào file
    move $a0, $s7
    la $a1, err_size_msg
    li $a2, 21     # Độ dài chuỗi "Error: size not match" là 21
    li $v0, 15
    syscall

    # 4. Đóng file
    move $a0, $s7
    li $v0, 16
    syscall

exit_mismatch:
    li $v0, 10
    syscall

file_error:
    la $a0, err_msg
    li $v0, 4
    syscall
    li $v0, 10
    syscall

read_error:
    la $a0, err_read_msg
    li $v0, 4
    syscall
    li $v0, 10
    syscall

# =========================================================================
# read_file_proc
# =========================================================================
read_file_proc:
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)

    move $s1, $a1

    # Open file
    li $a1, 0
    li $a2, 0
    li $v0, 13
    syscall
    move $s0, $v0
    blt $s0, 0, read_error

    # Read content
    move $a0, $s0
    la $a1, file_buffer
    li $a2, 2048
    li $v0, 14
    syscall
    move $s3, $v0
    
    # Close file
    move $a0, $s0
    li $v0, 16
    syscall

    la $s2, file_buffer
    add $s3, $s2, $s3

    li $t8, 0          # Count parsed numbers

parse_loop:
    # Removed explicit loop limit check vs N here to allow counting overflow
    bge $s2, $s3, done_parse

    lwc1 $f0, float_zero
    lwc1 $f1, float_one
    lwc1 $f2, ten_f
    lwc1 $f3, float_one
    li $t0, 0
    li $t1, 0

skip_spaces:
    bge $s2, $s3, finish_num
    lb $t2, 0($s2)
    beq $t2, 32, check_finish
    beq $t2, 9, check_finish
    beq $t2, 10, check_finish
    beq $t2, 13, check_finish
    beq $t2, 45, is_minus
    beq $t2, 46, is_dot
    blt $t2, 48, next_char
    bgt $t2, 57, next_char

    li $t1, 1
    sub $t2, $t2, 48
    mtc1 $t2, $f4
    cvt.s.w $f4, $f4

    beq $t0, 1, process_fraction

    mul.s $f0, $f0, $f2
    add.s $f0, $f0, $f4
    j next_char

process_fraction:
    mul.s $f3, $f3, $f2
    div.s $f4, $f4, $f3
    add.s $f0, $f0, $f4
    j next_char

is_minus:
    lwc1 $f1, neg_one_f
    j next_char

is_dot:
    li $t0, 1
    j next_char

check_finish:
    beqz $t1, next_char
    j finish_num

next_char:
    addi $s2, $s2, 1
    j skip_spaces

finish_num:
    beqz $t1, really_done
    
    lw $t9, N
    bge $t8, $t9, skip_store  # Nếu đã đủ 10 số, chỉ tăng biến đếm, không lưu
    
    mul.s $f0, $f0, $f1
    swc1 $f0, 0($s1)
    addi $s1, $s1, 4

skip_store:
    addi $t8, $t8, 1          # Luôn tăng biến đếm

    addi $s2, $s2, 1
    j parse_loop

really_done:
    j done_parse

done_parse:
    move $v0, $t8       # Trả về tổng số phần tử tìm thấy
    
    lw $s3, 16($sp)
    lw $s2, 12($sp)
    lw $s1, 8($sp)
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 20
    jr $ra

# =========================================================================
# autoCorrelation (BIASSED)
# =========================================================================
autoCorrelation:
    lw $t3, M        
    lw $t4, N        
    addi $t0, $zero, 0   

autoCorr_outer:
    bge $t0, $t3, autoCorr_done
    lwc1 $f4, float_zero      
    move $t1, $t0             

autoCorr_inner:
    bge $t1, $t4, autoCorr_inner_done
    sll $t5, $t1, 2
    la $t6, input_signal
    add $t6, $t6, $t5
    lwc1 $f0, 0($t6)

    sub $t7, $t1, $t0
    sll $t7, $t7, 2
    la $t8, input_signal
    add $t8, $t8, $t7
    lwc1 $f1, 0($t8)

    mul.s $f2, $f0, $f1
    add.s $f4, $f4, $f2
    addi $t1, $t1, 1
    j autoCorr_inner

autoCorr_inner_done:
    mtc1 $t4, $f5
    cvt.s.w $f5, $f5
    div.s $f4, $f4, $f5

    la $t6, gamma_xx
    sll $t7, $t0, 2
    add $t6, $t6, $t7
    swc1 $f4, 0($t6)

    addi $t0, $t0, 1
    j autoCorr_outer

autoCorr_done:
    jr $ra

# =========================================================================
# crossCorrelation (BIASSED)
# =========================================================================
crossCorrelation:
    lw $t3, M
    lw $t4, N
    addi $t0, $zero, 0   

crossCorr_outer:
    bge $t0, $t3, crossCorr_done
    lwc1 $f4, float_zero  
    move $t1, $t0         

crossCorr_inner:
    bge $t1, $t4, crossCorr_inner_done
    sll $t5, $t1, 2
    la $t6, desired_signal
    add $t6, $t6, $t5
    lwc1 $f0, 0($t6)

    sub $t7, $t1, $t0
    sll $t7, $t7, 2
    la $t8, input_signal
    add $t8, $t8, $t7
    lwc1 $f1, 0($t8)

    mul.s $f2, $f0, $f1
    add.s $f4, $f4, $f2
    addi $t1, $t1, 1
    j crossCorr_inner

crossCorr_inner_done:
    mtc1 $t4, $f5
    cvt.s.w $f5, $f5
    div.s $f4, $f4, $f5

    la $t6, gamma_dx
    sll $t7, $t0, 2
    add $t6, $t6, $t7
    swc1 $f4, 0($t6)

    la $t6, gamma_vector
    add $t6, $t6, $t7
    swc1 $f4, 0($t6)

    addi $t0, $t0, 1
    j crossCorr_outer

crossCorr_done:
    jr $ra

# =========================================================================
# build_R_matrix
# =========================================================================
build_R_matrix:
    lw $t3, M           
    la $t1, R_matrix    
    la $t2, gamma_xx

    addi $t0, $zero, 0   
build_row_loop:
    bge $t0, $t3, build_done
    addi $t1, $zero, 0   
build_col_loop:
    bge $t1, $t3, next_row_build
    sub $t2, $t0, $t1
    bltz $t2, pos_diff
    j use_diff
pos_diff:
    sub $t2, $zero, $t2
use_diff:
    sll $t4, $t2, 2
    la $t5, gamma_xx
    add $t5, $t5, $t4
    lwc1 $f0, 0($t5)
    
    mul $t6, $t0, $t3        
    add $t6, $t6, $t1        
    sll $t6, $t6, 2
    la $t7, R_matrix
    add $t7, $t7, $t6
    s.s $f0, 0($t7)
    addi $t1, $t1, 1
    j build_col_loop
next_row_build:
    addi $t0, $t0, 1
    j build_row_loop
build_done:
    jr $ra

# =========================================================================
# solve_wiener_hopf
# =========================================================================
solve_wiener_hopf:
    lw $t3, M
    la $t4, R_matrix
    la $t5, gamma_vector
    la $t6, optimize_coefficient

    addi $t0, $zero, 0
zero_x_loop:
    bge $t0, $t3, zero_x_done
    sll $t1, $t0, 2
    la $t7, optimize_coefficient
    add $t7, $t7, $t1
    lwc1 $f2, float_zero
    s.s $f2, 0($t7)
    addi $t0, $t0, 1
    j zero_x_loop
zero_x_done:

    lwc1 $f12, float_zero
    addi $t0, $zero, 0    
elim_outer:
    bge $t0, $t3, elim_done

    mul $t7, $t0, $t3        
    add $t7, $t7, $t0        
    sll $t7, $t7, 2
    la $t8, R_matrix
    add $t8, $t8, $t7
    lwc1 $f14, 0($t8)        

    c.eq.s $f14, $f12
    bc1f pivot_nonzero

    addi $t2, $t0, 1
find_swap:
    bge $t2, $t3, singular_case   
    mul $t9, $t2, $t3
    add $t9, $t9, $t0
    sll $t9, $t9, 2
    la $t7, R_matrix
    add $t7, $t7, $t9
    lwc1 $f2, 0($t7)
    c.eq.s $f2, $f12
    bc1t no_swap_here
    
    addi $t1, $zero, 0            
swap_row_loop:
    bge $t1, $t3, swap_done
    mul $t9, $t0, $t3
    add $t9, $t9, $t1
    sll $t9, $t9, 2
    la $t7, R_matrix
    add $t7, $t7, $t9
    lwc1 $f4, 0($t7)
    mul $t9, $t2, $t3
    add $t9, $t9, $t1
    sll $t9, $t9, 2
    la $t8, R_matrix
    add $t8, $t8, $t9
    lwc1 $f6, 0($t8)
    s.s $f6, 0($t7)
    s.s $f4, 0($t8)
    addi $t1, $t1, 1
    j swap_row_loop
swap_done:
    sll $t9, $t0, 2
    la $t7, gamma_vector
    add $t7, $t7, $t9
    lwc1 $f4, 0($t7)
    sll $t9, $t2, 2
    la $t8, gamma_vector
    add $t8, $t8, $t9
    lwc1 $f6, 0($t8)
    s.s $f6, 0($t7)
    s.s $f4, 0($t8)

    mul $t7, $t0, $t3
    add $t7, $t7, $t0
    sll $t7, $t7, 2
    la $t8, R_matrix
    add $t8, $t8, $t7
    lwc1 $f14, 0($t8)
    j pivot_ready

no_swap_here:
    addi $t2, $t2, 1
    j find_swap

singular_case:
    la $t7, optimize_coefficient
    lwc1 $f2, float_one
    s.s $f2, 0($t7)
    lwc1 $f2, float_zero
    addi $t7, $t7, 4
    addi $t9, $zero, 1
sing_loop:
    bge $t9, $t3, singular_done
    s.s $f2, 0($t7)
    addi $t7, $t7, 4
    addi $t9, $t9, 1
    j sing_loop
singular_done:
    jr $ra

pivot_nonzero:
pivot_ready:
    addi $t1, $zero, 0
norm_loop:
    bge $t1, $t3, norm_done
    blt $t1, $t0, skip_norm_elem
    mul $t9, $t0, $t3
    add $t9, $t9, $t1
    sll $t9, $t9, 2
    la $t7, R_matrix
    add $t7, $t7, $t9
    lwc1 $f4, 0($t7)
    div.s $f6, $f4, $f14
    s.s $f6, 0($t7)
skip_norm_elem:
    addi $t1, $t1, 1
    j norm_loop
norm_done:
    sll $t9, $t0, 2
    la $t7, gamma_vector
    add $t7, $t7, $t9
    lwc1 $f4, 0($t7)
    div.s $f6, $f4, $f14
    s.s $f6, 0($t7)

    addi $t2, $t0, 1
elim_k_loop:
    bge $t2, $t3, next_i
    mul $t9, $t2, $t3
    add $t9, $t9, $t0
    sll $t9, $t9, 2
    la $t7, R_matrix
    add $t7, $t7, $t9
    lwc1 $f8, 0($t7)    

    addi $t1, $t0, 0
elim_inner:
    bge $t1, $t3, elim_done_inner
    mul $t9, $t2, $t3
    add $t9, $t9, $t1
    sll $t9, $t9, 2
    la $t7, R_matrix
    add $t7, $t7, $t9
    lwc1 $f4, 0($t7)        
    mul $t9, $t0, $t3
    add $t9, $t9, $t1
    sll $t9, $t9, 2
    la $t8, R_matrix
    add $t8, $t8, $t9
    lwc1 $f6, 0($t8)        
    mul.s $f10, $f8, $f6
    sub.s $f2, $f4, $f10
    s.s $f2, 0($t7)
    addi $t1, $t1, 1
    j elim_inner
elim_done_inner:
    sll $t9, $t2, 2
    la $t7, gamma_vector
    add $t7, $t7, $t9
    lwc1 $f4, 0($t7)    
    sll $t9, $t0, 2
    la $t8, gamma_vector
    add $t8, $t8, $t9
    lwc1 $f6, 0($t8)    
    mul.s $f10, $f8, $f6
    sub.s $f2, $f4, $f10
    s.s $f2, 0($t7)

    addi $t2, $t2, 1
    j elim_k_loop

next_i:
    addi $t0, $t0, 1
    j elim_outer

elim_done:
    add $t0, $t3, $zero
    addi $t0, $t0, -1   
back_sub_i:
    blt $t0, $zero, back_sub_done
    sll $t9, $t0, 2
    la $t7, gamma_vector
    add $t7, $t7, $t9
    lwc1 $f4, 0($t7)        

    addi $t1, $t0, 1
back_inner:
    bge $t1, $t3, store_xi
    mul $t9, $t0, $t3
    add $t9, $t9, $t1
    sll $t9, $t9, 2
    la $t7, R_matrix
    add $t7, $t7, $t9
    lwc1 $f6, 0($t7)
    sll $t9, $t1, 2
    la $t8, optimize_coefficient
    add $t8, $t8, $t9
    lwc1 $f8, 0($t8)
    mul.s $f10, $f6, $f8
    sub.s $f4, $f4, $f10
    addi $t1, $t1, 1
    j back_inner

store_xi:
    sll $t9, $t0, 2
    la $t7, optimize_coefficient
    add $t7, $t7, $t9
    s.s $f4, 0($t7)
    addi $t0, $t0, -1
    j back_sub_i

back_sub_done:
    jr $ra

# =========================================================================
# filter_and_mmse
# =========================================================================
filter_and_mmse:
    addi $sp, $sp, -28
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)

    lw $s1, N
    lw $s0, M
    la $s2, optimize_coefficient
    la $s3, input_signal
    la $s4, desired_signal
    la $s5, output_signal

    li $t0, 0
    lwc1 $f20, float_zero

calc_loop:
    bge $t0, $s1, calc_done
    lwc1 $f0, float_zero
    li $t1, 0

inner_loop2:
    bge $t1, $s0, inner_done2
    sub $t2, $t0, $t1
    blt $t2, $zero, skip_mul2

    sll $t3, $t2, 2
    add $t3, $t3, $s3
    lwc1 $f2, 0($t3)

    sll $t3, $t1, 2
    add $t3, $t3, $s2
    lwc1 $f4, 0($t3)

    mul.s $f6, $f2, $f4
    add.s $f0, $f0, $f6

skip_mul2:
    addi $t1, $t1, 1
    j inner_loop2

inner_done2:
    sll $t3, $t0, 2
    add $t3, $t3, $s5
    swc1 $f0, 0($t3)

    sll $t3, $t0, 2
    add $t3, $t3, $s4
    lwc1 $f8, 0($t3)

    sub.s $f10, $f8, $f0
    mul.s $f10, $f10, $f10
    add.s $f20, $f20, $f10

    addi $t0, $t0, 1
    j calc_loop

calc_done:
    mtc1 $s1, $f16
    cvt.s.w $f16, $f16
    div.s $f18, $f20, $f16
    la $t0, mmse
    swc1 $f18, 0($t0)

    lw $s5, 24($sp)
    lw $s4, 20($sp)
    lw $s3, 16($sp)
    lw $s2, 12($sp)
    lw $s1, 8($sp)
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 28
    jr $ra


# =========================================================================
# write_float_proc
# =========================================================================
write_float_proc:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $t0, 4($sp)
    sw $t1, 8($sp)
    
    lwc1 $f0, float_zero
    c.lt.s $f12, $f0
    bc1f proc_pos
    
    move $a0, $s7
    la $a1, minus
    li $a2, 1
    li $v0, 15
    syscall
    sub.s $f12, $f0, $f12

proc_pos:
    cvt.w.s $f0, $f12        
    mfc1 $a0, $f0
    cvt.s.w $f1, $f0        
    jal write_int_proc
    move $a0, $s7
    la $a1, dot
    li $a2, 1
    li $v0, 15
    syscall
    
    sub.s $f2, $f12, $f1    
    la $t0, ten_f
    lwc1 $f3, 0($t0)
    mul.s $f2, $f2, $f3    
    la $t0, half_f          
    lwc1 $f4, 0($t0)
    add.s $f2, $f2, $f4     
    cvt.w.s $f2, $f2        
    mfc1 $a0, $f2
    abs $a0, $a0            
    jal write_int_proc
    
    lw $t1, 8($sp)
    lw $t0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 12
    jr $ra

write_int_proc:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    la $t0, int_buf
    add $t0, $t0, 10
    move $t1, $a0
    li $t2, 10
    bnez $t1, loop_conv
    addi $t0, $t0, -1
    li $t3, 48
    sb $t3, 0($t0)
    j write_now
loop_conv:
    beqz $t1, write_now
    div $t1, $t2
    mfhi $t3
    mflo $t1
    addi $t3, $t3, 48
    addi $t0, $t0, -1
    sb $t3, 0($t0)
    j loop_conv
write_now:
    la $t4, int_buf
    add $t4, $t4, 10
    sub $a2, $t4, $t0
    move $a1, $t0
    move $a0, $s7
    li $v0, 15
    syscall
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra