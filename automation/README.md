# MiniLinux package automation

The `recipes/` directory defines reviewable trusted host-package recipes. Run
`tools/validate-recipes.sh` first, then run `tools/prepare-priority-publication.sh`
to rebuild packages, test dependency installation in a self-contained MiniLinux
rootfs, regenerate `index.json`, and prepare a publication tree. The repository
workflow invokes this sequence before it updates packages on `main`.
