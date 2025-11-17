# 📘 Wiener Filter Implementation in MIPS Assembly
### Computer Architecture Lab – CO2008  
### Ho Chi Minh City University of Technology (HCMUT)

## 📌 Overview
This project implements the **Wiener Filter** in **MIPS Assembly** to perform signal denoising and compute the **Minimum Mean Square Error (MMSE)** between a desired signal and the filtered output.  
The program reads input from `input.txt`, applies a predefined Wiener filter, outputs the filtered signal, computes MMSE, and writes the results to `output.txt`.

## 📂 Project Structure
- main.asm — Main MIPS program  
- wiener_data.asm — Predefined data and filter coefficients  
- input.txt — Input signal (desired + noise)  
- output.txt — Generated output  
- README.md — Project documentation  

## 🚀 Features
- Full Wiener filter pipeline implemented in MIPS  
- Computes:  
  - Filtered output y(n)  
  - Error signal e(n)  
  - MMSE value  
- Validates input size  
- Outputs results to both console and file  
- Fully compatible with MARS MIPS simulator  

## 🧠 Technical Background
### Filter Output
y(n) = Σ hₖ · x(n − k)

### Error
e(n) = d(n) − y(n)

### MMSE
MMSE = (1/N) · Σ (e(n))²

All operations are implemented using floating-point MIPS instructions.

## 📥 Input Format (input.txt)
- Exactly **10 floating-point numbers**
- Example:  
6.7 3.7 7.0 3.5 7.0 3.5 3.5 7.0 3.8 2.1

## 📤 Output Format (output.txt)
Example output:
6.12 3.78 6.99 3.50 7.03 3.51 3.52 7.01 3.79 2.05  
0.0345

Line 1 → filtered signal  
Line 2 → MMSE value  

## 🛠️ How to Run (MARS)
1. Open MARS  
2. Load `main.asm`  
3. Put `input.txt` in the same directory  
4. Enable: Tools → Settings → “Allow pseudo instructions”  
5. Assemble → Run  
6. Output appears in console + generated file `output.txt`

## 🧪 Test Cases
Manual test cases were used to verify:  
- Correct filtering  
- Accurate MMSE computation  
- Proper error handling  


## 📄 Report
Includes:  
- Theory of Wiener Filter  
- Pseudo-code & flowchart  
- MIPS implementation explanation  
- Test screenshots  

## ⚠️ Plagiarism Warning
Similarity must be **under 50%**, verified with **MOSS**.

## ⭐ If this project helps you, please consider giving the repository a star!
