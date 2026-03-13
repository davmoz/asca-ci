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

BOOST_AUTO_TEST_SUITE_END()
