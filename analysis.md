# 📄 TÀI LIỆU PHÂN TÍCH: BỘ LỌC FIR & TÍNH TOÁN MMSE TRONG MIPS

## 📚 Mục Lục

1. [Mục tiêu chương trình](https://www.google.com/search?q=%231--m%E1%BB%A5c-ti%C3%AAu-ch%C6%B0%C6%A1ng-tr%C3%ACnh)
2. [Mô hình toán học áp dụng](https://www.google.com/search?q=%232--m%C3%B4-h%C3%ACnh-to%C3%A1n-h%E1%BB%8Dc-%C3%A1p-d%E1%BB%A5ng)
3. [Phân tích các hàm và lệnh MIPS quan trọng](https://www.google.com/search?q=%233-%EF%B8%8F-ph%C3%A2n-t%C3%ADch-c%C3%A1c-h%C3%A0m-v%C3%A0-l%E1%BB%87nh-mips-quan-tr%E1%BB%8Dng)
4. [Giải thuật chi tiết các module con](https://www.google.com/search?q=%234--gi%E1%BA%A3i-thu%E1%BA%ADt-chi-ti%E1%BA%BFt-c%C3%A1c-module-con)
5. [Lưu đồ bộ nhớ (Data Segment)](https://www.google.com/search?q=%235--l%C6%B0u-%C4%91%E1%BB%93-b%E1%BB%99-nh%E1%BB%9B-data-segment)
6. [Lưu ý khi chạy](https://www.google.com/search?q=%236-%EF%B8%8F-l%C6%B0u-%C3%BD-khi-ch%E1%BA%A1y)

-----

## 1\. 🎯 Mục tiêu chương trình

Đoạn code thực hiện hai nhiệm vụ chính của xử lý tín hiệu số:

1. **Lọc tín hiệu (Convolution):** Áp dụng bộ lọc có trọng số (`optimize_coefficient`) lên tín hiệu đầu vào (`input_signal`).
2. **Đánh giá sai số (MMSE):** So sánh tín hiệu sau lọc với tín hiệu mong muốn (`desired_signal`) để tính sai số trung bình bình phương.
3. **Xuất dữ liệu:** In kết quả đã làm tròn ra màn hình console và ghi vào file `output.txt`.

-----

## 2\. 🧮 Mô hình toán học áp dụng

### A. Tích chập (Convolution) - Logic tính Output y[n]

Trong đoạn label `loop_calc` và `inner_loop`, code thực hiện công thức:

$$y[n] = \sum_{k=0}^{M-1} h[k] \cdot x[n-k]$$

  * **$y[n]$**: `output_signal` tại vị trí $n$.
  * **$h[k]$**: `optimize_coefficient` (hệ số bộ lọc).
  * **$x[n-k]$**: `input_signal`.
  * **Điều kiện:** Nếu $n-k < 0$, bỏ qua (skip), tương ứng với lệnh `blt $t2, $zero, skip_mul`.

### B. Sai số trung bình bình phương (MMSE)

Trong đoạn cuối `loop_calc`, code tính sai số tích lũy:

$$MMSE = \frac{1}{N} \sum_{n=0}^{N-1} (d[n] - y[n])^2$$

  * **$d[n]$**: `desired_signal`.
  * **$y[n]$**: `output_signal`.
  * **Thực thi:** Biến `$f20` tích lũy tổng bình phương sai số, sau đó chia cho $N$ ở `done_calc`.

-----

## 3\. 🛠️ Phân tích các hàm và lệnh MIPS quan trọng

Chương trình sử dụng bộ xử lý dấu chấm động (**Coprocessor 1 - FPU**).

### A. Các lệnh xử lý số thực (Floating Point Unit)

Các lệnh thao tác trên thanh ghi `$f0` - `$f31`.

| Lệnh | Cú pháp | Ý nghĩa | Ứng dụng trong bài |
| :--- | :--- | :--- | :--- |
| **lwc1** | `lwc1 $f0, offset($t0)` | Load số thực từ RAM vào FPU | Load hệ số, input, hằng số (0.0, 10.0) |
| **swc1** | `swc1 $f0, offset($t0)` | Lưu số thực từ FPU ra RAM | Lưu `output_signal` và `mmse` |
| **add.s** | `add.s $f0, $f1, $f2` | Cộng 2 số thực (Single Precision) | Cộng dồn tích chập, cộng dồn lỗi |
| **sub.s** | `sub.s $f0, $f1, $f2` | Trừ 2 số thực | Tính `error = desired - output` |
| **mul.s** | `mul.s $f0, $f1, $f2` | Nhân 2 số thực | Nhân $h[k] \cdot x[n-k]$ hoặc bình phương lỗi |
| **div.s** | `div.s $f0, $f1, $f2` | Chia 2 số thực | Chia tổng lỗi cho $N$ để ra MMSE |
| **cvt.w.s** | `cvt.w.s $f0, $f1` | Chuyển float sang int | Dùng trong logic làm tròn số |
| **cvt.s.w** | `cvt.s.w $f0, $f1` | Chuyển int sang float | Khôi phục lại dạng float sau khi làm tròn |
| **c.lt.s** | `c.lt.s $f0, $f1` | So sánh nhỏ hơn | Kiểm tra số âm khi làm tròn/in ấn |
| **bc1f** | `bc1f label` | Nhảy nếu False | Điều hướng logic làm tròn |

-----

## 4\. 🧩 Giải thuật chi tiết các module con

### A. Logic làm tròn số (Rounding Logic)

Để output chỉ lấy 1 chữ số thập phân (ví dụ: `0.8999` -\> `0.9`):

1. Lấy số gốc $X$.
2. Nhân với 10: $X \cdot 10$.
3. Cộng thêm 0.5 (nếu dương) hoặc trừ 0.5 (nếu âm) để làm tròn.
4. Chuyển sang int (`cvt.w.s`).
5. Chuyển ngược lại float (`cvt.s.w`).
6. Chia cho 10.

**Đoạn code MIPS tương ứng:**

```mips
mul.s   $f16, $f12, $f14   ; Nhân 10
...
add.s   $f16, $f16, $f14   ; Cộng 0.5
cvt.w.s $f16, $f16         ; Chuyển sang int (làm tròn)
cvt.s.w $f12, $f16         ; Chuyển lại float
div.s   $f12, $f12, $f14   ; Chia 10
```

### B. Thủ tục ghi số thực vào file (`write_float_proc`)

  * **Xử lý dấu:** Nếu số âm, ghi ký tự `'-'` vào file, sau đó lấy trị tuyệt đối.
  * **Phần nguyên:** Chuyển `float -> int` rồi gọi `write_int_proc` để ghi phần nguyên.
  * **Dấu chấm:** Ghi ký tự `'.'` vào file.
  * **Phần thập phân:** Lấy `(số thực - phần nguyên) * 10`, chuyển sang int, gọi `write_int_proc` để ghi chữ số thập phân đầu tiên.
  * *Ghi chú:* Hàm này dùng syscall ghi chuỗi; chuyển từng ký tự/chuỗi vào buffer rồi gọi `syscall write`.

### C. Thủ tục chuyển số nguyên sang chuỗi (`write_int_proc`)

  * **Thuật toán:** Lặp chia lấy dư cho 10 để tách chữ số (sử dụng `div`, `mfhi`, `mflo`).
  * **Mỗi chữ số:** Cộng 48 (ASCII `'0'`) để chuyển sang ký tự.
  * **Lưu trữ:** Lưu các ký tự vào buffer (`int_buf`) theo thứ tự ngược (LSB trước), sau khi tách xong đảo lại thứ tự để ghi ra file.
  * **Xử lý số 0:** Nếu giá trị = 0 thì ghi ký tự `'0'` trực tiếp.

-----

## 5\. 💾 Lưu đồ bộ nhớ (Data Segment)

Bảng dưới đây mô tả các biến chính được sử dụng trong chương trình:

| Biến (Label) | Kích thước / Kiểu | Giá trị mẫu | Ý nghĩa |
| :--- | :--- | :--- | :--- |
| **Input** | Float Array (N=10) | `0.9, 0.3, 0.7...` | Tín hiệu đầu vào cần lọc |
| **Filter** | Float Array (M=3) | `0.857, 0.558, 0.211` | Hệ số bộ lọc FIR |
| **Desired** | Float Array | `<giá trị mong muốn>` | Tín hiệu mẫu để so khớp tính lỗi |
| **Output** | `.space 400` | (Trống) | Vùng nhớ lưu kết quả (đủ cho 100 số thực) |
| **int\_buf** | `.space 64` | (Trống) | Buffer tạm cho hàm `write_int_proc` |
| **str\_buf** | `.space 256` | (Trống) | Buffer ghép chuỗi trước khi syscall |

**Gợi ý khai báo trong `.data`:**

```mips
.data
input_signal:    .float 0.9, 0.3, 0.7, 1.5, 1.4, 0.1, 1.2, 0.7, 0.7, 1.1
filter_coeff:    .float 0.857, 0.558, 0.211
desired_signal:  .float 1.0, 0.5, 0.8, 1.2  # Ví dụ mẫu
output_signal:   .space 400
int_buf:         .space 64    # buffer cho write_int_proc
str_buf:         .space 256   # buffer để ghép chuỗi
```

-----

## 6\. ⚠️ Lưu ý khi chạy

> **Quan trọng:**
>
>   * Bật **"Load Exception Handler"** trong Settings của **Mars 4.5** để chức năng I/O (syscall file) hoạt động ổn định.
>   * File `output.txt` sẽ được tạo trong cùng thư mục với file `.asm` hoặc thư mục làm việc của trình giả lập MARS.
>   * Kiểm tra kích thước buffer trước khi ghi để tránh lỗi **overflow** khi chuyển số sang chuỗi.