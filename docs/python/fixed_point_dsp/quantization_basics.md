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



---

## 🐍 Python Implementation

This script demonstrates how to quantize a sine wave.

```python
import numpy as np
import matplotlib.pyplot as plt

def quantize(signal, fractional_bits):
    scaling_factor = 2 ** fractional_bits
    # Scale, Round, and Clip (to simulate hardware registers)
    quantized = np.round(signal * scaling_factor)
    return quantized / scaling_factor

# Parameters
fs = 1000
t = np.linspace(0, 1, fs)
freq = 5
float_signal = 0.9 * np.sin(2 * np.pi * freq * t)

# Quantize to 4 fractional bits (Total 5-6 bits)
fixed_signal = quantize(float_signal, 4)

# Calculate Quantization Error
error = float_signal - fixed_signal
print(f"Mean Squared Error: {np.mean(error**2)}")