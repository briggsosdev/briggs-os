## Briggs OS v3.7 — production release

Kernel SHA-256: `869c05622a2f5ab2a9fe0338ed0b3f89860cd57535534d7e68799d3387296581`

**License**: Free for personal use. Commercial use requires a license. See `LICENSE.md`.

### What you get

| File | What |
|---|---|
| `briggs.img` | Bootable HDD image (2 MB) |
| `briggs_kernel.bin` | Raw kernel (~397 KB) |
| `briggs_kernel.sig` | Ed25519 signature |
| `docs/PRODUCTION_USER_GUIDE.md` | How to deploy and use it |
| `docs/PRODUCTION_SECURITY_AUDIT.md` | Full audit write-up |
| `docs/TPM_INTEGRATION.md` | TPM 2.0 setup |
| `docs/SECURE_UPDATE.md` | How updates work |
| `docs/DROPBEAR_PORT.md` | SSH backend notes |

### Build details

- Dropbear SSH on 22, Argon2id (256 MB, t=3), Ed25519 offline-signed
- Entropy policy: fail-closed (no RDRAND = no boot)
- X25519 + ML-KEM-768 hybrid key exchange
- ChaCha20-Poly1305 vault encryption (constant-time, not AES)

### Security audit

18 findings total, every one of them resolved or accepted. The only reason there's any "accepted" is because things like "no MMU guard pages" are inherent to a bare-metal i386 OS without paged memory.

### Changes from v3.6

- Full Argon2id compiled in (256 MB, t=3) — dev builds skipped it
- Ed25519 offline signing + on-boot verification
- Dropbear SSH replaces the custom in-kernel SSH backend
- Entropy policy 2: fail-closed on missing RDRAND
- PIT-based session management with idle timeout
- Multi-session cooperative vault picker
- Session cleanup on TCP RST/FIN
- All 60/60 beta tests passing, 5/5 repro cycles

#### Fixes

- **CRIT-05**: AES S-box cache timing — switched vault cipher to ChaCha20-Poly1305 (no table lookups)
- **Poly1305**: OOB read of m[16] in non-final blocks — fixed
- **ChaCha20 decrypt**: State zeroed before keystream generation — fixed (key/nonce/SIGMA cleared)
- **HIGH-03**: ML-KEM-768 NTT used `% MLKEM_Q` (variable-time) — replaced with barrett_reduce + constant-time sign fix
- **MED-02**: Minimum password length bumped from 8 to 12
- **HIGH-07**: Build reproducibility — SOURCE_DATE_EPOCH, -frandom-seed, --build-id=none, ci-repro target
- **MED-03**: TPM2_Quote remote attestation — admin shell `tpm` command
- **MED-05**: DHCP parser fuzz harness — 5000+ random iterations, zero crashes
- **MED-06**: Network fuzzing integrated via fuzz_dhcp.py
