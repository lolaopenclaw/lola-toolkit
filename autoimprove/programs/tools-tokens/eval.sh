#!/bin/bash
# Token count for TOOLS.md (using tiktoken approximation)
python3 -c "
import sys
file_path = '/home/mleon/.openclaw/workspace/TOOLS.md'
with open(file_path, 'r') as f:
    content = f.read()
# Approximation: 1 token ≈ 0.75 words
words = len(content.split())
tokens = int(words * 1.33)
print(tokens)
" 2>/dev/null || wc -w < /home/mleon/.openclaw/workspace/TOOLS.md
