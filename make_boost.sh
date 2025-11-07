#!/usr/bin/env bash

# Strict mode for safer scripts
set -euo pipefail
IFS=$'\n\t'

#
# make_boost.sh
#
# Builds Boost from the local `boost` directory with only the components
# needed for unit testing and installs the build artifacts into the `boost_bin` directory.
# This script is designed for Linux only.
#
# Usage:
#   ./make_boost.sh [--clean] [--build-type Release|Debug] [--jobs N]
#
# Notes:
# - This script builds only Boost.Test and its dependencies (system, filesystem, etc.)
# - Artifacts are installed to `boost_bin` using b2 install with `--prefix`.
# - Boost.Test is the main component for unit testing in Boost.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOST_SRC_DIR="${SCRIPT_DIR}/boost"
BUILD_DIR="${SCRIPT_DIR}/boost_build"
INSTALL_DIR="${SCRIPT_DIR}/boost_bin"

CLEAN=0
BUILD_TYPE="release"
JOBS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean)
      CLEAN=1
      shift
      ;;
    --build-type)
      if [[ "${2:-}" == "Debug" ]]; then
        BUILD_TYPE="debug"
      else
        BUILD_TYPE="release"
      fi
      shift 2
      ;;
    --jobs|-j)
      JOBS="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "${BOOST_SRC_DIR}" ]]; then
  echo "Error: Boost source directory not found at '${BOOST_SRC_DIR}'." >&2
  echo "Make sure the 'boost' directory exists in the repository root." >&2
  exit 1
fi

if [[ ${CLEAN} -eq 1 ]]; then
  echo "Cleaning previous build and install directories..."
  rm -rf "${BUILD_DIR}" "${INSTALL_DIR}"
fi

mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}"

# Determine parallel build jobs when not explicitly provided
if [[ -z "${JOBS}" ]]; then
  if command -v nproc >/dev/null 2>&1; then
    JOBS=$(nproc)
  else
    JOBS=4
  fi
fi

echo "Configuring Boost (BUILD_TYPE=${BUILD_TYPE}, JOBS=${JOBS})..."

# Change to boost source directory for bootstrap
cd "${BOOST_SRC_DIR}"

# Run bootstrap if b2 is missing
if [[ ! -f "b2" ]]; then
  echo "Bootstrapping Boost build system..."
  if [[ -f "bootstrap.sh" ]]; then
    bash ./bootstrap.sh
  else
    echo "Error: bootstrap.sh not found in Boost source directory." >&2
    exit 1
  fi
fi

# Use b2 (bjam is deprecated)
if [[ ! -f "b2" ]]; then
  echo "Error: b2 not found. Bootstrap may have failed." >&2
  exit 1
fi
B2_CMD="./b2"

echo "Building Boost with unit test components..."

# Boost libraries needed for unit testing:
# - test: Boost.Test framework (main component)
# - system: Required by test and other libraries
# - filesystem: Often used in tests
# - chrono: Sometimes used in tests
# - timer: Sometimes used in tests
# - exception: Required by test

# Build only the libraries needed for unit tests
# --layout=system: Uses system-style layout (libboost_*.a/libboost_*.so)
# --with-*: Only build specified libraries
${B2_CMD} \
  --build-dir="${BUILD_DIR}" \
  --prefix="${INSTALL_DIR}" \
  --layout=system \
  variant=${BUILD_TYPE} \
  link=static,shared \
  threading=multi \
  -j${JOBS} \
  --with-test \
  --with-system \
  --with-filesystem \
  --with-chrono \
  --with-timer \
  --with-exception \
  install

echo "Boost installed to: ${INSTALL_DIR}"
echo "Done."

