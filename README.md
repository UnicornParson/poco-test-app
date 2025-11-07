# poco-test-app

Unit tests for Poco using Boost.Test framework.

## Project Description

This project provides a testing framework for Poco libraries using Boost.Test. It includes scripts to build Poco and Boost from source, and a test suite setup using CMake.

## Scripts

### make_poco.sh

Builds Poco library from the local `poco` directory with all features enabled and installs the build artifacts into the `poco_bin` directory.

**Usage:**
```bash
./make_poco.sh [--clean] [--build-type Release|Debug] [--generator <CMakeGenerator>] [--jobs N] [--sanitize]
```

**Options:**
- `--clean` - Clean previous build and install directories before building
- `--build-type Release|Debug` - Set the build type (default: Release)
- `--generator <CMakeGenerator>` - Specify CMake generator (e.g., "Unix Makefiles", "Ninja")
- `--jobs N` or `-j N` - Number of parallel build jobs (default: auto-detected via `nproc`)
- `--sanitize` - Enable AddressSanitizer (ASAN) and UndefinedBehaviorSanitizer (UBSAN) for detecting memory errors and undefined behavior

**Example:**
```bash
./make_poco.sh --clean --build-type Debug --jobs 8
./make_poco.sh --build-type Debug --sanitize
```

**Notes:**
- When using `--sanitize`, AddressSanitizer and UndefinedBehaviorSanitizer are enabled. This is useful for detecting memory errors and undefined behavior, but increases build time and binary size.
- It's recommended to use `--build-type Debug` with `--sanitize` for best results.
- Sanitizers add runtime instrumentation that helps detect issues like buffer overflows, use-after-free, memory leaks, and undefined behavior.

### make_boost.sh

Builds Boost library from the local `boost` directory with only the components needed for unit testing and installs the build artifacts into the `boost_bin` directory.

**Usage:**
```bash
./make_boost.sh [--clean] [--build-type Release|Debug] [--jobs N]
```

**Options:**
- `--clean` - Clean previous build and install directories before building
- `--build-type Release|Debug` - Set the build type (default: Release)
- `--jobs N` or `-j N` - Number of parallel build jobs (default: auto-detected via `nproc`)

**Built components:**
- `test` - Boost.Test framework (main component)
- `system` - Required by test and other libraries
- `filesystem` - Often used in tests
- `chrono` - Sometimes used in tests
- `timer` - Sometimes used in tests
- `exception` - Required by test

**Example:**
```bash
./make_boost.sh --clean --build-type Debug --jobs 8
```

### test.sh

Builds the poco-test-app project in the `build_app` directory (clean rebuild) and runs the test executable if the build is successful.

**Usage:**
```bash
./test.sh [--build-type Release|Debug] [--jobs N]
```

**Options:**
- `--build-type Release|Debug` - Set the build type (default: Release)
- `--jobs N` or `-j N` - Number of parallel build jobs (default: auto-detected via `nproc`)

**Example:**
```bash
./test.sh --build-type Debug --jobs 8
```

The script performs a clean rebuild and automatically finds and runs the test executable after successful build.

### update.sh

Updates git submodules (poco and boost) to their latest commits.

**Usage:**
```bash
./update.sh
```
