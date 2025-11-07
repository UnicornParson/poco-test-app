# Test directory CMakeLists.txt
# This file is included by the root CMakeLists.txt
# Add your unit tests here using Boost.Test

# Enable testing
enable_testing()

# Example test executable
add_executable(test_example
    test_json.cpp
)

target_link_libraries(test_example
    PRIVATE
        Poco::Foundation
        Poco::Util
        Poco::XML
        Poco::JSON
        Poco::Net
        Poco::Crypto
        Poco::NetSSL
        Boost::headers
        Boost::unit_test_framework
        Boost::filesystem
)

# Add test to CTest
add_test(NAME test_example COMMAND test_example)

