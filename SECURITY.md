# Security Notes

This repository contains a bare-metal OS intended to protect high-value secrets. Treat changes as security-sensitive.

## Entropy

`rand_bytes()` is used for security-critical material. Systems without `RDRAND` must not silently ship with weak entropy.

Controls:

- `BRIGGS_ENTROPY_POLICY=0`: interactive seeding if `RDRAND` missing (default)
- `BRIGGS_ENTROPY_POLICY=1`: warn-only (development / unattended VM testing)
- `BRIGGS_ENTROPY_POLICY=2`: fail closed (recommended for production builds)

## Remote admin transport

The in-kernel custom SSH transport is experimental and should not be treated as
production-grade remote access.

Controls:

- Development builds may still expose the custom SSH backend for VM testing.
- `BRIGGS_BUILD_PROD=1` disables the experimental remote backend at runtime.
- The intended replacement is a standards-based backend behind the new
  `kernel_remote.c` seam rather than further expanding the handwritten SSH code.

## Third-party code

If vendoring third-party projects, do not ship their VCS metadata (e.g. `third_party/**/.git`).

## Reporting

If you’re using this privately, define an internal reporting channel and escalation path before deploying.
