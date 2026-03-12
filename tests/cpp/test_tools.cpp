/**
 * Unit tests for tools.h/tools.cpp utility functions.
 *
 * These tests re-implement or extract the pure functions from tools.cpp
 * to avoid pulling in the full TFS dependency graph (otpch.h, configmanager,
 * boost::asio, etc.). The implementations tested here are identical to those
 * in src/tools.cpp.
 */

#include <gtest/gtest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <random>
#include <string>
#include <unordered_map>
#include <vector>

// ----------------------------------------------------------------
// Extracted pure functions from src/tools.cpp (no external deps)
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
    int res = sprintf(buffer, "%u.%u.%u.%u", ip & 0xFF, (ip >> 8) & 0xFF, (ip >> 16) & 0xFF, (ip >> 24));
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

constexpr bool hasBitSet(uint32_t flag, uint32_t flags) {
    return (flags & flag) != 0;
}

static constexpr int32_t NETWORKMESSAGE_MAXSIZE = 24590;

uint32_t adlerChecksum(const uint8_t* data, size_t length) {
    if (length > static_cast<size_t>(NETWORKMESSAGE_MAXSIZE)) return 0;
    const uint16_t adler = 65521;
    uint32_t a = 1, b = 0;
    while (length > 0) {
        size_t tmp = length > 5552 ? 5552 : length;
        length -= tmp;
        do {
            a += *data++;
            b += a;
        } while (--tmp);
        a %= adler;
        b %= adler;
    }
    return (b << 16) | a;
}

enum CombatType_t : uint16_t {
    COMBAT_NONE = 0,
    COMBAT_PHYSICALDAMAGE = 1 << 0,
    COMBAT_ENERGYDAMAGE = 1 << 1,
    COMBAT_EARTHDAMAGE = 1 << 2,
    COMBAT_FIREDAMAGE = 1 << 3,
    COMBAT_UNDEFINEDDAMAGE = 1 << 4,
    COMBAT_LIFEDRAIN = 1 << 5,
    COMBAT_MANADRAIN = 1 << 6,
    COMBAT_HEALING = 1 << 7,
    COMBAT_DROWNDAMAGE = 1 << 8,
    COMBAT_ICEDAMAGE = 1 << 9,
    COMBAT_HOLYDAMAGE = 1 << 10,
    COMBAT_DEATHDAMAGE = 1 << 11,
};

size_t combatTypeToIndex(CombatType_t combatType) {
    switch (combatType) {
        case COMBAT_PHYSICALDAMAGE: return 0;
        case COMBAT_ENERGYDAMAGE:   return 1;
        case COMBAT_EARTHDAMAGE:    return 2;
        case COMBAT_FIREDAMAGE:     return 3;
        case COMBAT_UNDEFINEDDAMAGE:return 4;
        case COMBAT_LIFEDRAIN:      return 5;
        case COMBAT_MANADRAIN:      return 6;
        case COMBAT_HEALING:        return 7;
        case COMBAT_DROWNDAMAGE:    return 8;
        case COMBAT_ICEDAMAGE:      return 9;
        case COMBAT_HOLYDAMAGE:     return 10;
        case COMBAT_DEATHDAMAGE:    return 11;
        default: return 0;
    }
}

CombatType_t indexToCombatType(size_t v) {
    return static_cast<CombatType_t>(1 << v);
}

// ----- SHA1 extracted from tools.cpp -----
static uint32_t circularShift(int bits, uint32_t value) {
    return (value << bits) | (value >> (32 - bits));
}

static void processSHA1MessageBlock(const uint8_t* messageBlock, uint32_t* H) {
    uint32_t W[80];
    for (int i = 0; i < 16; ++i) {
        const size_t offset = i << 2;
        W[i] = messageBlock[offset] << 24 | messageBlock[offset + 1] << 16 | messageBlock[offset + 2] << 8 | messageBlock[offset + 3];
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

std::string transformToSHA1(const std::string& input) {
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
//  TESTS
// ================================================================

// ---- replaceString ----
TEST(ToolsReplaceString, BasicReplacement) {
    std::string s = "hello world";
    replaceString(s, "world", "there");
    EXPECT_EQ(s, "hello there");
}

TEST(ToolsReplaceString, MultipleOccurrences) {
    std::string s = "aaa bbb aaa";
    replaceString(s, "aaa", "ccc");
    EXPECT_EQ(s, "ccc bbb ccc");
}

TEST(ToolsReplaceString, NoMatch) {
    std::string s = "hello";
    replaceString(s, "xyz", "abc");
    EXPECT_EQ(s, "hello");
}

TEST(ToolsReplaceString, EmptyReplacement) {
    std::string s = "hello world";
    replaceString(s, " world", "");
    EXPECT_EQ(s, "hello");
}

TEST(ToolsReplaceString, OverlappingPattern) {
    std::string s = "aaa";
    replaceString(s, "aa", "b");
    EXPECT_EQ(s, "ba");
}

// ---- trim functions ----
TEST(ToolsTrim, TrimRight) {
    std::string s = "hello   ";
    trim_right(s, ' ');
    EXPECT_EQ(s, "hello");
}

TEST(ToolsTrim, TrimLeft) {
    std::string s = "   hello";
    trim_left(s, ' ');
    EXPECT_EQ(s, "hello");
}

TEST(ToolsTrim, TrimString) {
    std::string s = "  hello  ";
    trimString(s);
    EXPECT_EQ(s, "hello");
}

TEST(ToolsTrim, TrimRightCustomChar) {
    std::string s = "hello...";
    trim_right(s, '.');
    EXPECT_EQ(s, "hello");
}

TEST(ToolsTrim, TrimLeftCustomChar) {
    std::string s = "...hello";
    trim_left(s, '.');
    EXPECT_EQ(s, "hello");
}

TEST(ToolsTrim, TrimStringAllSpaces) {
    std::string s = "     ";
    trimString(s);
    EXPECT_EQ(s, "");
}

// ---- case conversion ----
TEST(ToolsCase, ToLower) {
    std::string s = "Hello World";
    toLowerCaseString(s);
    EXPECT_EQ(s, "hello world");
}

TEST(ToolsCase, AsLower) {
    EXPECT_EQ(asLowerCaseString("HELLO"), "hello");
}

TEST(ToolsCase, AsUpper) {
    EXPECT_EQ(asUpperCaseString("hello"), "HELLO");
}

TEST(ToolsCase, MixedCase) {
    EXPECT_EQ(asLowerCaseString("HeLLo WoRLd"), "hello world");
    EXPECT_EQ(asUpperCaseString("HeLLo WoRLd"), "HELLO WORLD");
}

TEST(ToolsCase, EmptyString) {
    EXPECT_EQ(asLowerCaseString(""), "");
    EXPECT_EQ(asUpperCaseString(""), "");
}

// ---- explodeString ----
TEST(ToolsExplode, BasicSplit) {
    auto v = explodeString("a,b,c", ",");
    ASSERT_EQ(v.size(), 3u);
    EXPECT_EQ(v[0], "a");
    EXPECT_EQ(v[1], "b");
    EXPECT_EQ(v[2], "c");
}

TEST(ToolsExplode, WithLimit) {
    auto v = explodeString("a,b,c,d", ",", 2);
    ASSERT_EQ(v.size(), 2u);
    EXPECT_EQ(v[0], "a");
    EXPECT_EQ(v[1], "b,c,d");
}

TEST(ToolsExplode, NoSeparator) {
    auto v = explodeString("hello", ",");
    ASSERT_EQ(v.size(), 1u);
    EXPECT_EQ(v[0], "hello");
}

TEST(ToolsExplode, MultiCharSeparator) {
    auto v = explodeString("a::b::c", "::");
    ASSERT_EQ(v.size(), 3u);
    EXPECT_EQ(v[0], "a");
    EXPECT_EQ(v[1], "b");
    EXPECT_EQ(v[2], "c");
}

TEST(ToolsExplode, EmptyString) {
    auto v = explodeString("", ",");
    ASSERT_EQ(v.size(), 1u);
    EXPECT_EQ(v[0], "");
}

TEST(ToolsExplode, EmptyElements) {
    auto v = explodeString(",a,,b,", ",");
    ASSERT_EQ(v.size(), 5u);
    EXPECT_EQ(v[0], "");
    EXPECT_EQ(v[1], "a");
    EXPECT_EQ(v[2], "");
    EXPECT_EQ(v[3], "b");
    EXPECT_EQ(v[4], "");
}

// ---- vectorAtoi ----
TEST(ToolsVectorAtoi, BasicConversion) {
    StringVector sv = {"1", "2", "3"};
    auto iv = vectorAtoi(sv);
    ASSERT_EQ(iv.size(), 3u);
    EXPECT_EQ(iv[0], 1);
    EXPECT_EQ(iv[1], 2);
    EXPECT_EQ(iv[2], 3);
}

TEST(ToolsVectorAtoi, NegativeNumbers) {
    StringVector sv = {"-5", "0", "10"};
    auto iv = vectorAtoi(sv);
    EXPECT_EQ(iv[0], -5);
    EXPECT_EQ(iv[1], 0);
    EXPECT_EQ(iv[2], 10);
}

// ---- IP conversion ----
TEST(ToolsIP, ConvertLocalhost) {
    // 127.0.0.1 in little-endian = 0x0100007F
    EXPECT_EQ(convertIPToString(0x0100007F), "127.0.0.1");
}

TEST(ToolsIP, ConvertBroadcast) {
    EXPECT_EQ(convertIPToString(0xFFFFFFFF), "255.255.255.255");
}

TEST(ToolsIP, ConvertZero) {
    EXPECT_EQ(convertIPToString(0), "0.0.0.0");
}

TEST(ToolsIP, Convert192168) {
    // 192.168.1.1 => 0x0101A8C0
    EXPECT_EQ(convertIPToString(0x0101A8C0), "192.168.1.1");
}

// ---- ucfirst / ucwords ----
TEST(ToolsCase, Ucfirst) {
    EXPECT_EQ(ucfirst("hello"), "Hello");
}

TEST(ToolsCase, UcfirstLeadingSpaces) {
    EXPECT_EQ(ucfirst("  hello"), "  Hello");
}

TEST(ToolsCase, UcfirstEmpty) {
    EXPECT_EQ(ucfirst(""), "");
}

TEST(ToolsCase, Ucwords) {
    EXPECT_EQ(ucwords("hello world test"), "Hello World Test");
}

TEST(ToolsCase, UcwordsEmpty) {
    EXPECT_EQ(ucwords(""), "");
}

TEST(ToolsCase, UcwordsSingleWord) {
    EXPECT_EQ(ucwords("hello"), "Hello");
}

// ---- booleanString ----
TEST(ToolsBoolean, TrueValues) {
    EXPECT_TRUE(booleanString("true"));
    EXPECT_TRUE(booleanString("yes"));
    EXPECT_TRUE(booleanString("1"));
    EXPECT_TRUE(booleanString("True"));
    EXPECT_TRUE(booleanString("YES"));
}

TEST(ToolsBoolean, FalseValues) {
    EXPECT_FALSE(booleanString("false"));
    EXPECT_FALSE(booleanString("no"));
    EXPECT_FALSE(booleanString("0"));
    EXPECT_FALSE(booleanString(""));
}

// ---- getFirstLine ----
TEST(ToolsFirstLine, MultiLine) {
    EXPECT_EQ(getFirstLine("line1\nline2\nline3"), "line1");
}

TEST(ToolsFirstLine, SingleLine) {
    EXPECT_EQ(getFirstLine("hello"), "hello");
}

TEST(ToolsFirstLine, Empty) {
    EXPECT_EQ(getFirstLine(""), "");
}

TEST(ToolsFirstLine, StartsWithNewline) {
    EXPECT_EQ(getFirstLine("\nhello"), "");
}

// ---- hasBitSet ----
TEST(ToolsBits, HasBitSet) {
    EXPECT_TRUE(hasBitSet(0x01, 0x0F));
    EXPECT_TRUE(hasBitSet(0x04, 0x0F));
    EXPECT_FALSE(hasBitSet(0x10, 0x0F));
    EXPECT_FALSE(hasBitSet(0x01, 0x00));
}

// ---- adlerChecksum ----
TEST(ToolsAdler, BasicChecksum) {
    const char* data = "Hello";
    uint32_t checksum = adlerChecksum(reinterpret_cast<const uint8_t*>(data), 5);
    EXPECT_NE(checksum, 0u);
    // Verify known Adler-32 for "Hello": 0x058C01F5
    EXPECT_EQ(checksum, 0x058C01F5u);
}

TEST(ToolsAdler, EmptyData) {
    uint32_t checksum = adlerChecksum(nullptr, 0);
    // a=1, b=0 => (0 << 16) | 1 = 1
    EXPECT_EQ(checksum, 1u);
}

TEST(ToolsAdler, OversizedReturnsZero) {
    uint32_t checksum = adlerChecksum(nullptr, NETWORKMESSAGE_MAXSIZE + 1);
    EXPECT_EQ(checksum, 0u);
}

// ---- combatTypeToIndex / indexToCombatType ----
TEST(ToolsCombat, TypeToIndex) {
    EXPECT_EQ(combatTypeToIndex(COMBAT_PHYSICALDAMAGE), 0u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_ENERGYDAMAGE), 1u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_FIREDAMAGE), 3u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_ICEDAMAGE), 9u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_DEATHDAMAGE), 11u);
}

TEST(ToolsCombat, IndexToType) {
    EXPECT_EQ(indexToCombatType(0), COMBAT_PHYSICALDAMAGE);
    EXPECT_EQ(indexToCombatType(1), COMBAT_ENERGYDAMAGE);
    EXPECT_EQ(indexToCombatType(3), COMBAT_FIREDAMAGE);
    EXPECT_EQ(indexToCombatType(9), COMBAT_ICEDAMAGE);
}

TEST(ToolsCombat, RoundTrip) {
    for (size_t i = 0; i < 12; ++i) {
        CombatType_t ct = indexToCombatType(i);
        EXPECT_EQ(combatTypeToIndex(ct), i);
    }
}

// ---- SHA1 ----
TEST(ToolsSHA1, EmptyString) {
    EXPECT_EQ(transformToSHA1(""), "da39a3ee5e6b4b0d3255bfef95601890afd80709");
}

TEST(ToolsSHA1, HelloWorld) {
    // SHA1("Hello World") = 0a4d55a8d778e5022fab701977c5d840bbc486d0
    EXPECT_EQ(transformToSHA1("Hello World"), "0a4d55a8d778e5022fab701977c5d840bbc486d0");
}

TEST(ToolsSHA1, Password) {
    // SHA1("password") = 5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8
    EXPECT_EQ(transformToSHA1("password"), "5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8");
}

TEST(ToolsSHA1, Deterministic) {
    std::string hash1 = transformToSHA1("test");
    std::string hash2 = transformToSHA1("test");
    EXPECT_EQ(hash1, hash2);
}

TEST(ToolsSHA1, DifferentInputsDifferentHashes) {
    EXPECT_NE(transformToSHA1("abc"), transformToSHA1("abd"));
}
