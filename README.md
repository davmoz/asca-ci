# ASCA - Custom Medivia-Style MMORPG Server

ASCA is a custom MMORPG server based on The Forgotten Server (TFS) 1.3, featuring extensive gameplay systems inspired by Medivia and other custom servers.

## Key Features

- **Custom Vocations** -- Mage, Druid, Archer, Knight with promoted variants (High Mage, Guardian Druid, Sharpshooter, Imperial Knight)
- **6 Crafting Systems** -- Smithing, Alchemy, Cooking, Woodworking, Tailoring, Enchanting
- **Item Rank System** -- Upgrade equipment from rank 0 to rank 5 with scaling stats
- **Item Attributes** -- Random attribute rolls (STR/DEX/INT) on equipment
- **Enchanting** -- Use Painite Crystals to add random enchantments to gear
- **Task & Bestiary System** -- Monster hunting tasks with rewards
- **PvP System** -- Skull system with configurable frag timers
- **Custom Spells** -- Expanded spell list with vocation-specific abilities

## Setup

### Docker (Recommended)

```bash
cp config.lua.dist config.lua
# Edit config.lua with your settings
docker compose up -d
```

### Manual

1. Install dependencies: LuaJIT, MySQL/MariaDB, Boost, pugixml, crypto++
2. Build with CMake:
   ```bash
   mkdir build && cd build
   cmake .. && make -j$(nproc)
   ```
3. Import `schema.sql` into your database
4. Copy `config.lua.dist` to `config.lua` and configure
5. Run `./build/tfs`

## Roadmap

See [AUDIT_AND_ROADMAP.md](AUDIT_AND_ROADMAP.md) for a detailed server audit and upgrade roadmap.
