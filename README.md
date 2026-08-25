# ohj-mdbook-tooling

Shared mdBook tooling images for Ohjelmointi course material repositories.

To keep builds as fast as possible, the project compiles and publishes two distinct target image variants to GitHub Container Registry (GHCR):

1. **`runner`**: An ultra-compact runtime image (~150MB uncompressed) optimized for headlessly compiling course books in GitHub Actions CI/CD pipelines in seconds.
2. **`devcontainer`**: A fully-featured developer image containing Rust, Cargo, and system utilities designed for local VS Code Dev Container / Codespaces use.

---

## Included Tools

* `mdbook@0.4.52`
* `mdbook-mermaid@0.16.2`
* `mdbook-alerts@0.8.0`
* `mdbook-katex@0.9.4`
* `mdbook-plantuml@0.8.0`
* `mdbook-inline-highlighting@1.0.0`
* `mdbook-svgbob` (cloned from `boozook/mdbook-svgbob` commit `3431f100`)
* `mdbook-codeblock-tabs` (custom preprocessor in `preprocessors/rust`)
* `mdbook-accordion` (POSIX wrapper around custom Python script in `preprocessors/python`)

---

## Image Tags

Both images are published to GHCR with the following tags:

| Variant | Stable Tag | Latest Tag | Git Hash Tag |
| :--- | :--- | :--- | :--- |
| **Runner** | `ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:runner` | `ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:runner-latest` | `ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:runner-<git-sha>` |
| **Dev Container** | `ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:devcontainer` | `ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:devcontainer-latest` | `ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:devcontainer-<git-sha>` |

> [!TIP]
> For stable production course repositories, pin to a specific `<git-sha>` tag. A published `<git-sha>` image is immutable, so it prevents silent breakages from tooling upgrades.

> [!NOTE]
> Pinning a tag pins the *published image*, not the *build*. Rebuilding the same commit later can still produce different binaries: the base images (`rust:bookworm`, `debian:bookworm-slim`) and the `apt` and crates.io registries all move. `Cargo.lock` pins the dependency versions of `mdbook-codeblock-tabs` only (see [Updating the Preprocessor Dependencies](#updating-the-preprocessor-dependencies)); the `mdbook*` tools installed from crates.io re-resolve their own dependencies on every build.

---

## CI/CD Pipeline Usage (Runner)

You can run the ultra-lightweight `runner` image in your course repository workflows using one of two methods:

### Method A: Job Container (Recommended)
This runs the entire job steps context natively inside the container. GitHub automatically handles directory mapping and permissions.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:runner-latest

    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      - name: Build mdBook
        run: build # equivalent to running 'mdbook build'
```

### Method B: Isolated Docker Run
Best if you only want to compile the book as a single step inside a standard virtual machine host.

```yaml
      - name: Build mdBook
        run: |
          docker run --rm \
            -v "${{ github.workspace }}:/workspace" \
            ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:runner-latest \
            build
```

---

## Local Dev Container Usage

Configure your course repository to use the `devcontainer` image in `.devcontainer/devcontainer.json`:

```json
{
  "name": "Ohjelmointi mdBook",
  "image": "ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:devcontainer-latest",
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {}
  },
  "forwardPorts": [3000],
  "customizations": {
    "vscode": {
      "extensions": [
        "rust-lang.rust-analyzer",
        "tamasfe.even-better-toml",
        "yzhang.markdown-all-in-one"
      ]
    }
  },
  "remoteUser": "vscode"
}
```

---

## Local Build & Test

To build the targets locally on your machine:

```bash
# Build the devcontainer variant
docker build --target devcontainer -t ohj-mdbook-tooling:devcontainer .

# Build the runner variant
docker build --target mdbook-runner -t ohj-mdbook-tooling:runner .
```

To test rendering a local book repository using the runner image:

```bash
docker run --rm -v "$PWD":/workspace ohj-mdbook-tooling:runner build
```

---

## Updating the Preprocessor Dependencies

The custom `mdbook-codeblock-tabs` preprocessor is built with `cargo install --locked`, so its `Cargo.lock` — not just the version ranges in `Cargo.toml` — decides which dependency versions end up in the image. Dependency updates and upstream bug fixes are therefore **not** picked up automatically; you have to refresh the lock file and commit it.

> [!IMPORTANT]
> **For maintainers of this repository.** Pinning is a trade: the image can no longer break by surprise, but it can no longer heal by itself either. Dependency fixes — security fixes included — will not reach the image until someone refreshes `Cargo.lock` here. Treat it as recurring maintenance rather than something to do only when a build fails:
>
> * before each teaching period, so that any breakage surfaces during preparation instead of mid-course;
> * whenever the pinned `mdbook` version is bumped in the `Dockerfile`;
> * whenever a security advisory affects a crate listed in `Cargo.lock`.
>
> A scheduled workflow (`.github/workflows/dependency-check.yml`) runs this check on the first of each month and opens an issue when the lock has fallen behind. It only reports — applying the update is still a deliberate, manual step.
>
> To see what *would* change without writing anything, add `--dry-run` to the `cargo update` command below.

You do not need a local Rust toolchain — run Cargo in a throwaway container:

```bash
# Update every dependency to the newest semver-compatible version
docker run --rm \
  -v "$PWD/preprocessors/rust/mdbook-codeblock-tabs":/app \
  -w /app \
  rust:bookworm cargo update

# ...or update a single dependency only
docker run --rm \
  -v "$PWD/preprocessors/rust/mdbook-codeblock-tabs":/app \
  -w /app \
  rust:bookworm cargo update -p pulldown-cmark
```

Then verify that the image still builds, and commit `Cargo.lock`:

```bash
docker build --target mdbook-runner -t ohj-mdbook-tooling:runner .
git add preprocessors/rust/mdbook-codeblock-tabs/Cargo.lock
git commit -m "chore: update mdbook-codeblock-tabs dependencies"
```

> [!NOTE]
> On Linux the container writes `Cargo.lock` as `root`. Add `--user "$(id -u):$(id -g)" -e CARGO_HOME=/tmp/cargo-home` to the `docker run` command to keep the file owned by you.

Bumping a *major* version of a dependency still requires editing `Cargo.toml` first; `cargo update` only moves within the ranges declared there.
