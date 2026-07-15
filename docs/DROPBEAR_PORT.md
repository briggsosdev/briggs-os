# Dropbear Port Plan

## Why this is staged

Briggs is a bare-metal kernel, not a POSIX userland:

- no libc / file-descriptor model
- no socket API in the Dropbear sense
- no process model
- vault/admin UX is coupled to the current in-kernel SSH session API

That means Dropbear cannot be treated as a simple source swap for
`kernel_ssh.c`.

## New seam

`kernel/kernel_remote.c` is the transport seam for remote admin.

Current backend:

- development: custom in-kernel SSH backend
- production: disabled by default

Target backend:

- Dropbear-backed remote transport

Repository support landed:

- `tools/fetch_dropbear.sh` can vendor an official Dropbear release into `third_party/dropbear`
- `tools/wsl_smoke_build.sh` provides deterministic dev/prod smoke builds in WSL

## Coupling points that must be adapted

Packet ingress:

- `kernel/Network/rtl8139.c` now dispatches to `remote_on_packet()`

Lifecycle:

- `kernel/kernel_main.c` now starts remote admin with `remote_init()`
- `kernel/kernel_main.c` now polls it with `remote_poll()`

Session/UI layer still coupled to SSH helpers:

- `ssh_readline()`
- `ssh_send_str()`
- `ssh_close()`
- `ssh_printf_uint()`
- `ssh_printf_hex()`

These are the next extraction targets before Dropbear can fully replace the
custom backend.

## Safe integration rules

- Keep Dropbear wire behavior standard
- Do not customize SSH packet/KEX/crypto internals
- Plug Briggs auth/role logic in after transport/session establishment
- Disable unused SSH features:
  - port forwarding
  - SCP/SFTP
  - agent forwarding
  - unused auth methods
- Keep Briggs vault crypto separate from transport crypto

## Status: COMPLETE (2026-05-03)

The Dropbear port is finished. The vault shell I/O was already transport-neutral
(`s_str()` / `s_ln()` / `s_printf()` call `remote_*()`).
