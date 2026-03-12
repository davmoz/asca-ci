# Phase 1: Skill System Extensions

> **Scope**: Add Cooking and Mining skills to the C++ engine, upgrade Fishing from basic action to full skill
> **Files Analyzed**: `src/player.h`, `src/enums.h`, `src/const.h`, `src/vocation.h`, `src/vocation.cpp`, `src/protocolgame.cpp`, `src/iologindata.cpp`, `schema.sql`

---

## 1. Current Skill Architecture

### How Skills Work in TFS 1.3

**Skill Enum** (`src/enums.h` lines 286-300):
```cpp
enum skills_t : uint8_t {
    SKILL_FIST = 0,
    SKILL_CLUB = 1,
    SKILL_SWORD = 2,
    SKILL_AXE = 3,
    SKILL_DISTANCE = 4,
    SKILL_SHIELD = 5,
    SKILL_FISHING = 6,

    SKILL_MAGLEVEL = 7,
    SKILL_LEVEL = 8,

    SKILL_FIRST = SKILL_FIST,
    SKILL_LAST = SKILL_FISHING   // <-- This controls array sizes everywhere
};
```

**Key Observation**: `SKILL_LAST = SKILL_FISHING = 6` is used to size arrays throughout the engine:
- `skillMultipliers[SKILL_LAST + 1]` in `src/vocation.h` line 103 (array of 7 elements)
- `cacheSkill[SKILL_LAST + 1]` in `src/vocation.h` line 98
- `skills[SKILL_LAST + 1]` in `src/player.h` line 1219
- `varSkills[SKILL_LAST + 1]` in `src/player.h` line 1277
- `skillBase[SKILL_LAST + 1]` in `src/vocation.cpp` line 182 (static: `{50, 50, 50, 50, 30, 100, 20}`)
- `Abilities::skills[SKILL_LAST + 1]` in `src/items.h` line 216

**Skill Struct** (`src/player.h` lines 101-105):
```cpp
struct Skill {
    uint64_t tries = 0;
    uint16_t level = 10;
    uint8_t percent = 0;
};
```

**Skill Progression Formula** (`src/vocation.cpp` line 195):
```cpp
uint64_t tries = skillBase[skill] * pow(skillMultipliers[skill], level - 11);
```

**Database Storage** (`schema.sql`):
Skills are stored as individual columns in the `players` table:
```sql
skill_fist INT UNSIGNED DEFAULT 10,
skill_fist_tries BIGINT UNSIGNED DEFAULT 0,
skill_club INT UNSIGNED DEFAULT 10,
skill_club_tries BIGINT UNSIGNED DEFAULT 0,
-- ... etc for each skill
skill_fishing INT UNSIGNED DEFAULT 10,
skill_fishing_tries BIGINT UNSIGNED DEFAULT 0,
```

**Database Load/Save** (`src/iologindata.cpp` lines 387-388):
```cpp
static const std::string skillNames[] = {"skill_fist", "skill_club", "skill_sword",
    "skill_axe", "skill_dist", "skill_shielding", "skill_fishing"};
static const std::string skillNameTries[] = {"skill_fist_tries", "skill_club_tries",
    "skill_sword_tries", "skill_axe_tries", "skill_dist_tries",
    "skill_shielding_tries", "skill_fishing_tries"};
```

**Protocol (Client Display)** (`src/protocolgame.cpp` lines 2924-2938):
```cpp
void ProtocolGame::AddPlayerSkills(NetworkMessage& msg) {
    msg.addByte(0xA1);
    for (uint8_t i = SKILL_FIRST; i <= SKILL_LAST; ++i) {
        msg.add<uint16_t>(player->getSkillLevel(i));
        msg.add<uint16_t>(player->getBaseSkill(i));
        msg.addByte(player->getSkillPercent(i));
    }
    for (uint8_t i = SPECIALSKILL_FIRST; i <= SPECIALSKILL_LAST; ++i) {
        msg.add<uint16_t>(std::min<int32_t>(100, player->varSpecialSkills[i]));
        msg.add<uint16_t>(0);
    }
}
```

---

## 2. Adding New Skills: Cooking and Mining

### 2.1 Enum Changes (`src/enums.h`)

**Current**:
```cpp
SKILL_FISHING = 6,
SKILL_LAST = SKILL_FISHING
```

**New**:
```cpp
enum skills_t : uint8_t {
    SKILL_FIST = 0,
    SKILL_CLUB = 1,
    SKILL_SWORD = 2,
    SKILL_AXE = 3,
    SKILL_DISTANCE = 4,
    SKILL_SHIELD = 5,
    SKILL_FISHING = 6,
    SKILL_COOKING = 7,
    SKILL_MINING = 8,

    SKILL_MAGLEVEL = 9,    // shifted from 7
    SKILL_LEVEL = 10,      // shifted from 8

    SKILL_FIRST = SKILL_FIST,
    SKILL_LAST = SKILL_MINING  // changed from SKILL_FISHING
};
```

**WARNING**: Changing `SKILL_MAGLEVEL` and `SKILL_LEVEL` values will break any code that uses these constants. Need to audit all references.

**Alternative (safer) approach**: Keep SKILL_MAGLEVEL and SKILL_LEVEL where they are, and define:
```cpp
enum skills_t : uint8_t {
    SKILL_FIST = 0,
    SKILL_CLUB = 1,
    SKILL_SWORD = 2,
    SKILL_AXE = 3,
    SKILL_DISTANCE = 4,
    SKILL_SHIELD = 5,
    SKILL_FISHING = 6,
    SKILL_COOKING = 7,
    SKILL_MINING = 8,

    SKILL_MAGLEVEL = 9,
    SKILL_LEVEL = 10,

    SKILL_FIRST = SKILL_FIST,
    SKILL_LAST = SKILL_MINING
};
```

Since `SKILL_MAGLEVEL` and `SKILL_LEVEL` are only used as sentinel values (they are not stored in the `skills[]` array -- magic level has its own separate storage via `magLevel`/`manaSpent`), shifting them is safe as long as all references are updated.

**Files referencing SKILL_MAGLEVEL or SKILL_LEVEL** (need grep & update):
- `src/luascript.cpp` -- Lua constant registration
- `src/player.cpp` -- offline training, skill advance
- `src/condition.cpp` -- condition parameter mapping
- `src/items.cpp` -- item attribute parsing
- `data/lib/core/constants.lua` -- Lua constants

### 2.2 Static Base Values (`src/vocation.cpp`)

**Current** (line 182):
```cpp
uint32_t Vocation::skillBase[SKILL_LAST + 1] = {50, 50, 50, 50, 30, 100, 20};
```

**New**:
```cpp
uint32_t Vocation::skillBase[SKILL_LAST + 1] = {50, 50, 50, 50, 30, 100, 20, 30, 30};
//                                               fist club swrd axe  dist shld fish cook mine
```

Cooking and Mining get base value 30 (moderate progression speed, between Distance's 30 and Fishing's 20).

### 2.3 Default Skill Multipliers (`src/vocation.h`)

**Current** (line 103):
```cpp
float skillMultipliers[SKILL_LAST + 1] = {1.5f, 2.0f, 2.0f, 2.0f, 2.0f, 1.5f, 1.1f};
```

**New**:
```cpp
float skillMultipliers[SKILL_LAST + 1] = {1.5f, 2.0f, 2.0f, 2.0f, 2.0f, 1.5f, 1.1f, 1.1f, 1.1f};
```

Cooking and Mining default to 1.1 (same as Fishing) -- all vocations train these at equal speed.

### 2.4 Vocations XML (`data/XML/vocations.xml`)

Add two more `<skill>` entries to each vocation:
```xml
<skill id="7" multiplier="1.1" />  <!-- Cooking -->
<skill id="8" multiplier="1.1" />  <!-- Mining -->
```

### 2.5 Player Skill Storage (`src/player.h`)

The `skills[SKILL_LAST + 1]` array (line 1219) and `varSkills[SKILL_LAST + 1]` (line 1277) will automatically expand when `SKILL_LAST` changes. No manual change needed beyond the enum.

### 2.6 Database Schema Changes

**New migration SQL** (create as `data/migrations/28.lua`):
```lua
function onUpdateDatabase()
    print("> Updating database to version 29 (adding cooking and mining skills)")
    db.query("ALTER TABLE `players` ADD `skill_cooking` INT UNSIGNED NOT NULL DEFAULT 10 AFTER `skill_fishing_tries`")
    db.query("ALTER TABLE `players` ADD `skill_cooking_tries` BIGINT UNSIGNED NOT NULL DEFAULT 0 AFTER `skill_cooking`")
    db.query("ALTER TABLE `players` ADD `skill_mining` INT UNSIGNED NOT NULL DEFAULT 10 AFTER `skill_cooking_tries`")
    db.query("ALTER TABLE `players` ADD `skill_mining_tries` BIGINT UNSIGNED NOT NULL DEFAULT 0 AFTER `skill_mining`")
    return true
end
```

**Also update `schema.sql`** to include the new columns for fresh installs:
```sql
  `skill_cooking` int unsigned NOT NULL DEFAULT 10,
  `skill_cooking_tries` bigint unsigned NOT NULL DEFAULT 0,
  `skill_mining` int unsigned NOT NULL DEFAULT 10,
  `skill_mining_tries` bigint unsigned NOT NULL DEFAULT 0,
```

### 2.7 Database Load/Save (`src/iologindata.cpp`)

**Update the skill name arrays** (line 387-388):
```cpp
static const std::string skillNames[] = {"skill_fist", "skill_club", "skill_sword",
    "skill_axe", "skill_dist", "skill_shielding", "skill_fishing",
    "skill_cooking", "skill_mining"};
static const std::string skillNameTries[] = {"skill_fist_tries", "skill_club_tries",
    "skill_sword_tries", "skill_axe_tries", "skill_dist_tries",
    "skill_shielding_tries", "skill_fishing_tries",
    "skill_cooking_tries", "skill_mining_tries"};
```

**Update the SELECT query** (around line 239) to include `skill_cooking`, `skill_cooking_tries`, `skill_mining`, `skill_mining_tries`.

**Update the save query** (around line 757) to include:
```cpp
query << "`skill_cooking` = " << player->skills[SKILL_COOKING].level << ',';
query << "`skill_cooking_tries` = " << player->skills[SKILL_COOKING].tries << ',';
query << "`skill_mining` = " << player->skills[SKILL_MINING].level << ',';
query << "`skill_mining_tries` = " << player->skills[SKILL_MINING].tries << ',';
```

### 2.8 Protocol Changes (`src/protocolgame.cpp`)

**Problem**: The Tibia 10.98 client expects exactly 7 skills (Fist through Fishing) in the skills packet. Sending 9 skills would break the packet parsing.

**Solutions**:

**Option A: OTClient Required (Recommended)**
If using OTClient (which we should for custom features), modify the OTClient code to expect 9 skills instead of 7. The server-side `AddPlayerSkills` will naturally send 9 skills since it iterates `SKILL_FIRST` to `SKILL_LAST`.

**Option B: Separate Packet for Custom Skills**
Keep the standard skill packet as-is (7 skills), and send Cooking/Mining via a custom packet or through the "special skills" mechanism. Store them in the `varSpecialSkills` array or use a custom message type.

**Option C: Use Player Storage Values**
Don't send via the skills protocol at all. Instead, use storage values displayed via a custom UI window in OTClient. This avoids C++ protocol changes but makes the skills second-class.

**Recommended approach**: Option A. We will need OTClient anyway for other custom features (crafting UI, task UI, etc.).

**Server-side change** (already works if SKILL_LAST is updated):
```cpp
void ProtocolGame::AddPlayerSkills(NetworkMessage& msg) {
    msg.addByte(0xA1);
    for (uint8_t i = SKILL_FIRST; i <= SKILL_LAST; ++i) {  // Now iterates 0-8
        msg.add<uint16_t>(player->getSkillLevel(i));
        msg.add<uint16_t>(player->getBaseSkill(i));
        msg.addByte(player->getSkillPercent(i));
    }
    // ... special skills unchanged
}
```

**OTClient-side change** (in the client's skills module):
Add skill entries for Cooking (id 7) and Mining (id 8) to the skills panel with appropriate icons and names.

### 2.9 Lua Script Interface (`src/luascript.cpp`)

Register the new skill constants:
```cpp
registerEnum(SKILL_COOKING)
registerEnum(SKILL_MINING)
```

Update any Lua library files that define skill constants:
```lua
-- data/lib/core/constants.lua (or equivalent)
SKILL_COOKING = 7
SKILL_MINING = 8
```

### 2.10 Condition Parameters (`src/enums.h`)

Add condition parameters for the new skills so items/conditions can modify them:
```cpp
CONDITION_PARAM_SKILL_COOKING = 55,     // new
CONDITION_PARAM_SKILL_COOKINGPERCENT = 56,  // new
CONDITION_PARAM_SKILL_MINING = 57,      // new
CONDITION_PARAM_SKILL_MININGPERCENT = 58,   // new
```

Update `src/condition.cpp` to handle these new parameters.

### 2.11 Item Attributes for New Skills (`src/items.h`)

Add parse entries so items can grant cooking/mining skill bonuses:
```cpp
ITEM_PARSE_SKILLCOOKING,
ITEM_PARSE_SKILLMINING,
```

Update `src/items.cpp` `parseItemNode()` to handle `"skillcooking"` and `"skillmining"` XML attributes.

---

## 3. Upgrading Fishing

### Current Fishing Implementation

Fishing in TFS 1.3 is already a skill (`SKILL_FISHING = 6`) with:
- Proper skill progression via `addSkillAdvance(SKILL_FISHING, tries)`
- Database storage (`skill_fishing`, `skill_fishing_tries`)
- Client display (7th skill in skills panel)
- Vocation multipliers in `vocations.xml`

What fishing lacks compared to Medivia:
- Only catches generic "fish" item
- No fish species variety
- No location-based catches
- No fishing rod tiers
- No fish pool objects
- No time-of-day modifiers

### Fishing Upgrade Plan

The fishing upgrade is primarily a **Lua scripting** task, not a C++ engine change. The skill infrastructure already exists.

**1. Create fish species items** in `data/items/items.xml`:
- Common: Trout, Bass, Cod, Herring
- Uncommon: Salmon, Tuna, Swordfish
- Rare: Golden Fish, Crystal Perch, Deep Sea Eel
- Legendary: Ancient Leviathan Scale, Prismatic Koi

**2. Create fish pool map objects**: Special water tiles with action IDs that determine available species.

**3. Implement tiered fishing rods** in `data/items/items.xml`:
- Basic Fishing Rod (existing item 2580) -- catches common fish
- Improved Fishing Rod -- catches common + uncommon
- Expert Fishing Rod -- catches all species
- Each rod can have different `actionid` values used in the fishing Lua script

**4. Rewrite fishing action** (`data/actions/scripts/tools/fishing.lua`):
```lua
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local fishingSkill = player:getSkillLevel(SKILL_FISHING)
    local rodTier = getRodTier(item:getId())
    local locationPool = getLocationPool(toPosition)
    local timeModifier = getTimeModifier()

    -- Calculate catch based on skill, rod, location, time
    local catchTable = buildCatchTable(fishingSkill, rodTier, locationPool, timeModifier)
    local caughtFish = rollCatch(catchTable)

    if caughtFish then
        player:addItem(caughtFish.itemId, 1)
        player:addSkillTries(SKILL_FISHING, caughtFish.skillTries)
        -- visual/sound effects
    else
        player:addSkillTries(SKILL_FISHING, 1)
        -- "You didn't catch anything" message
    end
    return true
end
```

---

## 4. Complete File Change List

### C++ Source Files (must recompile):

| File | Change |
|------|--------|
| `src/enums.h` | Add `SKILL_COOKING=7`, `SKILL_MINING=8`, shift `SKILL_MAGLEVEL` to 9, `SKILL_LEVEL` to 10, update `SKILL_LAST` |
| `src/vocation.h` | Update default `skillMultipliers` array initializer to 9 elements |
| `src/vocation.cpp` | Update `skillBase[]` array to 9 elements |
| `src/iologindata.cpp` | Update `skillNames[]`, `skillNameTries[]` arrays; update SELECT/INSERT/UPDATE queries |
| `src/luascript.cpp` | Register `SKILL_COOKING`, `SKILL_MINING` enums; update `SKILL_MAGLEVEL`, `SKILL_LEVEL` values |
| `src/condition.cpp` | Add handling for `CONDITION_PARAM_SKILL_COOKING`, `CONDITION_PARAM_SKILL_MINING` and percent variants |
| `src/items.cpp` | Add `ITEM_PARSE_SKILLCOOKING`, `ITEM_PARSE_SKILLMINING` parsing |
| `src/items.h` | Add parse enum entries |
| `src/player.cpp` | Audit any hardcoded skill ID references; add offline training support for new skills |

### Data Files:

| File | Change |
|------|--------|
| `data/XML/vocations.xml` | Add `<skill id="7">` and `<skill id="8">` to all vocations |
| `data/lib/core/constants.lua` | Add `SKILL_COOKING = 7`, `SKILL_MINING = 8` |
| `schema.sql` | Add `skill_cooking`, `skill_cooking_tries`, `skill_mining`, `skill_mining_tries` columns |
| `data/migrations/28.lua` | Database migration to add new columns |

### OTClient Files (if using custom client):

| File | Change |
|------|--------|
| Skills module | Add Cooking (7) and Mining (8) to the skills panel display |
| Protocol parser | Update expected skill count from 7 to 9 |

---

## 5. Testing Plan

1. **Compile test**: Build the server with all enum/array changes; fix any compilation errors from shifted constants.
2. **Database test**: Run migration, verify new columns exist with default values.
3. **Login test**: Create a new character, verify all 9 skills display correctly (via OTClient or debug output).
4. **Skill advance test**: Call `player:addSkillTries(SKILL_COOKING, 1000)` from a talkaction to verify progression.
5. **Save/load test**: Log out and back in; verify Cooking and Mining levels persist.
6. **Vocation multiplier test**: Verify different vocations train new skills at correct rates.
7. **Fishing upgrade test**: Test the enhanced fishing script with different rod tiers and locations.

---

## 6. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Shifting SKILL_MAGLEVEL breaks hardcoded references | HIGH | Grep entire src/ for `SKILL_MAGLEVEL` and `SKILL_LEVEL`; update all references |
| Client packet mismatch (9 skills vs expected 7) | HIGH | Requires OTClient; cannot use standard Tibia client |
| Array bounds overflow from SKILL_LAST change | MEDIUM | All arrays use `SKILL_LAST + 1` sizing; verify with compiler |
| Lua scripts using old skill IDs | LOW | Update `constants.lua` and grep data/ for hardcoded skill numbers |
| Database migration failure on existing data | LOW | Migration only adds columns with defaults; no data modification |
