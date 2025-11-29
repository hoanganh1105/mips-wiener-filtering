.data
# ================= VARIABLES =================
N: .word 10
M: .word 3

# He so bo loc
optimize_coefficient: .float 0.8568918466567993, 0.5583352744579315, 0.2105703055858612

# Input:
input_signal: .float 0.8999999761581421, 0.30000001192092896, 0.699999988079071, 1.5, 1.399999976158142, 0.10000000149011612, 1.2000000476837158, 0.699999988079071, 0.699999988079071, 1.100000023841858

# Desired:
desired_signal: .float 0.0, 0.10000000149011612, 0.20000000298023224, 0.4000000059604645, 0.5, 0.6000000238418579, 0.699999988079071, 0.800000011920929, 0.800000011920929, 0.8999999761581421

# Vung nho luu output y[n]
output_signal: .space 400

# mmse (number): 
mmse: .float 0.0

# ================= FLOATS HỖ TRỢ =================
zero_f: .float 0.0
ten_f:  .float 10.0
half_f: .float 0.5

# ================= STRINGS & FILE =================
filename:     .asciiz "output.txt"
filtered_msg: .asciiz "Filtered output: "
mmse_msg:     .asciiz "MMSE: "
space:        .asciiz " "
nl:           .asciiz "\n"
minus:        .asciiz "-"
dot:          .asciiz "."
int_buf:      .space 20
debug_err:    .asciiz "[LOI] Khong the tao file!\n"

.text
.globl main
main:
    # --- 1. MO FILE ---
    la $a0, filename
    li $a1, 1        # Write-only
    li $a2, 0
    li $v0, 13
    syscall
    move $s7, $v0    # File descriptor

    blt $s7, 0, file_error

    # --- 2. LOAD DU LIEU (CAP NHAT TEN BIEN) ---
    lw $s1, N                # N
    lw $s0, M                # M
    la $s2, optimize_coefficient # Load dia chi h
    la $s3, input_signal         # Load dia chi x
    la $s4, desired_signal       # Load dia chi d
    la $s5, output_signal        # Load dia chi out

    li $t0, 0
    lwc1 $f20, zero_f    # Bien tich luy tong Error^2

loop_calc:
    bge $t0, $s1, done_calc
    lwc1 $f0, zero_f     # y[n]
    li $t1, 0

inner_loop:
    bge $t1, $s0, end_inner
    sub $t2, $t0, $t1    # idx_x = n - k
    blt $t2, $zero, skip_mul

    # Load input_signal[n-k]
    sll $t3, $t2, 2
    add $t3, $t3, $s3
    lwc1 $f2, 0($t3)

    # Load optimize_coefficient[k]
    sll $t3, $t1, 2
    add $t3, $t3, $s2
    lwc1 $f4, 0($t3)

    # Convolution
    mul.s $f6, $f2, $f4
    add.s $f0, $f0, $f6

skip_mul:
    addi $t1, $t1, 1
    j inner_loop
end_inner:
    # Luu ket qua vao output_signal[n]
    sll $t3, $t0, 2
    add $t3, $t3, $s5
    swc1 $f0, 0($t3)

    # --- Tinh Error MMSE ---
    # Load desired_signal[n]
    sll $t3, $t0, 2
    add $t3, $t3, $s4
    lwc1 $f8, 0($t3)
    
    # error = desired - output
    sub.s $f10, $f8, $f0
    mul.s $f10, $f10, $f10 # error^2
    add.s $f20, $f20, $f10 # sum += error^2

    addi $t0, $t0, 1
    j loop_calc

done_calc:
    mtc1 $s1, $f16
    cvt.s.w $f16, $f16
    div.s $f18, $f20, $f16  # $f18 = MMSE value calculated

    # [RUBRIC] Save MMSE to variable 'mmse'
    la $t0, mmse
    swc1 $f18, 0($t0)

    # --- 3. GHI CONSOLE & FILE ---
    # Header "Filtered output: "
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
    lwc1 $f12, 0($t0) # Load output_signal[n]

    # === ROUNDING LOGIC Y[N] ===
    la $t0, ten_f
    lwc1 $f14, 0($t0)
    mul.s $f16, $f12, $f14
    lwc1 $f30, zero_f
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
    lwc1 $f14, 0($t0)      # Load lai 10.0
    div.s $f12, $f12, $f14

    # Console
    li $v0, 2
    syscall
    la $a0, space
    li $v0, 4
    syscall

    # File
    jal write_float_proc
    move $a0, $s7
    la $a1, space
    li $a2, 1
    li $v0, 15
    syscall

    addi $s6, $s6, 1
    j loop_print
end_print:
    # Xuong dong
    la $a0, nl
    li $v0, 4
    syscall
    move $a0, $s7
    la $a1, nl
    li $a2, 1
    li $v0, 15
    syscall

    # Header "MMSE: "
    la $a0, mmse_msg
    li $v0, 4
    syscall
    move $a0, $s7
    la $a1, mmse_msg
    li $a2, 6
    li $v0, 15
    syscall

    # === ROUNDING LOGIC MMSE ===
    # Load lai gia tri MMSE tu bien nho de dam bao dung yeu cau
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
    lwc1 $f14, 0($t0)      # Load lai 10.0
    div.s $f12, $f12, $f14

    # Console
    li $v0, 2
    syscall

    # File
    jal write_float_proc

    # Close file
    move $a0, $s7
    li $v0, 16
    syscall

    # Exit
    li $v0, 10
    syscall

file_error:
    la $a0, debug_err
    li $v0, 4
    syscall
    li $v0, 10
    syscall

# ================= THU TUC CONVERT SO =================
write_float_proc:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $t0, 4($sp)
    sw $t1, 8($sp)
    lwc1 $f0, zero_f
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
