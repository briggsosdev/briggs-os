# TPM Integration for Briggs OS
# Provides measured boot and attestation capabilities

## Overview
Briggs OS includes TPM 2.0 support for:
- Measured boot (PCR extends)
- Secure key storage
- Random number generation
- Remote attestation

## Files
- `kernel/kernel_tpm.c` - TPM 2.0 driver (TPM2 commands)
- `boot/tpm_stage2.s` - TPM measurement in stage2 (extends PCRs before kernel load)
- `kernel/kernel_main.c` - Admin shell `tpm` command for on-demand TPM2_Quote generation (MED-03)

## TPM Resources Used
- PCR 0-7: BIOS/Stage2 measurements
- PCR 8: Kernel measurement  
- PCR 9: Initial config measurement
- NV Index 0x1500000: Briggs OS public key storage

## Measured Boot Flow
1. Stage1 (boot.bin) measures stage2 -> PCR 0
2. Stage2 measures itself -> PCR 1
3. Stage2 measures kernel -> PCR 8
4. Stage2 measures config -> PCR 9
5. Kernel extends PCRs during runtime for loaded modules

## Build Integration
```bash
# Enable TPM support (default: enabled)
./build.py --enable-tpm

# Disable TPM (for VMs without TPM)
./build.py --disable-tpm
```

## Implemented
- [x] TPM2_Extend in stage2 (PCR1)
- [x] TPM2_GetRandom for kernel RNG seeding
- [x] TPM2_Quote for remote attestation (admin shell `tpm` command, PCR 8, MED-03)

## TODO
- [ ] Store Ed25519 public key in TPM NV storage
