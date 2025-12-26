# setting up the python environment
Creating a virtual env allows to have a perfect recreatable workspace. So make one with the following command.

# FFT Reference Model (Floating-Point)

Before moving to Fixed-Point ASIC implementation, I developed this floating-point reference model. Unlike high-level library functions (like `numpy.fft`), this model uses an **iterative, in-place approach** that mirrors how a hardware Finite State Machine (FSM) and Address Generation Unit (AGU) operate.

## 1. The Butterfly "Hardware" Block
In a physical ASIC, the butterfly is a logic cluster of 4 multipliers and 6 adders. I've modeled it here as a standalone function to ensure the data path is clearly defined.

$$
X_{upper} = A + (W \cdot B) \\
X_{lower} = A - (W \cdot B)
$$

```python
def butterfly_unit(A_re, A_im, B_re, B_im, W_re, W_im):
    # Complex Multiplication: (B_re + jB_im) * (W_re + jW_im)
    # Real = ac - bd, Imag = ad + bc
    B_twid_re = (B_re * W_re) - (B_im * W_im)
    B_twid_im = (B_re * W_im) + (B_im * W_re)
    
    # Sum and Difference
    up_re = A_re + B_twid_re
    up_im = A_im + B_twid_im
    low_re = A_re - B_twid_re
    low_im = A_im - B_twid_im
    
    return up_re, up_im, low_re, low_im