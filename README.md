<div align="center">

# 🛡️ Briggs OS

**Bare-metal password vault operating system**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-x86_32--bit-brightgreen)]()
[![Boot](https://img.shields.io/badge/boot-BIOS-legacy-yellow)]()
[![Crypto](https://img.shields.io/badge/crypto-AES--256--GCM--SIV%20|%20ChaCha20--Poly1305%20|%20ML--KEM--768-blueviolet)]()

A dedicated secret-storage appliance that boots from a raw disk image and exposes a single SSH service. All cryptography is hand-rolled, no external libraries, no operating system underneath — just bare-metal security.

---

</div>

## ✨ Features

| Area | Details |
|------|---------|
| **🔐 At-rest encryption** | AES-256-GCM-SIV with key commitment (nonce-misuse resistant) |
| **🔑 Password hashing** | Argon2id (256 MB, t=3) — ~1-3s per hash on modern hardware |
| **🌐 Remote access** | Dropbear SSH with hybrid X25519 + ML-KEM-768 key exchange |
| **✅ Verified boot** | SHA-256 + Ed25519 offline signing chain |
| **📏 TPM 2.0** | Measured boot (PCR1: stage2, PCR8: kernel) + RNG seeding |
| **👥 Multi-user** | SUPERADMIN, TIER2 (vault manager), TIER1 (basic user) |
| **📂 Shared vaults** | Granular read/write/owner access control |
| **🔐 Two-factor** | TOTP authenticator + hardware token support per user |
| **📋 Audit log** | HMAC-SHA256 chained, tamper-evident |
| **🔄 Secure update** | TFTP download with Ed25519 verification + rollback |
| **🛡️ Firewall** | Per-IP blocking, rate limiting, event logging |

## 🚀 Quick Start

```bash
qemu-system-i386 -drive file=build/briggs.img,format=raw \
    -m 512M -no-reboot -serial stdio -cpu qemu64,rdrand=on \
    -net nic,model=e1000 -net user,hostfwd=tcp::2222-:22
```

```
ssh -p 2222 admin@localhost
```

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [`PRODUCTION_USER_GUIDE.md`](docs/PRODUCTION_USER_GUIDE.md) | Full deployment, operations, and command reference |
| [`PRODUCTION_SECURITY_AUDIT.md`](docs/PRODUCTION_SECURITY_AUDIT.md) | NSA-style security audit (19 findings) |
| [`TPM_INTEGRATION.md`](docs/TPM_INTEGRATION.md) | TPM 2.0 setup and measured boot |
| [`SECURE_UPDATE.md`](docs/SECURE_UPDATE.md) | Secure update system design |
| [`DROPBEAR_PORT.md`](docs/DROPBEAR_PORT.md) | Dropbear SSH backend notes |

## 🔒 Security Posture

- **Crypto**: AES-256, ChaCha20-Poly1305, Ed25519, X25519, ML-KEM-768, Argon2id
- **Entropy**: Fail-closed (RDRAND required at boot)
- **Side-channels**: Constant-time tag comparisons (`ct_memcmp`); ChaCha20 is fully constant-time
- **Memory**: All secrets zeroed via `kmemzero_secure()` with compiler barrier
- **Self-tests**: All crypto primitives verified via KAT on every boot
- **Supply chain**: Ed25519 offline signing; build artifacts checksummed

> See [full security audit](docs/PRODUCTION_SECURITY_AUDIT.md) for detailed findings and remediation.

## 📦 Release Artifacts

| File | Size | Description |
|------|------|-------------|
| `build/briggs.img` | 2 MB | Bootable raw HDD image |
| `build/briggs_kernel.bin` | ~404 KB | Kernel binary (Ed25519 signed) |
| `build/briggs_kernel.sig` | 64 B | Ed25519 signature |
| `build/CHECKSUMS.txt` | — | SHA-256 + MD5 of build artifacts |
| `RELEASE_CHECKSUMS.txt` | — | SHA-256 of entire release |

## 📋 Build Profile (v3.7 prod-remote)

| Parameter | Value |
|-----------|-------|
| Kernel SHA-256 | `2d5bbcfb5098c11697f62c3a6fda143d7071dbfe2544ab98bda3fa3d4ab024a0` |
| SSH backend | Dropbear (port 22) |
| Argon2id | 256 MB, t=3, p=1 |
| Entropy policy | 2 (fail-closed) |
| Key exchange | X25519 + ML-KEM-768 hybrid |
| Architecture | x86 32-bit, BIOS legacy boot |
| Tests | 60/60 beta, 5/5 repro cycles |

---

<div align="center">

*Built with 🔧 from scratch — no stdlib, no OS, no dependencies*

</div>
