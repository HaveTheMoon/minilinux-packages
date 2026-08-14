# MiniLinux Packages

Official `x86_64` binary packages for **MiniLinux Next** and its `minipkg` package manager. Every `.mlpkg` is a `tar.xz` archive containing a metadata file and a root filesystem tree; `x86_64/index.json` publishes the package file names and SHA-256 checksums that `minipkg` verifies before installation.

## Configure minipkg

On MiniLinux, set the repository URL and refresh the index:

```sh
printf '%s\n' 'https://raw.githubusercontent.com/HaveTheMoon/minilinux-packages/main/x86_64' > /etc/minipkg/repositories
minipkg update
```

Install one of the first packages:

```sh
minipkg install fastfetch
fastfetch

minipkg install neofetch
neofetch --ascii /usr/share/minilinux/neofetch/logo.txt
```

## Available packages

| Package | Version | Notes |
| --- | --- | --- |
| `fastfetch` | 2.67.1 | Upstream Linux x86_64 release, verified against its upstream SHA-256; includes the MiniLinux monitor logo. |
| `neofetch` | 7.1.0 | Upstream Bash script with the minimal Bash runtime and the MiniLinux monitor logo. |
| `sudo` | 1.9.15p5 | Privilege delegation for root and members of the `sudo` group; installing it does not grant any user privileges automatically. |
| `curl` | 8.5.0 | Command-line HTTP, HTTPS and other protocol client. |
| `nano` | 7.2 | Small terminal text editor. |
| `htop` | 3.3.0 | Interactive process and resource viewer. |
| `less` | 590 | Terminal pager for long files and command output. |
| `file` | 5.45 | Utility that identifies file types using the bundled magic database. |
| `zip` | 3.0 | ZIP archive creator. |
| `unzip` | 6.0 | ZIP archive extractor. |

## Upstream projects

Fastfetch is distributed upstream under the MIT License by [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch). Neofetch is distributed upstream under the MIT License by [dylanaraps/neofetch](https://github.com/dylanaraps/neofetch). This repository repackages those artifacts for MiniLinux; it does not claim ownership of either upstream project.
