# ===============================================
# main.asm - FIXED VERSION 2 (Handling Windows \r\n)
# ===============================================

.data
# filenames (Dùng đường dẫn tuyệt đối để MARS tìm thấy file)
# Lưu ý: Dùng dấu '/' hoặc '\\' thay vì '\' đơn lẻ
fn_input:     .asciiz "D:/HCMUT/Computer Architecture/Assignment/input.txt"
fn_desired:   .asciiz "D:/HCMUT/Computer Architecture/Assignment/desired.txt"

# buffer for file read
buffer:       .space 64

# max samples
MAX_SAMPLES:  .word 10

# arrays
input_vals:   .space 40      # 10 words x 4 bytes
desired_vals: .space 40

# messages
msg_err_open: .asciiz "Error: cannot open file\n"
msg_done:     .asciiz "Done reading files.\n"
msg_loaded:   .asciiz "Loaded samples: "
msg_nl:       .asciiz "\n"
msg_sample:   .asciiz "Sample "
msg_colon:    .asciiz ": "

.text
.globl main

# ----------------------------
# main
# ----------------------------
main:
    # load MAX_SAMPLES
    la   $t0, MAX_SAMPLES
    lw   $s7, 0($t0)        # $s7 = max samples (10)

    # 1. READ INPUT.TXT
    la   $a0, fn_input
    la   $a1, input_vals
    move $a2, $s7           # Pass limit (10)
    jal  read_file_to_scaled_array
    move $s0, $v0           # $s0 = count_input

    # 2. READ DESIRED.TXT
    la   $a0, fn_desired
    la   $a1, desired_vals
    move $a2, $s7           # Pass limit (10)
    jal  read_file_to_scaled_array
    move $s1, $v0           # $s1 = count_desired

    # Print Summary
    la $a0, msg_done
    jal print_string

    la $a0, msg_loaded
    jal print_string

    move $a0, $s0
    jal print_int

    la $a0, msg_nl
    jal print_string

    # Size check
    beq $s0, $s1, sizes_ok
    la $a0, msg_err_open
    jal print_string
    j exit_program

sizes_ok:
    # Print loop (display first 5 samples)
    li $t1, 0
print_loop_samples:
    bge $t1, $s0, after_print_samples

    la $a0, msg_sample
    jal print_string

    move $a0, $t1
    jal print_int

    la $a0, msg_colon
    jal print_string

    # print input_vals[t1]
    la $t2, input_vals
    sll $t3, $t1, 2
    add $t2, $t2, $t3
    lw $a0, 0($t2)
    jal print_int

    la $a0, msg_colon
    jal print_string

    # print desired_vals[t1]
    la $t2, desired_vals
    sll $t3, $t1, 2
    add $t2, $t2, $t3
    lw $a0, 0($t2)
    jal print_int

    la $a0, msg_nl
    jal print_string

    addi $t1, $t1, 1
    li $t4, 5
    blt $t1, $t4, print_loop_samples

after_print_samples:

exit_program:
    li $v0, 10
    syscall

# =================================================
# SUBROUTINES
# =================================================

print_string:
    li $v0, 4
    syscall
    jr $ra

print_int:
    li $v0, 1
    syscall
    jr $ra

# =================================================
# read_file_to_scaled_array
# a0 = filename, a1 = dest array, a2 = max_count
# returns v0 = samples_stored
# =================================================
read_file_to_scaled_array:
    # Stack Frame
    addi $sp, $sp, -36
    sw   $ra, 32($sp)
    sw   $s0, 28($sp)
    sw   $s1, 24($sp)
    sw   $s2, 20($sp)
    sw   $s3, 16($sp)
    sw   $s4, 12($sp)
    sw   $s5, 8($sp)
    sw   $s6, 4($sp)
    sw   $s7, 0($sp)

    move $s0, $a0      # filename
    move $s1, $a1      # dest ptr
    move $s2, $a2      # max count

    # Open file
    move $a0, $s0
    li   $a1, 0
    li   $v0, 13
    syscall
    move $s3, $v0      # fd
    bltz $s3, open_err

    # Init variables
    li $s4, 0          # samples_stored
    li $s5, 0          # buf_index
    li $s6, 0          # bytes_in_buf
    
    # Init Parsing State
    li $s7, 0          # accumulator
    li $t8, 1          # sign
    li $t9, 0          # has_digits flag (0 = no digits parsed yet)

read_loop:
    beq $s5, $s6, do_read

parse_char:
    la   $t0, buffer
    add  $t0, $t0, $s5
    lb   $t1, 0($t0)
    addi $s5, $s5, 1        # advance index

    # Delimiters
    li   $t2, 32   # space
    beq  $t1, $t2, finish_number
    li   $t2, 9    # tab
    beq  $t1, $t2, finish_number
    li   $t2, 10   # LF
    beq  $t1, $t2, finish_number
    li   $t2, 13   # CR
    beq  $t1, $t2, finish_number

    # Sign
    li   $t2, 43   # +
    beq  $t1, $t2, set_plus
    li   $t2, 45   # -
    beq  $t1, $t2, set_minus

    # Digits
    li   $t2, 48
    li   $t3, 57
    blt  $t1, $t2, parse_char   # Ignore non-digits (like .)
    bgt  $t1, $t3, parse_char

    # Found a digit -> Set flag
    li   $t9, 1    

    sub  $t1, $t1, 48
    mul  $s7, $s7, 10
    add  $s7, $s7, $t1
    j parse_char

set_plus:
    li $t8, 1
    j parse_char

set_minus:
    li $t8, -1
    j parse_char

finish_number:
    # CRITICAL FIX: Only store if we actually parsed some digits
    # This prevents storing 0 when hitting \n immediately after \r
    beq $t9, $zero, reset_parse 

    mul $t0, $s7, $t8
    sw  $t0, 0($s1)
    addi $s1, $s1, 4
    addi $s4, $s4, 1

    bge $s4, $s2, done_read

reset_parse:
    li $s7, 0
    li $t8, 1
    li $t9, 0          # Reset has_digits flag
    j parse_char

do_read:
    move $a0, $s3
    la   $a1, buffer
    li   $a2, 64
    li   $v0, 14
    syscall
    move $s6, $v0
    beq  $s6, $zero, done_read_eof # Handle EOF
    li   $s5, 0
    j parse_char

open_err:
    la $a0, msg_err_open
    li $v0, 4
    syscall
    li $v0, 0
    j cleanup

done_read_eof:
    # Check if there is a pending number at EOF (e.g. file ends without newline)
    beq $t9, $zero, done_read # If no pending digits, just finish
    
    # Store the last pending number
    mul $t0, $s7, $t8
    sw  $t0, 0($s1)
    addi $s4, $s4, 1

done_read:
    move $a0, $s3
    li   $v0, 16
    syscall
    move $v0, $s4

cleanup:
    lw   $ra, 32($sp)
    lw   $s0, 28($sp)
    lw   $s1, 24($sp)
    lw   $s2, 20($sp)
    lw   $s3, 16($sp)
    lw   $s4, 12($sp)
    lw   $s5, 8($sp)
    lw   $s6, 4($sp)
    lw   $s7, 0($sp)
    addi $sp, $sp, 36
    jr $ra