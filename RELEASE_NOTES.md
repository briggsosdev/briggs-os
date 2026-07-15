## Briggs OS v3.7 — Production Release

**Kernel SHA-256**: `2d5bbcfb5098c11697f62c3a6fda143d7071dbfe2544ab98bda3fa3d4ab024a0`

### What's included
- **briggs.img** — Raw HDD image (2 MB, bootable)
- **briggs_kernel.bin** — Kernel binary (~404 KB), Ed25519 signed
- **briggs_kernel.sig** — Ed25519 signature
- **boot.bin / stage2.bin** — Boot chain (verified)
- **CHECKSUMS.txt** — Build artifact checksums
- **docs/PRODUCTION_USER_GUIDE.md** — Full deployment & operations manual
- **docs/PRODUCTION_SECURITY_AUDIT.md** — NSA-style security audit (19 findings)
- **docs/TPM_INTEGRATION.md** — TPM 2.0 setup guide
- **docs/SECURE_UPDATE.md** — Secure update system
- **docs/DROPBEAR_PORT.md** — SSH port notes

### Build profile
- **Dropbear SSH** on port 22
- **Argon2id** password hashing (256 MB, t=3)
- **Ed25519** offline-signed boot verification
- **Entropy policy**: fail-closed (RDRAND required — no boot without it)
- **Hybrid key exchange**: X25519 + ML-KEM-768 (post-quantum secure)
- **At-rest encryption**: AES-256-GCM-SIV with key commitment
- **TOTP / hardware token** 2FA (optional per user)

### Quick start (QEMU)
```bash
qemu-system-i386 -drive file=briggs.img,format=raw \
    -m 512M -no-reboot -serial stdio -cpu qemu64,rdrand=on \
    -net nic,model=e1000 -net user,hostfwd=tcp::2222-:22
```
Then: `ssh -p 2222 admin@localhost`

### Security audit summary
- 19 findings identified
- 1 unmitigated CRITICAL (AES S-box cache timing — use ChaCha20-Poly1305 as workaround)
- 2 OPEN HIGH, 3 OPEN MEDIUM
- Full details: `docs/PRODUCTION_SECURITY_AUDIT.md`

### Changes since v3.6
- Full Argon2id (256 MB, t=3) compiled in for production
- Ed25519 offline signing + verification
- Dropbear SSH backend (custom SSH disabled in production)
- Entropy policy 2 (fail-closed on missing RDRAND)
- PIT-based session management with idle timeout
- Multi-session cooperative vault_picker
- Session cleanup on RST/FIN
- 60/60 beta tests passing, 5/5 repro cycles
