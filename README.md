# ASCA - Custom MMORPG Server

ASCA is a custom MMORPG server based on The Forgotten Server (TFS) 1.3, built with C++20 for Tibia protocol 10.98. It features extensive custom gameplay systems including crafting, factions, prey, imbuing, achievements, bestiary, and PvP.

## Quick Start (Docker)

The fastest way to get the server running:

```bash
# 1. Clone the repository
git clone https://github.com/DocKarma1/asca.git
cd asca

# 2. Generate an RSA key for protocol encryption
openssl genrsa -out key.pem 2048

# 3. Create a .env file (optional - defaults work out of the box)
cp .env.example .env

# 4. Start the server and database
docker compose up -d

# 5. Check logs
docker compose logs -f tfs
```

The server will be available on ports 7171 (login) and 7172 (game). See [Connecting a Client](#connecting-a-client) below.

### Creating an Account

Connect to the database and create an account:

```bash
docker compose exec db mariadb -u forgottenserver -pchange_me_password forgottenserver
```

```sql
INSERT INTO accounts (name, password, type, premdays)
VALUES ('admin', SHA1('your_password'), 5, 365);

INSERT INTO players (name, account_id, vocation, town_id)
VALUES ('Admin', 1, 0, 1);
```

## Manual Setup

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

#### Ubuntu/Debian

```bash
sudo apt-get update && sudo apt-get install -y \
  build-essential cmake git \
  libboost-all-dev libmysqlclient-dev libluajit-5.1-dev \
  libpugixml-dev libssl-dev libfmt-dev libgmp-dev
```

#### macOS

```bash
brew install boost mysql-client luajit pugixml openssl fmt gmp cmake
```

### Build

```bash
cmake -B build
cmake --build build -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
```

### Run Tests

```bash
# C++ tests
ctest --test-dir build --output-on-failure

# Lua tests
lua tests/lua/run_tests.lua

# Integration tests (requires running server on localhost:7171/7172)
python3 tests/integration/test_server.py
```

### Database Setup

```bash
# Start MySQL/MariaDB, then:
mysql -u root -p -e "CREATE DATABASE forgottenserver;"
mysql -u root -p -e "CREATE USER 'forgottenserver'@'localhost' IDENTIFIED BY 'your_password';"
mysql -u root -p -e "GRANT ALL ON forgottenserver.* TO 'forgottenserver'@'localhost';"
mysql -u root -p forgottenserver < schema.sql
```

### Configure

```bash
cp config.lua.dist config.lua
# Edit config.lua — set mysqlPass, ip, and other settings
```

### Generate RSA Key

```bash
openssl genrsa -out key.pem 2048
```

### Run

```bash
./build/tfs
```

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

## Configuration

See `config.lua.dist` for all available settings with documentation. Key sections:
- **Combat** -- PvP rules, skull system, protection level
- **Connection** -- IP, ports, max players
- **Database** -- MySQL credentials
- **Rates** -- Experience, skill, loot multipliers
- **Custom Systems** -- Toggle and configure crafting, factions, prey, etc.

## Connecting a Client

ASCA uses Tibia protocol 10.98. You need a compatible client with the matching data files.

### Using OTClient Redemption (ascaclient)

```bash
# 1. Clone and build the client
git clone https://github.com/DocKarma1/ascaclient.git
cd ascaclient
cmake --preset macos-release   # or linux-release / windows-release
cmake --build build/macos-release

# 2. Add Tibia 10.98 data files
mkdir -p data/things/1098/
# Place Tibia.dat and Tibia.spr (from a Tibia 10.98 client) into data/things/1098/

# 3. Run the client
./otclient
```

In the login screen, set the server to `127.0.0.1`, port `7171`, and select protocol version **1098**.

Optionally, preconfigure the server list in `init.lua`:

```lua
Servers_init = {
    ["127.0.0.1"] = {
        ["port"] = 7171,
        ["protocol"] = 1098,
        ["httpLogin"] = false
    },
}
```

## Roadmap

See [AUDIT_AND_ROADMAP.md](AUDIT_AND_ROADMAP.md) for the engine modernization roadmap.
