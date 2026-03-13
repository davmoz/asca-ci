/**
 * Boost.Test unit tests for SHA1 hashing (transformToSHA1 from tools.cpp).
 *
 * The SHA1 implementation is re-implemented here to avoid pulling in
 * the full TFS dependency graph.
 */

#define BOOST_TEST_MODULE sha1

#include <boost/test/unit_test.hpp>

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

// ----------------------------------------------------------------
// SHA1 extracted from src/tools.cpp
// ----------------------------------------------------------------

static uint32_t circularShift(int bits, uint32_t value) {
    return (value << bits) | (value >> (32 - bits));
}

static void processSHA1MessageBlock(const uint8_t* messageBlock, uint32_t* H) {
    uint32_t W[80];
    for (int i = 0; i < 16; ++i) {
        const size_t offset = i << 2;
        W[i] = messageBlock[offset] << 24 | messageBlock[offset + 1] << 16 |
               messageBlock[offset + 2] << 8 | messageBlock[offset + 3];
    }
    for (int i = 16; i < 80; ++i) {
        W[i] = circularShift(1, W[i - 3] ^ W[i - 8] ^ W[i - 14] ^ W[i - 16]);
    }
    uint32_t A = H[0], B = H[1], C = H[2], D = H[3], E = H[4];
    for (int i = 0; i < 20; ++i) {
        const uint32_t tmp = circularShift(5, A) + ((B & C) | ((~B) & D)) + E + W[i] + 0x5A827999;
        E = D; D = C; C = circularShift(30, B); B = A; A = tmp;
    }
    for (int i = 20; i < 40; ++i) {
        const uint32_t tmp = circularShift(5, A) + (B ^ C ^ D) + E + W[i] + 0x6ED9EBA1;
        E = D; D = C; C = circularShift(30, B); B = A; A = tmp;
    }
    for (int i = 40; i < 60; ++i) {
        const uint32_t tmp = circularShift(5, A) + ((B & C) | (B & D) | (C & D)) + E + W[i] + 0x8F1BBCDC;
        E = D; D = C; C = circularShift(30, B); B = A; A = tmp;
    }
    for (int i = 60; i < 80; ++i) {
        const uint32_t tmp = circularShift(5, A) + (B ^ C ^ D) + E + W[i] + 0xCA62C1D6;
        E = D; D = C; C = circularShift(30, B); B = A; A = tmp;
    }
    H[0] += A; H[1] += B; H[2] += C; H[3] += D; H[4] += E;
}

std::string transformToSHA1(std::string_view input) {
    uint32_t H[] = {0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0};
    uint8_t messageBlock[64];
    size_t index = 0;
    uint32_t length_low = 0;
    uint32_t length_high = 0;
    for (char ch : input) {
        messageBlock[index++] = ch;
        length_low += 8;
        if (length_low == 0) length_high++;
        if (index == 64) {
            processSHA1MessageBlock(messageBlock, H);
            index = 0;
        }
    }
    messageBlock[index++] = 0x80;
    if (index > 56) {
        while (index < 64) messageBlock[index++] = 0;
        processSHA1MessageBlock(messageBlock, H);
        index = 0;
    }
    while (index < 56) messageBlock[index++] = 0;
    messageBlock[56] = length_high >> 24;
    messageBlock[57] = length_high >> 16;
    messageBlock[58] = length_high >> 8;
    messageBlock[59] = length_high;
    messageBlock[60] = length_low >> 24;
    messageBlock[61] = length_low >> 16;
    messageBlock[62] = length_low >> 8;
    messageBlock[63] = length_low;
    processSHA1MessageBlock(messageBlock, H);
    char hexstring[41];
    static const char hexDigits[] = {"0123456789abcdef"};
    for (int hashByte = 20; --hashByte >= 0;) {
        const uint8_t byte = H[hashByte >> 2] >> (((3 - hashByte) & 3) << 3);
        index = hashByte << 1;
        hexstring[index] = hexDigits[byte >> 4];
        hexstring[index + 1] = hexDigits[byte & 15];
    }
    return std::string(hexstring, 40);
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
