# FFT Reference Model (Floating-Point)

Before moving to Fixed-Point ASIC implementation, it is important to have a reference model to test out the concept and act as a scoreboard in the testbench. For that purpose, it is crucial to have a floating-point reference model.

We will use a **bottom-up approach** here. Getting the basic building blocks built first, tested, and the concept understood is a good way to proceed.

### Key Sub-Blocks

* **Bit Reversal for Indices and a RAM to store the data.**
    This has to be done either at the input level or the output level of the FFT. A RAM to mimic the hardware is a good idea here.
    
* **Butterfly Unit**
    For performing FFT, one of the basic blocks is a FFT butterfly. To keep things simple, let's focus on building the FFT with a **Radix-2** butterfly. The Butterfly needs to perform complex multiplication operations.
    
* **FFT Stages and Data Feeding**
    The butterfly "spans its wings" based on the FFT stage. FFT relies on splitting an $N$-point FFT to $N/2$-point FFT of even and odd indices and making use of the twiddle factor symmetry. This is basically controlling the data flow to the butterfly and controlling the stages.

---

## 1. The Butterfly "Hardware" Block

In a physical ASIC, the butterfly is a logic cluster of 4 multipliers and 6 adders.

$$X[k] = E[k] + W_N^k O[k]$$

$$X[k + N/2] = E[k] - W_N^k O[k]$$



By feeding $E[k]$ and $O[k]$ terms to the butterfly, one could compute $X[k]$ and $X[k + N/2]$. This involves two complex multipliers and two complex adders.

The complex multiplication typically needs 4 multiplications, but this can be reduced to **3 multiplications** by using the Gauss multiplication method.

### 1.1 Gauss Complex Multiplication

**Step 1: The "Overlap" Term**
Let's create a common multiplication that uses both real and imaginary parts of our numbers. We will call it $k_1$:

$$k_1 = C \cdot (A + B)$$

If we expand this, we get:
$$k_1 = AC + BC$$

Notice that $AC$ is part of our desired Real result, and $BC$ is part of our desired Imaginary result.

**Step 2: Isolating the Real Part**
We want $AC - BD$. We already have $AC + BC$ from $k_1$. To get rid of that $+BC$ and turn it into $-BD$, we need another multiplication. Let's try to find a term that involves $B$:

$$k_3 = B \cdot (C + D) = BC + BD$$

Now, look what happens if we subtract $k_3$ from $k_1$:
$$k_1 - k_3 = (AC + BC) - (BC + BD)$$
$$k_1 - k_3 = AC - BD$$

**This is exactly our Real Part!**

**Step 3: Isolating the Imaginary Part**
We want $AD + BC$. We already have $AC + BC$ from $k_1$. To get rid of the $+AC$ and turn it into $+AD$, we need a term that involves $A$:

$$k_2 = A \cdot (D - C) = AD - AC$$

Now, look what happens if we add $k_1$ and $k_2$:
$$k_1 + k_2 = (AC + BC) + (AD - AC)$$
$$k_1 + k_2 = BC + AD$$

**This is exactly our Imaginary Part!**



#### Hardware Requirement Summary

| Intermediate | Operation | Hardware Requirement |
| :--- | :--- | :--- |
| **$k_1$** | $C \cdot (A + B)$ | 1 Mult, 1 Add |
| **$k_2$** | $A \cdot (D - C)$ | 1 Mult, 1 Sub |
| **$k_3$** | $B \cdot (C + D)$ | 1 Mult, 1 Add |
| **Real Result** | $k_1 - k_3$ | 1 Sub |
| **Imag Result** | $k_1 + k_2$ | 1 Add |

### Python Implementation

```python
def multiplier_3mul(A, B, C, D):
    """
    Computes (A + jB) * (C + jD) using Gauss's 3-multiplier method.
    """
    # Pre-additions (Cheap in Silicon)
    sum_AB = A + B
    diff_DC = D - C
    sum_CD = C + D
    
    # 3 Multiplications (Expensive in Silicon)
    k1 = C * sum_AB
    k2 = A * diff_DC
    k3 = B * sum_CD
    
    # Final assembly
    real_out = k1 - k3
    imag_out = k1 + k2
    return real_out, imag_out

def butterfly_unit(A_re, A_im, B_re, B_im, W_re, W_im):
    # Twiddle product: (B_re + jB_im) * (W_re + jW_im)
    twid_re, twid_im = multiplier_3mul(B_re, B_im, W_re, W_im)
    
    # Sum/Diff stage
    up_re, up_im = A_re + twid_re, A_im + twid_im
    low_re, low_im = A_re - twid_re, A_im - twid_im
    return up_re, up_im, low_re, low_im
```

## 2. Bit Reversal for Indices and a RAM to store the data.

![Fig 2.1 A simplified butterfly map](../../assets/figures/DSP/fft8_radix2.drawio.svg)

The data as it moves across the butterfly stages, get shuffled due to sorting them by even and odd indices as shown in the figure.
so to revert back the order of the FFT, a bit reversal of the indices are needed.
This can be done either at the start or at the end of the FFT.


since we are going for a radix 2 butterfly design, two instances of data needs to be read simultaneously. To solve this problem, we could add two single port RAM with half the size. 

Following that train of thoughts. One way of partitioning the data, would be move the odd indices to One RAM and the viceversa. This would work for stage 1, but for stage 2 the two reads will end up from the same 
RAM. Oops.

The solution is simple. 

For Stage 1, the data read spans by changing the LSB bit.
For stage 2, the data read spans by changing the 2nd LSB bit.
For stage 3, the data read spans by changing the 3rd LSB bit. 

So we could use XOR based banking. Which is to use the parity of the XOR sum of all the bits of the address to resolve the banking..

### 2.1 python implementation of the RAM.

```python
import math

class XOR_RAM:
    """
    Dual-Bank RAM with Parity Banking & Dense Addressing.
    """
    def __init__(self, size):
        self.depth = size // 2
        self.bank0 = [0] * self.depth  # Even Parity Bank
        self.bank1 = [0] * self.depth  # Odd Parity Bank

    def _translate(self, logical_addr):
        """
        Hardware Decoder:
        - Bank = XOR Sum of bits (Parity)
        - Row  = Logical Address >> 1
        """
        bank = bin(logical_addr).count('1') % 2
        row  = logical_addr >> 1
        return bank, row

    def check_access(self, addr_A, addr_B):
        """
        Simulates a simultaneous read. Returns details for printing.
        Raises ValueError if a collision occurs.
        """
        bank_A, row_A = self._translate(addr_A)
        bank_B, row_B = self._translate(addr_B)

        if bank_A == bank_B:
            raise ValueError(f"CONFLICT! {addr_A} & {addr_B} -> Both Bank {bank_A}")
            
        return (bank_A, row_A), (bank_B, row_B)

def verify_fft_8_banking():
    N = 8
    stages = int(math.log2(N))
    ram = XOR_RAM(N)
    
    print(f"{'Stage':<6} | {'Pair (Logical)':<16} | {'Bin A':<6} {'Bin B':<6} | {'Bank A':<7} {'Bank B':<7} | {'Result'}")
    print("-" * 80)

    # Simulate FFT AGU Loops
    for s in range(1, stages + 1):
        span = 2**(s - 1)
        m = 2**s
        
        for group in range(0, N, m):
            for k in range(span):
                idx_A = group + k
                idx_B = group + k + span
                
                try:
                    (bA, rA), (bB, rB) = ram.check_access(idx_A, idx_B)
                    
                    # Formatting for clean output
                    bin_A = f"{idx_A:03b}"
                    bin_B = f"{idx_B:03b}"
                    status = "✅ OK"
                    
                    print(f"Stg {s:<2} | ({idx_A}, {idx_B}){' ':<8} | {bin_A:<6} {bin_B:<6} | {bA:<7} {bB:<7} | {status}")
                    
                except ValueError as e:
                    print(f"Stg {s:<2} | ({idx_A}, {idx_B}) - ❌ FAIL: {e}")

if __name__ == "__main__":
    verify_fft_8_banking()
```


### 2.2 Conflict-Free Memory: XOR Strategy & Addressing
To solve the conflict in Stage 2, we use **Parity Banking**. This ensures that any two addresses differing by 1 bit (Hamming distance 1) always land in different banks.

Running the python verification generates this table. And we can validate that there is no memory access conflict with this approach.
```bash
Stage  | Pair (Logical)   | Bin A  Bin B  | Bank A  Bank B  | Result
--------------------------------------------------------------------------------
Stg 1  | (0, 1)         | 000    001    | 0       1       | ✅ OK
Stg 1  | (2, 3)         | 010    011    | 1       0       | ✅ OK
Stg 1  | (4, 5)         | 100    101    | 1       0       | ✅ OK
Stg 1  | (6, 7)         | 110    111    | 0       1       | ✅ OK
Stg 2  | (0, 2)         | 000    010    | 0       1       | ✅ OK
Stg 2  | (1, 3)         | 001    011    | 1       0       | ✅ OK
Stg 2  | (4, 6)         | 100    110    | 1       0       | ✅ OK
Stg 2  | (5, 7)         | 101    111    | 0       1       | ✅ OK
Stg 3  | (0, 4)         | 000    100    | 0       1       | ✅ OK
Stg 3  | (1, 5)         | 001    101    | 1       0       | ✅ OK
Stg 3  | (2, 6)         | 010    110    | 1       0       | ✅ OK
Stg 3  | (3, 7)         | 011    111    | 0       1       | ✅ OK
```