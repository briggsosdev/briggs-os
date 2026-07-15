# Briggs OS — Production User Guide

**Version**: 3.7 (prod-remote)  
**Build Date**: 2026-07-15  
**Kernel SHA-256**: 2d5bbcfb5098c11697f62c3a6fda143d7071dbfe2544ab98bda3fa3d4ab024a0  
**Document**: BRIGGS-UG-001

---

## 1. Overview

Briggs OS is a bare-metal x86 operating system that operates as a **dedicated hardware password/secret vault**. It boots from a raw HDD image, runs entirely from RAM, and exposes a single SSH service on port 22 (configurable). All cryptographic operations — hashing, encryption, signing, key exchange — are performed by hand-rolled implementations with no external libraries.

### Key Features

- **Password/secret vault** with private and shared vaults
- **SSH remote access** via Dropbear (production) with hybrid X25519 + ML-KEM-768 key exchange
- **Three-tier user model**: SUPERADMIN (admin), TIER2 (vault manager), TIER1 (basic user)
- **Argon2id password hashing** (256 MB, t=3) providing ~1-3s/hash on modern hardware
- **AES-256-GCM-SIV** at-rest encryption with key commitment (nonce-misuse resistant)
- **Verified boot**: SHA-256 + Ed25519 offline signing chain
- **TPM 2.0** measured boot (PCR1: stage2, PCR8: kernel) + RNG seeding
- **Secure update** via TFTP with Ed25519 verification
- **Firewall** with per-IP blocking, rate limiting, and audit logging
- **TOTP/HOTP 2FA** per user (optional)
- **Hardware token** support (optional)
- **Recovery console** (physical access required)

---

## 2. Deployment

### 2.1 Hardware Requirements

| Component | Minimum | Recommended |
|---|---|---|
| CPU | x86 (Pentium-class or later) | x86-64 with RDRAND and AES-NI |
| RAM | 512 MB | 1024 MB |
| Disk | 2 MB (HDD image) | 4 GB (for vault data) |
| Network | Any supported NIC | e1000 or RTL8139 |
| TPM | Optional | TPM 2.0 for measured boot |

### 2.2 Build Profiles

| Profile | Command | Use Case |
|---|---|---|
| dev | `make dev` | VM testing, unattended |
| dev-remote | `make dev-remote` | VM testing with SSH |
| prod-local | `make prod-local` | Production (no remote access) |
| prod-remote | `make prod-remote` | **Production with SSH (recommended)** |

The production build (`prod-remote`) enables:
- Full Argon2id (256 MB, t=3) — ~1-3s per hash on real hardware
- Ed25519 offline signing for boot verification
- Entropy policy 2 (fail-closed: no RDRAND = no boot)
- Dropbear SSH backend (custom SSH backend disabled)
- No dev-mode progress dots or debug output

### 2.3 Creating a Bootable Image

```bash
# Production build with SSH
make prod-remote
# Package as HDD image
make hdd
```

Output: `build/briggs.img` (2 MB raw HDD image)

### 2.4 Booting

**QEMU**:
```bash
qemu-system-i386 -drive file=build/briggs.img,format=raw \
    -m 512M -no-reboot -serial stdio -monitor none \
    -display none -cpu qemu64,rdrand=on \
    -net nic,model=e1000 -net user,hostfwd=tcp::2222-:22
```

**VirtualBox**: Create a new VM → Type: "Other", Version: "DOS". Attach briggs.img as an IDE Primary Master. Boot order: Hard Disk first. NIC: PCnet-FAST III (or e1000).

**Bare Metal**: Write briggs.img to a disk:
```bash
# Linux
dd if=build/briggs.img of=/dev/sdX bs=512 conv=fsync
# Windows
dd if=briggs.img of=\\.\PhysicalDriveX bs=512 --progress
```

---

## 3. First Boot — Setup Wizard

On first boot, the system presents a VGA-based setup wizard. A PS/2 keyboard is required (USB keyboards are not supported in the 32-bit boot path).

### Setup Steps

1. **Admin password**: Enter the SUPERADMIN password. Minimum strength 5/7 (must include uppercase, lowercase, digit, special character, ≥12 chars).

2. **Network configuration**:
   - `dhcp` or blank → DHCP (recommended for QEMU user-mode)
   - Static IP → enter IP, netmask (default 255.255.255.0), gateway, DNS

3. **Remote admin port**: Default 22. Change only if port forwarding requirements dictate otherwise.

4. **Recovery passphrase**: Emergency access passphrase for the physical recovery console. Store this in a sealed envelope.

5. **Hint**: Optional hint for the recovery passphrase (not secret — visible in recovery menu).

After setup, the system runs crypto self-tests (SHA-256, HMAC-SHA256, AES-256, AES-256-GCM, ChaCha20-Poly1305, AES-256-GCM-SIV, ML-KEM-768, Ed25519). If all pass, the Dropbear SSH server starts and the boot completes with `PASSED`.

---

## 4. Connecting via SSH

### 4.1 Client Configuration

```bash
ssh -p 2222 <username>@<server-ip>
```

**Important SSH options**:
- `-o PreferredAuthentications=password` (password auth is the default transport)
- `-o HostKeyAlgorithms=ssh-ed25519` (server uses Ed25519 host key)

### 4.2 SSH Host Key Verification

On first connection, verify the server's Ed25519 host key fingerprint:
```bash
ssh-keyscan -p 2222 <server-ip> | ssh-keygen -lf -
```

The host key is generated on first boot and stored encrypted on disk. If the disk is replaced, the host key changes — treat this as a potential man-in-the-middle signal.

### 4.3 Login Flow

```
Username: admin
Password: [enter password]
```

On successful authentication, the vault picker appears:
```
  [0] My Vault  (private)
  Enter number to open, or 'logout':
```

Type `0` to enter the private vault shell (`vault>`).

---

## 5. User Roles and Permissions

Three tiers of users, from most to least privileged:

| Role | Type | Created By | Capabilities |
|---|---|---|---|
| **SUPERADMIN** | Built-in (admin) | Setup wizard | Full system administration: user management, admin panel, firewall, audit, updates, all vault operations |
| **TIER2** | `add2 <user>` | SUPERADMIN | All vault operations PLUS shared vault creation/granting/revocation |
| **TIER1** | `add1 <user>` | SUPERADMIN | Private vault operations, shared vault viewing with granted access |

---

## 6. Command Reference

### 6.1 Vault Shell (`vault>`)

Basic vault commands (available to all users):

| Command | Description |
|---|---|
| `list` | List all records in private vault |
| `find <query>` | Search records by site/username |
| `add` | Add new vault record (interactive prompts) |
| `show <#>` | Show full details of record # (1-based) |
| `edit <#>` | Edit record # (leave blank to keep current) |
| `del <#>` | Delete record # (requires "yes" confirmation) |
| `genpw` | Generate random 24-char password |
| `prevpw <#>` | Show previous password for record # |
| `chpw` | Change own login password |
| `totp` | Toggle TOTP 2FA authenticator |
| `hwtoken` | Toggle hardware token 2FA |
| `pubkey` | Enroll SSH Ed25519 public key |
| `sysinfo` | Display system information |
| `save` | Save vault + database to disk |
| `logout` | Save and disconnect |
| `help` or `?` | Show command summary |

Shared vault commands (all users can list/view; TIER2+ can manage):

| Command | Description |
|---|---|
| `svlist` | List shared vaults I belong to |
| `svopen <id>` | Open shared vault by number |
| `svclose` | Close open shared vault |
| `svshow <#>` | Show record from open shared vault |
| `svadd` | Add record to open shared vault |
| `svdel <#>` | Delete record from open shared vault |
| `svcreate <name>` | Create new shared vault (TIER2+) |
| `svgrant <id> <user>` | Grant access to vault (TIER2+, owner) |
| `svrevoke <id> <user>` | Revoke access to vault (TIER2+, owner) |

SUPERADMIN-only vault commands:

| Command | Description |
|---|---|
| `admin` | Enter admin panel |
| `netmon` | Enter network monitor |
| `audit` | Dump HMAC-chained audit log |
| `rtc [timestamp]` | Show/set RTC clock |

### 6.2 Admin Panel (`admin>`)

| Command | Description |
|---|---|
| `list` | List all user accounts |
| `add1 <user>` | Create TIER1 user |
| `add2 <user>` | Create TIER2 user |
| `del <n>` | Delete user at index n |
| `lock <n>` | Lock user account |
| `unlock <n>` | Unlock user account |
| `resetpw <n>` | Reset user password (DESTROYS their vault records) |
| `update <sub>` | System update management |
| `wipe` | Wipe all data and reboot |
| `back` | Return to vault shell |

### 6.3 Network Monitor (`netmon>`)

| Command | Description |
|---|---|
| `log` | Show last 30 network events |
| `rules` | Show firewall ACL rules |
| `block` | Add firewall block rule |
| `unblock` | Remove firewall rule |
| `verify` | Verify audit log HMAC chain |
| `back` | Return to vault shell |

### 6.4 Update Commands (`update <sub>` from admin)

| Subcommand | Description |
|---|---|
| `update status` | Check for pending update |
| `update download <url>` | Download update via TFTP |
| `update verify` | Verify update package |
| `update apply` | Apply update (Ed25519-signed) |
| `update rollback` | Rollback to previous kernel |

### 6.5 Recovery Console (physical VGA, hold 'R' at boot)

| Command | Description |
|---|---|
| `integrity_check` | Verify audit log integrity |
| `db_status` | Database metadata |
| `unlock <user>` | Unlock locked account |
| `resetpw <user>` | Reset password (DESTROYS vault records) |
| `chrecovery` | Change recovery passphrase |
| `reboot` | Warm reboot |
| `exit` | Return to normal boot |

---

## 7. Password Policies

- Minimum length: 8 characters
- Required character classes: uppercase, lowercase, digit, special
- Strength scoring: 0-7 (minimum 5/7 for account passwords, 4/7 for recovery)
- Failed login lockout: 10 attempts → account locked; unlock via admin panel or recovery console
- Password reset destroys all vault records for that user (vault is encrypted with a key derived from the password)

---

## 8. Vault Encryption

### 8.1 At-Rest Encryption

All vault records are encrypted with **AES-256-GCM-SIV** (RFC 8452) with **key commitment**:

```
On disk layout:
  [0..31]           HMAC-SHA256 key commitment
  [32..32+len-1]    GCM-SIV ciphertext
  [32+len..32+len+15]  GCM-SIV authentication tag
```

Key commitment prevents the "invisible salamanders" attack where a single ciphertext authenticates under two different keys. Each record also has a unique random nonce.

### 8.2 Key Derivation

Vault encryption keys are derived from the user's password via **Argon2id** (RFC 9106):
- Memory: 256 MB (262,144 blocks of 1 KB)
- Time: 3 passes
- Parallelism: 1 lane
- Output: 256-bit encryption key

On modern x86 hardware, this takes 1-3 seconds per hash. In QEMU emulation, expect 10-30 seconds.

### 8.3 Anti-Rollback

Each vault save increments a sequence counter. The system rejects attempts to load an older version of the vault (replay attack protection).

---

## 9. Session Management

- **Idle timeout**: 240 seconds of inactivity → session ends, secrets wiped
- **Max sessions per IP**: 2 concurrent sessions from the same IP address
- **Session cleanup**: RST or FIN from the client triggers immediate cleanup
- **Disconnect behavior**: On logout or disconnect, all vault data is zeroed from memory

---

## 10. Network Security

### 10.1 Firewall

The built-in firewall supports ACL rules:
- Block by source IP and subnet mask
- Block by destination port
- HMAC-SHA256 chained event log (tamper-evident)

### 10.2 SSH Security

- Server: Ed25519 host key (generated on first boot)
- Key exchange: hybrid X25519 + ML-KEM-768 (post-quantum secure)
- Encryption: AES-256-GCM with sequence-number nonces
- No root login over SSH (SUPERADMIN account only)
- Rate limiting: implicit via Argon2id cost (~1-3s per auth attempt)

### 10.3 Audit Log

All security-relevant events (logins, failures, admin actions, network blocks) are recorded in an HMAC-chained audit log. Each entry contains:
- Event type and timestamp (Unix time from CMOS RTC)
- HMAC-SHA256(prev_entry_hash || event_data || key)
- Integrity verification via `audit` (vault shell) or `verify` (netmon)

---

## 11. Recovery Procedures

### 11.1 Forgot Admin Password

Physical access to the server is required:
1. Connect VGA monitor and PS/2 keyboard
2. Reboot and hold the 'R' key during boot
3. Enter the recovery passphrase (set during first boot)
4. The recovery shell (`recovery>`) offers:
   - `resetpw <user>` — reset password (WARNING: destroys all vault records for that user)
   - `unlock <user>` — unlock a locked account (does not destroy data)

### 11.2 Unlocking a User Account

Via admin panel (if SUPERADMIN can still log in):
```
admin> unlock <index>
```

Via recovery console (if SUPERADMIN is also locked):
```
recovery> unlock admin
```

### 11.3 System Update

1. Build the update package from the development machine:
```bash
python3 tools/make_update.py --write-hdd build/briggs.img
```
2. Transfer to a TFTP server reachable by the Briggs OS server
3. From the admin shell:
```
admin> update download tftp://<tftp-server>/<path-to-update>
admin> update verify    (confirms Ed25519 signature)
admin> update apply     (applies the update)
admin> reboot
```

### 11.4 Full System Wipe

```
admin> wipe
```
Type `WIPEALL` to confirm. This securely zeroes all vault data, user accounts, and audit logs from disk, then reboots. The system will re-enter the first-run setup wizard.

---

## 12. Monitoring

### 12.1 Serial Console

Connect to the serial console to observe boot-time diagnostics and kernel messages:
```bash
# QEMU: serial output via -serial stdio
# Bare metal: connect to serial port (115200 baud, 8N1)
```

### 12.2 Audit Log Export

The HMAC-chained audit log can be read via the `audit` command in the vault shell (SUPERADMIN only). Each entry includes a verification HMAC — any tampering is detectable via `netmon > verify`.

### 12.3 Network Monitor

The `netmon` shell provides real-time firewall and network event visibility:
```
netmon> log    # Last 30 events
netmon> rules  # Active block rules
```

---

## 13. Backup and Restore

### 13.1 What to Back Up

The entire disk image contains:
- Boot sectors (MBR, stage2) — public, can be regenerated
- Kernel binary — signed, can be regenerated
- BriggsDB (user accounts, shared vault metadata, audit log) — encrypted
- Encrypted vault records — encrypted per user

### 13.2 Backup Procedure

Periodically copy the full disk:
```bash
dd if=/dev/sdX of=briggs-backup-$(date +%Y%m%d).img bs=4M conv=fsync
```

### 13.3 Restore

Write the backup image to a new disk and boot. The system state (users, vaults, audit log) will be restored exactly as at backup time.

### 13.4 What Cannot Be Restored

- **User vault records**: If a user's password is reset, their vault records are permanently destroyed (encrypted with a key derived from the password).
- **SSH host key**: Generated on first boot; stored encrypted on disk. A full restore from backup preserves it.

---

## 14. Troubleshooting

| Symptom | Likely Cause | Resolution |
|---|---|---|
| "RDRAND not available — system halted" | CPU lacks RDRAND instruction | Use different CPU (Intel Ivy Bridge+ / AMD Jaguar+) |
| "No response from network" | DHCP failed or unsupported NIC | Check NIC model; use e1000 or RTL8139 |
| "SSH connection refused" | Dropbear not started yet | Wait for crypto self-tests to complete (~30-60s on first boot) |
| "Password accepted but no vault" | Login succeeds but vault_picker blocks | Check Argon2id is running; may take 10-30s in QEMU |
| "Connection closed immediately" | Session rejected (cap hit, firewall) | Check max sessions per IP (2); check firewall rules |
| "Admin password works but cannot run admin" | Wrong user (admin is SUPERADMIN; other users are TIER1/TIER2) | Verify you logged in as `admin` |
| "WARNING: Could not find MOV ECX sentinel" | Stage2 built without sentinel | Non-critical; kernel boots correctly |
| "QEMU boots but no serial output" | Missing `-serial stdio` or `-display none` | Add `-serial stdio` to QEMU command |
| "Update verify fails" | Signature mismatch or wrong update package | Ensure update was built from same Ed25519 keypair |

---

## 15. Technical Specifications

| Parameter | Value |
|---|---|
| Kernel size (prod-remote) | ~404 KB |
| Disk image size | 2 MB (raw HDD) |
| RAM usage (system) | ~4 MB + vault data |
| RAM usage (Argon2id) | 256 MB (temporary, freed after hash) |
| Max users | 10 |
| Max vault records per user | 100 |
| Max shared vaults | 10 |
| Max sessions per IP | 2 |
| Session idle timeout | 240 seconds |
| Password hash time (HW) | 1-3 seconds |
| Password hash time (QEMU) | 10-30 seconds |
| Supported NICs | e1000, RTL8139, VirtIO-Net |
| TPM version | 2.0 |

---

## 16. Cryptographic Standards Compliance

| Standard | Implementation | Status |
|---|---|---|
| FIPS 180-4 (SHA-256/512) | kernel_crypto.c | Verified via KAT |
| FIPS 197 (AES-256) | kernel_crypto.c | Verified via KAT |
| NIST SP 800-38D (AES-GCM) | kernel_crypto.c | Verified via KAT |
| RFC 8452 (AES-GCM-SIV) | kernel_crypto.c | Verified via KAT |
| RFC 8439 (ChaCha20-Poly1305) | kernel_crypto.c | Verified via KAT |
| RFC 9106 (Argon2id) | kernel_crypto_argon2.c | RFC-compliant J1/J2 selection |
| RFC 8032 (Ed25519) | kernel_ed25519_ref10.c | Verified via self-test |
| FIPS 203 (ML-KEM-768) | kernel_mlkem.c | Verified via KAT |

---

## 17. Quick Reference Card

```
Login:           ssh -p 22 <user>@<host>
Vault shell:     list | add | show <#> | edit <#> | del <#>
                 genpw | chpw | totp | help | logout
Shared vaults:   svlist | svopen <id> | svadd | svclose
                 svcreate <name> (TIER2+)
Admin panel:     admin (SUPERADMIN only)
                 add1/add2 <user> | list | lock/unlock <n> | del <n>
Recovery:        Hold 'R' at boot → recovery passphrase
                 unlock | resetpw | reboot
Firewall:        netmon → block | unblock | log | rules
Updates:         admin → update download/verify/apply/rollback
System info:     sysinfo
```
