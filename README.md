# MiniLinux Packages

Official `x86_64` binary packages for **MiniLinux Next** and its `minipkg` package manager. Every `.mlpkg` is a `tar.xz` archive containing a metadata file and a root filesystem tree; `x86_64/index.json` publishes the package file names and SHA-256 checksums that `minipkg` verifies before installation.

## Configure minipkg

On MiniLinux, set the repository URL and refresh the index:

```sh
printf '%s\n' 'https://raw.githubusercontent.com/DolcheMilk55/minilinux-packages/main/x86_64' > /etc/minipkg/repositories
minipkg update
```

Install one of the first packages:

```sh
minipkg install fastfetch
fastfetch

minipkg install neofetch
neofetch --ascii /usr/share/minilinux/neofetch/logo.txt
```

## Initial package set

| Package | Version | Notes |
| --- | --- | --- |
| `fastfetch` | 2.67.1 | Upstream Linux x86_64 release, verified against its upstream SHA-256; includes the MiniLinux monitor logo. |
| `neofetch` | 7.1.0 | Upstream Bash script with the minimal Bash runtime and the MiniLinux monitor logo. |

## Upstream projects

Fastfetch is distributed upstream under the MIT License by [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch). Neofetch is distributed upstream under the MIT License by [dylanaraps/neofetch](https://github.com/dylanaraps/neofetch). This repository repackages those artifacts for MiniLinux; it does not claim ownership of either upstream project.
