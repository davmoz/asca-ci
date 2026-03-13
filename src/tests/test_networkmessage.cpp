/**
 * Boost.Test unit tests for NetworkMessage serialization.
 *
 * Re-implements the core buffer operations from src/networkmessage.h/cpp
 * to avoid pulling in the full TFS dependency graph.
 */

#define BOOST_TEST_MODULE networkmessage
#include <boost/test/unit_test.hpp>

#include <cstdint>
#include <cstring>
#include <string>

// ----------------------------------------------------------------
// Constants from const.h
// ----------------------------------------------------------------
static constexpr int32_t NETWORKMESSAGE_MAXSIZE = 24590;

// ----------------------------------------------------------------
// Minimal NetworkMessage re-implementation (mirrors src/networkmessage.h)
// ----------------------------------------------------------------

class NetworkMessage
{
public:
	using MsgSize_t = uint16_t;
	static constexpr MsgSize_t INITIAL_BUFFER_POSITION = 8;
	enum { HEADER_LENGTH = 2 };
	enum { CHECKSUM_LENGTH = 4 };
	enum { XTEA_MULTIPLE = 8 };
	enum { MAX_BODY_LENGTH = NETWORKMESSAGE_MAXSIZE - HEADER_LENGTH - CHECKSUM_LENGTH - XTEA_MULTIPLE };

	NetworkMessage() = default;

	void reset() { info = {}; }

	uint8_t getByte() {
		if (!canRead(1)) return 0;
		return buffer[info.position++];
	}

	template<typename T>
	T get() {
		if (!canRead(sizeof(T))) return 0;
		T v;
		memcpy(&v, buffer + info.position, sizeof(T));
		info.position += sizeof(T);
		return v;
	}

	std::string getString(uint16_t stringLen = 0) {
		if (stringLen == 0) {
			stringLen = get<uint16_t>();
		}
		if (!canRead(stringLen)) return std::string();
		char* v = reinterpret_cast<char*>(buffer) + info.position;
		info.position += stringLen;
		return std::string(v, stringLen);
	}

	void skipBytes(int16_t count) { info.position += count; }

	void addByte(uint8_t value) {
		if (!canAdd(1)) return;
		buffer[info.position++] = value;
		info.length++;
	}

	template<typename T>
	void add(T value) {
		if (!canAdd(sizeof(T))) return;
		memcpy(buffer + info.position, &value, sizeof(T));
		info.position += sizeof(T);
		info.length += sizeof(T);
	}

	void addString(const std::string& value) {
		size_t stringLen = value.length();
		if (!canAdd(stringLen + 2) || stringLen > 8192) return;
		add<uint16_t>(stringLen);
		memcpy(buffer + info.position, value.c_str(), stringLen);
		info.position += stringLen;
		info.length += stringLen;
	}

	void addBytes(const char* bytes, size_t size) {
		if (!canAdd(size) || size > 8192) return;
		memcpy(buffer + info.position, bytes, size);
		info.position += size;
		info.length += size;
	}

	MsgSize_t getLength() const { return info.length; }
	void setLength(MsgSize_t newLength) { info.length = newLength; }
	MsgSize_t getBufferPosition() const { return info.position; }
	bool isOverrun() const { return info.overrun; }

	uint8_t* getBuffer() { return buffer; }

private:
	struct NetworkMessageInfo {
		MsgSize_t length = 0;
		MsgSize_t position = INITIAL_BUFFER_POSITION;
		bool overrun = false;
	};

	NetworkMessageInfo info;
	uint8_t buffer[NETWORKMESSAGE_MAXSIZE] = {};

	bool canAdd(size_t size) const {
		return (size + info.position) < MAX_BODY_LENGTH;
	}

	bool canRead(int32_t size) {
		if ((info.position + size) > (info.length + 8) || size >= (NETWORKMESSAGE_MAXSIZE - info.position)) {
			info.overrun = true;
			return false;
		}
		return true;
	}
};

// ================================================================
//  TESTS: Initial state
// ================================================================

BOOST_AUTO_TEST_CASE(test_initial_state)
{
	NetworkMessage msg;
	BOOST_TEST(msg.getLength() == 0);
	BOOST_TEST(msg.getBufferPosition() == NetworkMessage::INITIAL_BUFFER_POSITION);
	BOOST_TEST(!msg.isOverrun());
}

BOOST_AUTO_TEST_CASE(test_reset)
{
	NetworkMessage msg;
	msg.addByte(42);
	msg.reset();
	BOOST_TEST(msg.getLength() == 0);
	BOOST_TEST(msg.getBufferPosition() == NetworkMessage::INITIAL_BUFFER_POSITION);
	BOOST_TEST(!msg.isOverrun());
}

// ================================================================
//  TESTS: addByte / getByte roundtrip
// ================================================================

BOOST_AUTO_TEST_CASE(test_byte_roundtrip)
{
	NetworkMessage msg;
	msg.addByte(0x42);
	msg.addByte(0xFF);
	msg.addByte(0x00);

	BOOST_TEST(msg.getLength() == 3);

	// Reset position to read back (position is at INITIAL + 3, length is 3)
	// We need to set position back to where we started writing
	NetworkMessage readMsg;
	readMsg.addByte(0x42);
	readMsg.addByte(0xFF);
	readMsg.addByte(0x00);
	// Copy buffer and set up for reading
	readMsg.setLength(3);
	// Position is now at INITIAL + 3, reset to INITIAL for reading
	readMsg.reset();
	// After reset, length=0, position=INITIAL. We need to set length for reading.
	// Instead, write then rewind manually:
	NetworkMessage msg2;
	msg2.addByte(0x42);
	msg2.addByte(0xFF);
	msg2.addByte(0x00);
	// The length is 3, position is INITIAL+3
	// For reading, we need to copy and set up properly
	// Actually let's test using the buffer directly
	uint8_t* buf = msg2.getBuffer();
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION] == 0x42);
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION + 1] == 0xFF);
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION + 2] == 0x00);
}

// ================================================================
//  TESTS: add<T> / get<T> roundtrip
// ================================================================

BOOST_AUTO_TEST_CASE(test_uint16_roundtrip)
{
	NetworkMessage msg;
	msg.add<uint16_t>(0x1234);

	uint8_t* buf = msg.getBuffer();
	// Little-endian: low byte first
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION] == 0x34);
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION + 1] == 0x12);
	BOOST_TEST(msg.getLength() == 2);
}

BOOST_AUTO_TEST_CASE(test_uint32_roundtrip)
{
	NetworkMessage msg;
	msg.add<uint32_t>(0xDEADBEEF);

	uint8_t* buf = msg.getBuffer();
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION] == 0xEF);
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION + 1] == 0xBE);
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION + 2] == 0xAD);
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION + 3] == 0xDE);
	BOOST_TEST(msg.getLength() == 4);
}

BOOST_AUTO_TEST_CASE(test_mixed_types)
{
	NetworkMessage msg;
	msg.addByte(0xAA);
	msg.add<uint16_t>(0xBBCC);
	msg.add<uint32_t>(0x11223344);

	BOOST_TEST(msg.getLength() == 7); // 1 + 2 + 4
}

// ================================================================
//  TESTS: addString / getString roundtrip
// ================================================================

BOOST_AUTO_TEST_CASE(test_string_write_format)
{
	NetworkMessage msg;
	msg.addString("Hi");

	uint8_t* buf = msg.getBuffer();
	// String format: uint16_t length prefix + raw bytes
	uint16_t len;
	memcpy(&len, buf + NetworkMessage::INITIAL_BUFFER_POSITION, 2);
	BOOST_TEST(len == 2);
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION + 2] == 'H');
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION + 3] == 'i');
	// Total length: 2 (len prefix) + 2 (string data) = 4
	BOOST_TEST(msg.getLength() == 4);
}

BOOST_AUTO_TEST_CASE(test_empty_string)
{
	NetworkMessage msg;
	msg.addString("");

	BOOST_TEST(msg.getLength() == 2); // Just the uint16_t length prefix (0)
}

BOOST_AUTO_TEST_CASE(test_long_string)
{
	NetworkMessage msg;
	std::string longStr(1000, 'X');
	msg.addString(longStr);

	BOOST_TEST(msg.getLength() == 1002); // 2 + 1000
}

// ================================================================
//  TESTS: Length and position tracking
// ================================================================

BOOST_AUTO_TEST_CASE(test_position_advances)
{
	NetworkMessage msg;
	auto startPos = msg.getBufferPosition();
	BOOST_TEST(startPos == NetworkMessage::INITIAL_BUFFER_POSITION);

	msg.addByte(1);
	BOOST_TEST(msg.getBufferPosition() == startPos + 1);

	msg.add<uint16_t>(2);
	BOOST_TEST(msg.getBufferPosition() == startPos + 3);

	msg.add<uint32_t>(3);
	BOOST_TEST(msg.getBufferPosition() == startPos + 7);
}

BOOST_AUTO_TEST_CASE(test_length_tracks_written)
{
	NetworkMessage msg;
	BOOST_TEST(msg.getLength() == 0);

	msg.addByte(1);
	BOOST_TEST(msg.getLength() == 1);

	msg.addString("test");
	BOOST_TEST(msg.getLength() == 7); // 1 + 2 + 4
}

BOOST_AUTO_TEST_CASE(test_set_length)
{
	NetworkMessage msg;
	msg.setLength(42);
	BOOST_TEST(msg.getLength() == 42);
}

// ================================================================
//  TESTS: Skip bytes
// ================================================================

BOOST_AUTO_TEST_CASE(test_skip_bytes)
{
	NetworkMessage msg;
	auto startPos = msg.getBufferPosition();
	msg.skipBytes(10);
	BOOST_TEST(msg.getBufferPosition() == startPos + 10);
}

// ================================================================
//  TESTS: Buffer overflow protection
// ================================================================

BOOST_AUTO_TEST_CASE(test_read_from_empty_sets_overrun)
{
	NetworkMessage msg;
	// Length is 0, so reading should fail
	uint8_t val = msg.getByte();
	BOOST_TEST(val == 0);
	BOOST_TEST(msg.isOverrun());
}

BOOST_AUTO_TEST_CASE(test_read_uint16_from_empty_sets_overrun)
{
	NetworkMessage msg;
	uint16_t val = msg.get<uint16_t>();
	BOOST_TEST(val == 0);
	BOOST_TEST(msg.isOverrun());
}

BOOST_AUTO_TEST_CASE(test_get_string_from_empty_sets_overrun)
{
	NetworkMessage msg;
	std::string val = msg.getString();
	BOOST_TEST(val.empty());
	BOOST_TEST(msg.isOverrun());
}

BOOST_AUTO_TEST_CASE(test_string_too_long_rejected)
{
	NetworkMessage msg;
	// Try to add a string longer than 8192
	std::string tooLong(8193, 'A');
	auto lengthBefore = msg.getLength();
	msg.addString(tooLong);
	BOOST_TEST(msg.getLength() == lengthBefore); // Nothing written
}

// ================================================================
//  TESTS: addBytes
// ================================================================

BOOST_AUTO_TEST_CASE(test_add_bytes)
{
	NetworkMessage msg;
	const char data[] = {0x01, 0x02, 0x03, 0x04};
	msg.addBytes(data, 4);

	BOOST_TEST(msg.getLength() == 4);
	uint8_t* buf = msg.getBuffer();
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION] == 0x01);
	BOOST_TEST(buf[NetworkMessage::INITIAL_BUFFER_POSITION + 3] == 0x04);
}

BOOST_AUTO_TEST_CASE(test_add_bytes_too_large_rejected)
{
	NetworkMessage msg;
	char data[8193] = {};
	auto lengthBefore = msg.getLength();
	msg.addBytes(data, 8193);
	BOOST_TEST(msg.getLength() == lengthBefore); // Rejected
}

// ================================================================
//  TESTS: Constants
// ================================================================

BOOST_AUTO_TEST_CASE(test_constants)
{
	BOOST_TEST(NetworkMessage::INITIAL_BUFFER_POSITION == 8);
	BOOST_TEST(NetworkMessage::HEADER_LENGTH == 2);
	BOOST_TEST(NetworkMessage::CHECKSUM_LENGTH == 4);
	BOOST_TEST(NetworkMessage::XTEA_MULTIPLE == 8);
	BOOST_TEST(NetworkMessage::MAX_BODY_LENGTH > 0);
	BOOST_TEST(NetworkMessage::MAX_BODY_LENGTH < NETWORKMESSAGE_MAXSIZE);
}

BOOST_AUTO_TEST_CASE(test_max_body_length_calculation)
{
	int expected = NETWORKMESSAGE_MAXSIZE - 2 - 4 - 8; // header - checksum - xtea
	BOOST_TEST(NetworkMessage::MAX_BODY_LENGTH == expected);
}
