# =========================================================================
# MERGED WIENER FILTER PROGRAM - FULL FILE READING VERSION (FIXED ALIGNMENT)
# Bao gồm: ĐỌC FILE -> Tính toán hệ số -> Lọc tín hiệu -> Output
# =========================================================================

.data
# ---------------- CONFIG & DATA ----------------
N: .word 10
M: .word 3

# --- FILE PATHS (SỬA ĐÚNG ĐƯỜNG DẪN CỦA BẠN NẾU CẦN) ---
# Input signal file path
fn_input:     .asciiz "D:/HCMUT/Computer Architecture/Assignment/input.txt"

# Desired signal file path
# Thêm align để đảm bảo biến tiếp theo ko bị lệch
.align 2 
fn_desired:   .asciiz "D:/HCMUT/Computer Architecture/Assignment/desired.txt"

# Output file path
.align 2
filename:     .asciiz "D:/HCMUT/Computer Architecture/Assignment/output.txt"

# --- MẢNG DỮ LIỆU (KHÔNG CÒN HARD-CODE) ---
# QUAN TRỌNG: Thêm .align 2 để căn chỉnh địa chỉ về bội số của 4
.align 2 
input_signal:   .space 40 
.align 2
desired_signal: .space 40

# --- Biến lưu kết quả ---
.align 2
optimize_coefficient: .float 0.0, 0.0, 0.0
.align 2
output_signal:        .space 400
.align 2
mmse:                 .float 0.0

# --- Biến trung gian ---
.align 2
gamma_xx_0: .float 0.0
gamma_xx_1: .float 0.0
gamma_xx_2: .float 0.0
gamma_dx_0: .float 0.0
gamma_dx_1: .float 0.0
gamma_dx_2: .float 0.0

.align 2
R_matrix:   .float 0.0, 0.0, 0.0
            .float 0.0, 0.0, 0.0
            .float 0.0, 0.0, 0.0

.align 2
gamma_vector: .float 0.0, 0.0, 0.0

# --- Constants & Buffers ---
.align 2
float_zero:   .float 0.0
float_one:    .float 1.0
ten_f:        .float 10.0
half_f:       .float 0.5
neg_one_f:    .float -1.0

# Buffer đọc file (2048 bytes là đủ cho file text nhỏ)
.align 2
file_buffer:  .space 2048 

filtered_msg: .asciiz "Filtered output: "
mmse_msg:     .asciiz "MMSE: "
space:        .asciiz " "
nl:           .asciiz "\n"
minus:        .asciiz "-"
dot:          .asciiz "."
err_msg:      .asciiz "Error: cannot open output file\n"
err_read_msg: .asciiz "Error: cannot open input/desired file\n"
debug_msg:    .asciiz "--- Calculation Done. Applying Filter... ---\n"
msg_read_ok:  .asciiz "--- Files Loaded Successfully ---\n"
int_buf:      .space 20

.text
.globl main

# =========================================================================
# MAIN PROGRAM FLOW
# =========================================================================
main:
    # ---------------------------------------------------------
    # BƯỚC 0: ĐỌC DỮ LIỆU TỪ FILE (NEW FEATURE)
    # ---------------------------------------------------------
    
    # 1. Đọc file Input
    la $a0, fn_input       # Tên file
    la $a1, input_signal   # Nơi lưu
    jal read_file_proc     # Gọi hàm đọc
    
    # 2. Đọc file Desired
    la $a0, fn_desired     # Tên file
    la $a1, desired_signal # Nơi lưu
    jal read_file_proc     # Gọi hàm đọc
    
    # Thông báo đọc xong
    li $v0, 4
    la $a0, msg_read_ok
    syscall

    # ---------------------------------------------------------
    # PHẦN 1: TÍNH TOÁN HỆ SỐ BỘ LỌC (Logic cũ)
    # ---------------------------------------------------------
    jal autoCorrelation
    jal crossCorrelation
    jal build_R_matrix
    jal solve_wiener_hopf
    
    li $v0, 4
    la $a0, debug_msg
    syscall

    # ---------------------------------------------------------
    # PHẦN 2: LỌC TÍN HIỆU & TÍNH MMSE
    # ---------------------------------------------------------
    
    # Mở file output
    la $a0, filename
    li $a1, 1        # Write-only
    li $a2, 0
    li $v0, 13
    syscall
    move $s7, $v0    
    blt $s7, 0, file_error

    # Load tham số
    lw $s1, N
    lw $s0, M
    la $s2, optimize_coefficient
    la $s3, input_signal
    la $s4, desired_signal
    la $s5, output_signal
    
    li $t0, 0            
    lwc1 $f20, float_zero 

loop_calc:
    bge $t0, $s1, done_calc 
    lwc1 $f0, float_zero    
    li $t1, 0               

inner_loop:
    bge $t1, $s0, end_inner 
    sub $t2, $t0, $t1       
    blt $t2, $zero, skip_mul 

    sll $t3, $t2, 2
    add $t3, $t3, $s3
    lwc1 $f2, 0($t3)

    sll $t3, $t1, 2
    add $t3, $t3, $s2
    lwc1 $f4, 0($t3)

    mul.s $f6, $f2, $f4
    add.s $f0, $f0, $f6

skip_mul:
    addi $t1, $t1, 1
    j inner_loop

end_inner:
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
    j loop_calc

done_calc:
    mtc1 $s1, $f16
    cvt.s.w $f16, $f16
    div.s $f18, $f20, $f16
    la $t0, mmse
    swc1 $f18, 0($t0)

    # ---------------------------------------------------------
    # PHẦN 3: IN KẾT QUẢ
    # ---------------------------------------------------------
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

    # Rounding logic
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
# THỦ TỤC ĐỌC FILE FLOAT (NÂNG CAO)
# $a0: Tên file
# $a1: Địa chỉ mảng đích
# =========================================================================
read_file_proc:
    # Lưu thanh ghi
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp) # File Desc
    sw $s1, 8($sp) # Array Ptr
    sw $s2, 12($sp) # Buffer Ptr
    sw $s3, 16($sp) # Bytes Read

    move $s1, $a1   # Lưu địa chỉ mảng đích

    # 1. Mở file
    li $a1, 0       # Read-only
    li $a2, 0
    li $v0, 13
    syscall
    move $s0, $v0
    blt $s0, 0, read_error

    # 2. Đọc toàn bộ file vào buffer
    move $a0, $s0
    la $a1, file_buffer
    li $a2, 2048    # Max bytes
    li $v0, 14
    syscall
    move $s3, $v0   # Số byte thực đọc
    
    # Đóng file
    move $a0, $s0
    li $v0, 16
    syscall
    
    # 3. Parse Buffer
    la $s2, file_buffer # Con trỏ duyệt buffer
    add $s3, $s2, $s3   # Con trỏ kết thúc (Buffer + BytesRead)
    
    li $t8, 0           # Count (đếm số lượng số đã đọc, max 10)
    li $t9, 10          # Max N

parse_loop:
    bge $t8, $t9, done_parse # Đủ 10 số thì dừng
    bge $s2, $s3, done_parse # Hết buffer thì dừng

    # --- Parser Float Logic ---
    # Init: result = 0.0, sign = 1.0, is_fraction = 0, divisor = 1.0
    lwc1 $f0, float_zero   # Total val
    lwc1 $f1, float_one    # Sign
    lwc1 $f2, ten_f        # Constant 10.0
    lwc1 $f3, float_one    # Divisor (cho phần thập phân)
    li $t0, 0              # flag: đang ở phần thập phân? (0=No, 1=Yes)
    li $t1, 0              # flag: có số nào được đọc chưa?
    
skip_spaces:
    bge $s2, $s3, finish_num # Check EOF
    lb $t2, 0($s2)           # Load char
    
    # Check delimiters (Space, Tab, Newline, CR)
    beq $t2, 32, check_finish
    beq $t2, 9,  check_finish
    beq $t2, 10, check_finish
    beq $t2, 13, check_finish
    
    # Check minus sign
    beq $t2, 45, is_minus
    # Check dot
    beq $t2, 46, is_dot
    
    # Is Digit? (48-57)
    blt $t2, 48, next_char
    bgt $t2, 57, next_char
    
    # Process Digit
    li $t1, 1                # Mark: found digit
    sub $t2, $t2, 48         # ASCII to int
    mtc1 $t2, $f4
    cvt.s.w $f4, $f4         # Convert to float
    
    beq $t0, 1, process_fraction
    
    # Process Integer Part: total = total * 10 + digit
    mul.s $f0, $f0, $f2
    add.s $f0, $f0, $f4
    j next_char

process_fraction:
    # Process Fraction Part: divisor *= 10; total += digit / divisor
    mul.s $f3, $f3, $f2      # divisor *= 10
    div.s $f4, $f4, $f3      # digit / divisor
    add.s $f0, $f0, $f4
    j next_char

is_minus:
    lwc1 $f1, neg_one_f
    j next_char

is_dot:
    li $t0, 1               # Bật cờ thập phân
    j next_char

check_finish:
    # Nếu gặp delimiter mà chưa đọc được số nào -> Bỏ qua (đây là khoảng trắng đầu dòng)
    beqz $t1, next_char
    # Nếu đã đọc được số -> Lưu số và reset
    j finish_num

next_char:
    addi $s2, $s2, 1
    j skip_spaces

finish_num:
    beqz $t1, really_done # Nếu không có số nào để lưu
    
    # Kết thúc 1 số: Lưu vào mảng
    mul.s $f0, $f0, $f1   # Apply sign
    swc1 $f0, 0($s1)      # Store to array
    addi $s1, $s1, 4      # Next array slot
    addi $t8, $t8, 1      # Count++
    
    addi $s2, $s2, 1      # Move past the delimiter
    j parse_loop

really_done:
    # Case đặc biệt: File kết thúc ngay sau số cuối cùng mà không có khoảng trắng
    # Logic trên đã xử lý (bge $s2, $s3) nhưng để chắc chắn:
    j done_parse

done_parse:
    lw $s3, 16($sp)
    lw $s2, 12($sp)
    lw $s1, 8($sp)
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 20
    jr $ra

# =========================================================================
# PROCEDURES (MATH) & I/O - GIỮ NGUYÊN
# =========================================================================

autoCorrelation:
    li $t0, 0               
    lw $t1, M
    lw $t2, N
autoCorr_outer:
    bge $t0, $t1, autoCorr_done
    li $t3, 0               
    lwc1 $f4, float_zero    
autoCorr_inner:
    sub $t4, $t2, $t0       
    bge $t3, $t4, autoCorr_inner_done
    
    sll $t5, $t3, 2
    la $t9, input_signal 
    add $t6, $t5, $t9
    lwc1 $f0, 0($t6)
    
    add $t7, $t3, $t0
    sll $t7, $t7, 2
    la $t9, input_signal
    add $t8, $t7, $t9
    lwc1 $f1, 0($t8)
    
    mul.s $f2, $f0, $f1
    add.s $f4, $f4, $f2
    addi $t3, $t3, 1
    j autoCorr_inner
    
autoCorr_inner_done:
    mtc1 $t2, $f5           
    cvt.s.w $f5, $f5
    div.s $f4, $f4, $f5     
    
    beq $t0, 0, store_gamma0
    beq $t0, 1, store_gamma1
    beq $t0, 2, store_gamma2
    j skip_store_xx
store_gamma0: 
    s.s $f4, gamma_xx_0
    j skip_store_xx
store_gamma1: 
    s.s $f4, gamma_xx_1
    j skip_store_xx
store_gamma2: 
    s.s $f4, gamma_xx_2
skip_store_xx:
    addi $t0, $t0, 1
    j autoCorr_outer
autoCorr_done:
    jr $ra

crossCorrelation:
    li $t0, 0
    lw $t1, M
    lw $t2, N
crossCorr_outer:
    bge $t0, $t1, crossCorr_done
    li $t3, 0
    lwc1 $f4, float_zero
crossCorr_inner:
    sub $t4, $t2, $t0
    bge $t3, $t4, crossCorr_inner_done
    
    sll $t5, $t3, 2
    la $t6, desired_signal
    add $t6, $t6, $t5
    lwc1 $f0, 0($t6)
    
    add $t7, $t3, $t0
    sll $t7, $t7, 2
    la $t8, input_signal
    add $t8, $t8, $t7
    lwc1 $f1, 0($t8)
    
    mul.s $f2, $f0, $f1
    add.s $f4, $f4, $f2
    addi $t3, $t3, 1
    j crossCorr_inner
    
crossCorr_inner_done:
    mtc1 $t2, $f5
    cvt.s.w $f5, $f5
    div.s $f4, $f4, $f5
    
    beq $t0, 0, store_dx0
    beq $t0, 1, store_dx1
    beq $t0, 2, store_dx2
    j skip_store_dx
store_dx0:
    s.s $f4, gamma_dx_0
    la $t9, gamma_vector
    s.s $f4, 0($t9)
    j skip_store_dx
store_dx1:
    s.s $f4, gamma_dx_1 
    la $t9, gamma_vector
    s.s $f4, 4($t9)
    j skip_store_dx
store_dx2:
    s.s $f4, gamma_dx_2
    la $t9, gamma_vector
    s.s $f4, 8($t9)
skip_store_dx:
    addi $t0, $t0, 1
    j crossCorr_outer
crossCorr_done:
    jr $ra

build_R_matrix:
    lwc1 $f0, gamma_xx_0
    la $t9, R_matrix
    s.s $f0, 0($t9)
    s.s $f0, 16($t9)
    s.s $f0, 32($t9)

    lwc1 $f1, gamma_xx_1
    s.s $f1, 4($t9)
    s.s $f1, 12($t9)
    s.s $f1, 20($t9)
    s.s $f1, 28($t9)

    lwc1 $f2, gamma_xx_2
    s.s $f2, 8($t9)
    s.s $f2, 24($t9)
    jr $ra

solve_wiener_hopf:
    la $t9, R_matrix
    lwc1 $f0, 0($t9)     
    lwc1 $f1, 4($t9)     
    lwc1 $f2, 8($t9)     
    lwc1 $f3, 16($t9)    
    lwc1 $f4, 20($t9)    
    lwc1 $f5, 32($t9)    
    
    la $t9, gamma_vector    
    lwc1 $f6, 0($t9)     
    lwc1 $f7, 4($t9)     
    lwc1 $f8, 8($t9)     

    mul.s $f9, $f0, $f0
    mul.s $f9, $f9, $f0      
    
    mul.s $f10, $f0, $f1
    mul.s $f10, $f10, $f1
    add.s $f10, $f10, $f10   
    
    mul.s $f11, $f1, $f1
    mul.s $f11, $f11, $f2
    add.s $f11, $f11, $f11   
    
    mul.s $f12, $f0, $f2
    mul.s $f12, $f12, $f2    
    
    sub.s $f13, $f9, $f10
    add.s $f13, $f13, $f11
    sub.s $f13, $f13, $f12
    mov.s $f30, $f13         
    
    lwc1 $f14, float_zero
    c.eq.s $f30, $f14
    bc1t singular_det
    
    mul.s $f15, $f3, $f5
    mul.s $f16, $f4, $f4
    sub.s $f17, $f15, $f16 
    
    mul.s $f15, $f1, $f5
    mul.s $f16, $f2, $f4
    sub.s $f18, $f16, $f15 
    
    mul.s $f15, $f1, $f4
    mul.s $f16, $f2, $f3
    sub.s $f19, $f15, $f16 
    
    mov.s $f20, $f18         
    
    mul.s $f15, $f0, $f5
    mul.s $f16, $f2, $f2
    sub.s $f21, $f15, $f16 
    
    mul.s $f15, $f0, $f4
    mul.s $f16, $f1, $f2
    sub.s $f22, $f16, $f15 
    
    mov.s $f23, $f19         
    mov.s $f24, $f22         
    mov.s $f25, $f17         
    
    div.s $f17, $f17, $f30
    div.s $f18, $f18, $f30
    div.s $f19, $f19, $f30
    div.s $f20, $f20, $f30
    div.s $f21, $f21, $f30
    div.s $f22, $f22, $f30
    div.s $f23, $f23, $f30
    div.s $f24, $f24, $f30
    div.s $f25, $f25, $f30
    
    la $t9, optimize_coefficient
    mul.s $f26, $f17, $f6
    mul.s $f27, $f18, $f7
    add.s $f26, $f26, $f27
    mul.s $f27, $f19, $f8
    add.s $f26, $f26, $f27
    s.s $f26, 0($t9)
    
    mul.s $f26, $f20, $f6
    mul.s $f27, $f21, $f7
    add.s $f26, $f26, $f27
    mul.s $f27, $f22, $f8
    add.s $f26, $f26, $f27
    s.s $f26, 4($t9)
    
    mul.s $f26, $f23, $f6
    mul.s $f27, $f24, $f7
    add.s $f26, $f26, $f27
    mul.s $f27, $f25, $f8
    add.s $f26, $f26, $f27
    s.s $f26, 8($t9)
    
    j solve_done

singular_det:
    la $t9, optimize_coefficient
    lwc1 $f15, float_one
    s.s $f15, 0($t9) 

solve_done:
    jr $ra

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