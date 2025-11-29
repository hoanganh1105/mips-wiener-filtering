import math

# ================= DỮ LIỆU INPUT (Copy từ .data MIPS) =================

N = 10
M = 3

h = [
    0.8568918466567993, 0.5583352744579315, 0.2105703055858612
]

x = [
    0.8999999761581421, 0.30000001192092896, 0.699999988079071, 
    1.5, 1.399999976158142, 0.10000000149011612, 
    1.2000000476837158, 0.699999988079071, 0.699999988079071, 
    1.100000023841858
]

d = [
    0.0, 0.10000000149011612, 0.20000000298023224, 
    0.4000000059604645, 0.5, 0.6000000238418579, 
    0.699999988079071, 0.800000011920929, 0.800000011920929, 
    0.8999999761581421
]

# ================= HÀM MÔ PHỎNG LOGIC LÀM TRÒN MIPS =================
def mips_round_print(val):
    """
    Mô phỏng chính xác logic làm tròn trong code MIPS:
    1. Nhân 10
    2. Cộng 0.5 (nếu dương) hoặc trừ 0.5 (nếu âm)
    3. Cắt phần thập phân (convert to int)
    4. Chia lại cho 10
    """
    val_times_10 = val * 10.0
    
    if val_times_10 < 0:
        val_times_10 -= 0.5
    else:
        val_times_10 += 0.5
        
    # cvt.w.s (ép kiểu int trong MIPS sẽ cắt bỏ phần thập phân)
    rounded_int = int(val_times_10)
    
    # Chia lại cho 10.0 để in ra
    return rounded_int / 10.0

# ================= TÍNH TOÁN FILTER & MMSE =================
y_output = []
mmse_sum = 0.0

print("-" * 30)
print(f"{'n':<4} | {'y[n] (Raw)':<12} | {'d[n]':<10} | {'Error^2':<12}")
print("-" * 30)

for n in range(N):
    # 1. Tinh Convolution y[n]
    y_n = 0.0
    for k in range(M):
        idx_x = n - k
        if idx_x >= 0: # Check boundary (padding zero)
            val_x = x[idx_x]
            val_h = h[k]
            y_n += val_x * val_h
    
    y_output.append(y_n)
    
    # 2. Tinh MMSE Error
    e_n = d[n] - y_n
    e_sq = e_n * e_n
    mmse_sum += e_sq
    
    print(f"{n:<4} | {y_n:<12.5f} | {d[n]:<10.5f} | {e_sq:<12.5f}")

mmse_val = mmse_sum / N

print("-" * 30)
print(f"MMSE Raw Value: {mmse_val}")
print("-" * 30)

# ================= IN KẾT QUẢ ĐÚNG FORMAT ĐỀ BÀI =================
# Chuỗi kết quả output đã làm tròn
output_str_list = [str(mips_round_print(val)) for val in y_output]
output_line = "Filtered output: " + " ".join(output_str_list) + " "

# MMSE đã làm tròn
mmse_rounded = mips_round_print(mmse_val)
mmse_line = f"MMSE: {mmse_rounded} "

print("\n=== KẾT QUẢ MÔ PHỎNG ===")
print(output_line)
print(mmse_line)