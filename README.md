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
> For stable production course repositories, pin to a specific `<git-sha>` tag to ensure reproducible builds and prevent silent breakages from tooling upgrades.

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
