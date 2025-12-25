# Today I Learned (TIL)
A collection of small snippets, commands, and realizations from my daily engineering work.

---

### December 2025

#### Dec 25: The FFT "Butterfly" and Bit-Reversal
* **Topic:** #DSP #ASIC
* **Learned:** FFT revision.
* **Key Math:** $W_N^{k + N/2} = -W_N^k$. This symmetry is the secret to half the twiddle factor storage!

#### Dec 24: Git Branch Naming
* **Topic:** #Git
* **Learned:** GitHub Actions are branch-specific and deploy this page style documentation journal.


!!! note "TIL: Dec 25 - FFT Bit-Reversal"
    To implement an in-place FFT in an ASIC, bit-reversing the input addresses allows the butterfly structure to stay perfectly aligned with a single dual-port RAM.
    
---
[View all categories]