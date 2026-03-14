# ASCA - Project Guide

## Overview
ASCA is a TFS 1.3 (The Forgotten Server) fork — a C++20 MMORPG server emulator for the Tibia protocol 8.6. It includes extensive custom game systems built in Lua on top of the C++ engine.

## Build

```bash
# Dependencies: MySQL, Boost, Lua 5.1/LuaJIT, pugixml, OpenSSL, fmt
cmake -B build
cmake --build build

# Run tests
ctest --test-dir build

# Docker
docker compose up --build
```

## Directory Structure

```
src/               C++ engine source (~165 files)
src/tests/         Boost.Test unit tests (tools, sha1, xtea, base64, item, networkmessage)
tests/cpp/         Google Test unit tests (item, position, combat, condition, etc.)
data/
  lib/             Lua libraries — 26 custom game systems
  lib/core/        Core Lua modules (game, position, item, creature, etc.)
  lib/compat/      Backward-compatibility shims
  spells/          Spell scripts (instants, runes, attacks, healing, support)
  actions/         Item use scripts
  movements/       Step/equip/deequip scripts
  talkactions/     Chat command handlers
  creaturescripts/ Login/death/kill hooks
  globalevents/    Startup/timer/shutdown events
  npc/             54 NPC scripts
  monster/         706 monster definitions (XML)
  raids/           16 raid definitions (XML)
  items/items.xml  Item type definitions
  migrations/      Schema migration scripts (Lua)
config.lua.dist    Server configuration template
schema.sql         MySQL database schema
```

## Architecture

### Engine Core
- **Dispatcher** (`dispatcher.h/cpp`): Single-threaded game logic queue. All game state mutations go through the dispatcher.
- **Scheduler** (`scheduler.h/cpp`): Timed event queue — schedules future dispatcher tasks.
- **Game** (`game.h/cpp`): Central game logic — movement, combat, trading, map operations.
- **Map** (`map.h/cpp`): Tile grid with A* pathfinding. Loaded from OTBM binary format.

### Protocol Stack
- **Server** (`server.h/cpp`): TCP acceptor using Boost.Asio `io_context`.
- **Connection** (`connection.h/cpp`): Per-client socket handling, XTEA encryption, checksum validation.
- **ProtocolLogin** (`protocollogin.h/cpp`): Handles character list requests.
- **ProtocolGame** (`protocolgame.h/cpp`): Main game protocol — parses client packets, sends world state.
- **NetworkMessage** (`networkmessage.h/cpp`): Binary serialization buffer (little-endian).

### Data Layer
- **Database** (`database.h/cpp`): MySQL wrapper with connection pooling and query escaping.
- **IOLoginData** (`iologindata.h/cpp`): Player load/save to database.
- **IOMapSerialize** (`iomapserialize.h/cpp`): Map item persistence.

### Entity Model
- **Thing** → **Creature** → **Player** / **Monster** / **Npc**
- **Thing** → **Item** → **Container** / **Teleport** / **BedItem** / **Door** / etc.
- **ItemType** (`items.h`): Static item type data loaded from items.xml and items.otb.

### Lua Scripting
- **LuaScriptInterface** (`luascript.h/cpp`): Lua binding layer (~11,600 lines). Exposes game objects to Lua.
- Event types: Actions, TalkActions, MoveEvents, CreatureEvents, GlobalEvents, Spells, Weapons, Raids, Quests.

## Custom Game Systems (Lua)
All in `data/lib/`:
- `crafting*.lua` — Multi-profession crafting (smithing, mining, cooking, enchanting, farming)
- `faction_system.lua` — Player faction alignment
- `prey_system.lua` — Monster hunting bonuses
- `imbuing_system.lua` — Equipment enchantment slots
- `achievement_system.lua` — Achievement tracking
- `bestiary_system.lua` — Monster encyclopedia
- `daily_rewards.lua` — Login rewards
- `pvp_systems.lua` + `retro_pvp.lua` — PvP rulesets
- `task_system.lua` — Monster kill tasks
- `weekly_dungeons.lua` — Instanced dungeon content
- `legendary_items.lua` + `item_ranks.lua` — Item quality tiers
- Custom items: IDs 30000–30799

## Testing

### C++ Tests
```bash
ctest --test-dir build               # Run all tests
ctest --test-dir build -R test_item  # Run specific test
```

Two test frameworks:
- `tests/cpp/` — Google Test (item, position, combat, condition, vocation, configmanager, database, player, wildcardtree, tools)
- `src/tests/` — Boost.Test (tools, sha1, xtea, base64, item, networkmessage)

### Lua Tests
```bash
lua tests/lua/run_tests.lua
```

## Key Patterns
- **Config**: `ConfigManager` singleton with typed accessors (`getString`, `getNumber`, `getBoolean`). Keys in `configmanager.h`.
- **Database queries**: Use `fmt::format` for query building. Always escape user input with `db.escapeString()`.
- **[[nodiscard]]**: Applied to database query functions and crypto utilities. Use `(void)` cast for intentional fire-and-forget calls.
- **Protocol**: Protocol 10.98 constants in `definitions.h`. Do not change protocol version.
- **Custom content safety**: Never modify item IDs 30000–30799, monster files, NPC scripts, or Lua libraries without explicit request.
