# GOG CLI Drive Sharing Automation - Investigation Report

## Executive Summary
The task was to automate Google Drive folder sharing using GOG CLI. The main concern was that `gog auth print-access-token` fails from scripts, but investigation reveals:

1. **`gog auth print-access-token` doesn't exist** - This command is not part of the GOG CLI v0.9.0
2. **GOG CLI works perfectly from Python scripts** - Environment variables are inherited correctly
3. **`gog drive share` is fully functional** - The command already supports email sharing with permissions
4. **Tokens are stored encrypted** - In ~/.config/gogcli/keyring/ with PBES2-HS256+A128KW encryption

## Key Findings

### 1. GOG CLI Architecture
- **Version**: v0.9.0 (99d9575 from 2026-01-22)
- **Keyring Backend**: File-based with encryption
- **Location**: ~/.config/gogcli/keyring/
- **Environment Variables**:
  - `GOG_ACCOUNT`: Account email (lolaopenclaw@gmail.com)
  - `GOG_KEYRING_BACKEND`: file
  - `GOG_KEYRING_PASSWORD`: Encrypted keyring password
  - `GOG_CLIENT`: OAuth client name (default: default)

### 2. Token Storage & Security
- Tokens are stored as **encrypted JSON files** in ~/.config/gogcli/keyring/
- Format: PBES2-HS256+A128KW encryption (AES-256-GCM)
- Naming: `token:default:lolaopenclaw@gmail.com` and `token:lolaopenclaw@gmail.com`
- **Direct access to tokens is NOT recommended** - Encryption is intentional for security

### 3. Available Commands for Drive Sharing
✅ **`gog drive share <fileId> --email <email> --role reader --no-input`**
- Fully functional from CLI and Python scripts
- Supports all roles: reader, writer, commenter, organizer
- Works with headless/non-interactive mode via `--no-input`
- Returns error code 1 on failure, 0 on success

### 4. Command Line vs Script Execution
**Test Results:**
- ✅ `gog auth tokens list` works from Python subprocess
- ✅ `gog drive ls --json` works from Python subprocess  
- ✅ `gog drive share` works from Python subprocess
- ✅ Environment variables are inherited correctly in all cases
- ❌ Non-existent command `print-access-token` fails (as expected)

### 5. Alternative Approaches Investigated

#### A. Direct Token Extraction (NOT RECOMMENDED)
- Tokens are encrypted with GOG_KEYRING_PASSWORD
- Would require decrypting with Go's crypto/json library
- Security risk: exposing tokens in environment
- **Recommendation**: Use GOG CLI directly instead

#### B. Google Drive API v3 via curl
- Would require manually refreshing OAuth tokens
- More complex error handling
- Less maintainable than GOG CLI
- **Recommendation**: Use GOG CLI as it handles everything

#### C. GOG CLI Direct Usage (RECOMMENDED ✅)
- Already supports all required functionality
- Secure token management built-in
- Handles error cases gracefully
- Easy to script and automate

## Recommended Solution: Pure GOG CLI Automation

Use `gog drive share` directly with these advantages:
1. **No token exposure** - GOG manages them securely
2. **Works headless** - Via `--no-input` flag
3. **Batch automation** - Can share with multiple users
4. **Error handling** - Proper exit codes and error messages
5. **JSON output** - For scripting and logging

