/**
 * Boost.Test unit tests for XTEA encryption/decryption.
 *
 * Links against the actual xtea.cpp implementation but avoids pulling in
 * the rest of the TFS dependency graph by not including otpch.h.
 */

#define BOOST_TEST_MODULE xtea

#include <boost/test/unit_test.hpp>

#include <array>
#include <cstdint>
#include <cstring>
#include <vector>

// Forward-declare the xtea namespace matching src/xtea.h
namespace xtea {
using key = std::array<uint32_t, 4>;
void encrypt(uint8_t* data, size_t length, const key& k);
void decrypt(uint8_t* data, size_t length, const key& k);
}

// ================================================================
//  TESTS
// ================================================================

BOOST_AUTO_TEST_CASE(test_xtea_encrypt)
{
    // Known test vector: encrypt 0xdeadbeef 0xdeadbeef with key {0xdeadbeef x4}
    std::vector<uint8_t> data = {0xef, 0xbe, 0xad, 0xde, 0xef, 0xbe, 0xad, 0xde};
    std::vector<uint8_t> original = data;

    xtea::key k = {0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef};
    xtea::encrypt(data.data(), data.size(), k);

    // After encryption, data should differ from the original
    BOOST_TEST(data != original);
}

BOOST_AUTO_TEST_CASE(test_xtea_decrypt_reverses_encrypt)
{
    std::vector<uint8_t> original = {0xef, 0xbe, 0xad, 0xde, 0xef, 0xbe, 0xad, 0xde};
    std::vector<uint8_t> data = original;

    xtea::key k = {0xdeadbeef, 0xdeadbeef, 0xdeadbeef, 0xdeadbeef};
    xtea::encrypt(data.data(), data.size(), k);
    xtea::decrypt(data.data(), data.size(), k);

    BOOST_TEST(data == original);
}

BOOST_AUTO_TEST_CASE(test_xtea_roundtrip_zeros)
{
    std::vector<uint8_t> original(8, 0x00);
    std::vector<uint8_t> data = original;

    xtea::key k = {0x01020304, 0x05060708, 0x090a0b0c, 0x0d0e0f10};
    xtea::encrypt(data.data(), data.size(), k);
    BOOST_TEST(data != original);
    xtea::decrypt(data.data(), data.size(), k);
    BOOST_TEST(data == original);
}

BOOST_AUTO_TEST_CASE(test_xtea_roundtrip_multiple_blocks)
{
    // 24 bytes = 3 blocks of 8
    std::vector<uint8_t> original = {
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
        0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28,
    };
    std::vector<uint8_t> data = original;

    xtea::key k = {0xAAAAAAAA, 0xBBBBBBBB, 0xCCCCCCCC, 0xDDDDDDDD};
    xtea::encrypt(data.data(), data.size(), k);
    BOOST_TEST(data != original);
    xtea::decrypt(data.data(), data.size(), k);
    BOOST_TEST(data == original);
}

BOOST_AUTO_TEST_CASE(test_xtea_different_keys_different_output)
{
    std::vector<uint8_t> data1 = {0xef, 0xbe, 0xad, 0xde, 0xef, 0xbe, 0xad, 0xde};
    std::vector<uint8_t> data2 = data1;

    xtea::key k1 = {0x11111111, 0x22222222, 0x33333333, 0x44444444};
    xtea::key k2 = {0x55555555, 0x66666666, 0x77777777, 0x88888888};

    xtea::encrypt(data1.data(), data1.size(), k1);
    xtea::encrypt(data2.data(), data2.size(), k2);

    BOOST_TEST(data1 != data2);
}

BOOST_AUTO_TEST_CASE(test_xtea_wrong_key_does_not_decrypt)
{
    std::vector<uint8_t> original = {0xef, 0xbe, 0xad, 0xde, 0xef, 0xbe, 0xad, 0xde};
    std::vector<uint8_t> data = original;

    xtea::key k_encrypt = {0x11111111, 0x22222222, 0x33333333, 0x44444444};
    xtea::key k_wrong   = {0x55555555, 0x66666666, 0x77777777, 0x88888888};

    xtea::encrypt(data.data(), data.size(), k_encrypt);
    xtea::decrypt(data.data(), data.size(), k_wrong);

    BOOST_TEST(data != original);
}
