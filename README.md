# PureC OS Test DIST

Live ISO of PureC OS with the graphical desktop and an installer, built from the kernel and packages of the parent repository.

## Build

    make [PARENT=path-to-PureC-OS]

The parent defaults to `..` and is only built, never modified. The script needs `make`, `xorriso`, `limine` and a python3 with `cryptography` (the system one is picked automatically). It:

1. builds the kernel, the programs and host `pkg` in the parent (`make kernel programs`);
2. rebuilds the core packages (`programs/PureC-OS-Core-Programs packages`);
3. collects every package from `profile/packages.txt` out of `Trusted/bin` (core packages are taken from the fresh `bin/core-repo`) into `staging/repo`;
4. installs them with host `pkg` into `staging/stage` (`scripts/stage.sh`, signatures are checked);
5. builds the ISO with `scripts/mkiso.sh` (`scripts/gen_assets.py` merges `profile/overlay` over the base image, `scripts/make_esp_image.sh` makes the ESP).

The result is `out/purec-test-dist.iso`. Local build files are in `staging/`.

## Contents

- `profile/packages.txt` - all packages of `Trusted/repository.conf`; curl comes from the parent `make programs`.
- `profile/overlay/` - files laid over the image: os-release, issue, motd, hostname, `/etc/init/default.target` = graphical.target, `desktop.service` that starts the desktop as root and a disabled `display-manager.service` (no login screen on the live system).
- `profile/overlay/etc/distro-packages` - package list the installer passes to `pkg -S` (online, from the registry).
- `profile/overlay/etc/live-files` - live-only files the installer removes from the installed system.

## Install

Run `installer` in the terminal of the live system (the live session is root). The kernel lays down the system from the image, then the installer fetches the distribution packages with `pkg` from the registry (network needed), deletes the live-only files and sets the default target. The user is created by the installer.

## Requirements in the parent repository

- `src/fs/initramfs.c`: room for more than 512 files in the initramfs.
- `src/fs/install.c`: manifest limit of 512 KiB.
- `programs/PureC-OS-Core-Programs/installer/main.c`: reads `/etc/distro-packages` and `/etc/live-files` when present.
