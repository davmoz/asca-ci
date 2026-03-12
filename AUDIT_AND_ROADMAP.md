# Open Tibia Server - Full Audit & Medivia-Style Upgrade Roadmap

> **Date**: 2026-03-12
> **Current Engine**: The Forgotten Server (TFS) v1.3
> **Protocol**: Tibia Client 10.98 (protocol 1097-1098)
> **Language**: C++11 with LuaJIT scripting
> **Database**: MySQL/MariaDB
> **Target**: Medivia Online-level (or better) custom MMORPG server on latest TFS

---

## Table of Contents

1. [Current Server Audit](#1-current-server-audit)
2. [Engine Upgrade Path (TFS 1.3 -> 1.6+)](#2-engine-upgrade-path)
3. [Medivia Online Feature Analysis](#3-medivia-online-feature-analysis)
4. [Gap Analysis: What We Have vs What We Need](#4-gap-analysis)
5. [Implementation Roadmap](#5-implementation-roadmap)
6. [Phase Details](#6-phase-details)
7. [Technical Debt & Maintenance](#7-technical-debt--maintenance)

---

## 1. Current Server Audit

### 1.1 Engine Overview

| Property | Value |
|----------|-------|
| Engine | The Forgotten Server (TFS) |
| Version | **1.3** |
| Protocol | Tibia 10.98 (versions 1097-1098) |
| C++ Standard | C++11 |
| Build System | CMake 3.10+ |
| Database | MySQL/MariaDB only |
| Scripting | Lua via LuaJIT |
| Platforms | Linux, Windows (VS2014+), macOS |
| CI/CD | GitHub Actions, Travis CI, AppVeyor, Coverity |
| Container | Docker support included |

### 1.2 Source Code Inventory (src/)

**Total: ~165 C++ files (~82,000+ lines)**

| Module | Files | Description |
|--------|-------|-------------|
| Core Engine | 9 | game.cpp/h, server, otserv, constants, enums, tools |
| Protocol & Networking | 10 | protocolgame, protocollogin, protocolstatus, protocolold, connection, networkmessage, outputmessage, XTEA/RSA encryption |
| Database | 4 | MySQL database, manager, async tasks, login data |
| Map & World | 8 | map, tile, housetile, position, OTBM loader, serialization, spawns, towns |
| Players & Creatures | 8 | player, creature, monster, monsters, npc, outfit, vocation, mounts |
| Items & Inventory | 10 | item, items, itemloader, container, depotchest, depotlocker, inbox, storeinbox, trashholder, mailbox |
| Game Systems | 20 | combat, condition, spells, weapons, party, guild, house, raids, quests, chat, channels, market, ban, waitlist, groups, bed, teleport, movement |
| Scripting & Events | 12 | luascript, script, scriptmanager, baseevents, creatureevent, globalevent, events, actions, talkaction |
| Utilities | 14 | scheduler, tasks, fileloader, wildcardtree, configmanager, spectators, thread utilities, lock-free structures |

### 1.3 Data Directory Inventory (data/)

#### Spells: **235 Lua scripts, 175 defined spells**
- 139 instant spells, 36 rune spells
- Categories: Attack (77), Monster abilities (51), Conjuring (47), Healing (22), Support (25), Party (4), House (4), Custom (5)
- Includes: Exura, Exura Gran, Exura Vita, Sudden Death, Great Fireball, Paralyze, Magic Shield, Haste, Invisible, Levitate, all standard Tibia spells

#### Monsters: **703 monster definitions, 152 bosses**
- Full monster XML definitions with loot tables, AI behavior, spells, resistances
- Boss monsters include: Ferumbras, Morgaroth, Ghazbaran, Orshabaal, Demodras, Hellgorak, Infernatil, and 145+ more
- Categories: Dragons, Elementals, Demons, Humanoids, Undead, Beasts, Unique spawns

#### NPCs: **8 NPCs**
- Alice (Blessings), Banker (Banking), Riona (Shopkeeper), Eryn (General)
- The Oracle (Quest), The Forgotten King (Special), Tyoric, Deruno
- **CRITICAL GAP**: Only 8 NPCs - Medivia has hundreds

#### Items: **~1,600+ items**
- items.xml (1.5 MB) + items.otb (1.1 MB binary)
- Categories: Equipment, Weapons, Ammunition, Consumables, Quest Items, Containers, Fluids, Decorations
- Standard Tibia item set, no custom items

#### Actions: **209 action definitions, 39 Lua scripts**
- Enchanting, Market, Quests, Tools (Rope, Crowbar, Machete, Scythe, Pick, Shovel, Kitchen Knife, Fishing Rod)
- Food, Doors, Potions, Beds, Fluids, Teleports, Traps, Snow, Fireworks, Music

#### Talkactions: **45 chat commands**
- Admin: /ban, /ipban, /unban, /kick, /goto, /up, /down, /openserver, /closeserver, /B (broadcast)
- Creation: /m (monster), /i (item), /s (NPC), /summon
- Utility: /ghost, /clean, /hide, /reload, /raid
- Player: !buypremium, !buyhouse, !sellhouse, !leavehouse, !changesex, !uptime, !deathlist, !kills, !online, !serverinfo

#### Movements: **12 Lua scripts**
- Citizen teleportation, doors (closing, level, quest), drowning, swimming, snow, traps, decay, dough, walkback

#### Creature Scripts: **4 scripts**
- login.lua, logout.lua, firstitems.lua, plus creature script lib

#### Global Events: Present with XML + Lua scripts
#### Raids: raids.xml with testraid.xml example
#### Chat Channels: Configured with XML + Lua
#### Events/Callbacks: Event system with XML + Lua scripts

#### Map: **forgotten.otbm (3.7 MB)**
- Main world map with spawn definitions (67 KB) and house definitions (12 KB)
- Small/medium sized map

#### Lua Libraries (data/lib/):
- Core libraries: player.lua, creature.lua, item.lua, container.lua, combat.lua, constants.lua, game.lua, tile.lua
- Compatibility layer for older scripts
- Debug utilities

#### Database Migrations: **34 migration files** (0.lua through 33.lua)

### 1.4 Game Systems Currently Implemented

| System | Status | Notes |
|--------|--------|-------|
| Combat (melee/ranged/magic) | FULL | All damage types, area effects, callbacks |
| Conditions/Status Effects | FULL | 13 condition types (poison, fire, energy, speed, regen, etc.) |
| Party System | FULL | Shared XP, loot, leadership |
| Guild System | FULL | Ranks, wars, MOTD, invitations |
| House System | FULL | Ownership, rent, doors, access lists |
| Market System | FULL | Buy/sell offers, statistics, history |
| Quest System | FULL | XML-based quest tracking |
| Raid System | FULL | Scheduled monster raids |
| Spell System | FULL | Instant, rune, conjure spells |
| Weapon System | FULL | Melee, distance, wand classes |
| Monster AI | FULL | A* pathfinding, targeting strategies, summons |
| NPC System | BASIC | Only 8 NPCs, Lua scripted |
| Chat System | FULL | Channels, whisper, yell |
| Ban System | FULL | IP/account/character bans |
| Login Queue | FULL | Waitlist system |
| Mail System | FULL | Mailbox & parcels |
| Bed System | FULL | Offline training |
| Mount System | FULL | Mount definitions |
| Outfit System | FULL | Outfit definitions |
| Vocation System | FULL | 4 base + 4 promoted vocations |

### 1.5 What is NOT Implemented

| System | Status |
|--------|--------|
| Fishing (as a skill) | NOT PRESENT |
| Cooking System | NOT PRESENT |
| Farming System | NOT PRESENT |
| Mining System | NOT PRESENT |
| Smithing/Crafting | NOT PRESENT |
| Attribute/Enchanting System | NOT PRESENT |
| Item Rank System | NOT PRESENT |
| Bestiary | NOT PRESENT |
| Task/Hunting System | NOT PRESENT |
| Faction System | NOT PRESENT |
| Achievement System | NOT PRESENT |
| Daily Rewards | NOT PRESENT |
| Prey System | NOT PRESENT |
| Imbuing System | NOT PRESENT |
| Forge System | NOT PRESENT |
| Store/Premium Shop | NOT PRESENT |
| Custom Vocations (Archer/Ranger) | NOT PRESENT |
| Legendary Items | NOT PRESENT |
| Item Properties (STR/DEX/INT) | NOT PRESENT |
| Custom World Map | NOT PRESENT |
| Comprehensive NPC Network | NOT PRESENT (only 8 NPCs) |
| Custom Sprites/Graphics | NOT PRESENT |
| Anti-Cheat Systems | NOT PRESENT |
| War Auto-Accept | NOT PRESENT |
| Custom Outfits/Addons | MINIMAL |
| Event System (seasonal) | NOT PRESENT |

---

## 2. Engine Upgrade Path

### 2.1 Current State: TFS 1.3

- C++11, protocol 10.98
- Copyright 2019 Mark Samman
- Stable but **severely outdated** (3+ major versions behind)

### 2.2 Target: TFS 1.6 (Latest Stable)

| Feature | TFS 1.3 (Current) | TFS 1.6 (Target) |
|---------|-------------------|-------------------|
| Protocol | 10.98 | **13.10** |
| C++ Standard | C++11 | **C++17** |
| Lua | LuaJIT | **Lua 5.4** (LuaJIT optional) |
| NPC System | Old XML+Lua | **RevNpcSys** (pure Lua NPC system) |
| Login Server | None | **Built-in HTTP login server** |
| Storages | Old system | **New storage management** |
| CMake | 3.10 | **Updated CMake** |
| Stamina Bonus | 2 hours | **3 hours** |
| Market Fee Cap | 1,000 gold | **100,000 gold** |
| Podium | No | **Yes** |
| Colored Loot | No | **Yes** |
| Item Decay | Basic | **Improved** |

### 2.3 Upgrade Strategy

**Option A: Full Replacement (Recommended)**
1. Start fresh with TFS 1.6 from otland/forgottenserver
2. Port all 703 monsters, 235 spells, items, actions from current data/
3. Rebuild NPCs using RevNpcSys (Lua-native NPC system)
4. Re-create or convert map from OTBM format
5. Migrate database schema using TFS 1.6 schema + custom migrations

**Option B: Incremental Upgrade**
1. Merge TFS 1.4 changes into current codebase
2. Then merge TFS 1.5/1.6 changes
3. Higher risk of merge conflicts, but preserves custom changes

**Option C: TFS 1.5 Downgrade Fork (Protocol Flexibility)**
1. Use nekiro/TFS-1.5-Downgrades or MillhioreBT/forgottenserver-downgrade
2. Get TFS 1.5+ engine with older protocol support (7.72, 8.6, 10.98)
3. Best if you want to keep 10.98 protocol but get engine improvements

**Recommendation**: **Option A** - TFS 1.6 gives you the most modern engine, best community support, and the cleanest foundation for building Medivia-level features.

---

## 3. Medivia Online Feature Analysis

### 3.1 What Makes Medivia Special

Medivia Online is a custom OTS that has evolved far beyond standard TFS. It distinguishes itself through:

#### Custom Vocations
| Medivia Vocation | Promotion | Key Features |
|------------------|-----------|--------------|
| Knight | Imperial Knight | Melee master, Challenge/Taunt spells, high HP |
| **Archer** | Royal Archer | **Unique vocation** (replaces Paladin), bows/crossbows, balanced HP/damage |
| Mage | High Mage | Highest damage potential, Sudden Death & Magic Wall runes |
| Druid | Guardian Druid | Healing master, Purification (HoT spell), Ultimate Healing Runes |

#### Crafting & Gathering Systems (6 interconnected systems)
1. **Fishing** - Skill-based, fish pools, 12+ fish species, tiered by location/rod/skill
2. **Farming** - Grow vegetables/fruits in house planting pots or public farms
3. **Cooking** - Combine fish + farmed ingredients into stat-boosting meals, cooking skill progression
4. **Mining** - 11 ore types, rarity based on location danger, found everywhere
5. **Smithing** - Smelt ores into bars, craft top-tier equipment
6. **Enchanting (Attributes)** - Painite crystals enchant items, 3 crystal tiers, vocation-specific bonuses

#### Item System
- **Attributes**: Random bonuses on drops (Attack +1-3, Critical Hit, Berserk, Gauge, Crushing Blow, etc.)
- **Item Ranks**: Items have rank levels affecting stat bonuses
- **Properties**: Strength, Dexterity, Intelligence affecting damage/spellpower
- **Legendary Items**: Rare drops from elite monster variants with unique on-use effects
- **Vocation-specific attributes**: Some bonuses only work for certain classes

#### Task & Faction Systems
- **Hunter's Guild Tasks**: Accessible via in-game UI, kill X monsters for rewards
- **Tylar Tasks**: NPC-based task chains in Abukir
- **Experience Tasks**: Kill-count rewards with XP bonuses
- **Factions**: Series of unique missions pushing exploration, unlocking new spells per vocation, access to hunting spots, travel routes, and equipment crafting recipes

#### PvP & Combat
- **Retro PvP**: No rune hotkeys, manual aiming required
- **No Wands/Rods**: Low-level mages use war hammers and summons
- **Rope Hole Blocking**: Strategic PvP element
- **Guild Wars**: Auto-accept system when pending war invites exist
- **Skull System**: Custom PvP flagging

#### World & Content
- **Custom World Map**: Entirely built from scratch, massive continent
- **Custom Sprites**: Higher quality 2D pixel art graphics engine
- **4,855+ Wiki Articles**: Indicating massive content depth
- **Hidden Treasures & Secrets**: Exploration-heavy design
- **Weekly Dungeons**: Repeatable instanced content (quest-gated access)
- **Seasonal Events**: Annual events with exclusive rewards
- **Royal Outfit**: Prestige cosmetic with annual XP event
- **15+ Custom Raids**: With daily minimum raid guarantees

#### Housing & Customization
- **House Decorating**: Extensive decoration system
- **Floor Modification**: Change house flooring
- **Store Cosmetics**: Premium decorative items
- **Custom Outfits**: Tons of new outfits, skin colors, and addons via quests

#### Economy
- **Premium Account**: ~7 EUR/month with vocation promotions, enhanced regen
- **Player-driven economy**: Crafting creates economic sinks and sources
- **Multiple gold sinks**: Enchanting crystals, house rent, premium, crafting materials

---

## 4. Gap Analysis

### What We Have vs. What Medivia Has

| Feature | Our Server | Medivia | Gap Level |
|---------|-----------|---------|-----------|
| **Engine Version** | TFS 1.3 (10.98) | Custom (likely heavily modified TFS) | CRITICAL |
| **Vocations** | Standard 4 (Sorc/Druid/Pally/Knight) | Custom 4 (Knight/Archer/Mage/Druid) | MAJOR |
| **NPCs** | 8 | Hundreds | CRITICAL |
| **Monsters** | 703 (152 bosses) | Custom + Standard | MODERATE |
| **Map** | forgotten.otbm (3.7 MB) | Custom massive continent | CRITICAL |
| **Fishing** | Basic action script | Full skill system with species/tiers | MAJOR |
| **Cooking** | Not present | Full skill + recipe system | CRITICAL |
| **Farming** | Not present | House pots + public farms | CRITICAL |
| **Mining** | Not present | 11 ores, location-based rarity | CRITICAL |
| **Smithing** | Not present | Ore -> Bar -> Equipment pipeline | CRITICAL |
| **Enchanting** | Basic enchanting action | Painite crystals, 3 tiers, vocation bonuses | CRITICAL |
| **Item Attributes** | Not present | Random bonuses, vocation-specific | CRITICAL |
| **Item Ranks** | Not present | Rank progression system | CRITICAL |
| **Legendary Items** | Not present | Elite monster drops, unique effects | MAJOR |
| **Tasks** | Not present | Hunter's Guild + Tylar + Experience tasks | CRITICAL |
| **Factions** | Not present | Multi-quest faction chains | CRITICAL |
| **Bestiary** | Not present | Full creature encyclopedia | MAJOR |
| **Retro PvP** | Standard PvP | No hotkeys, manual aim, rope blocking | MAJOR |
| **Weekly Dungeons** | Not present | Instanced weekly content | MAJOR |
| **Custom Sprites** | Standard Tibia | Custom pixel art | CRITICAL |
| **Seasonal Events** | Not present | Annual events with rewards | MODERATE |
| **Anti-Cheat** | Not present | Required for production | CRITICAL |
| **Website/AAC** | Not present | Account management + shop | CRITICAL |

---

## 5. Implementation Roadmap

### Overview: 8 Phases

```
Phase 0: Foundation (Engine Upgrade)           [Weeks 1-4]
Phase 1: Core Systems Rewrite                  [Weeks 5-10]
Phase 2: Crafting & Gathering Systems          [Weeks 11-18]
Phase 3: Item System Overhaul                  [Weeks 19-24]
Phase 4: Content Pipeline                      [Weeks 25-36]
Phase 5: PvP & Social Systems                  [Weeks 37-42]
Phase 6: Polish & Production                   [Weeks 43-50]
Phase 7: Launch Preparation                    [Weeks 51-56]
```

**Estimated Total: ~14 months for a solo/small-team developer**

---

## 6. Phase Details

### Phase 0: Foundation - Engine Upgrade [Weeks 1-4]

**Goal**: Get running on TFS 1.6 with all existing content ported

- [ ] Clone TFS 1.6 from otland/forgottenserver
- [ ] Set up build environment (CMake, C++17 compiler, MySQL, Lua 5.4)
- [ ] Port all 703 monster XMLs to TFS 1.6 format
- [ ] Port all 235 spell scripts (check Lua compatibility with 5.4)
- [ ] Port items.xml and items.otb (may need OTB version update)
- [ ] Port all action scripts (39 scripts)
- [ ] Port all movement scripts (12 scripts)
- [ ] Port talkaction scripts (45 commands)
- [ ] Port creature scripts (4 scripts)
- [ ] Port global events, raids, chat channels
- [ ] Convert/rebuild NPCs using RevNpcSys
- [ ] Port or recreate map in compatible OTBM format
- [ ] Migrate database schema (schema.sql -> TFS 1.6 schema + 28 existing migrations)
- [ ] Verify build and basic server functionality
- [x] Set up Docker development environment

**Deliverable**: Server boots on TFS 1.6 with all existing content working

---

### Phase 1: Core Systems Rewrite [Weeks 5-10]

**Goal**: Modify base systems to support Medivia-style gameplay

#### 1.1 Custom Vocation System
- [x] Replace Paladin with Archer (Royal Archer promotion)
- [x] Rename promotions: Elite Knight -> Imperial Knight, Elder Druid -> Guardian Druid, Master Sorcerer -> High Mage
- [x] Rebalance vocation stats (HP/mana/cap/regen per level)
- [x] Remove wands and rods from game
- [ ] Add war hammer as low-level mage weapon
- [ ] Adjust spell availability per new vocation names
- [ ] Create Archer-specific spells and abilities

#### 1.2 Skill System Extensions
- [ ] Add Fishing as a proper skill (beyond basic action)
- [ ] Add Cooking skill (new skill type in C++ engine)
- [ ] Add Mining skill (new skill type in C++ engine)
- [ ] Modify `player.h/cpp` to support new skill types
- [ ] Modify `vocation.h/cpp` for new skill multipliers
- [ ] Update database schema for new skill columns
- [ ] Update protocol to send/display new skills to client

#### 1.3 Retro PvP Mechanics
- [x] Disable rune hotkey functionality (require manual use)
- [x] Implement rope hole blocking mechanic
- [x] Adjust PvP damage formulas
- [x] Implement custom skull system
- [x] Add guild war auto-accept on pending kill

**Deliverable**: Custom vocations playable, new skills trackable, retro PvP active

---

### Phase 2: Crafting & Gathering Systems [Weeks 11-18]

**Goal**: Implement the 6 interconnected crafting/gathering systems

#### 2.1 Fishing System
- [x] Create fish species items (12+ types with different rarity tiers)
- [x] Implement fish pool map objects (spawning/despawning)
- [x] Create fishing rod tiers (basic -> advanced)
- [x] Implement fishing skill progression (affects catch rate/species)
- [x] Add location-based fish availability
- [x] Add time-of-day fishing modifiers
- [x] Create fishing-related NPCs

#### 2.2 Farming System
- [x] Create seed/crop items (vegetables, fruits)
- [x] Implement planting pot house item
- [x] Create public farm locations on map
- [x] Implement growth cycle (plant -> grow -> harvest with timers)
- [x] Add watering/tending mechanics
- [x] Create farming tool items
- [x] Seasonal crop availability

#### 2.3 Cooking System
- [x] Implement cooking skill with progression
- [x] Create recipe system (ingredient combinations -> meals)
- [x] Design 20+ meal recipes with different stat buffs
- [x] Implement cooking stations (stoves, campfires)
- [x] Add buff duration and stacking rules
- [x] Create cooking-related NPCs (recipe teachers)
- [x] Fish as primary ingredient requirement

#### 2.4 Mining System
- [x] Create 11 ore types with rarity tiers
- [x] Place ore veins on world map (surface to deep caves)
- [x] Implement mining tool tiers (pickaxes)
- [x] Add mining skill progression
- [x] Implement ore respawn timers
- [x] Rarer ores in more dangerous locations
- [x] Mining-related sound/visual effects

#### 2.5 Smithing System
- [x] Implement smelting: ore -> bars (furnace interaction)
- [x] Create smithing recipes: bars + materials -> equipment
- [x] Design crafted equipment tier list (some of best-in-slot)
- [x] Implement anvil/forge interaction
- [x] Add smithing skill progression
- [x] Create smith NPC trainers
- [x] Quality/grade system for crafted items

#### 2.6 Enchanting System
- [x] Create Painite Crystal items (Small/Medium/Large shards)
- [x] Implement enchanting mechanic (crystal + item = attribute)
- [x] Design attribute pool per item type
- [x] Implement attribute generation with rarity weights
- [x] Add success/failure chances per crystal tier
- [x] Vocation-specific attributes (Intelligence for mages, etc.)
- [x] Attribute stacking rules and limits

**Deliverable**: All 6 crafting/gathering systems functional and interconnected

---

### Phase 3: Item System Overhaul [Weeks 19-24]

**Goal**: Implement Medivia's advanced item system

#### 3.1 Item Attributes (Random Bonuses)
- [x] Extend `item.h/cpp` to support random attribute generation
- [x] Define attribute types: Attack, Critical Hit, Berserk, Gauge, Crushing Blow, Dazing Blow, Lean, etc.
- [x] Implement attribute generation on monster loot drops
- [x] Create attribute display in item descriptions
- [x] Add vocation restrictions to certain attributes
- [x] Implement attribute effect processing in combat system

#### 3.2 Item Rank System
- [x] Design item rank progression (Rank 1-5 or similar)
- [x] Implement Properties system: Strength, Dexterity, Intelligence
- [x] Properties scale with Item Rank
- [x] Rank affects damage output and spellpower
- [x] Create rank upgrade mechanic (materials/gold cost)
- [x] Update client item tooltips for rank display

#### 3.3 Legendary Items
- [x] Design 20+ legendary items with unique effects
- [x] Create elite/legendary monster variants
- [x] Implement unique on-use item effects
- [x] Legendary item visual indicators
- [x] Drop rate balancing for legendary items
- [x] Legendary items cannot be enchanted (or have special rules)

#### 3.4 Equipment Rebalancing
- [ ] Rebalance all existing equipment for new systems
- [ ] Create new equipment tiers (crafted > dropped > shop)
- [ ] Design set bonuses for craftable equipment sets (e.g., Revenant set)
- [ ] Balance stat progression curves

**Deliverable**: Items have attributes, ranks, properties; legendary items exist

---

### Phase 4: Content Pipeline [Weeks 25-36]

**Goal**: Build the massive content that makes a world feel alive

#### 4.1 World Map
- [ ] Design new custom continent (or significantly expand current map)
- [ ] Create distinct biomes/regions with unique aesthetics
- [ ] Place cities with full NPC services
- [ ] Design hunting grounds for all level ranges (1-500+)
- [ ] Create cave systems, mountains, underwater areas
- [ ] Place ore veins, fish pools, farm plots across world
- [ ] Design quest-specific dungeons
- [x] Create weekly dungeon instances
- [ ] Hidden areas and secret passages
- [ ] Strategic PvP zones

#### 4.2 NPC Network (100+ NPCs minimum)
- [x] City NPCs: Shopkeepers (weapons, armor, tools, runes, potions)
- [x] Service NPCs: Bankers, Blessers, Boat captains, Carpet riders
- [x] Quest NPCs: Faction leaders, quest givers, lore characters
- [x] Craft NPCs: Smithing trainers, cooking teachers, mining instructors
- [x] Task NPCs: Hunter's Guild masters, Tylar-equivalent
- [x] Special NPCs: Promotion NPCs, outfit/addon quest NPCs
- [x] Guard NPCs for cities and important locations
- [x] Each NPC needs unique dialogue, shop lists, and purpose

#### 4.3 Task & Faction Systems
- [x] Implement Hunter's Guild task system (in-game UI button)
- [x] Create 50+ tasks across all level ranges
- [ ] Design 4+ faction questlines with branching rewards
- [ ] Faction reputation tracking
- [ ] Faction-specific rewards: spells, hunting grounds, travel routes, equipment recipes
- [x] Experience Tasks with kill-count XP bonuses

#### 4.4 Quest Content
- [x] Design 30+ quests of varying difficulty
- [x] Access quests (unlock areas/features)
- [x] Equipment quests (craft specific gear sets)
- [x] Lore quests (world-building narrative)
- [x] Promotion quests
- [x] Outfit/addon quests
- [x] Boss fight quests

#### 4.5 Monster Content
- [ ] Review and rebalance existing 703 monsters for new systems
- [ ] Add loot attribute generation to monster drops
- [ ] Create elite/legendary monster variants
- [ ] Design new custom monsters for new areas
- [ ] Create monsters that drop crafting materials (ores, ingredients, crystals)
- [ ] Balance spawn rates and respawn times

#### 4.6 Raid System Enhancement
- [x] Design 15+ new raids
- [x] Implement daily minimum raid guarantee
- [x] Create raid-specific boss monsters
- [x] Raid announcement system
- [x] Raid reward distribution

#### 4.7 Bestiary System
- [x] Design bestiary UI/data structure
- [x] Track kill counts per creature
- [x] Unlock creature information progressively
- [x] Display skin/loot success chances
- [x] Bestiary completion rewards

#### 4.8 Achievement System
- [x] Design achievement categories (exploration, combat, crafting, quests)
- [x] Create 100+ achievements
- [x] Achievement points and reward tiers
- [x] Achievement display in character info

**Deliverable**: Rich, explorable world with hundreds of NPCs, quests, tasks, and activities

---

### Phase 5: PvP & Social Systems [Weeks 37-42]

**Goal**: Create compelling multiplayer systems

#### 5.1 Enhanced Guild System
- [x] Guild halls with custom decorating
- [x] Guild bank
- [x] Guild achievements/levels
- [x] Enhanced guild war system with auto-accept
- [x] Guild alliances
- [x] Guild rankings and leaderboards

#### 5.2 PvP Enhancements
- [x] Arena/duel system
- [x] PvP zones with special rules
- [x] Bounty system
- [x] PvP rankings/leaderboard
- [x] Anti-griefing protections for low-levels

#### 5.3 Party System Enhancements
- [x] Party finder/matchmaking
- [x] Party quests (require full party)
- [x] Enhanced shared XP formulas
- [x] Party buffs (from druid healer role)

#### 5.4 Housing Enhancements
- [x] Floor modification system
- [x] Expanded decoration options
- [x] House display/showroom feature
- [x] House-based crafting stations
- [x] Planting pots for farming in houses

#### 5.5 Seasonal Events
- [x] Christmas event with exclusive rewards
- [x] Halloween event
- [x] Easter event
- [x] Anniversary event
- [x] Design event-specific monsters, quests, and cosmetic rewards
- [ ] Royal Outfit prestige system with annual XP event

**Deliverable**: Social systems encourage community building and competitive play

---

### Phase 6: Polish & Production [Weeks 43-50]

**Goal**: Production-ready server

#### 6.1 Custom Client
- [ ] Fork OTClient or use Mehah's otclient
- [ ] Implement custom sprites and graphics
- [ ] Add UI for: Tasks, Bestiary, Achievements, Crafting, Mining, Cooking
- [ ] Custom login screen
- [ ] Add attribute/rank display on items
- [ ] Add skill display for new skills (Fishing, Cooking, Mining)
- [ ] Performance optimization

#### 6.2 Website & AAC (Automatic Account Creator)
- [ ] Set up MyAAC or Gesior AAC (or custom)
- [ ] Player registration and login
- [ ] Character creation page
- [ ] Server info/status page
- [ ] Highscores (including new skills)
- [ ] Guild management page
- [ ] House management page
- [ ] Premium shop (if monetizing)
- [ ] News/changelog system
- [ ] Support ticket system

#### 6.3 Anti-Cheat & Security
- [ ] Implement bot detection
- [ ] Packet validation
- [ ] Speed hack detection
- [ ] Multi-client detection improvements
- [x] DDoS protection (network level)
- [x] SQL injection prevention audit
- [x] Rate limiting on login/actions

#### 6.4 Performance & Scalability
- [ ] Database query optimization
- [ ] Map loading optimization
- [ ] Memory profiling and leak detection
- [ ] Connection handling improvements
- [ ] Server save optimization
- [ ] Stress testing (100+ concurrent players)

#### 6.5 Admin Tools
- [ ] In-game admin panel
- [ ] Server monitoring dashboard
- [ ] Player analytics
- [ ] Economy monitoring tools
- [ ] Log management

**Deliverable**: Production-ready, secure, performant server with client and website

---

### Phase 7: Launch Preparation [Weeks 51-56]

**Goal**: Ready for public launch

- [ ] Closed beta testing (invite 20-50 players)
- [ ] Bug fix sprint based on beta feedback
- [ ] Balance adjustments (XP rates, loot rates, crafting difficulty)
- [ ] Economy stress testing
- [ ] Server infrastructure setup (hosting, backups, monitoring)
- [ ] Open beta (larger audience)
- [ ] Final polish based on open beta feedback
- [ ] Marketing preparation (OTLand, OTServList, Discord, social media)
- [ ] Launch day preparation (server capacity, GM team, support channels)
- [ ] Post-launch monitoring plan

**Deliverable**: Public server launch

---

## 7. Technical Debt & Maintenance

### Ongoing Concerns

1. **TFS Updates**: Monitor otland/forgottenserver for patches and security fixes
2. **Client Updates**: Keep OTClient fork updated
3. **Database Backups**: Automated daily backups with retention policy
4. **Content Updates**: Monthly content patches (new quests, monsters, items)
5. **Community Management**: Active GM team, forums/Discord moderation
6. **Economy Monitoring**: Watch for exploits, inflation, duplication bugs
7. **Performance Monitoring**: Server metrics, player count vs. performance

### Key Dependencies

| Dependency | Current | Target |
|-----------|---------|--------|
| C++ Compiler | C++11 | C++17 (GCC 9+ / Clang 10+ / MSVC 2019+) |
| CMake | 3.10 | 3.16+ |
| MySQL | Any | MySQL 8.0+ or MariaDB 10.6+ |
| Lua | LuaJIT | Lua 5.4 (with LuaJIT compat layer optional) |
| Boost | Required | Latest stable |
| PugiXML | Included | Included in TFS 1.6 |
| OpenSSL | Required | 1.1+ or 3.0+ |

### Repository Links

- TFS 1.6 (Latest Stable): https://github.com/otland/forgottenserver
- TFS 1.5 Downgrades: https://github.com/nekiro/TFS-1.5-Downgrades
- TFS Downgrade 1.5+: https://github.com/MillhioreBT/forgottenserver-downgrade
- OTClient: https://github.com/mehah/otclient
- MyAAC: https://github.com/slawkens/myaac
- OTLand Forums: https://otland.net

---

## Priority Matrix

### Must Have (MVP for Launch)
1. TFS 1.6 engine upgrade
2. Custom vocations (Archer replacing Paladin)
3. At least 3 crafting systems (Fishing, Cooking, Mining)
4. Item Attributes (random bonuses)
5. Task system (Hunter's Guild)
6. Custom world map with 50+ NPCs
7. 20+ quests
8. Website/AAC
9. Basic anti-cheat
10. Retro PvP mechanics

### Should Have (Post-MVP)
1. Smithing & full crafting pipeline
2. Farming system
3. Item Ranks & Properties
4. Faction system
5. Bestiary & Achievements
6. Weekly dungeons
7. Legendary items
8. 100+ NPCs
9. Seasonal events
10. Enhanced guild system

### Nice to Have (Future Updates)
1. Custom sprites/graphics engine
2. Advanced anti-cheat
3. Player housing floor modification
4. Guild halls with crafting stations
5. PvP arenas/rankings
6. Royal Outfit prestige
7. Mobile client support
8. Live event system

---

## 8. Detailed Implementation Notes

Detailed implementation plans with source code analysis, file change lists, starter code, and architecture decisions are maintained in the `docs/` directory:

### Phase 1: Core Systems

- **[docs/phase1-vocations.md](docs/phase1-vocations.md)** -- Vocation system overhaul
  - Replace Paladin with Archer (Royal Archer promotion)
  - Rename: Sorcerer->Mage (High Mage), Elder Druid->Guardian Druid, Elite Knight->Imperial Knight
  - Complete stat rebalancing tables (HP/mana/cap/regen/skill multipliers per vocation)
  - Spell redistribution plan for all vocation name references
  - Wand/rod removal strategy (remove from items/shops/loot, keep engine code)
  - War hammer as low-level mage weapon
  - Key finding: Vocation system is entirely data-driven from `data/XML/vocations.xml`; no C++ changes required for the rename/rebalance

- **[docs/phase1-skills.md](docs/phase1-skills.md)** -- Skill system extensions
  - Add SKILL_COOKING (7) and SKILL_MINING (8) to the C++ engine
  - Exact files and line numbers for all changes: `src/enums.h`, `src/vocation.h`, `src/vocation.cpp`, `src/iologindata.cpp`, `src/protocolgame.cpp`, `src/luascript.cpp`, `src/condition.cpp`, `src/items.cpp`
  - Database migration script for new skill columns
  - Protocol impact analysis: requires OTClient (standard client expects exactly 7 skills)
  - Fishing upgrade from basic action to full species/location/rod-tier system
  - Risk assessment: shifting SKILL_MAGLEVEL/SKILL_LEVEL constants requires careful audit

- **[docs/phase1-retro-pvp.md](docs/phase1-retro-pvp.md)** -- Retro PvP mechanics
  - Rune hotkey blocking: add check in `src/actions.cpp` to block `isHotkey` for rune items
  - Rope hole blocking: Lua-side creature check on destination tile
  - PvP damage reduction: configurable multipliers in `Combat::doTargetCombat()`
  - Custom skull system: configurable thresholds, skull-based death penalties
  - Guild war auto-accept: trigger on `Player::onKilledCreature()` when pending war exists
  - All changes config-driven via `config.lua` for runtime tunability

### Phase 2: Crafting & Gathering

- **[docs/phase2-crafting-overview.md](docs/phase2-crafting-overview.md)** -- Architecture for all 6 crafting systems
  - Shared crafting framework design (`data/lib/crafting.lua`) with recipe/ingredient data structures
  - Skill progression curves (exponential formula analysis with projected training times)
  - Individual system designs: Fishing (12+ species, pool system), Farming (growth cycles), Cooking (20+ recipes with stat buffs), Mining (11 ores, vein depletion/respawn), Smithing (two-phase smelting+forging), Enchanting (Painite crystals, attribute pools)
  - Item ID range allocation (30001-30799)
  - Database tables: `crafting_recipes`, `farming_plots`, `player_crafting_log`
  - NPC interaction plans for each system
  - Implementation order based on dependency graph

### Phase 3: Item System

- **[docs/phase3-items.md](docs/phase3-items.md)** -- Item system overhaul
  - Random attribute system using existing `CustomAttribute` infrastructure (no new C++ types needed)
  - 18 attribute types defined with pools per item category (weapons, armor, shields, boots)
  - Attribute generation tied to monster difficulty level
  - Item rank system (0-5) with exponential upgrade costs and failure penalties
  - Properties system (STR/DEX/INT) derived from equipped item ranks and attributes
  - Legendary item framework: fixed attributes, unique on-hit/on-equip effects, elite monster variants
  - Combat integration points in `Player::getArmor()`, `Player::getDefense()`, combat event callbacks
  - Key finding: existing `grade`, `attackModPassive`, `critPassive` etc. in `ItemType` suggest prior custom work that can be leveraged

### Key Architectural Decisions

1. **Data-driven vocation system**: All vocation changes are XML-only, minimizing C++ risk
2. **CustomAttribute for item attributes**: Leverages existing serialization (`ATTR_CUSTOM_ATTRIBUTES`) -- no new binary format needed
3. **Lua-first crafting**: All crafting logic in Lua for rapid iteration; C++ only for new skill enums and database columns
4. **OTClient required**: Custom skills, attributes display, and crafting UI all require OTClient fork
5. **Config-driven PvP**: All PvP tuning values in `config.lua` for live adjustment without recompilation

---

*This document serves as a living roadmap. Update checkboxes as features are completed. Each phase should be committed to git as a milestone.*
