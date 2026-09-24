#!/usr/bin/env bash
set -euo pipefail

image=${1:?image tag required}

source constants.env

docker build \
  --build-arg DEBIAN_TAG="$DEBIAN_TAG" \
  --build-arg DEBIAN_BUILD_DEPS="$DEBIAN_BUILD_DEPS" \
  --build-arg DEBIAN_PIPX_DEPS="$DEBIAN_PIPX_DEPS" \
  --build-arg CHECKMAKE_VERSION="$CHECKMAKE_VERSION" \
  -t "$image" \
  -f scripts/docker/Dockerfile .
