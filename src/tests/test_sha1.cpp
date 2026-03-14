/**
 * Boost.Test unit tests for SHA1 hashing (transformToSHA1 from tools.cpp).
 *
 * Uses OpenSSL EVP API matching the production implementation.
 */

#define BOOST_TEST_MODULE sha1

#include <boost/test/unit_test.hpp>

#include <cstdint>
#include <string>
#include <string_view>
#include <memory>
#include <stdexcept>

#include <openssl/evp.h>

// ----------------------------------------------------------------
// SHA1 using OpenSSL EVP — matches src/tools.cpp implementation
// ----------------------------------------------------------------

std::string transformToSHA1(std::string_view input) {
    std::unique_ptr<EVP_MD_CTX, decltype(&EVP_MD_CTX_free)> ctx{EVP_MD_CTX_new(), EVP_MD_CTX_free};
    if (!ctx) {
        throw std::runtime_error("Failed to create EVP context");
    }

    std::unique_ptr<EVP_MD, decltype(&EVP_MD_free)> md{EVP_MD_fetch(nullptr, "SHA1", nullptr), EVP_MD_free};
    if (!md) {
        throw std::runtime_error("Failed to fetch SHA1");
    }

    if (!EVP_DigestInit_ex(ctx.get(), md.get(), nullptr)) {
        throw std::runtime_error("Message digest initialization failed");
    }

    if (!EVP_DigestUpdate(ctx.get(), input.data(), input.size())) {
        throw std::runtime_error("Message digest update failed");
    }

    unsigned int len = EVP_MD_size(md.get());
    std::string digest(static_cast<size_t>(len), '\0');
    if (!EVP_DigestFinal_ex(ctx.get(), reinterpret_cast<unsigned char*>(digest.data()), &len)) {
        throw std::runtime_error("Message digest finalization failed");
    }

    // Convert binary digest to hex string
    static const char hexDigits[] = "0123456789abcdef";
    std::string hexStr(len * 2, '\0');
    for (unsigned int i = 0; i < len; ++i) {
        auto byte = static_cast<unsigned char>(digest[i]);
        hexStr[i * 2] = hexDigits[byte >> 4];
        hexStr[i * 2 + 1] = hexDigits[byte & 0x0F];
    }
    return hexStr;
}

// ================================================================
//  TESTS — known SHA1 test vectors
// ================================================================

BOOST_AUTO_TEST_CASE(test_sha1_empty_string)
{
    BOOST_TEST(transformToSHA1("") == "da39a3ee5e6b4b0d3255bfef95601890afd80709");
}

BOOST_AUTO_TEST_CASE(test_sha1_hello_world)
{
    BOOST_TEST(transformToSHA1("Hello World") == "0a4d55a8d778e5022fab701977c5d840bbc486d0");
}

BOOST_AUTO_TEST_CASE(test_sha1_password)
{
    BOOST_TEST(transformToSHA1("password") == "5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8");
}

BOOST_AUTO_TEST_CASE(test_sha1_abc)
{
    // NIST test vector: SHA1("abc") = a9993e364706816aba3e25717850c26c9cd0d89d
    BOOST_TEST(transformToSHA1("abc") == "a9993e364706816aba3e25717850c26c9cd0d89d");
}

BOOST_AUTO_TEST_CASE(test_sha1_deterministic)
{
    std::string hash1 = transformToSHA1("test");
    std::string hash2 = transformToSHA1("test");
    BOOST_TEST(hash1 == hash2);
}

BOOST_AUTO_TEST_CASE(test_sha1_different_inputs)
{
    BOOST_TEST(transformToSHA1("abc") != transformToSHA1("abd"));
}

// NIST CAVP short message test vectors (binary inputs)
BOOST_AUTO_TEST_CASE(test_sha1_nist_single_byte)
{
    using namespace std::string_view_literals;
    // SHA1("\x36") = c1dfd96eea8cc2b62785275bca38ac261256e278
    BOOST_TEST(transformToSHA1("\x36"sv) == "c1dfd96eea8cc2b62785275bca38ac261256e278");
}

BOOST_AUTO_TEST_CASE(test_sha1_nist_two_bytes)
{
    using namespace std::string_view_literals;
    // SHA1("\x19\x5a") = 0a1c2d555bbe431ad6288af5a54f93e0449c9232
    BOOST_TEST(transformToSHA1("\x19\x5a"sv) == "0a1c2d555bbe431ad6288af5a54f93e0449c9232");
}

BOOST_AUTO_TEST_CASE(test_sha1_nist_three_bytes)
{
    using namespace std::string_view_literals;
    BOOST_TEST(transformToSHA1("\xdf\x4b\xd2"sv) == "bf36ed5d74727dfd5d7854ec6b1d49468d8ee8aa");
}
