📘 Wiener Filter Implementation in MIPS Assembly
Computer Architecture Lab – CO2008
Ho Chi Minh City University of Technology (HCMUT)
📌 Overview

This project implements the Wiener Filter using MIPS Assembly to perform signal denoising and compute the Minimum Mean Square Error (MMSE) between the desired signal and the filtered output.

The program:

Reads an input signal from input.txt

Applies a predefined Wiener filter

Produces the filtered signal

Computes the MMSE value

Exports results to output.txt following the assignment format

📂 Project Structure

📦 wiener-filter-mips
┣ 📜 main.asm – Main MIPS program
┣ 📜 wiener_data.asm – Predefined coefficients & data
┣ 📜 input.txt – Input signal
┣ 📜 output.txt – Generated output result
┗ 📄 README.md

🚀 Features

Linear optimum filter implemented in pure MIPS

Computes:

Filter output y(n)

Error e(n) = d(n) - y(n)

MMSE value

Handles input size mismatch (prints “Error: size not match”)

Fully compatible with the MARS MIPS simulator

🧠 Technical Background
Filter output:

y(n) = Σ hₖ · x(n − k)

Error:

e(n) = d(n) − y(n)

Minimum Mean Square Error:

MMSE = (1/N) · Σ (e(n))²

All computations are performed using MIPS floating-point instructions (add.s, sub.s, mul.s, div.s, etc.).

📥 Input Format — input.txt

Contains exactly 10 floating-point numbers

Represents the noisy observed signal x(n)

Example:

6.7 3.7 7.0 3.5 7.0 3.5 3.5 7.0 3.8 2.1

📤 Output Format — output.txt

Example output:

6.12 3.78 6.99 3.50 7.03 3.51 3.52 7.01 3.79 2.05
0.0345

Line 1 → filtered sequence
Line 2 → MMSE value

🛠️ How to Run (MARS)

Open MARS

Load main.asm

Put input.txt in the same folder

Enable:

Tools → Settings → Allow pseudo instructions

Assemble → Run

Results appear in the console and output.txt is generated automatically

🧪 Test Cases

The project includes several manual test cases to verify:

Correct filtering behavior

Accurate MMSE computation

Proper error handling

👥 Group Members
Name	Student ID	Role
Nguyễn A	23xxxxxx	MIPS coding
Trần B	23xxxxxx	Filter logic & I/O
Lê C	23xxxxxx	Testing & report
📄 Report

The report includes:

Wiener Filter theory

Algorithm explanation

Flowchart & pseudo-code

MIPS code structure

Test results & screenshots

⚠️ Plagiarism Warning

Similarity must be below 50%, verified via MOSS (Stanford).
