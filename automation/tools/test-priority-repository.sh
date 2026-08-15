#!/bin/sh
# Install and smoke-test the full priority repository in a clean MiniLinux rootfs.
set -eu

export LANG=C.utf8 LC_ALL=C.utf8 LANGUAGE=C.utf8

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REPO=${1:-"$ROOT/build/package-staging/x86_64"}
TESTROOT="$ROOT/build/priority-repository-test-rootfs"
RECIPE_PACKAGES=$(awk -F '\t' 'NR > 1 && $1 !~ /^#/ { print $2 }' "$ROOT/recipes/priority.tsv" | tr '\n' ' ')
BASE_PACKAGES='fastfetch neofetch sudo curl nano htop less file zip unzip'

[ -f "$REPO/index.json" ] || { echo "test-priority-repository: missing $REPO/index.json" >&2; exit 1; }
sudo umount -l "$TESTROOT/proc" 2>/dev/null || true
sudo rm -rf "$TESTROOT"
sudo mkdir -p "$TESTROOT/bin" "$TESTROOT/usr/bin" "$TESTROOT/etc/minipkg" "$TESTROOT/opt/minilinux/staging-repo" "$TESTROOT/dev" "$TESTROOT/proc" "$TESTROOT/tmp"
sudo chmod 1777 "$TESTROOT/tmp"
sudo mknod -m 666 "$TESTROOT/dev/null" c 1 3
sudo install -m 0755 /bin/busybox "$TESTROOT/bin/busybox"
for APPLET in sh tar sha256sum mktemp grep awk sed head cp mkdir rm find; do
    sudo ln -s busybox "$TESTROOT/bin/$APPLET"
done
printf '%s\n' 'root:x:0:0:root:/root:/bin/sh' | sudo tee "$TESTROOT/etc/passwd" >/dev/null
printf '%s\n' 'root:x:0:' | sudo tee "$TESTROOT/etc/group" >/dev/null
sudo mkdir -p "$TESTROOT/root"
sudo install -m 0755 "$ROOT/tools/minipkg" "$TESTROOT/bin/minipkg"
sudo mount --bind /proc "$TESTROOT/proc"
cleanup() { sudo umount "$TESTROOT/proc" 2>/dev/null || true; }
trap cleanup EXIT INT TERM
printf '%s\n' 'file:///opt/minilinux/staging-repo' | sudo tee "$TESTROOT/etc/minipkg/repositories" >/dev/null
sudo cp -a "$REPO/." "$TESTROOT/opt/minilinux/staging-repo/"

sudo chroot "$TESTROOT" /bin/minipkg update
sudo chroot "$TESTROOT" /bin/minipkg install $RECIPE_PACKAGES
sudo chroot "$TESTROOT" /bin/minipkg install $BASE_PACKAGES
sudo chroot "$TESTROOT" /usr/bin/gcc --version | head -n 1
sudo chroot "$TESTROOT" /usr/bin/g++ --version | head -n 1
sudo chroot "$TESTROOT" /usr/bin/python3 -c 'import sys; assert sys.version_info.major == 3; print(sys.version)'
sudo chroot "$TESTROOT" /usr/bin/git --version
sudo chroot "$TESTROOT" /bin/sh -c 'printf "#include <stdio.h>\nint main(void){puts(\"MiniLinux toolchain OK\");}\n" >/tmp/hello.c && gcc /tmp/hello.c -o /tmp/hello && /tmp/hello'
sudo chroot "$TESTROOT" /bin/sh -c 'printf "#include <iostream>\nint main(){std::cout << \"MiniLinux C++ OK\";}\n" >/tmp/hello.cpp && g++ /tmp/hello.cpp -o /tmp/hello-cpp && /tmp/hello-cpp'
while IFS= read -r COMMAND; do
    [ -n "$COMMAND" ] || continue
    sudo chroot "$TESTROOT" /bin/sh -c "$COMMAND"
done <<'EOF'
/usr/bin/bash --version
/usr/bin/patch --version
/usr/bin/cmake --version
/usr/bin/ninja --version
/usr/bin/meson --version
/usr/bin/perl -v
/usr/bin/gdb --version
/usr/bin/strace --version
/usr/bin/ltrace --version
/usr/bin/valgrind --version
/usr/bin/bzip2 --version
/usr/bin/xz --version
/usr/bin/zstd --version
/usr/bin/7z
/usr/bin/tar --version
/usr/bin/gzip --version
/usr/bin/wget --version
/usr/bin/rsync --version
/usr/bin/ssh -V
/usr/bin/nmap --version
/bin/ip -Version
/usr/bin/ping -V
/bin/netstat --version
/usr/bin/traceroute --version
/usr/bin/dig -v
/usr/bin/whois --version
/usr/bin/jq --version
/usr/bin/tree --version
/usr/bin/lsof -v
/usr/bin/bc --version
/usr/bin/tmux -V
/usr/bin/screen --version
EOF
printf 'Full 50-package priority repository test passed.\n'
