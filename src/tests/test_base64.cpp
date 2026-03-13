#define BOOST_TEST_MODULE Base64Test
#include <boost/test/unit_test.hpp>

#include "base64.h"

BOOST_AUTO_TEST_SUITE(base64_suite)

BOOST_AUTO_TEST_CASE(encode_empty)
{
	BOOST_CHECK_EQUAL(base64::encode(""), "");
}

BOOST_AUTO_TEST_CASE(encode_hello)
{
	BOOST_CHECK_EQUAL(base64::encode("Hello"), "SGVsbG8=");
}

BOOST_AUTO_TEST_CASE(encode_hello_world)
{
	BOOST_CHECK_EQUAL(base64::encode("Hello, World!"), "SGVsbG8sIFdvcmxkIQ==");
}

BOOST_AUTO_TEST_CASE(decode_empty)
{
	BOOST_CHECK_EQUAL(base64::decode(""), "");
}

BOOST_AUTO_TEST_CASE(decode_hello)
{
	BOOST_CHECK_EQUAL(base64::decode("SGVsbG8="), "Hello");
}

BOOST_AUTO_TEST_CASE(decode_hello_world)
{
	BOOST_CHECK_EQUAL(base64::decode("SGVsbG8sIFdvcmxkIQ=="), "Hello, World!");
}

BOOST_AUTO_TEST_CASE(roundtrip)
{
	std::string original = "The quick brown fox jumps over the lazy dog";
	BOOST_CHECK_EQUAL(base64::decode(base64::encode(original)), original);
}

BOOST_AUTO_TEST_CASE(roundtrip_binary)
{
	std::string binary;
	for (int i = 0; i < 256; ++i) {
		binary.push_back(static_cast<char>(i));
	}
	BOOST_CHECK_EQUAL(base64::decode(base64::encode(binary)), binary);
}

// --- Padding variants ---

BOOST_AUTO_TEST_CASE(encode_1_byte_no_padding_needed)
{
	// 3 bytes = no padding
	BOOST_CHECK_EQUAL(base64::encode("abc"), "YWJj");
}

BOOST_AUTO_TEST_CASE(encode_1_byte_one_pad)
{
	// 2 bytes = 1 padding char
	BOOST_CHECK_EQUAL(base64::encode("ab"), "YWI=");
}

BOOST_AUTO_TEST_CASE(encode_1_byte_two_pad)
{
	// 1 byte = 2 padding chars
	BOOST_CHECK_EQUAL(base64::encode("a"), "YQ==");
}

BOOST_AUTO_TEST_CASE(encode_4_bytes)
{
	// 4 bytes: 1 group of 3 + 1 remainder
	BOOST_CHECK_EQUAL(base64::encode("abcd"), "YWJjZA==");
}

BOOST_AUTO_TEST_CASE(encode_5_bytes)
{
	// 5 bytes: 1 group of 3 + 2 remainder
	BOOST_CHECK_EQUAL(base64::encode("abcde"), "YWJjZGU=");
}

BOOST_AUTO_TEST_CASE(encode_6_bytes)
{
	// 6 bytes: 2 groups of 3, no padding
	BOOST_CHECK_EQUAL(base64::encode("abcdef"), "YWJjZGVm");
}

// --- Special characters ---

BOOST_AUTO_TEST_CASE(roundtrip_special_chars)
{
	std::string special = "!@#$%^&*()_+-=[]{}|;':\",./<>?\n\t\r";
	BOOST_CHECK_EQUAL(base64::decode(base64::encode(special)), special);
}

BOOST_AUTO_TEST_CASE(roundtrip_null_bytes)
{
	std::string withNulls = std::string("hello\0world\0", 12);
	BOOST_CHECK_EQUAL(base64::decode(base64::encode(withNulls)), withNulls);
}

BOOST_AUTO_TEST_CASE(roundtrip_unicode_bytes)
{
	std::string utf8 = "\xc3\xa9\xc3\xa0\xc3\xbc"; // éàü in UTF-8
	BOOST_CHECK_EQUAL(base64::decode(base64::encode(utf8)), utf8);
}

// --- Large data ---

BOOST_AUTO_TEST_CASE(roundtrip_large)
{
	// 10 KB of patterned data
	std::string large;
	large.reserve(10240);
	for (int i = 0; i < 10240; ++i) {
		large.push_back(static_cast<char>(i % 256));
	}
	BOOST_CHECK_EQUAL(base64::decode(base64::encode(large)), large);
}

// --- Invalid input handling ---

BOOST_AUTO_TEST_CASE(decode_invalid_no_crash)
{
	// Invalid base64 should not crash, just return empty or partial
	BOOST_CHECK_NO_THROW(base64::decode("!!!not-base64!!!"));
	BOOST_CHECK_NO_THROW(base64::decode("===="));
	BOOST_CHECK_NO_THROW(base64::decode("A"));
}

BOOST_AUTO_TEST_CASE(decode_single_char)
{
	// Single char is not valid base64 but should not crash
	BOOST_CHECK_NO_THROW(base64::decode("Q"));
}

BOOST_AUTO_TEST_CASE(decode_whitespace_only)
{
	BOOST_CHECK_NO_THROW(base64::decode("   "));
}

BOOST_AUTO_TEST_SUITE_END()
