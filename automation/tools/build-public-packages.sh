#!/bin/sh
# Build the public MiniLinux x86_64 binary package repository.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-"$ROOT/packages-public/x86_64"}
case "$OUT" in /*) ;; *) OUT="$ROOT/$OUT";; esac
WORK="$ROOT/build/public-packages"
ARCH=x86_64
FASTFETCH_VERSION=2.67.1
NEOFETCH_VERSION=7.1.0
FASTFETCH_URL="https://github.com/fastfetch-cli/fastfetch/releases/download/$FASTFETCH_VERSION/fastfetch-linux-amd64.tar.gz"
FASTFETCH_SHA256=adc8a9eb64eccef267e50bb1e6f9a767bb608da5ee4a3b652ef36a10d9105d4d
NEOFETCH_URL="https://raw.githubusercontent.com/dylanaraps/neofetch/$NEOFETCH_VERSION/neofetch"

die() { echo "build-public-packages: $*" >&2; exit 1; }
copy_item() {
    SOURCE=$1
    DESTROOT=$2
    [ -e "$SOURCE" ] || die "missing host item: $SOURCE"
    DEST="$DESTROOT$SOURCE"
    mkdir -p "$(dirname "$DEST")"
    cp -aL "$SOURCE" "$DEST"
}
copy_elf() {
    OBJECT=$1
    DESTROOT=$2
    copy_item "$OBJECT" "$DESTROOT"
    ldd "$OBJECT" 2>/dev/null | awk '/=> \/[^ ]+/ { print $3 } /^[[:space:]]*\// { print $1 }' | while IFS= read -r LIBRARY; do
        [ -n "$LIBRARY" ] && copy_item "$LIBRARY" "$DESTROOT"
    done
}
copy_binary() {
    BINARY=$1
    DESTROOT=$2
    [ -x "$BINARY" ] || die "missing executable: $BINARY"
    copy_elf "$BINARY" "$DESTROOT"
}
package_archive() {
    NAME=$1
    VERSION=$2
    DESCRIPTION=$3
    STAGE=$4
    PKGWORK="$WORK/$NAME"
    ARCHIVE="$OUT/$NAME-$VERSION-$ARCH.mlpkg"
    rm -rf "$PKGWORK"
    mkdir -p "$PKGWORK/root"
    cp -a "$STAGE/." "$PKGWORK/root/"
    printf '{"format":1,"name":"%s","version":"%s","architecture":"%s","description":"%s","dependencies":""}\n' \
        "$NAME" "$VERSION" "$ARCH" "$DESCRIPTION" > "$PKGWORK/meta.json"
    (cd "$PKGWORK" && tar --owner=0 --group=0 -cJf "$ARCHIVE" meta.json root)
}
public_version() {
    dpkg-query -W -f='${Version}' "$1" 2>/dev/null |
        sed 's/^[0-9]*://; s/.*+really//; s/-.*$//; s@/@_@g'
}
build_host_binary_package() {
    NAME=$1
    DEB=$2
    BINARY=$3
    DESCRIPTION=$4
    STAGE="$WORK/$NAME-root"
    mkdir -p "$STAGE"
    copy_binary "$BINARY" "$STAGE"
    package_archive "$NAME" "$(public_version "$DEB")" "$DESCRIPTION" "$STAGE"
}

rm -rf "$WORK" "$OUT"
mkdir -p "$WORK/downloads" "$OUT" "$WORK/fastfetch-root" "$WORK/neofetch-root"

# Fastfetch is published by its upstream project. Verify the published archive
# checksum before it is repackaged for MiniLinux.
curl -fL --retry 3 -o "$WORK/downloads/fastfetch.tar.gz" "$FASTFETCH_URL"
printf '%s  %s\n' "$FASTFETCH_SHA256" "$WORK/downloads/fastfetch.tar.gz" | sha256sum -c - >/dev/null || die "official fastfetch archive checksum mismatch"
tar -xzf "$WORK/downloads/fastfetch.tar.gz" -C "$WORK/downloads"
FASTFETCH_BIN=$(find "$WORK/downloads" -type f -name fastfetch -perm -u+x | head -n 1)
[ -n "$FASTFETCH_BIN" ] || die "fastfetch binary not found in official archive"
mkdir -p "$WORK/fastfetch-root/usr/bin" "$WORK/fastfetch-root/usr/share/minilinux/fastfetch"
copy_binary "$FASTFETCH_BIN" "$WORK/fastfetch-root"
mv "$WORK/fastfetch-root$FASTFETCH_BIN" "$WORK/fastfetch-root/usr/bin/fastfetch.bin"
cat > "$WORK/fastfetch-root/usr/bin/fastfetch" <<'EOF'
#!/bin/sh
exec /usr/bin/fastfetch.bin --logo /usr/share/minilinux/fastfetch/logo.txt "$@"
EOF
chmod 755 "$WORK/fastfetch-root/usr/bin/fastfetch"
{
    printf '  \033[32m╔══════════════╗\033[0m\n'
    printf '  \033[32m║\033[0m  \033[1;97m┌────────┐\033[0m  \033[32m║\033[0m\n'
    printf '  \033[32m║\033[0m  \033[1;97m│  >_    │\033[0m  \033[32m║\033[0m\n'
    printf '  \033[32m║\033[0m  \033[1;97m└────────┘\033[0m  \033[32m║\033[0m\n'
    printf '  \033[32m╚══════════════╝\033[0m\n'
} > "$WORK/fastfetch-root/usr/share/minilinux/fastfetch/logo.txt"
package_archive fastfetch "$FASTFETCH_VERSION" "Fast system information tool with MiniLinux logo" "$WORK/fastfetch-root"

# Neofetch is an upstream Bash script; package the interpreter it requires.
mkdir -p "$WORK/neofetch-root/usr/bin"
curl -fL --retry 3 -o "$WORK/neofetch-root/usr/bin/neofetch" "$NEOFETCH_URL"
sed -i '1s|^#!.*|#!/usr/bin/bash|' "$WORK/neofetch-root/usr/bin/neofetch"
chmod 755 "$WORK/neofetch-root/usr/bin/neofetch"
copy_binary /usr/bin/bash "$WORK/neofetch-root"
mkdir -p "$WORK/neofetch-root/usr/share/minilinux/neofetch"
cp "$WORK/fastfetch-root/usr/share/minilinux/fastfetch/logo.txt" "$WORK/neofetch-root/usr/share/minilinux/neofetch/logo.txt"
package_archive neofetch "$NEOFETCH_VERSION" "Bash system information tool with MiniLinux logo" "$WORK/neofetch-root"

# Eight practical base programs. Each package contains the executable and all
# dynamic libraries reported by ldd, so minipkg can install it on clean images.
build_host_binary_package curl curl /usr/bin/curl "Command-line data transfer tool"
build_host_binary_package nano nano /usr/bin/nano "Simple terminal text editor"
build_host_binary_package htop htop /usr/bin/htop "Interactive process viewer"
build_host_binary_package less less /usr/bin/less "Terminal pager"
build_host_binary_package zip zip /usr/bin/zip "ZIP archive creator"
build_host_binary_package unzip unzip /usr/bin/unzip "ZIP archive extractor"

# file additionally needs libmagic's compiled database.
FILE_STAGE="$WORK/file-root"
mkdir -p "$FILE_STAGE"
copy_binary /usr/bin/file "$FILE_STAGE"
copy_item /usr/share/misc/magic.mgc "$FILE_STAGE"
package_archive file "$(public_version file)" "File type identification utility" "$FILE_STAGE"

# sudo needs its policy plugin, PAM authentication module, and conservative
# defaults. The package does not add users to the sudo group automatically.
SUDO_STAGE="$WORK/sudo-root"
mkdir -p "$SUDO_STAGE"
copy_binary /usr/bin/sudo "$SUDO_STAGE"
for ITEM in /usr/libexec/sudo/*.so /usr/libexec/sudo/libsudo_util.so* /usr/lib/x86_64-linux-gnu/security/pam_unix.so; do
    [ -e "$ITEM" ] || continue
    copy_elf "$ITEM" "$SUDO_STAGE"
done
mkdir -p "$SUDO_STAGE/etc/pam.d" "$SUDO_STAGE/etc/sudoers.d"
cat > "$SUDO_STAGE/etc/pam.d/sudo" <<'EOF'
auth    required pam_unix.so
account required pam_unix.so
session required pam_unix.so
EOF
cat > "$SUDO_STAGE/etc/sudoers" <<'EOF'
Defaults env_reset
Defaults !fqdn
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
root ALL=(ALL:ALL) ALL
%sudo ALL=(ALL:ALL) ALL
EOF
chmod 440 "$SUDO_STAGE/etc/sudoers"
package_archive sudo "$(public_version sudo)" "Privilege delegation and command execution tool" "$SUDO_STAGE"

# Create a deterministic SHA-256 index from all generated archives.
{
    printf '{"format":1,"packages":[\n'
    FIRST=1
    for ARCHIVE in "$OUT"/*.mlpkg; do
        META=$(tar -xOJf "$ARCHIVE" meta.json)
        NAME=$(printf '%s' "$META" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
        VERSION=$(printf '%s' "$META" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')
        DESCRIPTION=$(printf '%s' "$META" | sed -n 's/.*"description":"\([^"]*\)".*/\1/p')
        HASH=$(sha256sum "$ARCHIVE" | awk '{print $1}')
        [ "$FIRST" -eq 1 ] || printf ',\n'
        FIRST=0
        printf '{"name":"%s","version":"%s","file":"%s","sha256":"%s","description":"%s","dependencies":""}' \
            "$NAME" "$VERSION" "$(basename "$ARCHIVE")" "$HASH" "$DESCRIPTION"
    done
    printf '\n]}\n'
} > "$OUT/index.json"

printf 'Built %s package(s) and %s\n' "$(find "$OUT" -maxdepth 1 -name '*.mlpkg' | wc -l)" "$OUT/index.json"
