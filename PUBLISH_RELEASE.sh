#!/usr/bin/env bash
# Briggs OS v3.7 — Publish GitHub Release
#
# Prerequisites:
#   1. Install GitHub CLI (gh): https://cli.github.com/
#   2. gh auth login
#   3. Run this script.
#
set -euo pipefail

REPO="briggs-os/briggs-os"   # change to your GitHub org/repo
TAG="v3.7-prod-remote"
ZIP="../briggs_os_v3_7_prod-remote.zip"

echo "==> Creating GitHub repo..."
gh repo create "$REPO" --public --description "Briggs OS v3.7 — bare-metal password vault (prod-remote)"

echo "==> Pushing code..."
git remote add origin "https://github.com/$REPO.git"
git push origin master
git push origin "$TAG"

echo "==> Creating release..."
gh release create "$TAG" \
    --repo "$REPO" \
    --title "Briggs OS v3.7 (prod-remote)" \
    --notes "
## Briggs OS v3.7 — Production Release

**Kernel SHA-256**: \`2d5bbcfb5098c11697f62c3a6fda143d7071dbfe2544ab98bda3fa3d4ab024a0\`

### What's included
- **briggs.img** — Raw HDD image (2 MB, bootable)
- **briggs_kernel.bin** — Kernel binary (~404 KB), Ed25519 signed
- **briggs_kernel.sig** — Ed25519 signature
- Documentation: production user guide, security audit, TPM guide, secure update guide

### Build profile
- Dropbear SSH (port 22)
- Argon2id password hashing (256 MB, t=3)
- Ed25519 boot verification
- Entropy policy: fail-closed (RDRAND required)
- Hybrid X25519 + ML-KEM-768 key exchange (post-quantum secure)

### Quick start
\`\`\`
qemu-system-i386 -drive file=briggs.img,format=raw \\
    -m 512M -no-reboot -serial stdio -cpu qemu64,rdrand=on \\
    -net nic,model=e1000 -net user,hostfwd=tcp::2222-:22
\`\`\`

### Documentation
- \`docs/PRODUCTION_USER_GUIDE.md\` — Full deployment and operations manual
- \`docs/PRODUCTION_SECURITY_AUDIT.md\` — NSA-style security audit

### Security audit summary
- 19 findings: 1 unmitigated CRITICAL (AES S-box cache timing), 2 OPEN HIGH, 3 OPEN MEDIUM
- See audit document for full details and remediation priorities
" \
    "$ZIP#Briggs OS v3.7 prod-remote binary release"

echo "==> Done! Release at: https://github.com/$REPO/releases/tag/$TAG"
