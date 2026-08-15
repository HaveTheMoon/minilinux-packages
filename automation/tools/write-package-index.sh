#!/bin/sh
# Write the line-oriented index format consumed by MiniLinux minipkg.
set -eu

OUT=${1:?usage: write-package-index.sh DIRECTORY}
[ -d "$OUT" ] || { echo "write-package-index: missing directory $OUT" >&2; exit 1; }

ARCHIVES=$(find "$OUT" -maxdepth 1 -type f -name '*.mlpkg' -printf '%f\n' | LC_ALL=C sort)
[ -n "$ARCHIVES" ] || { echo "write-package-index: no .mlpkg archives in $OUT" >&2; exit 1; }

{
    printf '{"format":1,"packages":[\n'
    FIRST=1
    for FILE in $ARCHIVES; do
        ARCHIVE="$OUT/$FILE"
        META=$(tar -xOJf "$ARCHIVE" meta.json)
        NAME=$(printf '%s' "$META" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
        VERSION=$(printf '%s' "$META" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')
        DESCRIPTION=$(printf '%s' "$META" | sed -n 's/.*"description":"\([^"]*\)".*/\1/p')
        DEPENDENCIES=$(printf '%s' "$META" | sed -n 's/.*"dependencies":"\([^"]*\)".*/\1/p')
        [ -n "$NAME" ] && [ -n "$VERSION" ] && [ -n "$DESCRIPTION" ] || { echo "write-package-index: invalid metadata in $FILE" >&2; exit 1; }
        HASH=$(sha256sum "$ARCHIVE" | awk '{print $1}')
        [ "$FIRST" -eq 1 ] || printf ',\n'
        FIRST=0
        printf '{"name":"%s","version":"%s","file":"%s","sha256":"%s","description":"%s","dependencies":"%s"}' \
            "$NAME" "$VERSION" "$FILE" "$HASH" "$DESCRIPTION" "$DEPENDENCIES"
    done
    printf '\n]}\n'
} > "$OUT/index.json"
printf 'Wrote %s\n' "$OUT/index.json"
