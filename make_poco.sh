#!/usr/bin/env bash

# Strict mode for safer scripts
set -euo pipefail
IFS=$'\n\t'

#
# make_poco.sh
#
# Builds Poco from the local `poco` directory with all features enabled
# (as much as possible, depending on available dependencies) and installs
# the build artifacts into the `poco_bin` directory.
#
# Usage:
#   ./make_poco.sh [--clean] [--build-type Release|Debug] [--generator <CMakeGenerator>] [--jobs N] [--sanitize]
#
# Notes:
# - This script attempts to enable all known Poco components via CMake flags.
#   Some components require external dependencies (e.g., OpenSSL, ODBC, MySQL,
#   Apache HTTPD). If a dependency is missing, CMake may fail. In that case,
#   either install the missing dependency or disable the component by editing
#   the flags below.
# - Artifacts are installed to `poco_bin` using CMake install with
#   `CMAKE_INSTALL_PREFIX`.
# - Works with single-config (Unix Makefiles, Ninja) and multi-config
#   generators (MSVC). For multi-config, we pass `--config <type>`.
# - When using --sanitize, AddressSanitizer (ASAN) and UndefinedBehaviorSanitizer
#   (UBSAN) are enabled. This is useful for detecting memory errors and undefined
#   behavior, but increases build time and binary size. It's recommended to use
#   --build-type Debug with --sanitize for best results.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POCO_SRC_DIR="${SCRIPT_DIR}/poco"
BUILD_DIR="${SCRIPT_DIR}/poco_build"
INSTALL_DIR="${SCRIPT_DIR}/poco_bin"

CLEAN=0
BUILD_TYPE="Release"
GENERATOR=""
JOBS=""
SANITIZE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean)
      CLEAN=1
      shift
      ;;
    --build-type)
      BUILD_TYPE="${2:-Release}"
      shift 2
      ;;
    --generator)
      GENERATOR="${2:-}"
      shift 2
      ;;
    --jobs|-j)
      JOBS="${2:-}"
      shift 2
      ;;
    --sanitize)
      SANITIZE=1
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "${POCO_SRC_DIR}" ]]; then
  echo "Error: Poco source directory not found at '${POCO_SRC_DIR}'." >&2
  echo "Make sure the 'poco' directory exists in the repository root." >&2
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
  elif [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || "$(uname -s)" == CYGWIN* ]]; then
    # Fallback for Git Bash on Windows
    JOBS=${NUMBER_OF_PROCESSORS:-4}
  else
    JOBS=4
  fi
fi

# Sanitizers require debug symbols, so adjust build type if needed
if [[ ${SANITIZE} -eq 1 ]] && [[ "${BUILD_TYPE}" == "Release" ]]; then
  echo "Warning: Sanitizers work best with Debug build. Consider using --build-type Debug with --sanitize."
fi

SANITIZE_FLAGS=""
if [[ ${SANITIZE} -eq 1 ]]; then
  # Enable AddressSanitizer and UndefinedBehaviorSanitizer
  # -fsanitize=address: Enable AddressSanitizer (detects memory errors)
  # -fsanitize=undefined: Enable UndefinedBehaviorSanitizer (detects undefined behavior)
  # -fno-omit-frame-pointer: Keep frame pointers for better stack traces
  # -g: Include debug information (required for meaningful sanitizer output)
  SANITIZE_FLAGS="-fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer -g"
  echo "Configuring Poco (BUILD_TYPE=${BUILD_TYPE}, JOBS=${JOBS}, SANITIZE=ASAN+UBSAN)..."
else
  echo "Configuring Poco (BUILD_TYPE=${BUILD_TYPE}, JOBS=${JOBS})..."
fi

# Common CMake options
CMAKE_OPTS=(
  -S "${POCO_SRC_DIR}"
  -B "${BUILD_DIR}"
  -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
  -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"
  -DPOCO_UNBUNDLED=OFF              # Prefer bundled third-party to reduce external deps
  -DPOCO_DISABLE_INTERNAL_OPENSSL=OFF
  -DENABLE_TESTS=OFF                # Skip tests for faster, leaner install
  -DENABLE_SAMPLES=OFF
)

# Add sanitizer flags if enabled
if [[ ${SANITIZE} -eq 1 ]]; then
  # Append sanitizer flags to CMAKE_CXX_FLAGS
  # This ensures all targets are built with sanitizers
  CMAKE_OPTS+=(-DCMAKE_CXX_FLAGS="${SANITIZE_FLAGS}")
  CMAKE_OPTS+=(-DCMAKE_C_FLAGS="${SANITIZE_FLAGS}")
  # Also set linker flags for sanitizers
  CMAKE_OPTS+=(-DCMAKE_EXE_LINKER_FLAGS="${SANITIZE_FLAGS}")
  CMAKE_OPTS+=(-DCMAKE_SHARED_LINKER_FLAGS="${SANITIZE_FLAGS}")
fi

# Attempt to enable all known Poco components. Adjust as needed if configuration fails.
CMAKE_ENABLE_ALL=(
  -DPOCO_ENABLE_FOUNDATION=ON
  -DPOCO_ENABLE_UTIL=ON
  -DPOCO_ENABLE_XML=ON
  -DPOCO_ENABLE_JSON=ON
  -DPOCO_ENABLE_NET=ON
  -DPOCO_ENABLE_CRYPTO=ON
  -DPOCO_ENABLE_NETSSL=ON
  -DPOCO_ENABLE_NETSSL_WIN=ON
  -DPOCO_ENABLE_DATA=ON
  -DPOCO_ENABLE_DATA_SQLITE=ON
  -DPOCO_ENABLE_DATA_ODBC=ON
  -DPOCO_ENABLE_DATA_MYSQL=ON
  -DPOCO_ENABLE_MONGODB=ON
  -DPOCO_ENABLE_REDIS=ON
  -DPOCO_ENABLE_ZIP=ON
  -DPOCO_ENABLE_PDF=ON
  -DPOCO_ENABLE_SEVENZIP=ON
  -DPOCO_ENABLE_PAGECOMPILER=ON
  -DPOCO_ENABLE_PAGECOMPILER_FILE2PAGE=ON
  -DPOCO_ENABLE_ENCODINGS=ON
  -DPOCO_ENABLE_JWT=ON
  -DPOCO_ENABLE_CPPPARSER=ON
  -DPOCO_ENABLE_PROMETHEUS=ON
  -DPOCO_ENABLE_DNSSD=ON
  -DPOCO_ENABLE_TRACE=ON
  -DPOCO_ENABLE_APACHECONNECTOR=ON
  -DPOCO_ENABLE_ACTIVERECORD=ON
)

if [[ -n "${GENERATOR}" ]]; then
  CMAKE_GEN=(-G "${GENERATOR}")
else
  CMAKE_GEN=()
fi

cmake "${CMAKE_OPTS[@]}" "${CMAKE_ENABLE_ALL[@]}" "${CMAKE_GEN[@]}"

echo "Building Poco..."

# Detect if generator is multi-config (e.g., Visual Studio). If so, pass --config.
GENERATOR_NAME=$(cmake -B "${BUILD_DIR}" -LA 2>/dev/null | sed -n 's/^CMAKE_GENERATOR:INTERNAL=//p' || true)
if [[ -z "${GENERATOR_NAME}" && -f "${BUILD_DIR}/CMakeCache.txt" ]]; then
  GENERATOR_NAME=$(sed -n 's/^CMAKE_GENERATOR:INTERNAL=//p' "${BUILD_DIR}/CMakeCache.txt" || true)
fi

BUILD_ARGS=(--build "${BUILD_DIR}" --parallel "${JOBS}")
INSTALL_ARGS=(--target install)

case "${GENERATOR_NAME}" in
  *"Visual Studio"*|*"Xcode"*)
    BUILD_ARGS+=(--config "${BUILD_TYPE}")
    ;;
  *)
    : # single-config generators do not need --config
    ;;
esac

cmake "${BUILD_ARGS[@]}"
cmake "${BUILD_ARGS[@]}" "${INSTALL_ARGS[@]}"

echo "Poco installed to: ${INSTALL_DIR}"
echo "Done."


