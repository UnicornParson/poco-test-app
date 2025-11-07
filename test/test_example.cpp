#define BOOST_TEST_MODULE poco_test_example
#include <boost/test/unit_test.hpp>

#include <Poco/Foundation.h>
#include <Poco/Exception.h>
#include <Poco/String.h>

#include <boost/filesystem.hpp>
#include <boost/system/error_code.hpp>

#include <string>
#include <vector>
#include <cmath>

// Simple test case
BOOST_AUTO_TEST_CASE(test_basic_arithmetic)
{
    int a = 2;
    int b = 3;
    BOOST_TEST(a + b == 5);
    BOOST_TEST(a * b == 6);
    BOOST_TEST(b - a == 1);
}

// Test case with assertions
BOOST_AUTO_TEST_CASE(test_string_operations)
{
    std::string str = "Hello, World!";
    BOOST_TEST(str.length() == 13);
    BOOST_TEST(str.find("World") != std::string::npos);
    BOOST_TEST(str.substr(0, 5) == "Hello");
}

// Test case using Poco string utilities
BOOST_AUTO_TEST_CASE(test_poco_string_utilities)
{
    std::string str = "  Hello World  ";
    
    // Test Poco string trimming
    std::string trimmed = Poco::trim(str);
    BOOST_TEST(trimmed == "Hello World");
    
    // Test Poco string case conversion
    std::string upper = Poco::toUpper(trimmed);
    std::string lower = Poco::toLower(trimmed);
    BOOST_TEST(upper == "HELLO WORLD");
    BOOST_TEST(lower == "hello world");
    
    // Test Poco string replace
    std::string replaced = Poco::replace(trimmed, "World", "Boost");
    BOOST_TEST(replaced == "Hello Boost");
}

// Test case with exceptions
BOOST_AUTO_TEST_CASE(test_exception_handling)
{
    BOOST_CHECK_THROW(
        throw Poco::RuntimeException("Test exception"),
        Poco::RuntimeException
    );
    
    BOOST_CHECK_NO_THROW(
        int x = 42;
        BOOST_TEST(x == 42);
    );
}

// Test case with floating point comparison
BOOST_AUTO_TEST_CASE(test_floating_point)
{
    double a = 0.1;
    double b = 0.2;
    double sum = a + b;
    
    // Use tolerance for floating point comparison
    BOOST_TEST(sum == 0.3, boost::test_tools::tolerance(1e-9));
    
    // Test sqrt
    BOOST_TEST(std::sqrt(4.0) == 2.0, boost::test_tools::tolerance(1e-9));
    BOOST_TEST(std::sqrt(9.0) == 3.0, boost::test_tools::tolerance(1e-9));
}

// Test case using Boost.Filesystem
BOOST_AUTO_TEST_CASE(test_boost_filesystem)
{
    namespace fs = boost::filesystem;
    
    // Test path operations
    fs::path p1("/usr/local");
    fs::path p2("bin");
    fs::path p3 = p1 / p2;
    
    BOOST_TEST(p3.string() == "/usr/local/bin");
    BOOST_TEST(p3.parent_path() == p1);
    BOOST_TEST(p3.filename() == p2);
}

// Test case with vectors
BOOST_AUTO_TEST_CASE(test_vector_operations)
{
    std::vector<int> vec = {1, 2, 3, 4, 5};
    
    BOOST_TEST(vec.size() == 5);
    BOOST_TEST(vec[0] == 1);
    BOOST_TEST(vec[4] == 5);
    
    vec.push_back(6);
    BOOST_TEST(vec.size() == 6);
    BOOST_TEST(vec.back() == 6);
}

// Test suite example
BOOST_AUTO_TEST_SUITE(test_suite_example)

BOOST_AUTO_TEST_CASE(test_case_1)
{
    BOOST_TEST(1 + 1 == 2);
}

BOOST_AUTO_TEST_CASE(test_case_2)
{
    BOOST_TEST(2 * 2 == 4);
}

BOOST_AUTO_TEST_SUITE_END()

