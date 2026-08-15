#!/bin/sh
# Build, test and prepare a complete public repository tree without publishing.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE="$ROOT/build/package-staging/x86_64"
OUT=${1:-"$ROOT/build/publication-ready"}

"$ROOT/tools/build-priority-packages.sh" "$SOURCE"
"$ROOT/tools/test-priority-repository.sh" "$SOURCE"

rm -rf "$OUT"
mkdir -p "$OUT/x86_64" "$OUT/automation/recipes" "$OUT/automation/tools" "$OUT/.github/workflows"
cp -a "$SOURCE/." "$OUT/x86_64/"
if [ -f "$ROOT/packages-public/README.md" ]; then
    cp "$ROOT/packages-public/README.md" "$OUT/README.md"
else
    cp "$ROOT/README.md" "$OUT/README.md"
fi
cp "$ROOT/recipes/priority.tsv" "$OUT/automation/recipes/priority.tsv"
cp "$ROOT/recipes/"*.recipe "$OUT/automation/recipes/"
cp "$ROOT/recipes/README.md" "$OUT/automation/recipes/"
cp "$ROOT/tools/build-priority-packages.sh" "$ROOT/tools/build-public-packages.sh" "$ROOT/tools/test-priority-repository.sh" "$ROOT/tools/validate-recipes.sh" "$ROOT/tools/write-package-index.sh" "$ROOT/tools/merge-repository-index.mjs" "$ROOT/tools/prepare-package-updates.mjs" "$ROOT/tools/verify-repository-index.mjs" "$ROOT/tools/prepare-priority-publication.sh" "$ROOT/tools/minipkg" "$OUT/automation/tools/"
WORKFLOW_ROOT=$ROOT
[ -f "$WORKFLOW_ROOT/.github/workflows/priority-repository-verify.yml" ] || WORKFLOW_ROOT=$(dirname "$ROOT")
cp "$WORKFLOW_ROOT/.github/workflows/priority-repository-verify.yml" "$OUT/.github/workflows/"
[ -f "$WORKFLOW_ROOT/.github/workflows/manual-package-publish.yml" ] && cp "$WORKFLOW_ROOT/.github/workflows/manual-package-publish.yml" "$OUT/.github/workflows/"
cat > "$OUT/automation/README.md" <<'EOF'
# MiniLinux package automation

The `recipes/` directory defines reviewable trusted host-package recipes. Run
`tools/validate-recipes.sh` first, then run `tools/prepare-priority-publication.sh`
to rebuild packages, test dependency installation in a self-contained MiniLinux
rootfs, regenerate `index.json`, and prepare a publication tree. The repository
workflow invokes this sequence before it updates packages on `main`.
EOF
printf 'Publication staging is ready at %s\n' "$OUT"
