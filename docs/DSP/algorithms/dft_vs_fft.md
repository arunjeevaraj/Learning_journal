# DFT vs. FFT: Complexity and Implementation

## A personal remark about this topic
This is one algorithm, which took forever for me to understand and grasp and even now I dont dare to claim to understand it fully. From my batchelors as a theory topic and to double down into it's depth during image processing electives by performing 2D FFT. 
I knew about the maths and how to do it, I knew about the spectrum analysis and to make use of the data. But conceptually to digest it further, it took me more time. The orthogonal basis vectors and vector space analysis,
opened up a different perspective. It gave me the idea about how the Maths actually work to create the magic behind the curtain. 

Through my first career, and beyond. I had to make use of it during my time working with 4G LTE layer 1 and 2. THe OFDMA frames decoding needed the iFFT and then ultimately to feed it to perform cellsearch.
Here optimization on the FFT was not prioritized, but the fast implementation and system level integration were more pivotal to see the cellsearch working against the Matlab model in an actual FPGA hardware.
Fun ways to learn about lots of topics, looking back.
Then it came back to me as a task, this time to  implement a parameterizable, scalable and adaptable fixed point implementation targetting different signal processing chains in an ASIC.
The efficiency, and memory footprint were paramount. To implement it as toolkit that supports varying lengths of FFT to be deployed, has some challenges when a single memory was used to store the source and target of the FFT butterfly stages.
 
 In this post, lets take a step toward understanding DFT and then dive a bit in to the FFT. Compare what changes and how it made the algorithm ubiquitous. 

## 1. The Mathematical Foundation

The **Discrete Fourier Transform (DFT)** converts a sequence of $N$ complex numbers into another sequence of $N$ complex numbers in the frequency domain.

### The DFT Formula
For each frequency bin $k$, the calculation is:
$$X[k] = \sum_{n=0}^{N-1} x[n] \cdot e^{-j\frac{2\pi}{N}kn}$$

### The Complexity Problem
To compute a full $N$-point DFT:
1. We calculate $N$ frequency bins ($k=0$ to $N-1$).
2. For *each* bin, we perform $N$ complex multiplications and $N-1$ complex additions.
3. This results in **$O(N^2)$** total operations.



---

## 2. The FFT "Divide and Conquer"
The **Fast Fourier Transform (FFT)**, specifically the Radix-2 Cooley-Tukey algorithm, reduces this complexity by splitting the DFT into even and odd indices recursively. How does this actually work. and Why ?
By splitting the input sequence into even indices ($2n$) and odd indices ($2n+1$), we can rewrite the DFT summation as:
$$X[k] = \sum_{n=0}^{N/2-1} x[2n]e^{-j\frac{2\pi}{N}k(2n)} + \sum_{n=0}^{N/2-1} x[2n+1]e^{-j\frac{2\pi}{N}k(2n+1)}$$
After some algebraic manipulation and using the Twiddle Factor $W_N^k = e^{-j\frac{2\pi}{N}k}$, we arrive at the two equations that define the **FFT Butterfly**. These equations allow us to calculate two frequency outputs simultaneously from the even ($E[k]$) and odd ($O[k]$) sub-sequences:
$$X[k] = E[k] + W_N^k O[k]$$

$$X[k + N/2] = E[k] - W_N^k O[k]$$

The "magic" that allows the second half of the spectrum ($X[k + N/2]$) to be calculated with a simple subtraction is the symmetry of the twiddle factors:

$$W_N^{k + \frac{N}{2}} = -W_N^k$$

If you want to find X[k] for N=8:

    You split your 8 samples into 4 even and 4 odd indices.

    You run a 4-point FFT on the even samples to get E[k].

    You run a 4-point FFT on the odd samples to get O[k].

    You combine them using the Butterfly: 
$$X[k] = E[k] + W_N^k.​O[k]$$.

But it doesn't stop there. To find that 4-point FFT, the algorithm splits that into two 2-point FFTs. And the 2-point FFT is split into 1-point FFTs.

    Note: A 1-point FFT is the easiest math in the world: the DFT of a single sample is just the sample itself! X[0]=x[0].

### Visualizing the Split ($N=8$)
To process an 8-point signal, we decompose it until we reach 2-point butterflies:

1. **Stage 1:** Split `[x0, x1, x2, x3, x4, x5, x6, x7]` into Even `[x0, x2, x4, x6]` and Odd `[x1, x3, x5, x7]`.
2. **Stage 2:** Split the Even group into `[x0, x4]` and `[x2, x6]` and the Odd group into `[x1, x5]` and `[x3, x7]`
3. **Stage 3:** The 2-point Butterfly operates on these pairs.

The 8 Point FFT, as it tickles down the stages. You could see the sequence gets a different order, with indices 000, 100, 010, 110, 001, 101, 011, 111. If you look at it a few times, you would see that it is just bit reversed at the indices.

graph LR
    A[Input Signal] --> B[Bit Reversal]
    B --> C[Stage 1: 2-pt FFT]
    C --> D[Stage 2: 4-pt FFT]
    D --> E[Stage 3: 8-pt FFT]
    E --> F[Frequency Output]
    
### The Butterfly Operation
By exploiting the symmetry of the twiddle factors ($e^{-j...}$), we reuse intermediate results. This reduces the complexity to:
$$\text{Complexity} = O(N \log_2 N)$$



| N Samples | DFT ($N^2$) | FFT ($N \log_2 N$) | Speedup Factor |
| :--- | :--- | :--- | :--- |
| 64 | 4,096 | 384 | ~10x |
| 1024 | 1,048,576 | 10,240 | ~102x |
| 4096 | 16,777,216 | 49,152 | ~341x |

---

## 3. Python Demonstration
Below is a script to visualize the massive performance gap as $N$ increases.

```python
import numpy as np
import time
import matplotlib.pyplot as plt

def manual_dft(x):
    N = len(x)
    n = np.arange(N)
    k = n.reshape((N, 1))
    e = np.exp(-2j * np.pi * k * n / N)
    return np.dot(e, x)

sizes = [64, 128, 256, 512, 1024]
dft_times = []
fft_times = []

for N in sizes:
    # Generate random signal
    x = np.random.random(N)
    
    # Time DFT
    start = time.time()
    manual_dft(x)
    dft_times.append(time.time() - start)
    
    # Time FFT
    start = time.time()
    np.fft.fft(x)
    fft_times.append(time.time() - start)

print(f"For N=1024, FFT is {dft_times[-1]/fft_times[-1]:.2f}x faster!")