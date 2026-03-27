#!/bin/bash
python3 -c "
import sys
file_path = '/home/mleon/.openclaw/workspace/PROJECTS.md'
with open(file_path, 'r') as f:
    content = f.read()
words = len(content.split())
tokens = int(words * 1.33)
print(tokens)
" 2>/dev/null || wc -w < /home/mleon/.openclaw/workspace/PROJECTS.md
