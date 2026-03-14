# ASCA - Custom MMORPG Server

ASCA is a custom MMORPG server based on The Forgotten Server (TFS) 1.3, built with C++20 for Tibia protocol 8.6. It features custom gameplay systems including crafting, factions, prey, imbuing, achievements, bestiary, and PvP.

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose

### 1. Clone and configure

```bash
git clone https://github.com/DocKarma1/asca.git
cd asca
cp key.pem.dist key.pem
```

### 2. Start the server

```bash
docker compose up -d
```

This starts MariaDB and the game server. The database schema is imported automatically on first run. Wait for the health check to pass (~15 seconds):

```bash
docker compose ps
```

Both services should show `Up (healthy)`. To watch the server log:

```bash
docker compose logs -f tfs
```

You should see `>> ASCA Server Online!` when the server is ready.

### 3. Create an account

```bash
docker compose exec db mariadb -uforgottenserver -pchange_me_password forgottenserver
```

Run this SQL to create a test account with a level 8 Knight:

```sql
-- Create account (password will be 'test123')
INSERT INTO accounts (name, password, type, premium_ends_at)
VALUES ('testaccount', SHA1('test123'), 1, UNIX_TIMESTAMP() + 86400 * 30);

-- Create character on that account
INSERT INTO players (name, account_id, level, vocation, town_id,
  health, healthmax, experience, mana, manamax, cap, soul,
  looktype, lookbody, lookfeet, lookhead, looklegs,
  conditions, posx, posy, posz)
VALUES ('MyCharacter', LAST_INSERT_ID(), 8, 4, 1,
  185, 185, 4200, 90, 90, 470, 100,
  131, 113, 115, 95, 39,
  '', 0, 0, 0);
```

Type `exit` to leave the database shell.

### 4. Connect with the client

See the [ascaclient](https://github.com/DocKarma1/ascaclient) repo for client setup. The server listens on:

| Port | Protocol |
|------|----------|
| 7171 | Login (character list) |
| 7172 | Game (gameplay) |

Login with account name `testaccount` and password `test123`.

### Stopping the server

```bash
docker compose down        # Stop containers (preserves database)
docker compose down -v     # Stop and delete database volume
```

---

## Manual Setup (without Docker)

### Dependencies

| Library | Ubuntu/Debian | macOS (Homebrew) | Alpine |
|---------|--------------|------------------|--------|
| Boost | `libboost-all-dev` | `boost` | `boost-dev` |
| MySQL/MariaDB | `libmysqlclient-dev` | `mysql-client` | `mariadb-connector-c-dev` |
| LuaJIT | `libluajit-5.1-dev` | `luajit` | `luajit-dev` |
| pugixml | `libpugixml-dev` | `pugixml` | `pugixml-dev` |
| OpenSSL | `libssl-dev` | `openssl` | `openssl-dev` |
| fmt | `libfmt-dev` | `fmt` | `fmt-dev` |
| GMP | `libgmp-dev` | `gmp` | `gmp-dev` |

### Build

```bash
cmake -B build
cmake --build build -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
```

### Database

Create the database and import the schema:

```bash
mysql -u root -p -e "CREATE DATABASE forgottenserver;"
mysql -u root -p -e "CREATE USER 'forgottenserver'@'localhost' IDENTIFIED BY 'your_password';"
mysql -u root -p -e "GRANT ALL ON forgottenserver.* TO 'forgottenserver'@'localhost';"
mysql -u root -p forgottenserver < schema.sql
```

### Configure and run

```bash
cp config.lua.dist config.lua
cp key.pem.dist key.pem
# Edit config.lua — set mysqlPass and other settings
./build/tfs
```

---

## Running Tests

```bash
# C++ unit tests
ctest --test-dir build --output-on-failure

# Lua tests
lua tests/lua/run_tests.lua

# Integration tests (requires running server on localhost:7171/7172)
python3 tests/integration/test_server.py
python3 tests/integration/test_login_860.py
```

---

## Project Structure

```
src/               C++ engine (~165 files)
src/tests/         Boost.Test unit tests
tests/cpp/         Google Test unit tests
tests/lua/         Lua test suite (178 tests)
data/
  lib/             26 custom Lua game systems
  spells/          Spell scripts
  actions/         Item use scripts
  movements/       Step/equip/deequip scripts
  talkactions/     Chat command handlers
  creaturescripts/ Login/death/kill hooks
  globalevents/    Startup/timer/shutdown events
  npc/             54 NPC scripts
  monster/         706 monster definitions
  world/           Map files (OTBM format)
  items/           Item type definitions
  migrations/      Database migration scripts
config.lua.dist    Server configuration template
schema.sql         Database schema
key.pem.dist       Standard OTServ RSA key (for OTClient compatibility)
```

## Key Features

- **Custom Vocations** -- Mage, Druid, Archer, Knight with promoted variants
- **6 Crafting Systems** -- Smithing, Mining, Cooking, Enchanting, Farming, and more
- **Item Rank System** -- Upgrade equipment from rank 0 to rank 5
- **Faction System** -- Player faction alignment with reputation
- **Prey System** -- Monster hunting bonuses
- **Imbuing System** -- Equipment enchantment slots
- **Achievement & Bestiary** -- Monster encyclopedia and achievements
- **Task System** -- Monster kill tasks with rewards
- **Daily Rewards** -- Login reward system
- **PvP System** -- Skull system with configurable rules

## Environment Variables (Docker)

| Variable | Default | Description |
|----------|---------|-------------|
| `MYSQL_HOST` | `db` | Database hostname |
| `MYSQL_PORT` | `3306` | Database port |
| `MYSQL_USER` | `forgottenserver` | Database username |
| `MYSQL_PASSWORD` | `change_me_password` | Database password |
| `MYSQL_DATABASE` | `forgottenserver` | Database name |
| `SERVER_IP` | `127.0.0.1` | Server public IP |
| `LOGIN_PORT` | `7171` | Login server port |
| `GAME_PORT` | `7172` | Game server port |

## Roadmap

See [AUDIT_AND_ROADMAP.md](AUDIT_AND_ROADMAP.md) for the engine modernization roadmap.
