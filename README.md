# 📉 Wiener Filter – MIPS Implementation

## 📂 Cấu trúc Thư mục

| File                   | Mô tả                                                         |
| ---------------------- | ------------------------------------------------------------- |
| **wiener_mips.asm**    | Mã nguồn chính (MIPS). Chứa logic tính toán Filter và MMSE.   |
| **wiener_ref.py**      | Code kiểm chứng (Python). Dùng để so sánh kết quả với MIPS.   |
| **data_test_MIPS.txt** | 10 bộ Test Case cho MIPS (nhiễu trắng, nhiễu hồng, số âm...). |
| **data_test_PY.txt**   | 10 bộ Test Case tương ứng cho Python.                         |
| **output.txt**         | File kết quả đầu ra được sinh ra bởi chương trình MIPS.       |

---

## 🛠️ Yêu cầu Hệ Thống

* **Java Runtime Environment (JRE)** để chạy MARS Simulator.
* **MARS 4.5 Simulator** (file *Mars4_5.jar*).
* **Python 3.x** để chạy script kiểm chứng.

---

## 🚀 Hướng Dẫn Chạy Chương Trình

### **1. Khởi động MARS Simulator**

Có thể mở MARS thông qua dòng lệnh để đảm bảo môi trường Java hoạt động đúng.

```bash
java -jar "đường_dẫn_đến_file_Mars4_5.jar"
```

**Ví dụ Windows:**

```bash
java -jar "C:\Users\Student\Downloads\Mars4_5.jar"
```

**Ví dụ MacOS/Linux:**

```bash
java -jar "/home/user/Downloads/Mars4_5.jar"
```

---

### **2. Nạp và chạy chương trình MIPS**

1. Mở MARS → File → Open → **wiener_mips.asm**
2. Nhấn **F3** để biên dịch
3. Nhấn **F5** để chạy

Kết quả hiển thị tại tab **Run I/O** và được lưu vào **output.txt**.

---

## 🧪 Thay Đổi Test Case

1. Mở file **data_test_MIPS.txt**
2. Chọn test case mong muốn
3. Sao chép toàn bộ phần **[DATA SECTION]**
4. Mở file **wiener_mips.asm**
5. Dán đè vào phần `.data`
6. Chạy lại chương trình

---

## 🐍 Kiểm Chứng Bằng Python

1. Lấy dữ liệu từ **data_test_PY.txt**
2. Cập nhật vào **wiener_ref.py**
3. Chạy:

```bash
python wiener_ref.py
```

So sánh output & MMSE giữa Python và MIPS.

---

## 📊 Kết Quả Mẫu – Test Case "An Toàn"

```text
Filtered output: 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0
MMSE: 0.2
```

*MMSE thực tế = 0.16 → làm tròn thành 0.2 theo yêu cầu đề bài.*

---
