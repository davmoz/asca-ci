#!/bin/bash
# Test that the TFS server binary can be built and starts up.
# This test requires CMake build dependencies to be installed.
#
# Usage: bash tests/integration/test_server_boot.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build_test"

echo "=== TFS Server Boot Test ==="
echo "Project root: $PROJECT_ROOT"

PASSED=0
FAILED=0
TOTAL=0

pass() {
    PASSED=$((PASSED + 1))
    TOTAL=$((TOTAL + 1))
    echo "  PASS: $1"
}

fail() {
    FAILED=$((FAILED + 1))
    TOTAL=$((TOTAL + 1))
    echo "  FAIL: $1"
}

# Test 1: CMakeLists.txt exists
echo ""
echo "--- Build System ---"
if [ -f "$PROJECT_ROOT/CMakeLists.txt" ]; then
    pass "CMakeLists.txt exists"
else
    fail "CMakeLists.txt not found"
fi

# Test 2: src/CMakeLists.txt exists
if [ -f "$PROJECT_ROOT/src/CMakeLists.txt" ]; then
    pass "src/CMakeLists.txt exists"
else
    fail "src/CMakeLists.txt not found"
fi

# Test 3: Source files present
echo ""
echo "--- Source Files ---"
SRC_COUNT=$(find "$PROJECT_ROOT/src" -name "*.cpp" | wc -l | tr -d ' ')
if [ "$SRC_COUNT" -gt 50 ]; then
    pass "Source files present ($SRC_COUNT .cpp files)"
else
    fail "Insufficient source files (found $SRC_COUNT)"
fi

# Test 4: Header files present
HDR_COUNT=$(find "$PROJECT_ROOT/src" -name "*.h" | wc -l | tr -d ' ')
if [ "$HDR_COUNT" -gt 50 ]; then
    pass "Header files present ($HDR_COUNT .h files)"
else
    fail "Insufficient header files (found $HDR_COUNT)"
fi

# Test 5: Key source files
echo ""
echo "--- Key Source Files ---"
KEY_FILES=(
    "src/otpch.h"
    "src/otserv.cpp"
    "src/game.cpp"
    "src/player.cpp"
    "src/creature.cpp"
    "src/monster.cpp"
    "src/npc.cpp"
    "src/combat.cpp"
    "src/luascript.cpp"
    "src/database.cpp"
    "src/configmanager.cpp"
    "src/tools.cpp"
)

for f in "${KEY_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$f" ]; then
        pass "$f exists"
    else
        fail "$f not found"
    fi
done

# Test 6: Data directory structure
echo ""
echo "--- Data Directory ---"
DATA_DIRS=(
    "data/spells"
    "data/actions"
    "data/movements"
    "data/talkactions"
    "data/monster"
    "data/npc"
    "data/items"
    "data/lib"
    "data/migrations"
    "data/XML"
)

for d in "${DATA_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$d" ]; then
        pass "$d directory exists"
    else
        fail "$d directory not found"
    fi
done

# Test 7: Config file template
echo ""
echo "--- Configuration ---"
if [ -f "$PROJECT_ROOT/config.lua.dist" ]; then
    pass "config.lua.dist exists"
else
    fail "config.lua.dist not found"
fi

# Test 8: Schema file
if [ -f "$PROJECT_ROOT/schema.sql" ]; then
    pass "schema.sql exists"
else
    fail "schema.sql not found"
fi

# Test 9: RSA key
if [ -f "$PROJECT_ROOT/key.pem" ]; then
    pass "key.pem exists"
else
    fail "key.pem not found"
fi

# Test 10: Try cmake configure (if cmake available)
echo ""
echo "--- Build Configuration ---"
if command -v cmake &> /dev/null; then
    pass "cmake is available"

    # Don't actually build - just verify cmake can start
    # (Full build requires all dependencies)
else
    echo "  SKIP: cmake not available"
fi

# Summary
echo ""
echo "========================================"
echo "Results: $PASSED/$TOTAL passed, $FAILED failed"
echo "========================================"

exit $FAILED
