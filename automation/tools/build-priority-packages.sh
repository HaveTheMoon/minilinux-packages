#!/bin/sh
# Build a priority-ordered MiniLinux repository from trusted local recipes.
# Recipes are shell data files controlled by this source tree; do not accept
# untrusted recipes from downloads or pull requests without review.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-"$ROOT/build/package-staging/x86_64"}
WORK="$ROOT/build/priority-packages"
RECIPES="$ROOT/recipes"
ARCH=x86_64

die() { echo "build-priority-packages: $*" >&2; exit 1; }
host_version() { dpkg-query -W -f='${Version}' "$1" 2>/dev/null | sed 's/^[0-9]*://' | tr '/' '_'; }

copy_item() {
    SOURCE=$1 DESTROOT=$2
    [ -e "$SOURCE" ] || return 0
    mkdir -p "$DESTROOT$(dirname "$SOURCE")"
    cp -aL "$SOURCE" "$DESTROOT$SOURCE"
}
copy_elf() {
    OBJECT=$1 DESTROOT=$2
    copy_item "$OBJECT" "$DESTROOT"
    ldd "$OBJECT" 2>/dev/null | awk '/=> \/[^ ]+/ { print $3 } /^[[:space:]]*\// { print $1 }' | while IFS= read -r LIBRARY; do
        [ -n "$LIBRARY" ] && copy_item "$LIBRARY" "$DESTROOT"
    done
}
copy_path() {
    SOURCE=$1 DESTROOT=$2
    [ -e "$SOURCE" ] || return 0
    if [ -d "$SOURCE" ]; then
        mkdir -p "$DESTROOT$(dirname "$SOURCE")"
        # Preserve symlinks within large runtime trees. Dereferencing every
        # link breaks on optional development links that can be dangling on a
        # CI runner (for example, lldb's bundled LLVM links). Copy real targets
        # separately so absolute compiler links such as liblto_plugin resolve
        # in the packaged rootfs.
        cp -a "$SOURCE" "$DESTROOT$(dirname "$SOURCE")/"
        find "$SOURCE" -type l -print | while IFS= read -r LINK; do
            TARGET=$(readlink -f "$LINK" 2>/dev/null || true)
            [ -n "$TARGET" ] && [ -e "$TARGET" ] && copy_item "$TARGET" "$DESTROOT"
        done
        find "$SOURCE" -type f -perm -u+x -print | while IFS= read -r EXECUTABLE; do
            copy_elf "$EXECUTABLE" "$DESTROOT"
        done
    else
        if [ -x "$SOURCE" ]; then
            copy_elf "$SOURCE" "$DESTROOT"
        else
            copy_item "$SOURCE" "$DESTROOT"
        fi
    fi
}
package_archive() {
    NAME=$1 VERSION=$2 DESCRIPTION=$3 DEPENDENCIES=$4 STAGE=$5
    PKGWORK="$WORK/$NAME"
    ARCHIVE="$OUT/$NAME-$VERSION-$ARCH.mlpkg"
    rm -rf "$PKGWORK"
    mkdir -p "$PKGWORK/root"
    cp -a "$STAGE/." "$PKGWORK/root/"
    printf '{"format":1,"name":"%s","version":"%s","architecture":"%s","description":"%s","dependencies":"%s"}\n' \
        "$NAME" "$VERSION" "$ARCH" "$DESCRIPTION" "$DEPENDENCIES" > "$PKGWORK/meta.json"
    (cd "$PKGWORK" && tar --owner=0 --group=0 -cJf "$ARCHIVE" meta.json root)
}
rm -rf "$WORK" "$OUT"
mkdir -p "$WORK" "$OUT"
"$ROOT/tools/validate-recipes.sh"
"$ROOT/tools/build-public-packages.sh" "$OUT"

for RECIPE in "$RECIPES"/[0-9][0-9][0-9]-*.recipe; do
    [ -f "$RECIPE" ] || continue
    unset NAME HOST_PACKAGE DESCRIPTION DEPENDENCIES BINARIES EXTRA_PATHS TEST_COMMAND
    # shellcheck disable=SC1090
    . "$RECIPE"
    [ -n "${NAME:-}" ] && [ -n "${HOST_PACKAGE:-}" ] && [ -n "${DESCRIPTION:-}" ] || die "invalid recipe $RECIPE"
    VERSION=$(host_version "$HOST_PACKAGE")
    [ -n "$VERSION" ] || die "host package is unavailable: $HOST_PACKAGE"
    STAGE="$WORK/$NAME-root"
    mkdir -p "$STAGE"
    for BINARY in ${BINARIES:-}; do
        [ -x "$BINARY" ] || die "$NAME recipe requires executable $BINARY"
        copy_elf "$BINARY" "$STAGE"
    done
    for PATH_ITEM in ${EXTRA_PATHS:-}; do copy_path "$PATH_ITEM" "$STAGE"; done
    package_archive "$NAME" "$VERSION" "$DESCRIPTION" "${DEPENDENCIES:-}" "$STAGE"
done

"$ROOT/tools/write-package-index.sh" "$OUT"
printf 'Built %s package(s) in priority staging repository %s\n' "$(find "$OUT" -maxdepth 1 -name '*.mlpkg' | wc -l)" "$OUT"
