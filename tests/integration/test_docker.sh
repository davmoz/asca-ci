#!/bin/bash
# Test Docker build and configuration.
#
# Usage: bash tests/integration/test_docker.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== TFS Docker Test ==="

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

skip() {
    TOTAL=$((TOTAL + 1))
    echo "  SKIP: $1"
}

# Test 1: Dockerfile exists
echo ""
echo "--- Docker Configuration ---"
if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
    pass "Dockerfile exists"
else
    fail "Dockerfile not found"
fi

# Test 2: Dockerfile has multi-stage build
if grep -q "FROM.*AS build" "$PROJECT_ROOT/Dockerfile" 2>/dev/null; then
    pass "Dockerfile uses multi-stage build"
else
    fail "Dockerfile doesn't use multi-stage build"
fi

# Test 3: Dockerfile exposes correct ports
if grep -q "EXPOSE 7171" "$PROJECT_ROOT/Dockerfile" 2>/dev/null; then
    pass "Dockerfile exposes port 7171 (login)"
else
    fail "Dockerfile doesn't expose port 7171"
fi

if grep -q "EXPOSE.*7172" "$PROJECT_ROOT/Dockerfile" 2>/dev/null; then
    pass "Dockerfile exposes port 7172 (game)"
else
    fail "Dockerfile doesn't expose port 7172"
fi

# Test 4: Dockerfile copies data directory
if grep -q "COPY data" "$PROJECT_ROOT/Dockerfile" 2>/dev/null; then
    pass "Dockerfile copies data directory"
else
    fail "Dockerfile doesn't copy data directory"
fi

# Test 5: Dockerfile copies schema
if grep -q "schema.sql\|\.sql" "$PROJECT_ROOT/Dockerfile" 2>/dev/null; then
    pass "Dockerfile includes SQL schema"
else
    fail "Dockerfile doesn't include SQL schema"
fi

# Test 6: Dockerfile sets entrypoint
if grep -q "ENTRYPOINT" "$PROJECT_ROOT/Dockerfile" 2>/dev/null; then
    pass "Dockerfile has ENTRYPOINT"
else
    fail "Dockerfile missing ENTRYPOINT"
fi

# Test 7: Dockerfile sets workdir
if grep -q "WORKDIR" "$PROJECT_ROOT/Dockerfile" 2>/dev/null; then
    pass "Dockerfile has WORKDIR"
else
    fail "Dockerfile missing WORKDIR"
fi

# Test 8: Docker CI workflow exists
echo ""
echo "--- Docker CI ---"
if [ -f "$PROJECT_ROOT/.github/workflows/docker-image.yml" ]; then
    pass "Docker CI workflow exists"
else
    fail "Docker CI workflow not found"
fi

# Test 9: Docker build (only if docker is available)
echo ""
echo "--- Docker Build (optional) ---"
if command -v docker &> /dev/null; then
    pass "Docker is available"
    echo "  NOTE: Skipping actual build (requires full dependency chain)"
else
    skip "Docker not available - skipping build test"
fi

# Summary
echo ""
echo "========================================"
echo "Results: $PASSED/$TOTAL passed, $FAILED failed"
echo "========================================"

exit $FAILED
