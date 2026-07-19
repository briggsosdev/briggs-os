# BRIGGS OS

[![License: Personal Use Free](https://img.shields.io/badge/license-Personal%20Use%20Free-brightgreen?style=flat-square)](LICENSE.md)
[![Platform](https://img.shields.io/badge/platform-i386-blue?style=flat-square)]()
[![Release](https://img.shields.io/github/v/release/briggsosdev/briggs-os?style=flat-square)](https://github.com/briggsosdev/briggs-os/releases)
[![Audit](https://img.shields.io/badge/audit-0%20unresolved%20findings-success?style=flat-square)](docs/PRODUCTION_SECURITY_AUDIT.md)

Bootable x86 OS that turns any PC into a dedicated hardware password vault. SSH in, store secrets, get out. No Linux, no web UI, no bloat.

## Quick start

```bash
qemu-system-i386 -drive file=briggs.img,format=raw \
    -m 512M -no-reboot -serial stdio \
    -cpu qemu64,rdrand=on \
    -net nic,model=e1000 \
    -net user,hostfwd=tcp::2222-:22
```

```bash
ssh -p 2222 admin@localhost
```

First boot walks you through setup.

## Crypto (all hand written, no libc)

- Argon2id at 256 MB, 3 passes for passwords
- ChaCha20-Poly1305 for vault encryption
- X25519 + ML-KEM-768 for key exchange
- Ed25519 for signing (done offline)
- RDRAND or the machine doesn't boot

## What's inside

```
briggs.img               Bootable disk image (2 MB)
briggs_kernel.bin        The kernel (~397 KB)
briggs_kernel.sig        Ed25519 signature
virus_scan_report.pdf    Virus scan results
docs/                    Manual, audit report, TPM setup
```

## License

Free if you're an individual using it for yourself. Businesses need a paid license. See LICENSE.md.

## Audit

All findings fixed. Report in docs/PRODUCTION_SECURITY_AUDIT.md — 18 items, all done.

## Who this is for

Anyone who wants a password vault that isn't Electron, isn't in the cloud, and doesn't trust a closed-source TPM. Old PC or a VM, this runs on it.

This is security software. Don't trust it with real secrets until you've reviewed it yourself.
