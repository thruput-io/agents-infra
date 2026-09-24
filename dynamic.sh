#!/usr/bin/env bash
set -euo pipefail

emit() {
  printf '%s := %s\n' "$1" "$2"
}

source constants.env

os=$(uname -s | tr '[:upper:]' '[:lower:]')

case "$os" in
  linux)
    install_command=$DEBIAN_INSTALL_COMMAND
    build_deps=$DEBIAN_BUILD_DEPS
    ;;
  darwin)
    install_command=$DARWIN_INSTALL_COMMAND
    build_deps=$DARWIN_BUILD_DEPS
    ;;
  *)
    echo "Unsupported OS: '$os'" >&2
    exit 1
    ;;
esac

echo "# Generated from dynamic.sh"
emit INSTALL_COMMAND "$install_command"
emit BUILD_DEPS "$build_deps"
emit DEBIAN_BUILD_DEPS "$DEBIAN_BUILD_DEPS"
emit DEBIAN_PIPX_DEPS "$DEBIAN_PIPX_DEPS"
emit DEBIAN_TAG "$DEBIAN_TAG"
emit CHECKMAKE_VERSION "$CHECKMAKE_VERSION"
emit COLLECTION_NAMESPACE "$COLLECTION_NAMESPACE"
emit COLLECTION_NAME "$COLLECTION_NAME"
