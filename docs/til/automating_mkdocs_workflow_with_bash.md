---
date: 2026-04-23
tags: [Automation, Bash, MkDocs]
---
# automating mkdocs workflow with bash

**Date:** 2026-04-23

## Context
1. It was getting hard for me to remember the mkdocs command. So it felt better to have a bash based script.
2. updating the index page in TIL and automating the index.md updation and management of files.

## Implementation / Notes
1. I developed a `manage.sh` script to handle these tasks.
 It uses `sed` to automatically update index files and `python3 -m webbrowser` to handle cross-platform browser launching.
 To ensure the newest notes appear at the top of the index, I used this `sed` command:
```bash
sed -i "/# /a * [$datestamp] [$topic](./${filename}.md)" "$index_file"


2. created a common configuration part in the script to make future updates easier.