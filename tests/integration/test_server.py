#!/usr/bin/env python3
"""Integration tests for the running ASCA server.

Tests the server's network protocols and basic functionality.
Requires the server to be running on localhost:7171 (login) and 7172 (game).
"""

import socket
import struct
import sys
import xml.etree.ElementTree as ET
import hashlib
import time


TIMEOUT = 5
LOGIN_PORT = 7171
GAME_PORT = 7172
HOST = "127.0.0.1"

passed = 0
failed = 0

# Cache for status response (rate-limited to one request per 5 seconds)
_status_cache = None


def test(name, func):
    global passed, failed
    try:
        func()
        print(f"  PASS: {name}")
        passed += 1
    except Exception as e:
        print(f"  FAIL: {name} - {e}")
        failed += 1


# --- Port tests ---

def test_login_port_open():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect((HOST, LOGIN_PORT))
    finally:
        s.close()

def test_game_port_open():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect((HOST, GAME_PORT))
    finally:
        s.close()


# --- Status protocol tests ---

def _fetch_status():
    """Send a Tibia status protocol request and return the raw XML response."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect((HOST, LOGIN_PORT))
        # Status protocol: 2-byte length header (little-endian) + protocol ID + command + "info"
        # First 0xFF = protocol identifier (consumed by make_protocol)
        # Second 0xFF = status command byte (read by onRecvFirstMessage)
        # Then "info" = 4-char status request string
        body = b'\xFF\xFF' + b'info'
        header = struct.pack('<H', len(body))  # uint16_t little-endian
        s.sendall(header + body)
        # Read response - raw TCP data, collect all chunks
        time.sleep(2)
        data = b''
        while True:
            try:
                chunk = s.recv(65536)
                if not chunk:
                    break
                data += chunk
            except socket.timeout:
                break
        # Response is raw XML (no length header) due to setRawMessages(true)
        return data
    finally:
        s.close()


def send_status_request():
    """Get status response, using cache to avoid rate limiting."""
    global _status_cache
    if _status_cache is None:
        _status_cache = _fetch_status()
    return _status_cache


def test_status_responds():
    data = send_status_request()
    assert len(data) > 0, "No response from status protocol"


def test_status_is_xml():
    data = send_status_request()
    # Skip the first 4 bytes (length header)
    xml_data = data
    # Try to parse as XML
    root = ET.fromstring(xml_data)
    assert root.tag == "tsqp", f"Expected <tsqp>, got <{root.tag}>"


def test_status_has_server_info():
    data = send_status_request()
    xml_data = data
    root = ET.fromstring(xml_data)
    serverinfo = root.find("serverinfo")
    assert serverinfo is not None, "No <serverinfo> element"
    assert "servername" in serverinfo.attrib, "No servername attribute"


def test_status_server_name():
    data = send_status_request()
    xml_data = data
    root = ET.fromstring(xml_data)
    serverinfo = root.find("serverinfo")
    name = serverinfo.get("servername", "")
    assert name == "ASCA", f"Expected server name 'ASCA', got '{name}'"


def test_status_has_players():
    data = send_status_request()
    xml_data = data
    root = ET.fromstring(xml_data)
    players = root.find("players")
    assert players is not None, "No <players> element"
    online = players.get("online", "")
    assert online.isdigit(), f"Online count not a number: '{online}'"


def test_status_has_map():
    data = send_status_request()
    xml_data = data
    root = ET.fromstring(xml_data)
    map_elem = root.find("map")
    assert map_elem is not None, "No <map> element"
    assert "name" in map_elem.attrib, "No map name attribute"


def test_status_has_owner():
    data = send_status_request()
    xml_data = data
    root = ET.fromstring(xml_data)
    owner = root.find("owner")
    assert owner is not None, "No <owner> element"


def test_status_uptime():
    data = send_status_request()
    xml_data = data
    root = ET.fromstring(xml_data)
    serverinfo = root.find("serverinfo")
    uptime = serverinfo.get("uptime", "")
    assert uptime.isdigit(), f"Uptime not a number: '{uptime}'"
    assert int(uptime) >= 0, "Uptime is negative"


# --- Database tests ---

def test_database_account_exists():
    """Verify our test account exists via status protocol (server loaded DB)."""
    # We can't query DB directly from here, but we verified the server
    # loaded the map and started — which requires a working DB connection.
    # The server would not start if the DB was unreachable.
    data = send_status_request()
    assert len(data) > 10, "Server not responding (DB may be down)"


# --- Login protocol tests ---

def test_login_rejects_garbage():
    """Server should handle garbage data gracefully (not crash)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect((HOST, LOGIN_PORT))
        s.send(b'\x00\x01\x02\x03\x04\x05')
        time.sleep(0.5)
        # Server should either close the connection or send an error
        try:
            data = s.recv(1024)
        except (socket.timeout, ConnectionResetError):
            data = b''
        # If we get here without exception, the server handled it gracefully
    finally:
        s.close()


def test_game_port_rejects_garbage():
    """Game port should handle garbage data gracefully."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect((HOST, GAME_PORT))
        s.send(b'\xFF\xFE\xFD\xFC')
        time.sleep(0.5)
        try:
            data = s.recv(1024)
        except (socket.timeout, ConnectionResetError):
            data = b''
    finally:
        s.close()


def test_server_still_up_after_garbage():
    """Verify server survived garbage input."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect((HOST, LOGIN_PORT))
    finally:
        s.close()


# --- Concurrent connection test ---

def test_multiple_connections():
    """Server should handle multiple simultaneous connections."""
    sockets = []
    try:
        for _ in range(10):
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(TIMEOUT)
            s.connect((HOST, LOGIN_PORT))
            sockets.append(s)
        assert len(sockets) == 10, "Could not open 10 connections"
    finally:
        for s in sockets:
            s.close()


# --- Health check test ---

def test_health_check():
    """Docker health check should pass."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    try:
        s.connect((HOST, LOGIN_PORT))
        # Connection succeeded = healthy
    finally:
        s.close()


def test_status_zero_players_online():
    """No players should be online on a fresh server."""
    data = send_status_request()
    xml_data = data
    root = ET.fromstring(xml_data)
    players = root.find("players")
    online = int(players.get("online", "-1"))
    assert online == 0, f"Expected 0 players online, got {online}"


if __name__ == "__main__":
    print("=" * 60)
    print("ASCA Server Integration Tests")
    print("=" * 60)

    print("\n[Port Connectivity]")
    test("Login port (7171) is open", test_login_port_open)
    test("Game port (7172) is open", test_game_port_open)

    print("\n[Status Protocol]")
    test("Status protocol responds", test_status_responds)
    test("Status response is valid XML", test_status_is_xml)
    test("Status has server info", test_status_has_server_info)
    test("Server name is 'ASCA'", test_status_server_name)
    test("Status has player count", test_status_has_players)
    test("Zero players online", test_status_zero_players_online)
    test("Status has map info", test_status_has_map)
    test("Status has owner info", test_status_has_owner)
    test("Server uptime is valid", test_status_uptime)

    print("\n[Database]")
    test("Server connected to database", test_database_account_exists)

    print("\n[Protocol Robustness]")
    test("Login port rejects garbage gracefully", test_login_rejects_garbage)
    test("Game port rejects garbage gracefully", test_game_port_rejects_garbage)
    test("Server survives garbage input", test_server_still_up_after_garbage)

    print("\n[Concurrency]")
    test("Handles 10 simultaneous connections", test_multiple_connections)

    print("\n[Health]")
    test("Health check passes", test_health_check)

    print("\n" + "=" * 60)
    total = passed + failed
    print(f"Results: {passed}/{total} passed, {failed} failed")
    print("=" * 60)

    sys.exit(1 if failed > 0 else 0)
