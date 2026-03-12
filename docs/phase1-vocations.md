# Phase 1: Vocation System Overhaul

> **Scope**: Replace Paladin with Archer, rename promotions, rebalance stats, redistribute spells, remove wands/rods, add war hammer for mages
> **Files Analyzed**: `src/vocation.h`, `src/vocation.cpp`, `data/XML/vocations.xml`, `src/enums.h`, `src/const.h`

---

## 1. Current Architecture

### How Vocations Work in TFS 1.3

The vocation system is defined in two layers:

**C++ Engine** (`src/vocation.h`, `src/vocation.cpp`):
- `Vocation` class stores: name, description, stat gains per level (HP/mana/cap), regen rates, skill multipliers, formula multipliers (melee/dist/defense/armor), attack speed, base speed, soul, client ID
- `Vocations` class loads all vocations from `data/XML/vocations.xml` into a `std::map<uint16_t, Vocation>`
- Skills indexed 0-6: Fist(0), Club(1), Sword(2), Axe(3), Distance(4), Shield(5), Fishing(6)
- Skill progression uses formula: `skillBase[skill] * pow(skillMultiplier[skill], level - 11)`
- Mana progression: `1600 * pow(manaMultiplier, magLevel - 1)`
- Static base values: `skillBase[7] = {50, 50, 50, 50, 30, 100, 20}`

**XML Data** (`data/XML/vocations.xml`):
- 9 vocations defined: None(0), Sorcerer(1), Druid(2), Paladin(3), Knight(4), Master Sorcerer(5), Elder Druid(6), Royal Paladin(7), Elite Knight(8)
- `fromvoc` attribute links promotions to base vocations (e.g., Master Sorcerer fromvoc=1 -> Sorcerer)
- `clientid` maps to Tibia client vocation display: 1=Knight, 2=Paladin, 3=Sorcerer, 4=Druid

**Enum** (`src/enums.h` line 386-388):
```cpp
enum Vocation_t : uint16_t {
    VOCATION_NONE = 0
};
```
Only `VOCATION_NONE` is defined as a constant; all other vocation IDs are purely data-driven from XML.

### Current Vocation Stats Table

| ID | Name | clientid | HP/lvl | Mana/lvl | Cap/lvl | Mana Mult | Melee Skill Mult | Dist Skill Mult | Shield Mult |
|----|------|----------|--------|----------|---------|-----------|-------------------|-----------------|-------------|
| 0 | None | 0 | 5 | 5 | 10 | 4.0 | 1.5 | 2.0 | 1.5 |
| 1 | Sorcerer | 3 | 5 | 30 | 10 | 1.1 | 1.5 | 2.0 | 1.5 |
| 2 | Druid | 4 | 5 | 30 | 10 | 1.1 | 1.5(fist)/1.8(melee) | 1.8 | 1.5 |
| 3 | Paladin | 2 | 10 | 15 | 20 | 1.4 | 1.2 | 1.1 | 1.1 |
| 4 | Knight | 1 | 15 | 5 | 25 | 3.0 | 1.1 | 1.4 | 1.1 |
| 5 | Master Sorcerer | 3 | 5 | 30 | 10 | 1.1 | 1.5 | 2.0 | 1.5 |
| 6 | Elder Druid | 4 | 5 | 30 | 10 | 1.1 | 1.5 | 1.8 | 1.5 |
| 7 | Royal Paladin | 2 | 10 | 15 | 20 | 1.4 | 1.2 | 1.1 | 1.1 |
| 8 | Elite Knight | 1 | 15 | 5 | 25 | 3.0 | 1.1 | 1.4 | 1.1 |

---

## 2. Planned Changes

### 2.1 Vocation Renaming

| Old ID | Old Name | New Name | New Description | New Promotion Name |
|--------|----------|----------|-----------------|-------------------|
| 1 | Sorcerer | Mage | "a mage" | High Mage (ID 5) |
| 2 | Druid | Druid | "a druid" (no change) | Guardian Druid (ID 6) |
| 3 | Paladin | Archer | "an archer" | Royal Archer (ID 7) |
| 4 | Knight | Knight | "a knight" (no change) | Imperial Knight (ID 8) |
| 5 | Master Sorcerer | High Mage | "a high mage" | - |
| 6 | Elder Druid | Guardian Druid | "a guardian druid" | - |
| 7 | Royal Paladin | Royal Archer | "a royal archer" | - |
| 8 | Elite Knight | Imperial Knight | "an imperial knight" | - |

### 2.2 Stat Rebalancing (Medivia-Style)

**New Stat Table**:

| ID | Name | HP/lvl | Mana/lvl | Cap/lvl | Mana Mult | HP Regen Ticks | HP Regen Amt | Mana Regen Ticks | Mana Regen Amt |
|----|------|--------|----------|---------|-----------|----------------|--------------|------------------|----------------|
| 1 | Mage | 5 | 30 | 10 | 1.1 | 6 | 5 | 3 | 5 |
| 2 | Druid | 5 | 30 | 10 | 1.1 | 6 | 5 | 3 | 5 |
| 3 | Archer | 10 | 15 | 20 | 1.4 | 4 | 5 | 4 | 5 |
| 4 | Knight | 15 | 5 | 25 | 3.0 | 3 | 5 | 6 | 5 |
| 5 | High Mage | 5 | 30 | 10 | 1.1 | 4 | 10 | 2 | 10 |
| 6 | Guardian Druid | 5 | 30 | 10 | 1.1 | 4 | 10 | 2 | 10 |
| 7 | Royal Archer | 10 | 15 | 20 | 1.4 | 3 | 10 | 3 | 10 |
| 8 | Imperial Knight | 15 | 5 | 25 | 3.0 | 2 | 10 | 4 | 10 |

**New Skill Multiplier Table** (lower = trains faster):

| Vocation | Fist | Club | Sword | Axe | Distance | Shield | Fishing |
|----------|------|------|-------|-----|----------|--------|---------|
| Mage | 1.5 | 2.0 | 2.0 | 2.0 | 2.0 | 1.5 | 1.1 |
| Druid | 1.5 | 1.8 | 1.8 | 1.8 | 1.8 | 1.5 | 1.1 |
| Archer | 1.2 | 1.4 | 1.4 | 1.4 | 1.1 | 1.1 | 1.1 |
| Knight | 1.1 | 1.1 | 1.1 | 1.1 | 1.8 | 1.1 | 1.1 |
| High Mage | 1.5 | 2.0 | 2.0 | 2.0 | 2.0 | 1.5 | 1.1 |
| Guardian Druid | 1.5 | 1.8 | 1.8 | 1.8 | 1.8 | 1.5 | 1.1 |
| Royal Archer | 1.2 | 1.4 | 1.4 | 1.4 | 1.1 | 1.1 | 1.1 |
| Imperial Knight | 1.1 | 1.1 | 1.1 | 1.1 | 1.8 | 1.1 | 1.1 |

**Archer gets the best Distance skill multiplier (1.1)** to match Medivia's emphasis on bows/crossbows. Knights lose their distance penalty (set to 1.8 instead of 1.4) since they should not be effective with ranged weapons.

### 2.3 Formula Multiplier Changes

| Vocation | meleeDamage | distDamage | defense | armor |
|----------|-------------|------------|---------|-------|
| Mage | 1.0 | 1.0 | 1.0 | 1.0 |
| Druid | 1.0 | 1.0 | 1.0 | 1.0 |
| Archer | 1.0 | 1.2 | 1.0 | 1.0 |
| Knight | 1.2 | 1.0 | 1.2 | 1.2 |
| High Mage | 1.0 | 1.0 | 1.0 | 1.0 |
| Guardian Druid | 1.0 | 1.0 | 1.0 | 1.0 |
| Royal Archer | 1.0 | 1.3 | 1.0 | 1.0 |
| Imperial Knight | 1.3 | 1.0 | 1.3 | 1.3 |

Archer gets a distance damage bonus; Knight gets melee/defense/armor bonuses.

---

## 3. Files to Modify

### 3.1 `data/XML/vocations.xml` -- Primary Change

Replace the entire file with new vocation names, stats, and multipliers. This is the simplest change since the engine reads everything from XML.

**Starter XML (replace current file)**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<vocations>
    <vocation id="0" clientid="0" name="None" description="none" gaincap="10" gainhp="5" gainmana="5" gainhpticks="6" gainhpamount="1" gainmanaticks="6" gainmanaamount="1" manamultiplier="4.0" attackspeed="2000" basespeed="220" soulmax="100" gainsoulticks="120" fromvoc="0">
        <formula meleeDamage="1.0" distDamage="1.0" defense="1.0" armor="1.0" />
        <skill id="0" multiplier="1.5" />
        <skill id="1" multiplier="2.0" />
        <skill id="2" multiplier="2.0" />
        <skill id="3" multiplier="2.0" />
        <skill id="4" multiplier="2.0" />
        <skill id="5" multiplier="1.5" />
        <skill id="6" multiplier="1.1" />
    </vocation>
    <vocation id="1" clientid="3" name="Mage" description="a mage" gaincap="10" gainhp="5" gainmana="30" gainhpticks="6" gainhpamount="5" gainmanaticks="3" gainmanaamount="5" manamultiplier="1.1" attackspeed="2000" basespeed="220" soulmax="100" gainsoulticks="120" fromvoc="1">
        <formula meleeDamage="1.0" distDamage="1.0" defense="1.0" armor="1.0" />
        <skill id="0" multiplier="1.5" />
        <skill id="1" multiplier="2.0" />
        <skill id="2" multiplier="2.0" />
        <skill id="3" multiplier="2.0" />
        <skill id="4" multiplier="2.0" />
        <skill id="5" multiplier="1.5" />
        <skill id="6" multiplier="1.1" />
    </vocation>
    <vocation id="2" clientid="4" name="Druid" description="a druid" gaincap="10" gainhp="5" gainmana="30" gainhpticks="6" gainhpamount="5" gainmanaticks="3" gainmanaamount="5" manamultiplier="1.1" attackspeed="2000" basespeed="220" soulmax="100" gainsoulticks="120" fromvoc="2">
        <formula meleeDamage="1.0" distDamage="1.0" defense="1.0" armor="1.0" />
        <skill id="0" multiplier="1.5" />
        <skill id="1" multiplier="1.8" />
        <skill id="2" multiplier="1.8" />
        <skill id="3" multiplier="1.8" />
        <skill id="4" multiplier="1.8" />
        <skill id="5" multiplier="1.5" />
        <skill id="6" multiplier="1.1" />
    </vocation>
    <vocation id="3" clientid="2" name="Archer" description="an archer" gaincap="20" gainhp="10" gainmana="15" gainhpticks="4" gainhpamount="5" gainmanaticks="4" gainmanaamount="5" manamultiplier="1.4" attackspeed="2000" basespeed="220" soulmax="100" gainsoulticks="120" fromvoc="3">
        <formula meleeDamage="1.0" distDamage="1.2" defense="1.0" armor="1.0" />
        <skill id="0" multiplier="1.2" />
        <skill id="1" multiplier="1.4" />
        <skill id="2" multiplier="1.4" />
        <skill id="3" multiplier="1.4" />
        <skill id="4" multiplier="1.1" />
        <skill id="5" multiplier="1.1" />
        <skill id="6" multiplier="1.1" />
    </vocation>
    <vocation id="4" clientid="1" name="Knight" description="a knight" gaincap="25" gainhp="15" gainmana="5" gainhpticks="3" gainhpamount="5" gainmanaticks="6" gainmanaamount="5" manamultiplier="3.0" attackspeed="2000" basespeed="220" soulmax="100" gainsoulticks="120" fromvoc="4">
        <formula meleeDamage="1.2" distDamage="1.0" defense="1.2" armor="1.2" />
        <skill id="0" multiplier="1.1" />
        <skill id="1" multiplier="1.1" />
        <skill id="2" multiplier="1.1" />
        <skill id="3" multiplier="1.1" />
        <skill id="4" multiplier="1.8" />
        <skill id="5" multiplier="1.1" />
        <skill id="6" multiplier="1.1" />
    </vocation>
    <vocation id="5" clientid="3" name="High Mage" description="a high mage" gaincap="10" gainhp="5" gainmana="30" gainhpticks="4" gainhpamount="10" gainmanaticks="2" gainmanaamount="10" manamultiplier="1.1" attackspeed="2000" basespeed="220" soulmax="200" gainsoulticks="15" fromvoc="1">
        <formula meleeDamage="1.0" distDamage="1.0" defense="1.0" armor="1.0" />
        <skill id="0" multiplier="1.5" />
        <skill id="1" multiplier="2.0" />
        <skill id="2" multiplier="2.0" />
        <skill id="3" multiplier="2.0" />
        <skill id="4" multiplier="2.0" />
        <skill id="5" multiplier="1.5" />
        <skill id="6" multiplier="1.1" />
    </vocation>
    <vocation id="6" clientid="4" name="Guardian Druid" description="a guardian druid" gaincap="10" gainhp="5" gainmana="30" gainhpticks="4" gainhpamount="10" gainmanaticks="2" gainmanaamount="10" manamultiplier="1.1" attackspeed="2000" basespeed="220" soulmax="200" gainsoulticks="15" fromvoc="2">
        <formula meleeDamage="1.0" distDamage="1.0" defense="1.0" armor="1.0" />
        <skill id="0" multiplier="1.5" />
        <skill id="1" multiplier="1.8" />
        <skill id="2" multiplier="1.8" />
        <skill id="3" multiplier="1.8" />
        <skill id="4" multiplier="1.8" />
        <skill id="5" multiplier="1.5" />
        <skill id="6" multiplier="1.1" />
    </vocation>
    <vocation id="7" clientid="2" name="Royal Archer" description="a royal archer" gaincap="20" gainhp="10" gainmana="15" gainhpticks="3" gainhpamount="10" gainmanaticks="3" gainmanaamount="10" manamultiplier="1.4" attackspeed="2000" basespeed="220" soulmax="200" gainsoulticks="15" fromvoc="3">
        <formula meleeDamage="1.0" distDamage="1.3" defense="1.0" armor="1.0" />
        <skill id="0" multiplier="1.2" />
        <skill id="1" multiplier="1.4" />
        <skill id="2" multiplier="1.4" />
        <skill id="3" multiplier="1.4" />
        <skill id="4" multiplier="1.1" />
        <skill id="5" multiplier="1.1" />
        <skill id="6" multiplier="1.1" />
    </vocation>
    <vocation id="8" clientid="1" name="Imperial Knight" description="an imperial knight" gaincap="25" gainhp="15" gainmana="5" gainhpticks="2" gainhpamount="10" gainmanaticks="4" gainmanaamount="10" manamultiplier="3.0" attackspeed="2000" basespeed="220" soulmax="200" gainsoulticks="15" fromvoc="4">
        <formula meleeDamage="1.3" distDamage="1.0" defense="1.3" armor="1.3" />
        <skill id="0" multiplier="1.1" />
        <skill id="1" multiplier="1.1" />
        <skill id="2" multiplier="1.1" />
        <skill id="3" multiplier="1.1" />
        <skill id="4" multiplier="1.8" />
        <skill id="5" multiplier="1.1" />
        <skill id="6" multiplier="1.1" />
    </vocation>
</vocations>
```

### 3.2 Spell Redistribution

All spell files in `data/spells/` that reference vocation names by string must be updated. The spell XML and Lua files use vocation names in their `<vocation>` tags.

**Files to search and replace**:
- `data/spells/spells.xml` -- all `<vocation name="Paladin"` -> `<vocation name="Archer"`
- `data/spells/spells.xml` -- all `<vocation name="Royal Paladin"` -> `<vocation name="Royal Archer"`
- `data/spells/spells.xml` -- all `<vocation name="Master Sorcerer"` -> `<vocation name="High Mage"`
- `data/spells/spells.xml` -- all `<vocation name="Elite Knight"` -> `<vocation name="Imperial Knight"`
- `data/spells/spells.xml` -- all `<vocation name="Elder Druid"` -> `<vocation name="Guardian Druid"`
- `data/spells/spells.xml` -- all `<vocation name="Sorcerer"` -> `<vocation name="Mage"`

Individual spell Lua scripts may also check vocation names -- grep for "Paladin", "Sorcerer", "Master Sorcerer", "Elder Druid", "Elite Knight" in all `data/spells/scripts/`.

**Archer-Specific Spell Design** (new spells to create):
- Aimed Shot (instant, single target ranged attack)
- Multi Shot (distance area spell, fan shape)
- Evasion (temporary defense buff)
- Tracking (reveal invisible creatures)
- Precision (critical hit chance buff)

### 3.3 Removing Wands and Rods

Wands and rods use `WEAPON_WAND` type defined in `src/const.h` line 370.

**Strategy**: Do NOT remove the code for WEAPON_WAND from the engine (it would be a large refactor). Instead:

1. **Remove all wand/rod items from `data/items/items.xml`** -- Remove or comment out item entries with `weapontype="wand"`.
2. **Remove wand/rod weapon scripts** from `data/weapons/` (any Lua files for wands/rods).
3. **Remove wand/rod entries from NPC shop lists** (any NPC selling wands/rods).
4. **Remove wand/rod loot** from monster loot tables in `data/monsters/`.

Items to remove (standard Tibia wands and rods):
- Wand of Vortex (2190), Wand of Dragonbreath (2191), Wand of Plague (2188), etc.
- Snakebite Rod (2182), Moonlight Rod (2186), Necrotic Rod (2185), etc.

### 3.4 War Hammer for Low-Level Mages

**Concept**: Since wands/rods are removed, mages need a physical weapon for early levels before they have enough mana to rely on spells.

**Implementation**:
1. Add a "War Hammer" item to `data/items/items.xml` (reuse an existing hammer sprite, e.g., item ID for war hammer already exists as ID 2391).
2. Make it `weapontype="club"` with low attack (20-25 atk), usable by all vocations.
3. Optionally create a "Mage Staff" item with similar stats and magic damage bonus.
4. Add these to starter item scripts (`data/creaturescripts/scripts/firstitems.lua`) for Mage and Druid vocations.
5. Add to NPC shops in starter cities.

### 3.5 C++ Engine Changes (Minimal)

The C++ engine itself needs minimal changes since vocations are data-driven. However:

1. **`src/enums.h`**: Optionally add named constants for clarity:
```cpp
enum Vocation_t : uint16_t {
    VOCATION_NONE = 0,
    VOCATION_MAGE = 1,
    VOCATION_DRUID = 2,
    VOCATION_ARCHER = 3,
    VOCATION_KNIGHT = 4,
    VOCATION_HIGH_MAGE = 5,
    VOCATION_GUARDIAN_DRUID = 6,
    VOCATION_ROYAL_ARCHER = 7,
    VOCATION_IMPERIAL_KNIGHT = 8,
};
```

2. **Any hardcoded vocation checks**: Search the entire `src/` for references to specific vocation IDs or names:
   - `VOCATION_NONE` is used in `combat.cpp:isProtected()` -- this is fine, it stays as ID 0.
   - Check `luascript.cpp` for any hardcoded vocation name strings.

3. **Database migration**: Update any existing player records if needed (vocation names are stored by ID, not name, so the data is compatible).

---

## 4. Implementation Order

1. Edit `data/XML/vocations.xml` with new names and stats (immediate, zero-risk).
2. Search-and-replace vocation names in `data/spells/spells.xml`.
3. Grep all `data/` Lua scripts for old vocation names and update.
4. Remove wand/rod items from shops/loot/items.
5. Add war hammer to starter items for mage vocations.
6. Add Vocation_t enum constants in `src/enums.h` (optional but helpful).
7. Create Archer-specific spell scripts.
8. Test: create a character of each vocation and verify stat gains, spell access, and skill training rates.

---

## 5. Migration Considerations

- **Existing characters**: Players with vocation IDs 1-8 will automatically get new names since the engine reads names from XML at runtime. No database migration needed for the rename itself.
- **Spell access**: If spell XML references vocations by name (string matching via `Vocations::getVocationId()`), the names must match exactly after the rename.
- **Client display**: `clientid` values are unchanged (1=Knight, 2=Paladin/Archer, 3=Sorcerer/Mage, 4=Druid), so the Tibia client will still show the same vocation icon. The text name comes from the server.
