## Briggs OS v3.7 — Production Release (updated)

**Kernel SHA-256**: `869c05622a2f5ab2a9fe0338ed0b3f89860cd57535534d7e68799d3387296581`

### What's included
- **briggs.img** — Raw HDD image (2 MB, bootable)
- **briggs_kernel.bin** — Kernel binary (~397 KB), Ed25519 signed
- **briggs_kernel.sig** — Ed25519 signature (64 bytes)
- **RELEASE_CHECKSUMS.txt** — SHA-256 checksums of all release files
- **docs/PRODUCTION_USER_GUIDE.md** — Full deployment & operations manual
- **docs/PRODUCTION_SECURITY_AUDIT.md** — Security audit report (18 findings, 0 unresolved)
- **docs/TPM_INTEGRATION.md** — TPM 2.0 setup guide
- **docs/SECURE_UPDATE.md** — Secure update system
- **docs/DROPBEAR_PORT.md** — SSH port notes

### Build profile
- **Dropbear SSH** on port 22
- **Argon2id** password hashing (256 MB, t=3)
- **Ed25519** offline-signed boot verification
- **Entropy policy**: fail-closed (RDRAND required — no boot without it)
- **Hybrid key exchange**: X25519 + ML-KEM-768 (post-quantum secure)
- **At-rest encryption**: ChaCha20-Poly1305 with key commitment (fully constant-time)
- **TOTP / hardware token** 2FA (optional per user)

### Quick start (QEMU)
```bash
qemu-system-i386 -drive file=briggs.img,format=raw \
    -m 512M -no-reboot -serial stdio -cpu qemu64,rdrand=on \
    -net nic,model=e1000 -net user,hostfwd=tcp::2222-:22
```
Then: `ssh -p 2222 admin@localhost`

### Security audit summary
- 18 findings identified
- **0 unmitigated CRITICAL** (CRIT-05: AES S-box cache timing → FIXED)
- **0 OPEN HIGH** (all HIGH findings resolved)
- **0 OPEN MEDIUM** (all MEDIUM findings resolved or accepted)
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
- **CRIT-05 FIXED**: Default vault cipher switched from AES-256-GCM-SIV to ChaCha20-Poly1305 (fully constant-time, no S-box lookup tables)
- **Poly1305 FIXED**: Removed OOB read of m[16] in non-final block processing
- **ChaCha20 decrypt FIXED**: State was being zeroed before decryption keystream generation (key/nonce/SIGMA cleared)
- **HIGH-03 FIXED**: ML-KEM-768 NTT variable-time reduction replaced with constant-time barrett_reduce + sign fix across poly_ntt, poly_intt, base_mul
- **MED-02 FIXED**: Minimum password length increased from 8 to 12 characters (pw_score thresholds now 12/16/20)
- **HIGH-07 FIXED**: Build reproducibility — SOURCE_DATE_EPOCH=0, -frandom-seed=0, --build-id=none, `make ci-repro` target
- **MED-03 FIXED**: TPM2_Quote remote attestation via admin shell `tpm` command
- **MED-05 FIXED**: DHCP parser fuzz harness (5000+ random iterations, zero crashes)
- **MED-06 FIXED**: Network fuzzing integrated via fuzz_dhcp.py + run_fuzz_dhcp.sh
