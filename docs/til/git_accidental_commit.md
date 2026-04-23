### 🛡️ Git: Removing Tracked Folders
If you accidentally commit a folder (like `site/` or `__pycache__`), use this sequence:

```bash
# 1. Remove from Git index (keep local files)
git rm -r --cached folder_name/

# 2. Update ignore list
echo "folder_name/" >> .gitignore

# 3. Finalize
git add .gitignore
git commit -m "chore: stop tracking folder_name"