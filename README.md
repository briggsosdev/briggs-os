# BRIGGS OS

Briggs OS is a BIOS-bootable x86 vault operating system with local setup and a staged remote-admin transport.

## Current Model

- One initial `SUPERADMIN` account is created during first boot.
- `TIER2` users can manage shared vault collaboration.
- `TIER1` users manage only their own vault and any shared vaults granted to them.

## Build Profiles

Three build profiles isolate object files in separate directories:

```bash
make dev          # Development build: REMOTE_DISABLED, skips Argon2/Ed25519
make prod-local   # Local-only production: REMOTE_DISABLED, full crypto
make prod-remote  # Full production with Dropbear networking
make ci           # Build all three profiles in sequence (requires distclean)
```

Required tools:

```bash
i686-elf-gcc      (or host gcc -m32 for dev-only builds)
i686-elf-as
i686-elf-ld
nasm
python3            (with cryptography package for Ed25519 signing)
```

Build artifacts:

- `build/briggs.img` — bootable HDD image
- `build/briggs.iso` — bootable ISO image (El Torito)
- `briggs_kernel.bin` — raw kernel binary

## First Boot

Boot the HDD or ISO image and complete the local setup flow:

- create the initial `admin` superadmin account
- choose DHCP or manual networking
- set the recovery passphrase

After setup, connect via the remote admin transport (prod-remote) or use the local VGA+serial console (dev/prod-local).

## Build + Run

```bash
make dev              # Build dev profile
make hdd              # Package HDD image
make run              # Build + run under QEMU
make run-iso          # Build + run ISO under QEMU
make smoke-test       # Automated QEMU smoke test
```

## Security

- **Ed25519 kernel verification**: kernel is cryptographically signed at build time; stage2 passes the signature and public key to the kernel, which verifies before executing.
- **Verified-boot trust**: SHA-256 of the Ed25519 public key is stored in ApplianceMeta on first boot; subsequent boots verify the running key matches the stored hash.
- **TPM measured boot**: kernel hash is extended into PCR 8.
- **All vault data encrypted**: AES-256-GCM-SIV with key commitment.
- **Argon2id KDF** (t=3, m=256MB): protects user passwords and vault keys.
- **TOTP / hardware token**: optional two-factor authentication per account.
- **Audit log**: HMAC-SHA256 chained, 256-entry ring.

## QEMU

Windows:

```powershell
.\run_qemu.ps1 hdd
.\run_qemu.ps1 ssh
```

WSL/Linux:

```bash
qemu-system-i386 \
  -drive file=build/briggs.img,format=raw \
  -m 512M \
  -no-reboot \
  -serial stdio \
  -net nic,model=e1000 \
  -net user
```

## Notes

- The primary supported path in this repo is the 32-bit BIOS flow in `boot/` and `kernel/`.
- The 64-bit and UEFI code remains experimental.
- The legacy in-kernel SSH backend is still present for development-only testing.
- See `docs/PRODUCTION_USER_GUIDE.md` for the full deployment and operations manual.
- See `docs/PRODUCTION_SECURITY_AUDIT.md` for the security audit report.
- This is security-sensitive software and should be independently reviewed before production use.
