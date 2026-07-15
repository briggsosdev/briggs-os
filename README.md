# BRIGGS OS v3.7 — Production Release

Briggs OS is a BIOS-bootable bare-metal x86 password vault operating system. It operates as a dedicated hardware secret vault accessed exclusively via SSH (Dropbear). This repository contains the production release artifacts only — no source code.

## User Model

- **SUPERADMIN** (`admin`): full system administration, user management, admin panel
- **TIER2**: shared vault management
- **TIER1**: personal vault + granted shared vaults

## Contents

| File | Description |
|---|---|
| `briggs.img` | Bootable HDD image (2 MB, BIOS/MBR) |
| `briggs_kernel.bin` | Raw kernel binary (~397 KB) |
| `briggs_kernel.sig` | Ed25519 signature (64 bytes) |
| `docs/PRODUCTION_USER_GUIDE.md` | Full deployment and operations manual |
| `docs/PRODUCTION_SECURITY_AUDIT.md` | Security audit report |
| `docs/TPM_INTEGRATION.md` | TPM 2.0 setup guide |
| `docs/SECURE_UPDATE.md` | Secure update system documentation |
| `docs/DROPBEAR_PORT.md` | Dropbear SSH integration notes |
| `RELEASE_NOTES.md` | Changelog and release notes |
| `SECURITY.md` | Security policy |
| `RELEASE_CHECKSUMS.txt` | SHA-256 checksums of release files |

## Quick Start (QEMU)

```bash
qemu-system-i386 -drive file=briggs.img,format=raw \
    -m 512M -no-reboot -serial stdio \
    -cpu qemu64,rdrand=on \
    -net nic,model=e1000 \
    -net user,hostfwd=tcp::2222-:22
```

Connect: `ssh -p 2222 admin@localhost`

## Security Highlights

- **Argon2id** password hashing (t=3, m=256MB)
- **Ed25519 offline-signed** kernel binary
- **ChaCha20-Poly1305** vault encryption (constant-time)
- **Hybrid key exchange**: X25519 + ML-KEM-768 (post-quantum)
- **TPM 2.0** measured boot (PCR1 stage2, PCR8 kernel)
- **TOTP / hardware token** two-factor authentication
- **HMAC-chained audit log** (256-entry ring)
- **Dropbear SSH** with session management and idle timeout

## Deployment

See `docs/PRODUCTION_USER_GUIDE.md` for:
- First-boot setup wizard
- Account creation and management
- SSH configuration and firewall
- Backup, recovery, and wipe procedures
- Troubleshooting guide

## Verification

```bash
sha256sum --check RELEASE_CHECKSUMS.txt
```

Kernel SHA-256: `869c05622a2f5ab2a9fe0338ed0b3f89860cd57535534d7e68799d3387296581`

## Security

- See `docs/PRODUCTION_SECURITY_AUDIT.md` for the full audit report (18 findings, 0 unresolved)
- This is security-sensitive software. Independently review before production use.
