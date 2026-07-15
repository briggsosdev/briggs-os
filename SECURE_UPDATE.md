# Secure Update Story for Briggs OS

## Overview
Briggs OS implements a secure, verified update mechanism with rollback protection.

## Update Components
1. **Kernel updates** - Signed with Ed25519
2. **Stage2 updates** - Signed with Ed25519  
3. **User data** - Protected by BriggsDB (encrypted at rest)
4. **Configuration** - Versioned, signed updates

## Update Flow

### 1. Download Update
```
User: update download <url>
- Downloads update package (kernel.bin, stage2.bin, etc.)
- Verifies package signature (Ed25519)
- Verifies checksum (SHA-256)
```

### 2. Verify Update
```
User: update verify
- Checks Ed25519 signature of new kernel
- Checks SHA-256 hash matches signed value
- Verifies TPM measurement (if available)
- Displays update metadata (version, date, size)
```

### 3. Apply Update
```
User: update apply
- Backs up current kernel to briggs_kernel.bak
- Backs up current stage2 to stage2.bak
- Writes new kernel to disk (LBA 4+)
- Updates stage2 with new kernel hash
- Updates boot configuration
- Sets rollback flag in RTC CMOS
```

### 4. Reboot and Verify
```
System reboots
Stage2 verifies new kernel (SHA-256 or Ed25519)
If verification fails:
  - Automatically rolls back to backup
  - Boots briggs_kernel.bak
  - Logs failure to recovery log
```

## Rollback Protection

### Anti-rollback Counter
- Stored in RTC CMOS (non-volatile)
- Incremented with each update
- New kernel must have version >= current counter
- Prevents downgrade attacks

### Backup Strategy
- Previous kernel backed up before update
- Automatic rollback on boot failure
- User can manually rollback: `update rollback`

## Update Package Format

```
update.bin:
  [Header: "BRIGGS_UPD", version, timestamp]
  [Ed25519 signature of payload]
  [Payload:]
    - kernel.bin (new kernel)
    - stage2.bin (new stage2)
    - version.txt
    - checksum.txt (SHA-256)
  [Footer: "END_UPD"]
```

## Security Properties

1. **Authenticated updates** - Ed25519 signatures
2. **Integrity protected** - SHA-256 checksums
3. **Rollback protection** - Version counters
4. **Atomic updates** - Backup before apply
5. **Verified boot** - Each stage verifies next

## Implementation Status

- [x] Ed25519 signing tool (`tools/sign_kernel.py`)
- [x] SHA-256 verification in stage2
- [x] Build system integration (`tools/build.py`)
- [ ] Update download client (kernel shell command)
- [ ] Update package builder (`tools/make_update.py`)
- [ ] Rollback mechanism (RTC CMOS counter)
- [ ] TPM measured boot integration
- [ ] Secure boot keys in TPM NV storage

## Commands (Planned)

```
Briggs> update status       # Show current version, pending updates
Briggs> update check        # Check for updates (from URL)
Briggs> update download     # Download and verify update
Briggs> update apply        # Apply pending update
Briggs> update rollback     # Rollback to previous version
Briggs> update verify       # Verify update integrity
```

## Future Work

1. **A/B partition scheme** - Two kernel partitions for safe updates
2. **Network update service** - Automated update checking
3. **Delta updates** - Binary diffs to reduce download size
4. **Signed modules** - Loadable kernel module signing
5. **TPM attestation** - Remote verification of update state
