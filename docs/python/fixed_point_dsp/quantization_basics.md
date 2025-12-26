# Fixed-Point Quantization

## 🎯 Objective
To understand how to convert floating-point signals into fixed-point representations suitable for FPGA/ASIC implementation, and to analyze the resulting quantization noise.

## 💡 Concept: The $Q_{m.n}$ Format
In hardware, we represent numbers using a fixed number of bits:
- **Total Bits ($W$):** The word length.
- **Integer Bits ($m$):** Bits for the integer part (including sign bit).
- **Fractional Bits ($n$):** Bits for the precision.

The formula to convert a float to fixed-point is:
$$Fixed = \text{round}(Float \times 2^n)$$

## 1. Theoretical Comparison

| Method | Hardware Cost | Statistical Bias |
| :--- | :--- | :--- |
| **Truncation** | Zero (just drop LSBs) | **High** (Always shifts the mean negative) |
| **Rounding** | Moderate (requires an adder) | **Low** (Mean error stays near zero)
## 2. Visualizing the Error

Below are the results of my Python simulation comparing a high-precision sine wave against its quantized versions.

### Error Distribution
[Insert your plot here: e.g., `![Error Histogram](../../assets/figures/DSP/truncation_vs_rounding.png)`]



### Observations:
* **Truncation Error:** The error is always between $(-1, 0]$. This introduces a **DC Offset** into the FFT bins, which can be catastrophic for weak signal detection.
* **Rounding Error:** The error is centered around $0$ (between $[-0.5, 0.5]$). While it costs slightly more logic, it preserves the dynamic range and prevents DC bias.

---

## 🐍 Python Implementation

This script demonstrates how to quantize a sine wave. Compare rounding versus truncation.
```python
import numpy as np
import matplotlib.pyplot as plt
from numfi import numfi

# 1. Setup Time and Signal (Use linspace for safety)
fs = 1000
duration = 0.1
# force exactly 100 points, or whatever fs * duration dictates
N_samples = int(fs * duration)
t = np.linspace(0, duration, N_samples, endpoint=False) 

f_signal = 20
x = np.sin(2 * np.pi * f_signal * t)

# 2. Fixed-point quantization
y_floor = numfi(x, s=1, w=8, f=2, RoundingMethod='Floor')
y_round = numfi(x, s=1, w=8, f=2, RoundingMethod='Nearest')

# 3. Calculate Errors (Force to array to prevent 'int' vs 'array' errors)
# np.broadcast_to ensures that if y_floor.f is a scalar, it stretches to match x
y_floor_vals = np.broadcast_to(y_floor.double, x.shape)
y_round_vals = np.broadcast_to(y_round.double, x.shape)

err_floor = y_floor_vals - x
err_round = y_round_vals - x

print("--- DEBUGGING DATA ---")
print(f"Original Signal Max: {np.max(x):.4f}")
print(f"Floor Signal Max:    {np.max(y_floor_vals):.4f}")
print(f"Round Signal Max:    {np.max(y_round_vals):.4f}")


# 4. Plotting
plt.figure(figsize=(12, 8))

# Subplot 1: Floor Error
plt.subplot(3, 1, 1)
plt.plot(t, err_floor, label='Floor Error')
plt.axhline(np.mean(err_floor), color='red', linestyle='--', label=f'Mean: {np.mean(err_floor):.4f}')
plt.title(f"Floor Error (Bias is visible)")
plt.legend(loc='upper right')
plt.grid(True)

# Subplot 2: Round Error
plt.subplot(3, 1, 2)
plt.plot(t, err_round, label='Round Error', color='orange')
plt.axhline(np.mean(err_round), color='red', linestyle='--', label=f'Mean: {np.mean(err_round):.4f}')
plt.title(f"Round Error (Centered on Zero)")
plt.legend(loc='upper right')
plt.grid(True)

# Subplot 3: Signal Comparison
plt.subplot(3, 1, 3)
plt.plot(t, x, label='Original signal', color='black', alpha=0.3)

# Use the explicitly broadcasted values here
plt.step(t, y_floor_vals, label='Floor (Truncated)', where='post', linestyle='--')
plt.step(t, y_round_vals, label='Round (Nearest)', where='post')

plt.axhline(np.mean(x), color='red', linestyle='--', label='Signal Mean')
plt.title("Signal Comparison: Original vs Fixed Point")
plt.xlabel("Time (s)")
plt.legend(loc='upper right')
plt.grid(True)

plt.tight_layout()
plt.show()
