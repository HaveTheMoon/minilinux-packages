# MiniLinux Packages

Official `x86_64` binary packages for **MiniLinux Next** and its `minipkg` package manager. Every `.mlpkg` is a `tar.xz` archive containing `meta.json` and a root filesystem tree. The `x86_64/index.json` file publishes package names, dependency information, archive file names, and SHA-256 checksums that `minipkg` verifies before installation.

## Configure minipkg

MiniLinux Next already uses this repository. To configure it manually or refresh an existing installation:

```sh
printf '%s\n' 'https://raw.githubusercontent.com/HaveTheMoon/minilinux-packages/main/x86_64' > /etc/minipkg/repositories
minipkg update
```

`minipkg` resolves and installs declared dependencies automatically. For example, installing `gxx` also installs the required C compiler, binutils, and C development files.

```sh
minipkg install gxx make pkg-config
printf '#include <iostream>\nint main(){std::cout << "MiniLinux";}\n' > hello.cpp
g++ hello.cpp -o hello && ./hello

minipkg install python3 git
```

## Available packages

| Package | Version | Notes |
| --- | --- | --- |
| `binutils` | 2.42 | GNU assembler, linker, and binary utilities required by native compilation. |
| `libc-dev` | 2.39 | C library headers, startup objects, development linker scripts, and vector-math runtime used by the compiler. |
| `gcc` | 13.3.0 | GNU C compiler with the x86_64 compiler runtime. Depends on `binutils` and `libc-dev`. |
| `gxx` | 13.3.0 | GNU C++ compiler driver, standard headers, and runtime libraries. Depends on `gcc`. |
| `make` | 4.3 | Build automation utility. |
| `pkg-config` | 1.8.1 | Metadata query tool used by many source builds. |
| `python3` | 3.12.3 | CPython interpreter and standard library. |
| `git` | 2.43.0 | Distributed version-control client; depends on `curl`. |
| `fastfetch` | 2.67.1 | Upstream Linux x86_64 release with the MiniLinux monitor logo. |
| `neofetch` | 7.1.0 | Upstream Bash system-information script with the MiniLinux monitor logo. |
| `sudo` | 1.9.15p5 | Privilege delegation for root and members of the `sudo` group; installation does not grant privileges automatically. |
| `curl` | 8.5.0 | Command-line HTTP, HTTPS, and other protocol client. |
| `nano` | 7.2 | Small terminal text editor. |
| `htop` | 3.3.0 | Interactive process and resource viewer. |
| `less` | 590 | Terminal pager for long files and command output. |
| `file` | 5.45 | Utility that identifies file types using the bundled magic database. |
| `zip` | 3.0 | ZIP archive creator. |
| `unzip` | 6.0 | ZIP archive extractor. |

## Package integrity

`minipkg install` downloads an archive only after obtaining its record from `index.json`, then checks its SHA-256 checksum before extraction. The repository workflow repeats this verification whenever the package tree or index changes.

## Controlled package automation

The `automation/` directory contains the reviewed MiniLinux recipe set and its
portable build/test tools. In the **Actions** tab, choose **Build and publish
MiniLinux packages** and select **Run workflow**. The workflow validates every
recipe, rebuilds the priority set on Ubuntu 24.04, installs the resulting
packages in a clean MiniLinux rootfs, verifies archive checksums, then updates
the repository only when all checks pass.

| Input | Result |
| --- | --- |
| `publish: true` | Commit verified archives and the merged `index.json` to `main`. |
| `publish: false` | Do not change `main`; upload the tested package output as a workflow artifact. |
| `update_mode: outdated` | Add missing packages and replace only packages whose version changed. |
| `update_mode: rebuild_all` | Publish freshly rebuilt copies of every package in the selected priority set. |

Existing archives remain in the repository unless a new verified version of the
same package is selected for publication. `index.json` is switched only after
its full set of listed archives passes SHA-256 verification.

## Upstream projects

Fastfetch is distributed upstream under the MIT License by [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch). Neofetch is distributed upstream under the MIT License by [dylanaraps/neofetch](https://github.com/dylanaraps/neofetch). This repository repackages those artifacts for MiniLinux; it does not claim ownership of either upstream project.
