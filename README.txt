================================================================
  BRIGGS OS v3.7 — Production Release (prod-remote)
================================================================

  Release Date:  2026-07-15
  Build Profile: prod-remote (Dropbear SSH, Argon2id, Ed25519)
  Kernel SHA-256: 2d5bbcfb5098c11697f62c3a6fda143d7071dbfe2544ab98bda3fa3d4ab024a0

  WHAT'S INCLUDED
  ---------------
  build/
    briggs.img          — Raw HDD image (2 MB) — BOOT THIS
    briggs_kernel.bin   — Kernel binary (~404 KB)
    briggs_kernel.sig   — Ed25519 signature (64 bytes)
    boot.bin            — MBR/boot sector (512 bytes)
    stage2.bin          — Stage2 bootloader (1526 bytes)
    CHECKSUMS.txt       — MD5 + SHA-256 of all build artifacts

  docs/
    PRODUCTION_USER_GUIDE.md        — Full deployment & operations manual
    PRODUCTION_SECURITY_AUDIT.md    — NSA-style security audit
    TPM_INTEGRATION.md              — TPM 2.0 integration guide
    SECURE_UPDATE.md                — Secure update system
    DROPBEAR_PORT.md                — Dropbear SSH port notes

  SECURITY.md                   — Security policy

  QUICK START
  -----------
  QEMU:
    qemu-system-i386 -drive file=build/briggs.img,format=raw ^
        -m 512M -no-reboot -serial stdio -monitor none ^
        -display none -cpu qemu64,rdrand=on ^
        -net nic,model=e1000 -net user,hostfwd=tcp::2222-:22

  VirtualBox: Create VM (Other/DOS), attach briggs.img as IDE,
              boot from Hard Disk.

  SSH: ssh -p 2222 admin@localhost  (password set on first boot)

  DOCUMENTATION
  -------------
  Start with docs/PRODUCTION_USER_GUIDE.md for deployment instructions.
  See docs/PRODUCTION_SECURITY_AUDIT.md for the detailed security analysis.

  SIGNING
  -------
  Kernel is signed with Ed25519 (tools/sign_kernel.py).
  Public key is embedded in boot.bin at offset 0x1b0 (root of trust).

================================================================
