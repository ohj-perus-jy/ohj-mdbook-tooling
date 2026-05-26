# ohj-mdbook-tooling

Shared mdBook tooling image for Ohjelmointi course material repositories.

The image installs mdBook and the preprocessors used by the course books so
that Codespace/devcontainer startup and CI builds do not need to compile Cargo
tools every time.

## Included tools

- `mdbook@0.4.52`
- `mdbook-mermaid@0.16.2`
- `mdbook-alerts@0.8.0`
- `mdbook-katex@0.9.4`
- `mdbook-plantuml@0.8.0`
- `mdbook-inline-highlighting@1.0.0`
- `mdbook-svgbob` from commit `3431f100c08eeca8b132241d0c372ec0f4aed85b`
- `mdbook-codeblock-tabs` from `preprocessors/rust/mdbook-codeblock-tabs`
- `mdbook-accordion` wrapper for `preprocessors/python/accordion.py`

## Image

The GitHub Actions workflow publishes the image to GHCR:

```text
ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:<tag>
```

For normal use, pin a released tag in course repositories instead of using a
moving branch tag.

## Dev Container usage

Example `.devcontainer/devcontainer.json`:

```json
{
  "name": "Ohjelmointi mdBook",
  "image": "ghcr.io/ohj-perus-jy/ohj-mdbook-tooling:main",
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
  }
}
```

## Local build

```bash
docker build -t ohj-mdbook-tooling .
```

To test a book repository with the image:

```bash
docker run --rm -v "$PWD":/work -w /work ohj-mdbook-tooling mdbook build
```
