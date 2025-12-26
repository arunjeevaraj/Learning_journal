# Today I Learned (TIL)
A digital log of small snippets and engineering realizations.

---

## 📅 December 2025

### Dec 26: Reference Models & Git
**Tags:** #DSP #Python #Git #mkdoc

???+ abstract "Key Realizations"
    * **FFT Span Logic:** Stage $S$ uses a stride of $2^{S-1}$.
    * **Git Safety:** `git rm --cached` is the best way to fix a messy repo.
    * **Mkdoc :**  It is good to have a local Mkdoc development env. Pip install mkdoc & then mkdoc serve.
    * **Comparing Fixed point data and real number :** Using Numfi library to generate fixed point data. 
[Read full FFT Reference Model →](../python/fixed_point_dsp/fft_reference_model.md)

### Dec 25: Project Kickoff
**Tags:** #Documentation #FFT

??? note "Initialization"
    * MkDocs environment established.
    * Focus shifted to ASIC parameterizable architectures.

---

## 🛠️ Technical Snippets

### 🐍 Python Environment Management
When starting a new DSP project, isolate dependencies to avoid version conflicts.

| Command | Action |
| :--- | :--- |
| `python -m venv dsp` | Create the virtual environment |
| `source dsp/bin/activate` | Activate (Linux/macOS) |
| `dsp\Scripts\activate` | Activate (Windows) |
| `pip install numpy matplotlib` | Install core DSP library stack |

---

### 🛡️ Git: Removing Tracked Folders
If you accidentally commit a folder (like `dsp/` or `__pycache__`), use this sequence to clean the repo without deleting your local files.

```bash
# 1. Remove from Git's tracking (but keep files on disk)
git rm -r --cached dsp/

# 2. Add to your .gitignore to prevent future tracking
echo "dsp/" >> .gitignore

# 3. Commit the change
git add .gitignore
git commit -m "chore: stop tracking virtual environment"
```