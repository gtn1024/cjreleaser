# cjreleaser

Automated release tool for [Cangjie](https://cangjie-lang.cn/) monorepo packages.

## Features

- **Monorepo support** — discovers workspace members, resolves dependencies, and publishes in topological order
- **Single package support** — works as a pre-check wrapper for `cjpm bundle` + `cjpm publish`
- **Pre-flight checks** — validates package metadata, detects duplicate publishes, checks dependency reachability
- **Dry run mode** — preview what would be published without making changes
- **Bundle-only mode** — transform and bundle without publishing
- **Config file** — `cjreleaser.toml` for persistent settings
- **Publish wait** — polls the central repository index after publish to ensure downstream packages can resolve dependencies

## Prerequisites

- Cangjie SDK >= 1.1.3
- `CANGJIE_STDX_PATH` environment variable pointing to the precompiled stdx `static/stdx/` directory
- `cangjie-repo.toml` configured with a valid registry token (required by `cjpm publish`)

## Build

```bash
export CANGJIE_STDX_PATH=/path/to/cangjie-stdx/linux_aarch64_cjnative/static/stdx
cjpm build
```

## Usage

### Dry run (preview)

```bash
cjreleaser --dry-run --root /path/to/monorepo
```

### Bundle only

```bash
cjreleaser --bundle-only --root /path/to/monorepo --skip-test
```

### Full publish

```bash
cjreleaser --root /path/to/monorepo
```

### Publish specific packages

```bash
cjreleaser --root /path/to/monorepo --only lib-a,lib-b
```

### Exclude packages

```bash
cjreleaser --root /path/to/monorepo --exclude internal-tool
```

## CLI Options

| Option | Short | Description |
|--------|-------|-------------|
| `--dry-run` | `-n` | Run checks without publishing |
| `--bundle-only` | | Transform and bundle without publishing |
| `--verbose` | `-v` | Enable verbose output |
| `--skip-test` | | Skip running `cjpm test` |
| `--skip-lint` | | Skip running `cjlint` |
| `--root <dir>` | `-r` | Specify project root directory |
| `--only <pkgs>` | | Only publish specified packages (comma-separated) |
| `--exclude <pkgs>` | | Exclude specified packages (comma-separated) |

## Configuration File

Create a `cjreleaser.toml` in your project root:

```toml
[release]
skip-test = false
skip-lint = true
include = ["lib-a", "lib-b"]
# exclude = ["internal-tool"]
```

CLI arguments override config file settings.

## How It Works

1. **Discover** — finds the root `cjpm.toml`, identifies workspace members
2. **Sort** — builds dependency graph and sorts packages in topological order (dependencies first)
3. **Precheck** — validates metadata (description, README, name, organization), checks for duplicate publishes
4. **Transform** — copies each package to `.cjreleaser/` staging directory and rewrites `path` dependencies to central registry coordinates
5. **Bundle & Publish** — for each package in order: `cjpm update` → `cjpm bundle` → `cjpm publish`
6. **Wait** — polls the central repository to confirm the package is indexed before proceeding to the next package

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE) for details.
