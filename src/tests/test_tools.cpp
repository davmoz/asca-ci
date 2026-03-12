/**
 * Boost.Test unit tests for string utility functions from tools.h/tools.cpp.
 *
 * Pure functions are re-implemented here to avoid pulling in the full TFS
 * dependency graph (configmanager, pugixml, boost::asio, etc.).
 */

#define BOOST_TEST_MODULE tools

#include <boost/test/unit_test.hpp>

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

// ----------------------------------------------------------------
// Extracted pure functions from src/tools.cpp
// ----------------------------------------------------------------

void replaceString(std::string& str, const std::string& sought, const std::string& replacement) {
    size_t pos = 0;
    size_t start = 0;
    size_t soughtLen = sought.length();
    size_t replaceLen = replacement.length();
    while ((pos = str.find(sought, start)) != std::string::npos) {
        str = str.substr(0, pos) + replacement + str.substr(pos + soughtLen);
        start = pos + replaceLen;
    }
}

void trim_right(std::string& source, char t) {
    source.erase(source.find_last_not_of(t) + 1);
}

void trim_left(std::string& source, char t) {
    source.erase(0, source.find_first_not_of(t));
}

void toLowerCaseString(std::string& source) {
    std::transform(source.begin(), source.end(), source.begin(), ::tolower);
}

std::string asLowerCaseString(std::string source) {
    toLowerCaseString(source);
    return source;
}

std::string asUpperCaseString(std::string source) {
    std::transform(source.begin(), source.end(), source.begin(), ::toupper);
    return source;
}

using StringVector = std::vector<std::string>;
using IntegerVector = std::vector<int32_t>;

StringVector explodeString(const std::string& inString, const std::string& separator, int32_t limit = -1) {
    StringVector returnVector;
    std::string::size_type start = 0, end = 0;
    while (--limit != -1 && (end = inString.find(separator, start)) != std::string::npos) {
        returnVector.push_back(inString.substr(start, end - start));
        start = end + separator.size();
    }
    returnVector.push_back(inString.substr(start));
    return returnVector;
}

IntegerVector vectorAtoi(const StringVector& stringVector) {
    IntegerVector returnVector;
    for (const auto& s : stringVector) {
        returnVector.push_back(std::stoi(s));
    }
    return returnVector;
}

void trimString(std::string& str) {
    str.erase(str.find_last_not_of(' ') + 1);
    str.erase(0, str.find_first_not_of(' '));
}

std::string convertIPToString(uint32_t ip) {
    char buffer[17];
    int res = snprintf(buffer, sizeof(buffer), "%u.%u.%u.%u", ip & 0xFF, (ip >> 8) & 0xFF, (ip >> 16) & 0xFF, (ip >> 24));
    if (res < 0) return {};
    return buffer;
}

std::string ucfirst(std::string str) {
    for (char& i : str) {
        if (i != ' ') {
            i = toupper(i);
            break;
        }
    }
    return str;
}

std::string ucwords(std::string str) {
    size_t strLength = str.length();
    if (strLength == 0) return str;
    str[0] = toupper(str.front());
    for (size_t i = 1; i < strLength; ++i) {
        if (str[i - 1] == ' ') {
            str[i] = toupper(str[i]);
        }
    }
    return str;
}

bool booleanString(const std::string& str) {
    if (str.empty()) return false;
    char ch = tolower(str.front());
    return ch != 'f' && ch != 'n' && ch != '0';
}

std::string getFirstLine(const std::string& str) {
    std::string firstLine;
    firstLine.reserve(str.length());
    for (const char c : str) {
        if (c == '\n') break;
        firstLine.push_back(c);
    }
    return firstLine;
}

// ================================================================
//  TESTS
// ================================================================

BOOST_AUTO_TEST_CASE(test_replace_string_basic)
{
    std::string s = "hello world";
    replaceString(s, "world", "there");
    BOOST_TEST(s == "hello there");
}

BOOST_AUTO_TEST_CASE(test_replace_string_multiple)
{
    std::string s = "aaa bbb aaa";
    replaceString(s, "aaa", "ccc");
    BOOST_TEST(s == "ccc bbb ccc");
}

BOOST_AUTO_TEST_CASE(test_replace_string_no_match)
{
    std::string s = "hello";
    replaceString(s, "xyz", "abc");
    BOOST_TEST(s == "hello");
}

BOOST_AUTO_TEST_CASE(test_replace_string_empty_replacement)
{
    std::string s = "hello world";
    replaceString(s, " world", "");
    BOOST_TEST(s == "hello");
}

BOOST_AUTO_TEST_CASE(test_trim_right)
{
    std::string s = "hello   ";
    trim_right(s, ' ');
    BOOST_TEST(s == "hello");
}

BOOST_AUTO_TEST_CASE(test_trim_left)
{
    std::string s = "   hello";
    trim_left(s, ' ');
    BOOST_TEST(s == "hello");
}

BOOST_AUTO_TEST_CASE(test_trim_string)
{
    std::string s = "  hello  ";
    trimString(s);
    BOOST_TEST(s == "hello");
}

BOOST_AUTO_TEST_CASE(test_trim_string_all_spaces)
{
    std::string s = "     ";
    trimString(s);
    BOOST_TEST(s == "");
}

BOOST_AUTO_TEST_CASE(test_to_lower)
{
    std::string s = "Hello World";
    toLowerCaseString(s);
    BOOST_TEST(s == "hello world");
}

BOOST_AUTO_TEST_CASE(test_as_lower)
{
    BOOST_TEST(asLowerCaseString("HELLO") == "hello");
}

BOOST_AUTO_TEST_CASE(test_as_upper)
{
    BOOST_TEST(asUpperCaseString("hello") == "HELLO");
}

BOOST_AUTO_TEST_CASE(test_case_empty)
{
    BOOST_TEST(asLowerCaseString("") == "");
    BOOST_TEST(asUpperCaseString("") == "");
}

BOOST_AUTO_TEST_CASE(test_explode_basic)
{
    auto v = explodeString("a,b,c", ",");
    BOOST_TEST(v.size() == 3u);
    BOOST_TEST(v[0] == "a");
    BOOST_TEST(v[1] == "b");
    BOOST_TEST(v[2] == "c");
}

BOOST_AUTO_TEST_CASE(test_explode_with_limit)
{
    auto v = explodeString("a,b,c,d", ",", 2);
    BOOST_TEST(v.size() == 3u);
    BOOST_TEST(v[0] == "a");
    BOOST_TEST(v[1] == "b");
    BOOST_TEST(v[2] == "c,d");
}

BOOST_AUTO_TEST_CASE(test_explode_no_separator)
{
    auto v = explodeString("hello", ",");
    BOOST_TEST(v.size() == 1u);
    BOOST_TEST(v[0] == "hello");
}

BOOST_AUTO_TEST_CASE(test_explode_multi_char_separator)
{
    auto v = explodeString("a::b::c", "::");
    BOOST_TEST(v.size() == 3u);
    BOOST_TEST(v[0] == "a");
    BOOST_TEST(v[1] == "b");
    BOOST_TEST(v[2] == "c");
}

BOOST_AUTO_TEST_CASE(test_explode_empty_elements)
{
    auto v = explodeString(",a,,b,", ",");
    BOOST_TEST(v.size() == 5u);
    BOOST_TEST(v[0] == "");
    BOOST_TEST(v[1] == "a");
    BOOST_TEST(v[2] == "");
    BOOST_TEST(v[3] == "b");
    BOOST_TEST(v[4] == "");
}

BOOST_AUTO_TEST_CASE(test_vector_atoi)
{
    StringVector sv = {"1", "2", "3"};
    auto iv = vectorAtoi(sv);
    BOOST_TEST(iv.size() == 3u);
    BOOST_TEST(iv[0] == 1);
    BOOST_TEST(iv[1] == 2);
    BOOST_TEST(iv[2] == 3);
}

BOOST_AUTO_TEST_CASE(test_vector_atoi_negative)
{
    StringVector sv = {"-5", "0", "10"};
    auto iv = vectorAtoi(sv);
    BOOST_TEST(iv[0] == -5);
    BOOST_TEST(iv[1] == 0);
    BOOST_TEST(iv[2] == 10);
}

BOOST_AUTO_TEST_CASE(test_convert_ip_localhost)
{
    BOOST_TEST(convertIPToString(0x0100007F) == "127.0.0.1");
}

BOOST_AUTO_TEST_CASE(test_convert_ip_broadcast)
{
    BOOST_TEST(convertIPToString(0xFFFFFFFF) == "255.255.255.255");
}

BOOST_AUTO_TEST_CASE(test_convert_ip_zero)
{
    BOOST_TEST(convertIPToString(0) == "0.0.0.0");
}

BOOST_AUTO_TEST_CASE(test_ucfirst)
{
    BOOST_TEST(ucfirst("hello") == "Hello");
}

BOOST_AUTO_TEST_CASE(test_ucfirst_leading_spaces)
{
    BOOST_TEST(ucfirst("  hello") == "  Hello");
}

BOOST_AUTO_TEST_CASE(test_ucfirst_empty)
{
    BOOST_TEST(ucfirst("") == "");
}

BOOST_AUTO_TEST_CASE(test_ucwords)
{
    BOOST_TEST(ucwords("hello world test") == "Hello World Test");
}

BOOST_AUTO_TEST_CASE(test_ucwords_empty)
{
    BOOST_TEST(ucwords("") == "");
}

BOOST_AUTO_TEST_CASE(test_boolean_string_true)
{
    BOOST_TEST(booleanString("true"));
    BOOST_TEST(booleanString("yes"));
    BOOST_TEST(booleanString("1"));
    BOOST_TEST(booleanString("True"));
}

BOOST_AUTO_TEST_CASE(test_boolean_string_false)
{
    BOOST_TEST(!booleanString("false"));
    BOOST_TEST(!booleanString("no"));
    BOOST_TEST(!booleanString("0"));
    BOOST_TEST(!booleanString(""));
}

BOOST_AUTO_TEST_CASE(test_get_first_line)
{
    BOOST_TEST(getFirstLine("line1\nline2\nline3") == "line1");
    BOOST_TEST(getFirstLine("hello") == "hello");
    BOOST_TEST(getFirstLine("") == "");
    BOOST_TEST(getFirstLine("\nhello") == "");
}
