# Phase 1: Retro PvP Mechanics

> **Scope**: Disable rune hotkeys, implement rope hole blocking, adjust PvP damage formulas, custom skull system, guild war auto-accept
> **Files Analyzed**: `src/combat.h`, `src/combat.cpp`, `src/game.h`, `src/game.cpp`, `src/actions.h`, `src/actions.cpp`, `src/player.h`, `src/player.cpp`, `src/const.h`, `src/protocolgame.cpp`

---

## 1. Current PvP Architecture

### 1.1 Combat System Overview

**Combat flow** (`src/combat.cpp`):
1. `Combat::canDoCombat(attacker, target)` -- checks if attack is allowed
2. `Combat::isProtected(attacker, target)` -- protection level check, vocation check, skull check
3. `Combat::doTargetCombat()` or `Combat::doAreaCombat()` -- applies damage
4. Damage goes through `Player::blockHit()` for defense/armor checks
5. `Player::onAttackedCreature()` triggers skull/frag logic

**Protection system** (`src/combat.cpp` lines 269-285):
```cpp
bool Combat::isProtected(const Player* attacker, const Player* target) {
    uint32_t protectionLevel = g_config.getNumber(ConfigManager::PROTECTION_LEVEL);
    if (target->getLevel() < protectionLevel || attacker->getLevel() < protectionLevel) {
        return true;
    }
    if (attacker->getVocationId() == VOCATION_NONE || target->getVocationId() == VOCATION_NONE) {
        return true;
    }
    if (attacker->getSkull() == SKULL_BLACK && attacker->getSkullClient(target) == SKULL_NONE) {
        return true;
    }
    return false;
}
```

**Skull system** (`src/const.h` lines 400-408):
```cpp
enum Skulls_t : uint8_t {
    SKULL_NONE = 0,
    SKULL_YELLOW = 1,
    SKULL_GREEN = 2,
    SKULL_WHITE = 3,
    SKULL_RED = 4,
    SKULL_BLACK = 5,
    SKULL_ORANGE = 6,
};
```

**Skull logic** (`src/player.cpp`):
- `addUnjustifiedDead()` (line ~3863) increments `skullTicks` by `FRAG_TIME`
- If `skullTicks > (KILLS_TO_BLACK - 1) * FRAG_TIME` -> SKULL_BLACK
- If `skullTicks > (KILLS_TO_RED - 1) * FRAG_TIME` -> SKULL_RED
- `checkSkullTicks()` decrements over time, removes skull when ticks reach 0

**Hotkey system** (`src/actions.cpp`):
- `Actions::useItem()` (line 417) receives `isHotkey` parameter
- `Actions::useItemEx()` (line 436) receives `isHotkey` parameter
- When `isHotkey` is true, `showUseHotkeyMessage()` is called (line 422, 453)
- The `isHotkey` flag is passed all the way to the Lua `onUse` callback as the 6th argument

---

## 2. Planned Changes

### 2.1 Disabling Rune Hotkeys

**Goal**: Players must manually drag-and-target runes, not use them via hotkeys. This is the signature Retro PvP mechanic.

**Where hotkey usage is handled** (`src/game.cpp`):
The game receives `playerUseWithCreature()` calls from the client protocol. The `isHotkey` flag is set by the protocol parser based on how the client sent the use request.

**Implementation Strategy**:

**Option A: Block at the Action Level (Recommended)**
In `src/actions.cpp`, modify `useItem()` and `useItemEx()` to block hotkey usage for rune items:

```cpp
// In Actions::useItem() and Actions::useItemEx(), after line that checks isHotkey:
bool Actions::useItemEx(Player* player, const Position& fromPos, const Position& toPos,
    uint8_t toStackPos, Item* item, bool isHotkey, Creature* creature)
{
    // NEW: Block rune hotkey usage for Retro PvP
    if (isHotkey && item->getWeaponType() == WEAPON_NONE) {
        const ItemType& itemType = Item::items[item->getID()];
        if (itemType.isRune()) {
            player->sendCancelMessage("You cannot use runes with hotkeys.");
            return false;
        }
    }
    // ... rest of existing code
}
```

**Option B: Block at the Protocol Level**
In `src/protocolgame.cpp`, when parsing the "use item with creature" packet, detect if the item is a rune and the usage came from a hotkey slot. Set `isHotkey = false` or block entirely.

**Option C: Configurable via config.lua**
Add a config option `retroPvpNoRuneHotkeys = true` so this can be toggled:

```cpp
// src/configmanager.h - add:
RETRO_PVP_NO_RUNE_HOTKEYS,

// src/configmanager.cpp - register:
boolean[RETRO_PVP_NO_RUNE_HOTKEYS] = getGlobalBoolean(L, "retroPvpNoRuneHotkeys", false);
```

Then in `actions.cpp`:
```cpp
if (isHotkey && g_config.getBoolean(ConfigManager::RETRO_PVP_NO_RUNE_HOTKEYS)) {
    const ItemType& itemType = Item::items[item->getID()];
    if (itemType.isRune()) {
        player->sendCancelMessage("You cannot use runes with hotkeys.");
        return false;
    }
}
```

**Files to modify**:
| File | Change |
|------|--------|
| `src/actions.cpp` | Add rune hotkey block in `useItemEx()` |
| `src/configmanager.h` | Add `RETRO_PVP_NO_RUNE_HOTKEYS` enum |
| `src/configmanager.cpp` | Register config option |
| `config.lua` | Add `retroPvpNoRuneHotkeys = true` |

### 2.2 Rope Hole Blocking

**Goal**: Players standing on a rope hole tile block other players from roping up through it. This creates strategic PvP chokepoints.

**How rope currently works**:
Rope is an action item (item ID 2120). When used on a tile with a rope hole (specific item IDs or action IDs), the player on the tile below is teleported up. The rope action script is in `data/actions/scripts/tools/rope.lua` or similar.

**Implementation**:

The blocking check should be added either in the rope action Lua script or in the C++ `Game::playerUseWithCreature` / movement code.

**Lua-side implementation** (simpler, recommended):
```lua
-- In the rope action script
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local ropePos = toPosition
    -- Check the tile above the rope hole for blocking creatures
    local upPos = Position(ropePos.x, ropePos.y, ropePos.z - 1)
    local upTile = Tile(upPos)

    if upTile then
        local creatures = upTile:getCreatures()
        for _, creature in ipairs(creatures) do
            if creature:isPlayer() and creature:getId() ~= player:getId() then
                player:sendCancelMessage("Someone is blocking the rope hole.")
                return false
            end
        end
    end

    -- Normal rope logic continues
    -- ...
end
```

**C++ side implementation** (if you want it built into the engine):
In `src/game.cpp`, in the function that handles tile movement via rope, add a check:
```cpp
// Pseudocode - in the rope/ladder movement handler
Tile* destTile = map.getTile(destPos);
if (destTile) {
    for (Creature* creature : destTile->getCreatures()) {
        if (creature->getPlayer() && creature->getPlayer() != player) {
            player->sendCancelMessage("Someone is blocking the rope hole.");
            return;
        }
    }
}
```

**Files to modify**:
| File | Change |
|------|--------|
| `data/actions/scripts/tools/rope.lua` | Add creature blocking check |
| Optionally `src/game.cpp` | Engine-level rope blocking |

### 2.3 PvP Damage Formula Adjustments

**Goal**: Modify PvP damage so fights are longer and more tactical (Medivia-style).

**Current damage flow** (`src/combat.cpp`):
- `doTargetCombat()` calls into `Creature::blockHit()` for defense
- `Player::blockHit()` applies shield blocking and armor reduction
- No specific PvP damage multiplier exists

**Implementation**: Add a PvP damage reduction factor.

**Config options** (`config.lua`):
```lua
pvpDamageReductionPercent = 50   -- PvP damage is reduced by 50%
pvpMagicDamageReductionPercent = 40  -- Magic PvP damage reduced by 40%
pvpPhysicalDamageReductionPercent = 50  -- Physical PvP reduced by 50%
```

**C++ implementation** (`src/combat.cpp`):

In `Combat::doTargetCombat()` (around line where damage is applied), add PvP reduction:

```cpp
void Combat::doTargetCombat(Creature* caster, Creature* target,
    CombatDamage& damage, const CombatParams& params)
{
    // ... existing code ...

    // NEW: PvP damage reduction
    if (caster && caster->getPlayer() && target->getPlayer()) {
        if (damage.primary.value < 0) {  // negative = damage
            double pvpReduction;
            if (damage.primary.type == COMBAT_PHYSICALDAMAGE) {
                pvpReduction = 1.0 - (g_config.getNumber(
                    ConfigManager::PVP_PHYSICAL_DAMAGE_REDUCTION) / 100.0);
            } else {
                pvpReduction = 1.0 - (g_config.getNumber(
                    ConfigManager::PVP_MAGIC_DAMAGE_REDUCTION) / 100.0);
            }
            damage.primary.value = static_cast<int32_t>(damage.primary.value * pvpReduction);
        }
        if (damage.secondary.value < 0) {
            double pvpReduction = 1.0 - (g_config.getNumber(
                ConfigManager::PVP_MAGIC_DAMAGE_REDUCTION) / 100.0);
            damage.secondary.value = static_cast<int32_t>(
                damage.secondary.value * pvpReduction);
        }
    }

    // ... rest of existing code ...
}
```

**Files to modify**:
| File | Change |
|------|--------|
| `src/combat.cpp` | Add PvP damage reduction in `doTargetCombat()` |
| `src/configmanager.h` | Add `PVP_PHYSICAL_DAMAGE_REDUCTION`, `PVP_MAGIC_DAMAGE_REDUCTION` |
| `src/configmanager.cpp` | Register config values |
| `config.lua` | Add PvP damage reduction settings |

### 2.4 Custom Skull System

**Goal**: Enhance the skull system for a more Medivia-like PvP experience.

**Current skull system** (`src/player.cpp`):
- Kill an unmarked player -> gain frag, increment `skullTicks`
- Configurable via `KILLS_TO_RED` and `KILLS_TO_BLACK` in config
- `FRAG_TIME` determines how long each frag counts
- Skull displayed via `Skulls_t` enum sent to client

**Planned enhancements**:

**a) Frag-based skull escalation with configurable thresholds**:
```lua
-- config.lua
fragTime = 24 * 60 * 60 * 1000  -- 24 hours per frag
killsToYellowSkull = 1           -- 1 unjustified kill = yellow skull
killsToRedSkull = 3              -- 3 unjustified kills = red skull
killsToBlackSkull = 6            -- 6 unjustified kills = black skull
yellowSkullDuration = 15 * 60 * 1000   -- 15 minutes
```

**b) White skull on attack** (already exists in TFS):
When you attack an unmarked player, you get a white skull. This is already handled by the infight/pzlock system.

**c) Orange skull for guild war participants** (already exists):
Players in active guild wars see each other with orange skulls.

**d) Custom: PvP death penalties scaling with skull**:
```cpp
// In player.cpp death() function:
double Player::getLostPercent() const {
    // Custom: skull-based death penalty
    Skulls_t skull = getSkull();
    switch (skull) {
        case SKULL_BLACK:
            return 0.15;  // 15% XP loss
        case SKULL_RED:
            return 0.12;  // 12% XP loss
        default:
            if (hasBlessing(1) && hasBlessing(2) && hasBlessing(3) &&
                hasBlessing(4) && hasBlessing(5)) {
                return 0.01;  // 1% with all blessings
            }
            return 0.10;  // 10% default
    }
}
```

**e) Skull display customization**:
No engine change needed for the skull types since `Skulls_t` already defines all the skull colors the client supports.

**Files to modify**:
| File | Change |
|------|--------|
| `src/player.cpp` | Custom death penalty based on skull; configurable yellow skull |
| `src/configmanager.h` | Add `KILLS_TO_YELLOW` and `YELLOW_SKULL_DURATION` |
| `src/configmanager.cpp` | Register new config values |
| `config.lua` | Add skull configuration |

### 2.5 Guild War Auto-Accept

**Goal**: When a guild has a pending war invitation and a member of that guild kills a member of the inviting guild, the war is automatically accepted.

**Current guild war system**:
- Wars are tracked in the database (`guild_wars` table)
- `Player::isInWar()` and `Player::isInWarList()` check war status
- Guild wars must be manually accepted via NPC or command

**Implementation**:

In `src/player.cpp`, in the `onKilledCreature()` function, add auto-accept logic:

```cpp
bool Player::onKilledCreature(Creature* target, bool lastHit) {
    // ... existing code ...

    Player* targetPlayer = target->getPlayer();
    if (targetPlayer && guild && targetPlayer->getGuild()) {
        // Check for pending war invitation between these guilds
        // If our guild has a pending war invite FROM the target's guild,
        // auto-accept it
        autoAcceptGuildWar(targetPlayer->getGuild());
    }

    // ... rest of existing code ...
}

void Player::autoAcceptGuildWar(Guild* enemyGuild) {
    if (!guild || !enemyGuild) return;

    // Query database for pending war:
    // SELECT id FROM guild_wars WHERE
    //   ((guild1 = our_guild AND guild2 = enemy_guild) OR
    //    (guild1 = enemy_guild AND guild2 = our_guild))
    //   AND status = 0  (pending)

    // If found, update status to 1 (active)
    // Notify both guilds via channel message

    Database& db = Database::getInstance();
    std::ostringstream query;
    query << "UPDATE `guild_wars` SET `status` = 1 WHERE `status` = 0 AND "
          << "((guild1 = " << guild->getId() << " AND guild2 = " << enemyGuild->getId() << ") OR "
          << "(guild1 = " << enemyGuild->getId() << " AND guild2 = " << guild->getId() << "))";

    if (db.executeQuery(query.str())) {
        // Notify guilds
        guild->broadcastMessage("War with " + enemyGuild->getName() +
            " has been auto-accepted due to PvP engagement!");
        enemyGuild->broadcastMessage("War with " + guild->getName() +
            " has been auto-accepted due to PvP engagement!");
    }
}
```

**Files to modify**:
| File | Change |
|------|--------|
| `src/player.cpp` | Add `autoAcceptGuildWar()` method; call from `onKilledCreature()` |
| `src/player.h` | Declare `autoAcceptGuildWar()` method |
| `src/guild.h` | Add `broadcastMessage()` if not present |
| `src/guild.cpp` | Implement `broadcastMessage()` |

---

## 3. Complete File Change Summary

| File | Changes |
|------|---------|
| `src/actions.cpp` | Block rune hotkey usage (lines ~422, ~453) |
| `src/combat.cpp` | PvP damage reduction in `doTargetCombat()` |
| `src/player.cpp` | Custom skull penalties in `getLostPercent()`; guild war auto-accept in `onKilledCreature()` |
| `src/player.h` | Declare `autoAcceptGuildWar()` |
| `src/guild.h` | Declare `broadcastMessage()` |
| `src/guild.cpp` | Implement `broadcastMessage()` |
| `src/configmanager.h` | Add enums: `RETRO_PVP_NO_RUNE_HOTKEYS`, `PVP_PHYSICAL_DAMAGE_REDUCTION`, `PVP_MAGIC_DAMAGE_REDUCTION`, `KILLS_TO_YELLOW`, `YELLOW_SKULL_DURATION` |
| `src/configmanager.cpp` | Register all new config values |
| `config.lua` | Add all new config options |
| `data/actions/scripts/tools/rope.lua` | Add rope hole blocking check |

---

## 4. Configuration Reference

```lua
-- config.lua additions for Retro PvP

-- Rune hotkeys
retroPvpNoRuneHotkeys = true

-- PvP damage reduction (percentage)
pvpPhysicalDamageReduction = 50
pvpMagicDamageReduction = 40

-- Skull system
fragTime = 86400000              -- 24 hours in ms
killsToYellowSkull = 1
killsToRedSkull = 3
killsToBlackSkull = 6

-- Guild war
guildWarAutoAccept = true
```

---

## 5. Implementation Order

1. **Rune hotkey blocking** -- highest impact, single file change in `actions.cpp`
2. **Rope hole blocking** -- Lua-only change, easy to test
3. **PvP damage reduction** -- config-driven, adjustable without recompile
4. **Skull system enhancements** -- builds on existing system
5. **Guild war auto-accept** -- requires database interaction, test carefully

---

## 6. Testing Plan

1. **Rune hotkeys**: Assign a rune to a hotkey slot; verify it says "You cannot use runes with hotkeys." when pressed. Verify manual drag-and-target still works.
2. **Rope blocking**: Stand a character on a rope hole tile; try to rope up with a second character; verify it is blocked. Remove the blocker; verify rope works.
3. **PvP damage**: Attack another player with known damage spell; compare damage with and without PvP reduction config.
4. **Skulls**: Kill an unmarked player; verify yellow skull appears. Kill 3; verify red skull. Verify death penalty scales.
5. **Guild war**: Create two guilds, send war invitation, have a member kill an enemy guild member; verify war auto-activates.
