# TFS Test Suite Makefile
# Run: make -C tests [target]

.PHONY: all lua xml db integration cpp clean help

SHELL := /bin/bash
PROJECT_ROOT := $(shell cd .. && pwd)

help:
	@echo "TFS Test Suite"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Run all tests (except C++ build)"
	@echo "  lua          - Run Lua script validation tests"
	@echo "  xml          - Run XML validation tests"
	@echo "  db           - Run database tests"
	@echo "  integration  - Run integration tests"
	@echo "  cpp          - Build and run C++ unit tests"
	@echo "  clean        - Clean build artifacts"
	@echo ""
	@echo "Run from project root: make -C tests [target]"

all: lua xml db integration

lua:
	@echo "=== Lua Tests ==="
	cd $(PROJECT_ROOT) && lua tests/lua/run_tests.lua

xml:
	@echo "=== XML Validation ==="
	cd $(PROJECT_ROOT) && python3 tests/xml/validate_all.py

db:
	@echo "=== Database Tests ==="
	cd $(PROJECT_ROOT) && python3 tests/db/test_migrations.py
	cd $(PROJECT_ROOT) && python3 tests/db/test_queries.py

integration:
	@echo "=== Integration Tests ==="
	bash integration/test_server_boot.sh
	cd $(PROJECT_ROOT) && python3 tests/integration/test_login.py
	cd $(PROJECT_ROOT) && python3 tests/integration/test_player_create.py
	bash integration/test_docker.sh

cpp:
	@echo "=== C++ Unit Tests ==="
	mkdir -p cpp/build
	cd cpp/build && cmake .. -DCMAKE_BUILD_TYPE=Release
	cd cpp/build && make -j$$(nproc 2>/dev/null || echo 4)
	cd cpp/build && ctest --output-on-failure

clean:
	rm -rf cpp/build
