# The builder stage
# This stage is used to build the actual mdbook and all other dependencies
FROM rust:bookworm AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*

COPY preprocessors /tmp/preprocessors
ENV CARGO_TARGET_DIR=/tmp/cargo-target

RUN cargo install \
        mdbook@0.4.52 \
        mdbook-mermaid@0.16.2 \
        mdbook-alerts@0.8.0 \
        mdbook-katex@0.9.4 \
        mdbook-plantuml@0.8.0 \
        mdbook-inline-highlighting@1.0.0 \
    && cargo install \
        --git https://github.com/boozook/mdbook-svgbob.git \
        --rev 3431f100c08eeca8b132241d0c372ec0f4aed85b \
    && cargo install --path /tmp/preprocessors/rust/mdbook-codeblock-tabs

# Runner stage
# This stage is used for the runner image, which can be used for running mdbook build via ci or command line
FROM debian:bookworm-slim AS mdbook-runner

LABEL org.opencontainers.image.source="https://github.com/ohj-perus-jy/ohj-mdbook-tooling"
LABEL org.opencontainers.image.description="Shared mdBook tooling image for Ohjelmointi course material repositories"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/cargo/bin/mdbook* /usr/local/bin/
COPY preprocessors/python /opt/mdbook-preprocessors
RUN chmod +x /opt/mdbook-preprocessors/mdbook-accordion \
    && ln -s /opt/mdbook-preprocessors/mdbook-accordion /usr/local/bin

VOLUME ["/workspace"]
WORKDIR /workspace
ENTRYPOINT [ "mdbook" ]

# Devcontainer stage
# This stage is used for the devcontainer, which can be used for working with ohj1/ohj2 materials
FROM mcr.microsoft.com/devcontainers/rust:bookworm AS devcontainer

LABEL org.opencontainers.image.source="https://github.com/ohj-perus-jy/ohj-mdbook-tooling"
LABEL org.opencontainers.image.description="Shared mdBook tooling image for Ohjelmointi course material repositories"
LABEL org.opencontainers.image.licenses="MIT"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/cargo/bin/mdbook* /usr/local/bin/
COPY preprocessors/python /opt/mdbook-preprocessors
RUN chmod +x /opt/mdbook-preprocessors/mdbook-accordion \
    && ln -s /opt/mdbook-preprocessors/mdbook-accordion /usr/local/bin/mdbook-accordion
