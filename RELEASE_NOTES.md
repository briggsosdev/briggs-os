## Briggs OS — production release

Kernel SHA-256: `869c05622a2f5ab2a9fe0338ed0b3f89860cd57535534d7e68799d3387296581`

License: free for personal use, businesses need a license. See LICENSE.md.

### Files

briggs.img — disk image (2 MB)
briggs_kernel.bin — kernel (~397 KB)
briggs_kernel.sig — Ed25519 sig
docs/ — manual, audit report, TPM guide, update guide

### What changed from last build

Entirely new codebase. Full Argon2id, Ed25519 signing, Dropbear SSH instead of the custom one, fail-closed entropy, session timeouts. All 60 beta tests pass.

### Bugs fixed

- CRIT-05: AES cache timing — switched to ChaCha20-Poly1305
- Poly1305: off-by-one in non-final blocks
- ChaCha20 decrypt: state got zeroed mid-decrypt
- HIGH-03: ML-KEM NTT used variable-time mod
- MED-02: bumped minimum password length to 12
- HIGH-07: builds now deterministic (SOURCE_DATE_EPOCH, -frandom-seed)
- MED-03: TPM quote command added to admin shell
- MED-05/06: DHCP fuzz harness, zero crashes

### Audit

18 findings, all handled. Report is in docs/.
