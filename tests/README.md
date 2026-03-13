# TFS Test Suite

Comprehensive test suite for The Forgotten Server (TFS 1.3) Tibia MMORPG server.

## Quick Start

Run all tests (Lua, XML, DB, integration) from the project root:

```bash
make -C tests all
```

## Test Categories

### 1. C++ Unit Tests (`tests/cpp/`)

Uses Google Test (gtest). Tests core server functions in isolation.

**Files:**
- `test_tools.cpp` - String manipulation, SHA1 hashing, Adler-32 checksum, combat type mappings
- `test_position.cpp` - Position struct operations, direction calculation, range checks
- `test_wildcardtree.cpp` - Player name autocomplete trie (insert, remove, search)
- `test_item.cpp` - Item attribute system, bitmask operations, ID constants
- `test_condition.cpp` - Condition type bitmasks, damage-over-time structures
- `test_combat.cpp` - CombatDamage struct, combat type names, damage formulas
- `test_vocation.cpp` - Vocation skill multipliers, mana progression, stat gains
- `test_configmanager.cpp` - Config get/set for strings, integers, booleans
- `test_database.cpp` - SQL escaping, query builder, schema validation

**Build and run:**
```bash
mkdir -p tests/cpp/build
cd tests/cpp/build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
ctest --output-on-failure
```

**Requirements:** CMake 3.10+, C++11 compiler, libpugixml-dev, libboost-dev

### 2. Lua Script Tests (`tests/lua/`)

Validates all Lua scripts for syntax errors and data file integrity.

**Files:**
- `run_tests.lua` - Main test runner with built-in assertion framework
- `test_spells.lua` - Spell definitions, script references, cooldown values
- `test_monsters.lua` - Monster XML index, health/experience values, file references
- `test_items.lua` - Item IDs, attributes, duplicate detection
- `test_npcs.lua` - NPC XML structure, script references
- `test_actions.lua` - Action definitions and script syntax
- `test_movements.lua` - Movement event types and script syntax
- `test_talkactions.lua` - Talkaction words uniqueness and script syntax
- `test_lib.lua` - Core library files, migrations, global events

**Run:**
```bash
lua tests/lua/run_tests.lua          # Run all
lua tests/lua/run_tests.lua spells   # Run specific suite
```

**Requirements:** Lua 5.1+ or LuaJIT

### 3. XML Validation (`tests/xml/`)

Python scripts that validate all XML data files.

**Files:**
- `validate_monsters.py` - Validates 703 monster XML files (health, experience, attacks)
- `validate_items.py` - Validates items.xml (IDs, attributes, duplicates)
- `validate_spells.py` - Validates spells.xml (groups, cooldowns, script references)
- `validate_npcs.py` - Validates NPC XML files (structure, script references)
- `validate_all.py` - Runs all validators plus checks vocations.xml, groups.xml, etc.

**Run:**
```bash
python3 tests/xml/validate_all.py
```

**Requirements:** Python 3.6+

### 4. Database Tests (`tests/db/`)

**Files:**
- `test_schema.sql` - Tests schema creation, table structure, and basic CRUD (requires MySQL)
- `test_migrations.py` - Verifies all 28 migration files exist and are sequential
- `test_queries.py` - Validates common query patterns against schema structure

**Run:**
```bash
python3 tests/db/test_migrations.py
python3 tests/db/test_queries.py
# MySQL schema test (requires running MySQL):
mysql -u root < tests/db/test_schema.sql
```

### 5. Integration Tests (`tests/integration/`)

**Files:**
- `test_server_boot.sh` - Verifies build system, source files, data directories
- `test_login.py` - Tests login protocol structures, Adler-32, SHA1, RSA key
- `test_player_create.py` - Tests player name validation, initial stats, vocation system
- `test_docker.sh` - Validates Dockerfile configuration (multi-stage, ports, entrypoint)

**Run:**
```bash
bash tests/integration/test_server_boot.sh
python3 tests/integration/test_login.py
python3 tests/integration/test_player_create.py
bash tests/integration/test_docker.sh
```

### 6. CI/CD

GitHub Actions workflow at `.github/workflows/tests.yml` runs all test categories on push and pull requests.

## Summary

| Category | Tests | Language | Dependencies |
|----------|-------|----------|--------------|
| C++ Unit | ~150 | C++ | gtest, cmake, boost, pugixml |
| Lua Scripts | ~60 | Lua | lua 5.1+ |
| XML Validation | ~40 | Python | python 3.6+ |
| Database | ~30 | Python/SQL | python 3.6+ |
| Integration | ~50 | Bash/Python | python 3.6+ |
| **Total** | **~330** | | |
