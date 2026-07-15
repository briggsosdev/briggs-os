# BRIGGS OS v3.7

A bootable x86 operating system that turns old hardware into a dedicated hardware password vault. Access it over SSH. No Linux underneath, no bloated web interface, just a stripped-down kernel that runs one thing and runs it well.

## What it does

- Runs on bare metal or in QEMU
- Exposes SSH on port 22 via Dropbear
- Create users, store passwords, share vaults
- Full admin panel for user management
- TPM 2.0 measured boot if you've got the chip
- Ed25519-signed kernel with verified boot chain

## The crypto stack (hand-rolled, no libc)

| Feature | What |
|---|---|
| Password hashing | Argon2id, 256 MB, 3 passes |
| Vault encryption | ChaCha20-Poly1305 (constant-time) |
| Key exchange | X25519 + ML-KEM-768 hybrid |
| Signatures | Ed25519 (offline signing) |
| Entropy | RDRAND or die (fail-closed) |
| 2FA | TOTP and/or hardware token |

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

First boot walks you through creating the admin account and setting up networking.

## What's in the box

```
briggs.img               Bootable HDD image
briggs_kernel.bin        The actual kernel (~397 KB)
briggs_kernel.sig        Ed25519 signature
docs/                    Full docs: deployment, security audit, TPM setup
RELEASE_CHECKSUMS.txt    sha256 of everything
```

## Security audit

All findings from the audit are addressed. The report is in `docs/PRODUCTION_SECURITY_AUDIT.md` — 18 items, all resolved or accepted.

- CRIT-05: AES S-box timing -> switched to ChaCha20-Poly1305
- HIGH-03: ML-KEM NTT variable-time -> constant-time Barrett reduction
- HIGH-07: Build reproducibility -> SOURCE_DATE_EPOCH + -frandom-seed
- MED-02: Minimum password length -> 12 chars
- MED-03: TPM remote attestation -> tpm2_quote() in admin shell

## Who is this for

People who want a dedicated password vault they can actually trust. No Electron, no cloud dependency, no closed-source TPM black box. If you've got an old PC or a VM, this runs on it.

This is security software. Review it before you trust it with real secrets.
