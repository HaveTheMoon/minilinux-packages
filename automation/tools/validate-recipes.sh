#!/bin/sh
# Validate trusted MiniLinux package recipes before any package build begins.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
RECIPES="$ROOT/recipes"
PRIORITY="$RECIPES/priority.tsv"
PUBLIC_PACKAGES='curl fastfetch file htop less nano neofetch sudo unzip zip'

die() { echo "validate-recipes: $*" >&2; exit 1; }
valid_name() { case "$1" in [a-z0-9][a-z0-9_-]*) return 0;; *) return 1;; esac; }
contains_word() { case " $1 " in *" $2 "*) return 0;; *) return 1;; esac; }

[ -d "$RECIPES" ] || die "missing recipes directory"
[ -f "$PRIORITY" ] || die "missing priority table"

RECIPE_NAMES=''
for RECIPE in "$RECIPES"/[0-9][0-9][0-9]-*.recipe; do
    [ -f "$RECIPE" ] || continue
    unset NAME HOST_PACKAGE DESCRIPTION DEPENDENCIES BINARIES EXTRA_PATHS TEST_COMMAND
    # Recipes are trusted source-tree data files. Do not run this validator on unreviewed input.
    . "$RECIPE"
    [ -n "${NAME:-}" ] || die "missing NAME in $RECIPE"
    valid_name "$NAME" || die "invalid NAME '$NAME' in $RECIPE"
    contains_word "$RECIPE_NAMES" "$NAME" && die "duplicate recipe NAME '$NAME'"
    RECIPE_NAMES="${RECIPE_NAMES:+$RECIPE_NAMES }$NAME"
done

for RECIPE in "$RECIPES"/[0-9][0-9][0-9]-*.recipe; do
    [ -f "$RECIPE" ] || continue
    unset NAME HOST_PACKAGE DESCRIPTION DEPENDENCIES BINARIES EXTRA_PATHS TEST_COMMAND
    . "$RECIPE"
    for FIELD in NAME HOST_PACKAGE DESCRIPTION DEPENDENCIES BINARIES EXTRA_PATHS TEST_COMMAND; do
        eval "VALUE=\${$FIELD+x}"
        [ "${VALUE:-}" = x ] || die "missing $FIELD in $RECIPE"
    done
    [ -n "$HOST_PACKAGE" ] || die "empty HOST_PACKAGE in $RECIPE"
    [ -n "$DESCRIPTION" ] || die "empty DESCRIPTION in $RECIPE"
    case "$DESCRIPTION" in *'"'*|*'\\'*|*'
'*) die "DESCRIPTION must be one-line JSON-safe text in $RECIPE";; esac
    [ -n "$BINARIES$EXTRA_PATHS" ] || die "recipe $NAME has no files to package"
    [ -n "$TEST_COMMAND" ] || die "recipe $NAME has no TEST_COMMAND"
    dpkg-query -W "$HOST_PACKAGE" >/dev/null 2>&1 || die "host package unavailable: $HOST_PACKAGE"
    for BINARY in $BINARIES; do [ -x "$BINARY" ] || die "$NAME requires executable $BINARY"; done
    for ITEM in $EXTRA_PATHS; do [ -e "$ITEM" ] || die "$NAME requires path $ITEM"; done
    sh -c "$TEST_COMMAND" >/dev/null 2>&1 || die "TEST_COMMAND failed for $NAME"
    SEEN=''
    OLD_IFS=$IFS; IFS=,
    for DEPENDENCY in $DEPENDENCIES; do
        IFS=$OLD_IFS
        [ -n "$DEPENDENCY" ] || continue
        valid_name "$DEPENDENCY" || die "invalid dependency '$DEPENDENCY' in $NAME"
        contains_word "$SEEN" "$DEPENDENCY" && die "duplicate dependency '$DEPENDENCY' in $NAME"
        [ "$DEPENDENCY" != "$NAME" ] || die "self dependency in $NAME"
        contains_word "$RECIPE_NAMES $PUBLIC_PACKAGES" "$DEPENDENCY" || die "unknown dependency '$DEPENDENCY' in $NAME"
        SEEN="${SEEN:+$SEEN }$DEPENDENCY"
        IFS=,
    done
    IFS=$OLD_IFS
done

PRIORITY_NAMES=$(awk -F '\t' 'NR > 1 && $1 !~ /^#/ { print $2 }' "$PRIORITY" | tr '\n' ' ')
for NAME in $RECIPE_NAMES; do
    contains_word "$PRIORITY_NAMES" "$NAME" || die "recipe $NAME is missing from priority.tsv"
done
printf 'Validated %s trusted MiniLinux recipe(s).\n' "$(printf '%s\n' "$RECIPE_NAMES" | wc -w)"
