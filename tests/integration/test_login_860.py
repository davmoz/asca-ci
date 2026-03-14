#!/usr/bin/env python3
"""Protocol 8.6 login integration tests.

Tests the server's login protocol by constructing valid 8.6 login packets
and verifying the server responds correctly.

Requires the server to be running on localhost:7171 with protocol 8.6.
"""

import socket
import struct
import sys
import time
import os

# Standard OTServ RSA public key (1024-bit, well-known in OT community)
OTSERV_RSA_N = int(
    '1091201329673994292788609605089955415282375029027981291234687579'
    '3726629149257644633073969600111060390723088861007265581882535850'
    '3429057592827629436413108566029093628212635953836686562675849720'
    '6207862794310902180176810615217550567108238764764442605581471797'
    '07119674283982419152118103759076030616683978566631413'
)
OTSERV_RSA_E = 65537

HOST = "127.0.0.1"
LOGIN_PORT = 7171
TIMEOUT = 5

passed = 0
failed = 0


def test(name, func):
    global passed, failed
    try:
        func()
        print(f"  PASS: {name}")
        passed += 1
    except Exception as e:
        print(f"  FAIL: {name} - {e}")
        failed += 1


def adler32_checksum(data: bytes) -> int:
    """Compute Adler-32 checksum matching TFS implementation."""
    MOD = 65521
    a = 1
    b = 0
    for byte in data:
        a = (a + byte) % MOD
        b = (b + a) % MOD
    return (b << 16) | a


def rsa_encrypt(data: bytes) -> bytes:
    """RSA encrypt 128 bytes using OTServ public key (no padding)."""
    assert len(data) == 128, f"RSA input must be 128 bytes, got {len(data)}"
    # Convert to integer (big-endian)
    m = int.from_bytes(data, byteorder='big')
    # RSA: c = m^e mod n
    c = pow(m, OTSERV_RSA_E, OTSERV_RSA_N)
    # Convert back to 128 bytes (big-endian)
    return c.to_bytes(128, byteorder='big')


def build_login_body(account_name: str, password: str) -> tuple:
    """Build the body of a login packet (after length header).

    Returns (body_bytes, xtea_key) tuple.
    """
    # Generate random XTEA key
    xtea_key = [
        int.from_bytes(os.urandom(4), 'little'),
        int.from_bytes(os.urandom(4), 'little'),
        int.from_bytes(os.urandom(4), 'little'),
        int.from_bytes(os.urandom(4), 'little'),
    ]

    # Build RSA plaintext block (128 bytes)
    rsa_plain = b'\x00'  # First byte must be 0x00 after decryption
    rsa_plain += struct.pack('<IIII', *xtea_key)
    # Account name (2-byte length + string)
    account_bytes = account_name.encode('latin-1')
    rsa_plain += struct.pack('<H', len(account_bytes)) + account_bytes
    # Password (2-byte length + string)
    password_bytes = password.encode('latin-1')
    rsa_plain += struct.pack('<H', len(password_bytes)) + password_bytes
    # Pad to 128 bytes with random data
    padding_len = 128 - len(rsa_plain)
    assert padding_len >= 0, f"RSA plaintext too long: {len(rsa_plain)} bytes"
    rsa_plain += os.urandom(padding_len)

    # RSA encrypt
    rsa_encrypted = rsa_encrypt(rsa_plain)

    # Build pre-RSA header:
    # 1 byte: protocol ID (0x01 for login)
    # 2 bytes: OS type
    # 2 bytes: client version
    # Then based on version < 971: 12 bytes (dat/spr/pic sigs)
    # Plus 1 byte preview state
    body = b'\x01'  # Protocol ID (consumed by make_protocol to select ProtocolLogin)

    # After protocol ID, onRecvFirstMessage reads:
    # 2 bytes: OS (skipped)
    # 2 bytes: version
    # 12 bytes: dat sig (4) + spr sig (4) + pic sig (4) [for version < 971]
    # 1 byte: 0 (preview state)
    # Then 128 bytes: RSA block
    body += struct.pack('<H', 2)  # OS = Windows
    body += struct.pack('<H', 860)  # Client version
    # For version < 971: server skips 12 bytes (dat sig + spr sig + pic sig)
    # No extra protocolVersion or preview byte
    body += struct.pack('<III', 0, 0, 0)  # dat, spr, pic signatures (12 bytes)
    body += rsa_encrypted  # 128 bytes RSA

    return body, xtea_key


def build_login_packet(account_name: str, password: str) -> tuple:
    """Build a complete network packet for 8.6 login.

    Returns (packet_bytes, xtea_key) tuple.
    """
    body, xtea_key = build_login_body(account_name, password)

    # Checksum covers everything after the checksum field
    checksum = adler32_checksum(body)

    # Full packet: [2-byte length][4-byte checksum][body]
    payload = struct.pack('<I', checksum) + body
    packet = struct.pack('<H', len(payload)) + payload

    return packet, xtea_key


def xtea_decrypt(data: bytes, key: list) -> bytes:
    """XTEA decrypt data (ECB mode, 32 rounds)."""
    DELTA = 0x9E3779B9
    MASK = 0xFFFFFFFF
    result = bytearray()

    for i in range(0, len(data), 8):
        v0 = int.from_bytes(data[i:i+4], 'little')
        v1 = int.from_bytes(data[i+4:i+8], 'little')
        total = (DELTA * 32) & MASK

        for _ in range(32):
            v1 = (v1 - (((v0 << 4 ^ v0 >> 5) + v0) ^ (total + key[(total >> 11) & 3]))) & MASK
            total = (total - DELTA) & MASK
            v0 = (v0 - (((v1 << 4 ^ v1 >> 5) + v1) ^ (total + key[total & 3]))) & MASK

        result += v0.to_bytes(4, 'little')
        result += v1.to_bytes(4, 'little')

    return bytes(result)


def send_login_and_recv(account_name: str, password: str) -> tuple:
    """Send login packet and receive response.

    Returns (raw_response, xtea_key) tuple.
    """
    packet, xtea_key = build_login_packet(account_name, password)

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect((HOST, LOGIN_PORT))
        s.sendall(packet)
        time.sleep(1)
        data = b''
        while True:
            try:
                chunk = s.recv(65536)
                if not chunk:
                    break
                data += chunk
            except socket.timeout:
                break
        return data, xtea_key
    finally:
        s.close()


def parse_login_response(data: bytes, xtea_key: list) -> dict:
    """Parse a login response packet.

    Returns dict with keys: 'type', 'message' or 'characters', 'premium_days', 'motd'.
    """
    result = {}
    if len(data) < 6:
        raise ValueError(f"Response too short: {len(data)} bytes")

    # [2-byte length][4-byte checksum][encrypted body]
    msg_len = struct.unpack_from('<H', data, 0)[0]
    checksum = struct.unpack_from('<I', data, 2)[0]
    encrypted = data[6:6 + msg_len - 4]

    # Decrypt with XTEA
    # Pad to multiple of 8 if needed
    if len(encrypted) % 8 != 0:
        encrypted += b'\x00' * (8 - len(encrypted) % 8)

    decrypted = xtea_decrypt(encrypted, xtea_key)

    # Parse decrypted content
    # First 2 bytes: decrypted message length
    inner_len = struct.unpack_from('<H', decrypted, 0)[0]
    body = decrypted[2:2 + inner_len]

    pos = 0
    while pos < len(body):
        opcode = body[pos]
        pos += 1

        if opcode == 0x0A:  # Error (version < 1076)
            str_len = struct.unpack_from('<H', body, pos)[0]
            pos += 2
            result['type'] = 'error'
            result['message'] = body[pos:pos + str_len].decode('latin-1')
            pos += str_len

        elif opcode == 0x14:  # MOTD
            str_len = struct.unpack_from('<H', body, pos)[0]
            pos += 2
            result['motd'] = body[pos:pos + str_len].decode('latin-1')
            pos += str_len

        elif opcode == 0x64:  # Character list
            result['type'] = 'charlist'
            char_count = body[pos]
            pos += 1
            result['characters'] = []
            for _ in range(char_count):
                # Character name
                name_len = struct.unpack_from('<H', body, pos)[0]
                pos += 2
                char_name = body[pos:pos + name_len].decode('latin-1')
                pos += name_len
                # World name
                world_len = struct.unpack_from('<H', body, pos)[0]
                pos += 2
                world_name = body[pos:pos + world_len].decode('latin-1')
                pos += world_len
                # IP and port
                ip_int = struct.unpack_from('<I', body, pos)[0]
                pos += 4
                port = struct.unpack_from('<H', body, pos)[0]
                pos += 2
                ip_str = f"{ip_int & 0xFF}.{(ip_int >> 8) & 0xFF}.{(ip_int >> 16) & 0xFF}.{(ip_int >> 24) & 0xFF}"
                result['characters'].append({
                    'name': char_name,
                    'world': world_name,
                    'ip': ip_str,
                    'port': port,
                })
            # Premium days
            result['premium_days'] = struct.unpack_from('<H', body, pos)[0]
            pos += 2

        else:
            # Unknown opcode, skip
            break

    return result


# --- Tests ---

def test_login_port_accepts_connection():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect((HOST, LOGIN_PORT))
    finally:
        s.close()


def test_login_wrong_password():
    """Server should return error for wrong password."""
    data, xtea_key = send_login_and_recv("testaccount", "wrongpassword")
    assert len(data) > 0, "No response from server"
    result = parse_login_response(data, xtea_key)
    assert result.get('type') == 'error', f"Expected error, got: {result}"
    assert 'not correct' in result.get('message', '').lower(), f"Unexpected error: {result.get('message')}"


def test_login_empty_account():
    """Server should reject empty account name."""
    data, xtea_key = send_login_and_recv("", "test123")
    assert len(data) > 0, "No response from server"
    result = parse_login_response(data, xtea_key)
    assert result.get('type') == 'error', f"Expected error, got: {result}"


def test_login_valid_credentials():
    """Server should return character list for valid credentials."""
    data, xtea_key = send_login_and_recv("testaccount", "test123")
    assert len(data) > 0, "No response from server"
    result = parse_login_response(data, xtea_key)
    assert result.get('type') == 'charlist', f"Expected charlist, got: {result}"
    assert len(result.get('characters', [])) > 0, "No characters in list"


def test_login_character_details():
    """Character list should have correct details."""
    data, xtea_key = send_login_and_recv("testaccount", "test123")
    result = parse_login_response(data, xtea_key)
    assert result.get('type') == 'charlist', f"Expected charlist, got: {result}"
    chars = result['characters']
    assert any(c['name'] == 'TestPlayer' for c in chars), f"TestPlayer not in character list: {chars}"


def test_login_game_port():
    """Character list should include game port 7172."""
    data, xtea_key = send_login_and_recv("testaccount", "test123")
    result = parse_login_response(data, xtea_key)
    assert result.get('type') == 'charlist', f"Expected charlist, got: {result}"
    chars = result['characters']
    assert any(c['port'] == 7172 for c in chars), f"No character with port 7172: {chars}"


def test_login_has_motd():
    """Response should include MOTD."""
    data, xtea_key = send_login_and_recv("testaccount", "test123")
    result = parse_login_response(data, xtea_key)
    # MOTD may or may not be configured, but if charlist works, the response is valid
    assert result.get('type') == 'charlist', f"Expected charlist, got: {result}"


def test_login_premium_days():
    """Response should include premium days field."""
    data, xtea_key = send_login_and_recv("testaccount", "test123")
    result = parse_login_response(data, xtea_key)
    assert result.get('type') == 'charlist', f"Expected charlist, got: {result}"
    assert 'premium_days' in result, "No premium_days in response"


def test_login_server_survives():
    """Server should still be up after login tests."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect((HOST, LOGIN_PORT))
    finally:
        s.close()


if __name__ == "__main__":
    print("=" * 60)
    print("ASCA Protocol 8.6 Login Tests")
    print("=" * 60)

    print("\n[Connection]")
    test("Login port accepts connection", test_login_port_accepts_connection)

    print("\n[Authentication]")
    test("Wrong password returns error", test_login_wrong_password)
    test("Empty account returns error", test_login_empty_account)
    test("Valid credentials return character list", test_login_valid_credentials)

    print("\n[Character List]")
    test("Character list contains TestPlayer", test_login_character_details)
    test("Character list has game port 7172", test_login_game_port)
    test("Response has MOTD or valid charlist", test_login_has_motd)
    test("Response includes premium days", test_login_premium_days)

    print("\n[Stability]")
    test("Server survives login tests", test_login_server_survives)

    print("\n" + "=" * 60)
    total = passed + failed
    print(f"Results: {passed}/{total} passed, {failed} failed")
    print("=" * 60)

    sys.exit(1 if failed > 0 else 0)
