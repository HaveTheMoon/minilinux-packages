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

The repository currently provides **50 MiniLinux x86_64 packages**. The
canonical version, dependency, archive, and checksum records are maintained in
[`x86_64/index.json`](x86_64/index.json); package names deliberately remain
independent of the Ubuntu build-host revision.

| Package | Purpose |
| --- | --- |
| `7zip` | 7-Zip archive creation and extraction tools. |
| `bash` | GNU command shell and scripting runtime. |
| `bc` | Arbitrary-precision calculator language. |
| `binutils` | GNU assembler, linker, and binary utilities. |
| `bzip2` | Bzip2 compression and decompression tools. |
| `cmake` | Cross-platform build system generator. |
| `curl` | Command-line data transfer client. |
| `dnsutils` | DNS lookup and diagnostic utilities. |
| `fastfetch` | Fast system information tool with MiniLinux logo. |
| `file` | File type identification utility. |
| `gcc` | GNU C compiler with x86_64 runtime support. |
| `gdb` | GNU debugger for native programs. |
| `git` | Distributed version-control client. |
| `gxx` | GNU C++ compiler driver. |
| `gzip` | Gzip compression and decompression tools. |
| `htop` | Interactive process viewer. |
| `iproute2` | IP networking and traffic-control tools. |
| `iputils-ping` | ICMP network reachability tools. |
| `jq` | Command-line JSON processor. |
| `less` | Terminal pager. |
| `libc-dev` | C library headers and startup objects for native compilation. |
| `lsof` | Open files and sockets inspection utility. |
| `ltrace` | Library call tracing utility. |
| `make` | GNU build automation tool. |
| `meson` | Python-based modern build system. |
| `nano` | Simple terminal text editor. |
| `neofetch` | Bash system information tool with MiniLinux logo. |
| `net-tools` | Legacy network interface and routing utilities. |
| `ninja` | Fast incremental build executor. |
| `nmap` | Network discovery and security auditing utility. |
| `openssh-client` | OpenSSH remote access and file-transfer client. |
| `patch` | Source patch application utility. |
| `perl` | Perl interpreter and core scripting tools. |
| `pkg-config` | Compiler and linker flag metadata helper. |
| `python3` | Python interpreter and standard library. |
| `rsync` | Efficient local and remote file synchronization utility. |
| `screen` | Terminal multiplexer and session manager. |
| `strace` | System-call and signal tracing utility. |
| `sudo` | Privilege delegation and command execution tool. |
| `tar` | GNU tar archive utility. |
| `tmux` | Terminal multiplexer for persistent sessions. |
| `traceroute` | Network route tracing utility. |
| `tree` | Directory hierarchy display utility. |
| `unzip` | ZIP archive extractor. |
| `valgrind` | Memory debugging and profiling framework. |
| `wget` | Command-line HTTP and HTTPS download client. |
| `whois` | WHOIS lookup and password hash tools. |
| `xz` | XZ compression and decompression tools. |
| `zip` | ZIP archive creator. |
| `zstd` | Zstandard compression and decompression tools. |

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

### Current priority build plan

All 50 priority packages have been built and verified. The controlled workflow
continues to use `publish: false` for a dry-run artifact or `publish: true` and
`update_mode: outdated` to publish missing or newer verified packages.

## Upstream projects

Fastfetch is distributed upstream under the MIT License by [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch). Neofetch is distributed upstream under the MIT License by [dylanaraps/neofetch](https://github.com/dylanaraps/neofetch). This repository repackages those artifacts for MiniLinux; it does not claim ownership of either upstream project.
