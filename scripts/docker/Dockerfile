ARG DEBIAN_TAG=trixie-slim
FROM debian:${DEBIAN_TAG}

ARG DEBIAN_BUILD_DEPS
ARG DEBIAN_PIPX_DEPS
ARG CHECKMAKE_VERSION

RUN apt-get update \
 && apt-get install -y --no-install-recommends ${DEBIAN_BUILD_DEPS} \
 && rm -rf /var/lib/apt/lists/*

ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin
RUN pipx install ${DEBIAN_PIPX_DEPS}

RUN arch="$(dpkg --print-architecture)" \
 && curl -fsSL -o /usr/local/bin/checkmake \
      "https://github.com/mrtazz/checkmake/releases/download/${CHECKMAKE_VERSION}/checkmake-${CHECKMAKE_VERSION}.linux.${arch}" \
 && chmod +x /usr/local/bin/checkmake \
 && checkmake --version

WORKDIR /work
