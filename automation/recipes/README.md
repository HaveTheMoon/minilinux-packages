# MiniLinux package recipes

Each trusted `NNN-name.recipe` file is a POSIX shell data file used to create one
`x86_64` `.mlpkg` archive from an installed Ubuntu host package. Recipes are code
reviewed repository content: do not source recipes obtained from untrusted pull
requests or downloads.

| Field | Requirement | Meaning |
| --- | --- | --- |
| `NAME` | Required | Lowercase MiniLinux package name. |
| `HOST_PACKAGE` | Required | Installed Ubuntu package queried through `dpkg-query`. |
| `DESCRIPTION` | Required | Single-line JSON-safe package description. |
| `DEPENDENCIES` | Required | Comma-separated MiniLinux package names, or empty. |
| `BINARIES` | Required | Space-separated executable paths copied with ELF runtime dependencies. |
| `EXTRA_PATHS` | Required | Space-separated files or trees required by the package, or empty. |
| `TEST_COMMAND` | Required | Host-side smoke test executed before archiving. |

Run `tools/validate-recipes.sh` before changing a recipe. The validator checks
required fields, package-name syntax, dependency names, paths, host package
availability, smoke tests, and the priority table. Build all recipes with
`tools/build-priority-packages.sh`.
