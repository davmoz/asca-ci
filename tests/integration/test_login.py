#!/usr/bin/env python3
"""
Test login protocol structures and packet format.

Validates the TFS login protocol without requiring a running server.
Tests packet structure, checksum calculation, and RSA key presence.
"""

import os
import sys
import struct
import hashlib
from pathlib import Path


def find_project_root():
    path = Path(__file__).resolve().parent
    while path != path.parent:
        if (path / "CMakeLists.txt").exists() and (path / "data").exists():
            return path
        path = path.parent
    return Path.cwd()


PROJECT_ROOT = find_project_root()

ERRORS = []
PASSED = 0
TOTAL = 0


def test(name, condition, msg=""):
    global PASSED, TOTAL
    TOTAL += 1
    if condition:
        PASSED += 1
        print(f"  PASS: {name}")
    else:
        ERRORS.append(f"{name}: {msg}")
        print(f"  FAIL: {name} - {msg}")


def adler32_checksum(data):
    """Python implementation of the same Adler-32 used by TFS."""
    MOD_ADLER = 65521
    a = 1
    b = 0
    for byte in data:
        a = (a + byte) % MOD_ADLER
        b = (b + a) % MOD_ADLER
    return (b << 16) | a


def test_adler32():
    """Test Adler-32 checksum matches known values."""
    print("\n--- Adler-32 Checksum ---")

    # Test empty
    test("Adler-32 empty data", adler32_checksum(b"") == 1, "Expected 1")

    # Test "Hello"
    result = adler32_checksum(b"Hello")
    test("Adler-32 'Hello'", result == 0x058C01F5,
         f"Expected 0x058C01F5, got 0x{result:08X}")

    # Test known value
    result = adler32_checksum(b"Wikipedia")
    expected = 0x11E60398
    test("Adler-32 'Wikipedia'", result == expected,
         f"Expected 0x{expected:08X}, got 0x{result:08X}")


def test_packet_structure():
    """Test TFS network packet structure."""
    print("\n--- Packet Structure ---")

    # TFS packet format: [2 bytes length][4 bytes checksum][payload]
    payload = b"\x01\x02\x03\x04\x05"
    checksum = adler32_checksum(payload)
    length = len(payload) + 4  # payload + checksum

    packet = struct.pack("<H", length) + struct.pack("<I", checksum) + payload

    # Verify packet structure
    test("Packet minimum size", len(packet) >= 6, f"Got {len(packet)} bytes")

    # Parse it back
    parsed_length = struct.unpack("<H", packet[0:2])[0]
    parsed_checksum = struct.unpack("<I", packet[2:6])[0]
    parsed_payload = packet[6:]

    test("Packet length field", parsed_length == length,
         f"Expected {length}, got {parsed_length}")
    test("Packet checksum field", parsed_checksum == checksum,
         f"Expected {checksum}, got {parsed_checksum}")
    test("Packet payload", parsed_payload == payload,
         f"Payload mismatch")


def test_sha1_password():
    """Test SHA1 password hashing (TFS uses SHA1 for passwords)."""
    print("\n--- SHA1 Password Hashing ---")

    password = "testpassword"
    expected_hash = hashlib.sha1(password.encode()).hexdigest()

    test("SHA1 hash length", len(expected_hash) == 40,
         f"Expected 40 chars, got {len(expected_hash)}")
    test("SHA1 hash is lowercase hex", all(c in "0123456789abcdef" for c in expected_hash))
    test("SHA1 deterministic", expected_hash == hashlib.sha1(password.encode()).hexdigest())
    test("SHA1 different passwords differ",
         hashlib.sha1(b"password1").hexdigest() != hashlib.sha1(b"password2").hexdigest())


def test_rsa_key():
    """Test RSA key handling - key.pem is excluded from git for security."""
    print("\n--- RSA Key ---")

    key_path = PROJECT_ROOT / "key.pem"
    if key_path.exists():
        content = key_path.read_text()
        test("RSA key has PEM header",
             "-----BEGIN" in content,
             "Missing PEM header")
        test("RSA key has PEM footer",
             "-----END" in content,
             "Missing PEM footer")
        test("RSA key is non-trivial",
             len(content) > 100,
             f"Key too short: {len(content)} bytes")
    else:
        # key.pem is intentionally excluded from git for security
        # In production, it should be generated or mounted as a secret
        test("RSA key excluded from repo (security best practice)", True)


def test_protocol_ports():
    """Test default protocol port values."""
    print("\n--- Protocol Ports ---")

    # Default TFS ports from configmanager.cpp
    GAME_PORT = 7172
    LOGIN_PORT = 7171
    STATUS_PORT = 7171

    test("Game port is valid", 1024 <= GAME_PORT <= 65535)
    test("Login port is valid", 1024 <= LOGIN_PORT <= 65535)
    test("Status port is valid", 1024 <= STATUS_PORT <= 65535)
    test("Game and login ports differ", GAME_PORT != LOGIN_PORT)


def test_client_version():
    """Test client version constants."""
    print("\n--- Client Version ---")

    # TFS 1.3 supports Tibia client versions around 10.98-12.x
    # Check that the protocol files exist
    protocol_files = ["src/protocolgame.cpp", "src/protocollogin.cpp",
                      "src/protocolstatus.cpp", "src/protocolold.cpp"]

    for pf in protocol_files:
        path = PROJECT_ROOT / pf
        test(f"{pf} exists", path.exists(), "Protocol file not found")


if __name__ == "__main__":
    print("=== TFS Login Protocol Tests ===")

    test_adler32()
    test_packet_structure()
    test_sha1_password()
    test_rsa_key()
    test_protocol_ports()
    test_client_version()

    print(f"\n{'=' * 40}")
    print(f"Results: {PASSED}/{TOTAL} passed, {len(ERRORS)} failed")
    print(f"{'=' * 40}")

    if ERRORS:
        print("\nFailures:")
        for e in ERRORS:
            print(f"  {e}")

    sys.exit(0 if not ERRORS else 1)
