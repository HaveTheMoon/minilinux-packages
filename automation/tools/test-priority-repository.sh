#!/bin/sh
# Install the priority developer set in a self-contained clean MiniLinux rootfs.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REPO=${1:-"$ROOT/build/package-staging/x86_64"}
TESTROOT="$ROOT/build/priority-repository-test-rootfs"

[ -f "$REPO/index.json" ] || { echo "test-priority-repository: missing $REPO/index.json" >&2; exit 1; }
sudo rm -rf "$TESTROOT"
sudo mkdir -p "$TESTROOT/bin" "$TESTROOT/usr/bin" "$TESTROOT/etc/minipkg" "$TESTROOT/opt/minilinux/staging-repo" "$TESTROOT/dev" "$TESTROOT/tmp"
sudo chmod 1777 "$TESTROOT/tmp"
sudo mknod -m 666 "$TESTROOT/dev/null" c 1 3
sudo install -m 0755 /bin/busybox "$TESTROOT/bin/busybox"
for APPLET in sh tar sha256sum mktemp grep awk sed head cp mkdir rm find; do
    sudo ln -s busybox "$TESTROOT/bin/$APPLET"
done
sudo install -m 0755 "$ROOT/tools/minipkg" "$TESTROOT/bin/minipkg"
printf '%s\n' 'file:///opt/minilinux/staging-repo' | sudo tee "$TESTROOT/etc/minipkg/repositories" >/dev/null
sudo cp -a "$REPO/." "$TESTROOT/opt/minilinux/staging-repo/"

sudo chroot "$TESTROOT" /bin/minipkg update
sudo chroot "$TESTROOT" /bin/minipkg install gxx
sudo chroot "$TESTROOT" /bin/minipkg install make pkg-config python3 git
sudo chroot "$TESTROOT" /usr/bin/gcc --version | head -n 1
sudo chroot "$TESTROOT" /usr/bin/g++ --version | head -n 1
sudo chroot "$TESTROOT" /usr/bin/python3 -c 'import sys; assert sys.version_info.major == 3; print(sys.version)'
sudo chroot "$TESTROOT" /usr/bin/git --version
sudo chroot "$TESTROOT" /bin/sh -c 'printf "#include <stdio.h>\nint main(void){puts(\"MiniLinux toolchain OK\");}\n" >/tmp/hello.c && gcc /tmp/hello.c -o /tmp/hello && /tmp/hello'
sudo chroot "$TESTROOT" /bin/sh -c 'printf "#include <iostream>\nint main(){std::cout << \"MiniLinux C++ OK\";}\n" >/tmp/hello.cpp && g++ /tmp/hello.cpp -o /tmp/hello-cpp && /tmp/hello-cpp'
printf 'Priority repository test passed.\n'
