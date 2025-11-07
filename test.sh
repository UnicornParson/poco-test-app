#!/usr/bin/env bash

# Strict mode for safer scripts
set -euo pipefail
IFS=$'\n\t'

#
# test.sh
#
# Builds the poco-test-app project in the build_app directory (clean rebuild)
# and runs the executable if the build is successful.
# This script is designed for Linux only.
#
# Usage:
#   ./test.sh [--build-type Release|Debug] [--jobs N]
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build_app"
SOURCE_DIR="${SCRIPT_DIR}"
POCO_BIN_DIR="${SCRIPT_DIR}/poco_bin"
BOOST_BIN_DIR="${SCRIPT_DIR}/boost_bin"

BUILD_TYPE="Release"
JOBS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-type)
      BUILD_TYPE="${2:-Release}"
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

# Determine parallel build jobs when not explicitly provided
if [[ -z "${JOBS}" ]]; then
  if command -v nproc >/dev/null 2>&1; then
    JOBS=$(nproc)
  else
    JOBS=4
  fi
fi

# Check if Poco is built, if not, build it
if [[ ! -d "${POCO_BIN_DIR}/lib/cmake/Poco" ]] || [[ ! -f "${POCO_BIN_DIR}/lib/cmake/Poco/PocoConfig.cmake" ]]; then
  echo "Poco library not found in ${POCO_BIN_DIR}. Building Poco..."
  if [[ -f "${SCRIPT_DIR}/make_poco.sh" ]]; then
    bash "${SCRIPT_DIR}/make_poco.sh" --build-type "${BUILD_TYPE}" --jobs "${JOBS}"
  else
    echo "Error: make_poco.sh not found!" >&2
    exit 1
  fi
else
  echo "Poco library found in ${POCO_BIN_DIR}"
fi

# Check if Boost is built, if not, build it
# Check for boost_unit_test_framework component (required for tests)
BOOST_FOUND=0
if [[ -d "${BOOST_BIN_DIR}/lib/cmake" ]]; then
  # Check if boost_unit_test_framework directory exists (pattern matching)
  shopt -s nullglob
  for boost_test_dir in "${BOOST_BIN_DIR}/lib/cmake/boost_unit_test_framework-"*; do
    if [[ -d "${boost_test_dir}" ]] && [[ -f "${boost_test_dir}/boost_unit_test_framework-config.cmake" ]]; then
      BOOST_FOUND=1
      break
    fi
  done
  shopt -u nullglob
fi

if [[ ${BOOST_FOUND} -eq 0 ]]; then
  echo "Boost library not found in ${BOOST_BIN_DIR}. Building Boost..."
  if [[ -f "${SCRIPT_DIR}/make_boost.sh" ]]; then
    bash "${SCRIPT_DIR}/make_boost.sh" --build-type "${BUILD_TYPE}" --jobs "${JOBS}"
  else
    echo "Error: make_boost.sh not found!" >&2
    exit 1
  fi
else
  echo "Boost library found in ${BOOST_BIN_DIR}"
fi

echo "Cleaning build directory: ${BUILD_DIR}..."
rm -rvf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

echo "Configuring CMake (BUILD_TYPE=${BUILD_TYPE}, JOBS=${JOBS})..."
cd "${BUILD_DIR}"

cmake \
  -S "${SOURCE_DIR}" \
  -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"

echo "Building project..."
if cmake --build "${BUILD_DIR}" --parallel "${JOBS}"; then
  echo "Build successful!"
  
  # Try to find and run the test executable
  # Look for poco-test-app or any executable in test directory
  TEST_EXECUTABLE=""
  
  # First, try to find poco-test-app in test directory
  if [[ -f "${BUILD_DIR}/test/poco-test-app" ]] && [[ -x "${BUILD_DIR}/test/poco-test-app" ]]; then
    TEST_EXECUTABLE="${BUILD_DIR}/test/poco-test-app"
  # If not found, look for any executable in test directory
  elif [[ -d "${BUILD_DIR}/test" ]]; then
    # Enable nullglob to handle cases when no files match
    shopt -s nullglob
    # Find first executable file in test directory (non-directory, executable)
    for exec_file in "${BUILD_DIR}"/test/*; do
      if [[ -f "${exec_file}" ]] && [[ -x "${exec_file}" ]]; then
        TEST_EXECUTABLE="${exec_file}"
        break
      fi
    done
    shopt -u nullglob
  fi
  
  # If no executable found in test, check root build directory
  if [[ -z "${TEST_EXECUTABLE}" ]]; then
    if [[ -f "${BUILD_DIR}/poco-test-app" ]] && [[ -x "${BUILD_DIR}/poco-test-app" ]]; then
      TEST_EXECUTABLE="${BUILD_DIR}/poco-test-app"
    fi
  fi
  
  # Run the executable if found
  if [[ -n "${TEST_EXECUTABLE}" ]]; then
    echo "Running: ${TEST_EXECUTABLE}"
    echo "---"
    "${TEST_EXECUTABLE}"
    EXIT_CODE=$?
    echo "---"
    echo "Executable finished with exit code: ${EXIT_CODE}"
    exit ${EXIT_CODE}
  else
    echo "Warning: No test executable found to run."
    echo "Build completed successfully, but no executable was found."
    echo "Please check that your test/CMakeLists.txt defines an executable."
    exit 0
  fi
else
  echo "Build failed!"
  exit 1
fi

