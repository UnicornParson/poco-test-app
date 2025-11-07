cmake_minimum_required(VERSION 3.10)

project(poco-test-app
    VERSION 1.0.0
    LANGUAGES CXX
)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Get the directory where this CMakeLists.txt is located
get_filename_component(SCRIPT_DIR "${CMAKE_CURRENT_SOURCE_DIR}" ABSOLUTE)

# Set paths to Poco and Boost installations
set(POCO_ROOT "${SCRIPT_DIR}/poco_bin")
set(BOOST_ROOT "${SCRIPT_DIR}/boost_bin")

# Add Poco and Boost to CMAKE_PREFIX_PATH so find_package can locate them
list(APPEND CMAKE_PREFIX_PATH "${POCO_ROOT}" "${BOOST_ROOT}")

# Set Poco-specific CMake variables
set(Poco_DIR "${POCO_ROOT}/lib/cmake/Poco" CACHE PATH "Path to Poco CMake config")

# Set Boost-specific CMake variables to use only local installation
# Force these variables to ensure CMake uses our local Boost
set(BOOST_ROOT "${BOOST_ROOT}" CACHE PATH "Root directory of Boost installation" FORCE)
set(BOOSTROOT "${BOOST_ROOT}" CACHE PATH "Root directory of Boost installation" FORCE)

# Find Poco
find_package(Poco REQUIRED
    COMPONENTS
        Foundation
        Util
        XML
        JSON
        Net
        Crypto
        NetSSL
)

# Find Boost - ensure we use only our local installation
# Clear any cached Boost variables that might point to system Boost
unset(Boost_FOUND CACHE)
unset(Boost_DIR CACHE)

# Set Boost directory explicitly
set(Boost_DIR "${BOOST_ROOT}/lib/cmake" CACHE PATH "Path to Boost CMake config" FORCE)

# Pre-set component directories to our Boost installation (version 1.90.0)
# This prevents BoostConfig.cmake from searching system paths for components
set(boost_headers_DIR "${BOOST_ROOT}/lib/cmake/boost_headers-1.90.0" CACHE PATH "Boost headers directory" FORCE)
set(boost_unit_test_framework_DIR "${BOOST_ROOT}/lib/cmake/boost_unit_test_framework-1.90.0" CACHE PATH "Boost unit_test_framework directory" FORCE)
set(boost_filesystem_DIR "${BOOST_ROOT}/lib/cmake/boost_filesystem-1.90.0" CACHE PATH "Boost filesystem directory" FORCE)
set(boost_chrono_DIR "${BOOST_ROOT}/lib/cmake/boost_chrono-1.90.0" CACHE PATH "Boost chrono directory" FORCE)
set(boost_timer_DIR "${BOOST_ROOT}/lib/cmake/boost_timer-1.90.0" CACHE PATH "Boost timer directory" FORCE)
set(boost_exception_DIR "${BOOST_ROOT}/lib/cmake/boost_exception-1.90.0" CACHE PATH "Boost exception directory" FORCE)

# Set CMAKE_PREFIX_PATH to prioritize our Boost
set(CMAKE_PREFIX_PATH "${BOOST_ROOT}" "${POCO_ROOT}" "${CMAKE_PREFIX_PATH}")

# Find Boost using Config mode
# Note: system is header-only in newer Boost versions, included via boost_headers
find_package(Boost REQUIRED
    CONFIG
    PATHS "${BOOST_ROOT}/lib/cmake"
    NO_DEFAULT_PATH
    COMPONENTS
        headers
        unit_test_framework
        filesystem
        chrono
        timer
        exception
)

# Print found libraries for verification
message(STATUS "Poco found: ${Poco_FOUND}")
message(STATUS "Poco libraries: ${Poco_LIBRARIES}")
message(STATUS "Boost found: ${Boost_FOUND}")
message(STATUS "Boost version: ${Boost_VERSION}")
message(STATUS "Boost libraries: ${Boost_LIBRARIES}")

# Add test subdirectory
add_subdirectory(test)

