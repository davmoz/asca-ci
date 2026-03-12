# Phase 3: Item System Overhaul

> **Scope**: Random attribute system, item rank progression, legendary item framework, properties system (STR/DEX/INT), combat integration
> **Files Analyzed**: `src/item.h`, `src/item.cpp`, `src/items.h`, `src/enums.h`, `src/combat.h`, `src/combat.cpp`, `src/player.h`

---

## 1. Current Item Architecture

### 1.1 Item Data Model

**ItemType** (`src/items.h`): Static item template loaded from `items.xml`. Contains base stats shared by all instances of the same item (attack, defense, armor, weight, etc.).

**Item** (`src/item.h`): Runtime item instance. Inherits base stats from `ItemType` but can override them via the `ItemAttributes` system.

**ItemAttributes** (`src/item.h` lines 117-525): Per-instance attribute storage using a vector of typed `Attribute` structs. Supports:
- **Integer attributes**: attack, defense, extraDefense, armor, hitChance, shootRange, weight, charges, duration, etc.
- **String attributes**: name, description, article, pluralName, text, writer
- **Custom attributes**: `CustomAttribute` using `boost::variant<blank, string, int64_t, double, bool>` -- stored in an `unordered_map<string, CustomAttribute>`

**Key existing attribute bit flags** (`src/enums.h` lines 66-97):
```cpp
ITEM_ATTRIBUTE_ATTACK = 1 << 10,
ITEM_ATTRIBUTE_DEFENSE = 1 << 11,
ITEM_ATTRIBUTE_EXTRADEFENSE = 1 << 12,
ITEM_ATTRIBUTE_ARMOR = 1 << 13,
ITEM_ATTRIBUTE_HITCHANCE = 1 << 14,
ITEM_ATTRIBUTE_CUSTOM = 1U << 31
```

**Custom attributes on items** (`src/item.h` lines 626-661):
```cpp
void setCustomAttribute(std::string& key, R value);
const CustomAttribute* getCustomAttribute(const std::string& key);
bool removeCustomAttribute(const std::string& key);
```

Custom attributes are serialized to disk via `ATTR_CUSTOM_ATTRIBUTES = 34` in the item save format, meaning they persist through server restarts.

**Items already have per-instance stat overrides**:
```cpp
int32_t getAttack() const {
    if (hasAttribute(ITEM_ATTRIBUTE_ATTACK)) {
        return getIntAttr(ITEM_ATTRIBUTE_ATTACK);  // per-instance override
    }
    return items[id].attack;  // base from ItemType
}
```

### 1.2 Existing Custom Properties in ItemType

The codebase already has some custom properties added (found in `src/items.h` lines 362-391):
```cpp
uint32_t grade = 0;
uint32_t attackModPassive = 0;
uint32_t healModPassive = 0;
uint32_t armPenPercents = 0;
uint32_t critPassive = 0;
uint32_t defenseModPassive = 0;
uint32_t attackSpeedBonus = 0;
uint32_t dodgePassive = 0;
uint32_t reflectpercentmagic = 0;
uint32_t reflectpercentphysical = 0;
// ... more
```

These are already parsed from `items.xml` but may not be fully integrated into combat calculations.

### 1.3 Combat Damage Flow

**Damage calculation** (`src/combat.cpp`):
1. `Combat::getCombatDamage()` -- calculates raw damage from formulas
2. `Combat::doTargetCombat()` -- applies damage to target, triggers `blockHit()`
3. `Player::blockHit()` -- applies shield/armor reduction
4. `Player::getArmor()` -- reads armor from equipment
5. `Player::getDefense()` -- reads defense from shield/weapon
6. Melee attack values come from `Player::getWeaponSkill()` and item attack stats

---

## 2. Random Attribute System

### 2.1 Design

When a monster drops equipment, the item may receive 0-3 random attributes from a pool. The attribute count and quality depend on:
- Monster difficulty level
- Item base quality
- Random chance

### 2.2 Attribute Types

| Attribute ID | Name | Display | Effect | Applies To |
|-------------|------|---------|--------|------------|
| attr_attack | Attack | Attack +X | Flat attack bonus | Weapons |
| attr_defense | Defense | Defense +X | Flat defense bonus | Shields, Armor |
| attr_armor | Armor | Armor +X | Flat armor bonus | Armor, Helmets, Legs, Boots |
| attr_critical | Critical Hit | Critical +X% | Crit chance | Weapons |
| attr_critdmg | Critical Damage | Crit Dmg +X% | Crit damage multiplier | Weapons |
| attr_berserk | Berserk | Berserk +X% | +damage when <50% HP | Weapons |
| attr_gauge | Gauge | Gauge +X% | +damage at full HP | Weapons |
| attr_crushing | Crushing Blow | Crushing +X% | Chance to deal double damage | Club weapons |
| attr_dazing | Dazing Blow | Dazing +X% | Chance to slow target | Sword weapons |
| attr_lean | Lean | Speed +X | Movement speed bonus | Boots |
| attr_fortitude | Fortitude | HP +X | Max HP bonus | Armor, Helmets |
| attr_wisdom | Wisdom | Mana +X | Max mana bonus | Armor, Helmets |
| attr_lifesteal | Life Steal | Life Steal +X% | Heal on hit percentage | Weapons |
| attr_manasteal | Mana Steal | Mana Steal +X% | Mana on hit percentage | Weapons |
| attr_resist_fire | Fire Resist | Fire Resist +X% | Fire damage reduction | Armor |
| attr_resist_ice | Ice Resist | Ice Resist +X% | Ice damage reduction | Armor |
| attr_resist_energy | Energy Resist | Energy Resist +X% | Energy damage reduction | Armor |
| attr_resist_earth | Earth Resist | Earth Resist +X% | Earth damage reduction | Armor |

### 2.3 Storage Architecture

Use the existing `CustomAttribute` system on `Item`. Each random attribute is stored as a custom attribute with a prefixed key:

```
Key format: "rattr_<attribute_id>"
Value: int64_t (the bonus value)
```

Example: A sword with Attack +3 and Critical +2%:
```cpp
item->setCustomAttribute("rattr_attack", 3);
item->setCustomAttribute("rattr_critical", 2);
```

These automatically serialize to disk via the existing `ATTR_CUSTOM_ATTRIBUTES` serialization.

### 2.4 Attribute Generation on Loot Drop

**Lua implementation** (`data/lib/itemattributes.lua`):

```lua
ItemAttributes = {}

-- Attribute definitions
ItemAttributes.pool = {
    weapons = {
        {id = "attack", name = "Attack", min = 1, max = 5, weight = 30},
        {id = "critical", name = "Critical Hit", min = 1, max = 5, weight = 20},
        {id = "critdmg", name = "Critical Damage", min = 5, max = 25, weight = 15},
        {id = "berserk", name = "Berserk", min = 1, max = 10, weight = 10},
        {id = "gauge", name = "Gauge", min = 1, max = 10, weight = 10},
        {id = "lifesteal", name = "Life Steal", min = 1, max = 5, weight = 10},
        {id = "manasteal", name = "Mana Steal", min = 1, max = 3, weight = 5},
    },
    armor = {
        {id = "defense", name = "Defense", min = 1, max = 5, weight = 25},
        {id = "armor", name = "Armor", min = 1, max = 3, weight = 25},
        {id = "fortitude", name = "Fortitude", min = 5, max = 50, weight = 20},
        {id = "wisdom", name = "Wisdom", min = 5, max = 50, weight = 15},
        {id = "resist_fire", name = "Fire Resist", min = 1, max = 5, weight = 5},
        {id = "resist_ice", name = "Ice Resist", min = 1, max = 5, weight = 5},
        {id = "resist_energy", name = "Energy Resist", min = 1, max = 5, weight = 5},
    },
    shields = {
        {id = "defense", name = "Defense", min = 1, max = 5, weight = 40},
        {id = "armor", name = "Armor", min = 1, max = 3, weight = 30},
        {id = "fortitude", name = "Fortitude", min = 5, max = 30, weight = 20},
        {id = "resist_earth", name = "Earth Resist", min = 1, max = 5, weight = 10},
    },
    boots = {
        {id = "lean", name = "Speed", min = 1, max = 10, weight = 40},
        {id = "armor", name = "Armor", min = 1, max = 2, weight = 30},
        {id = "resist_fire", name = "Fire Resist", min = 1, max = 3, weight = 15},
        {id = "resist_ice", name = "Ice Resist", min = 1, max = 3, weight = 15},
    },
}

-- Determine how many attributes an item gets
-- monsterLevel: level of the monster that dropped it
-- Returns 0-3
function ItemAttributes.rollAttributeCount(monsterLevel)
    local roll = math.random(1, 100)
    if monsterLevel >= 200 then
        if roll <= 30 then return 3 end
        if roll <= 70 then return 2 end
        if roll <= 95 then return 1 end
        return 0
    elseif monsterLevel >= 100 then
        if roll <= 15 then return 3 end
        if roll <= 50 then return 2 end
        if roll <= 85 then return 1 end
        return 0
    elseif monsterLevel >= 50 then
        if roll <= 5 then return 2 end
        if roll <= 40 then return 1 end
        return 0
    else
        if roll <= 15 then return 1 end
        return 0
    end
end

-- Generate random attributes for an item
function ItemAttributes.generateAttributes(item, monsterLevel)
    local pool = ItemAttributes.getPoolForItem(item)
    if not pool then return end

    local count = ItemAttributes.rollAttributeCount(monsterLevel)
    if count == 0 then return end

    local usedAttributes = {}
    local descriptions = {}

    for i = 1, count do
        local attr = ItemAttributes.weightedRandom(pool, usedAttributes)
        if attr then
            local value = math.random(attr.min, attr.max)
            -- Scale value by monster level
            local scaleFactor = math.min(2.0, 1.0 + (monsterLevel / 200))
            value = math.floor(value * scaleFactor)
            value = math.max(attr.min, math.min(attr.max * 2, value))

            item:setCustomAttribute("rattr_" .. attr.id, value)
            table.insert(usedAttributes, attr.id)
            table.insert(descriptions, attr.name .. " +" .. value)
        end
    end

    -- Update item description with attribute list
    if #descriptions > 0 then
        local desc = "[" .. table.concat(descriptions, ", ") .. "]"
        item:setSpecialDescription(desc)
    end
end

-- Hook into monster loot generation
-- Call from data/events/scripts/monster.lua onDropLoot
function ItemAttributes.onLootDrop(monster, corpse)
    local monsterLevel = monster:getType():getHealth() / 10  -- rough level estimate
    for _, item in pairs(corpse:getItems()) do
        local it = ItemType(item:getId())
        if it:getWeaponType() ~= WEAPON_NONE or it:getArmor() > 0 or
           it:getDefense() > 0 then
            ItemAttributes.generateAttributes(item, monsterLevel)
        end
    end
end
```

### 2.5 Combat Integration

Attributes stored as custom attributes need to be read during combat. This requires hooks in the combat event system.

**Reading attributes in combat** (`data/events/scripts/player.lua`):

```lua
-- Called when player attacks
function Player:onAttack(target)
    local weapon = self:getSlotItem(CONST_SLOT_LEFT) or self:getSlotItem(CONST_SLOT_RIGHT)
    if not weapon then return true end

    -- Read random attributes
    local critBonus = weapon:getCustomAttribute("rattr_critical") or 0
    local berserkBonus = weapon:getCustomAttribute("rattr_berserk") or 0
    local gaugeBonus = weapon:getCustomAttribute("rattr_gauge") or 0

    -- These values are stored on the player as temporary modifiers
    -- that the combat system reads
    self:setStorageValue(STORAGE_CRIT_BONUS, critBonus)

    -- Berserk: bonus damage when below 50% HP
    if berserkBonus > 0 and self:getHealth() < (self:getMaxHealth() / 2) then
        self:setStorageValue(STORAGE_DAMAGE_BONUS, berserkBonus)
    else
        self:setStorageValue(STORAGE_DAMAGE_BONUS, gaugeBonus > 0 and
            self:getHealth() == self:getMaxHealth() and gaugeBonus or 0)
    end

    return true
end
```

**For deeper integration** (C++ level), add attribute reading to `Player::getArmor()`, `Player::getDefense()`, etc.:

```cpp
// In src/player.cpp
int32_t Player::getArmor() const {
    int32_t armor = 0;
    // ... existing armor calculation from equipment ...

    // NEW: Add random attribute bonuses
    for (int32_t slot = CONST_SLOT_FIRST; slot <= CONST_SLOT_LAST; ++slot) {
        Item* item = inventory[slot];
        if (item) {
            const auto* armorAttr = item->getCustomAttribute("rattr_armor");
            if (armorAttr) {
                armor += static_cast<int32_t>(armorAttr->get<int64_t>());
            }
        }
    }

    return armor * vocation->armorMultiplier;
}
```

---

## 3. Item Rank System

### 3.1 Design

Items have a rank (0-5) that represents upgrade level. Higher rank items have stronger base stats and property bonuses.

### 3.2 Rank Storage

Use a custom attribute on each item:
```
Key: "item_rank"
Value: 0-5
```

### 3.3 Rank Effects

| Rank | Attack/Defense Modifier | Property Bonus | Visual Indicator |
|------|------------------------|----------------|------------------|
| 0 | +0% (base) | None | Normal name |
| 1 | +5% | +1 STR/DEX/INT | [+1] prefix |
| 2 | +10% | +2 STR/DEX/INT | [+2] prefix |
| 3 | +15% | +3 STR/DEX/INT | [+3] prefix |
| 4 | +20% | +5 STR/DEX/INT | [+4] prefix |
| 5 | +25% | +8 STR/DEX/INT | [+5] prefix |

### 3.4 Rank Upgrade Mechanic

Upgrading an item's rank requires:
- Gold cost (scales exponentially)
- Crafting materials (bars from Smithing)
- Success chance (decreases at higher ranks)

```lua
local rankUpgradeCosts = {
    [1] = {gold = 10000, material = {30404, 2}, chance = 90},    -- Steel bars
    [2] = {gold = 50000, material = {30407, 2}, chance = 75},    -- Mithril bars
    [3] = {gold = 200000, material = {30408, 3}, chance = 60},   -- Adamantite bars
    [4] = {gold = 500000, material = {30409, 2}, chance = 40},   -- Starmetal bars
    [5] = {gold = 1000000, material = {30410, 3}, chance = 25},  -- Dragon Scale bars
}

function upgradeItemRank(player, item)
    local currentRank = item:getCustomAttribute("item_rank") or 0
    if currentRank >= 5 then
        player:sendCancelMessage("This item is already at maximum rank.")
        return false
    end

    local nextRank = currentRank + 1
    local cost = rankUpgradeCosts[nextRank]

    -- Check gold
    if player:getMoney() < cost.gold then
        player:sendCancelMessage("Not enough gold.")
        return false
    end

    -- Check materials
    if player:getItemCount(cost.material[1]) < cost.material[2] then
        player:sendCancelMessage("Not enough materials.")
        return false
    end

    -- Consume resources
    player:removeMoney(cost.gold)
    player:removeItem(cost.material[1], cost.material[2])

    -- Roll success
    if math.random(1, 100) <= cost.chance then
        item:setCustomAttribute("item_rank", nextRank)
        -- Update item name to show rank
        local baseName = ItemType(item:getId()):getName()
        item:setAttribute(ITEM_ATTRIBUTE_NAME, "[+" .. nextRank .. "] " .. baseName)
        -- Boost base stats
        applyRankBonus(item, nextRank)
        player:sendTextMessage(MESSAGE_INFO_DESCR,
            "Upgrade successful! Item is now rank " .. nextRank .. ".")
        return true
    else
        -- Failure: item loses one rank (minimum 0)
        if currentRank > 0 then
            item:setCustomAttribute("item_rank", currentRank - 1)
            local baseName = ItemType(item:getId()):getName()
            if currentRank - 1 > 0 then
                item:setAttribute(ITEM_ATTRIBUTE_NAME,
                    "[+" .. (currentRank - 1) .. "] " .. baseName)
            else
                item:removeAttribute(ITEM_ATTRIBUTE_NAME)
            end
            applyRankBonus(item, currentRank - 1)
        end
        player:sendTextMessage(MESSAGE_INFO_DESCR,
            "Upgrade failed! Item rank decreased.")
        return false
    end
end

function applyRankBonus(item, rank)
    local baseType = ItemType(item:getId())
    local modifier = 1.0 + (rank * 0.05)

    -- Scale attack
    if baseType:getAttack() > 0 then
        item:setAttribute(ITEM_ATTRIBUTE_ATTACK,
            math.floor(baseType:getAttack() * modifier))
    end
    -- Scale defense
    if baseType:getDefense() > 0 then
        item:setAttribute(ITEM_ATTRIBUTE_DEFENSE,
            math.floor(baseType:getDefense() * modifier))
    end
    -- Scale armor
    if baseType:getArmor() > 0 then
        item:setAttribute(ITEM_ATTRIBUTE_ARMOR,
            math.floor(baseType:getArmor() * modifier))
    end
end
```

---

## 4. Properties System (STR/DEX/INT)

### 4.1 Design

Three meta-properties affect combat:
- **Strength (STR)**: Increases melee and physical ranged damage
- **Dexterity (DEX)**: Increases attack speed, dodge chance, movement speed
- **Intelligence (INT)**: Increases spell damage and mana pool

Properties come from:
- Item rank (primary source)
- Random attributes on items (rare)
- Enchanting (via crystals)
- Vocation bonuses (passive per level)

### 4.2 Storage

Properties are calculated dynamically from equipped items, not stored separately:

```lua
function getPlayerProperties(player)
    local str, dex, int = 0, 0, 0

    -- From equipped items
    for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
        local item = player:getSlotItem(slot)
        if item then
            local rank = item:getCustomAttribute("item_rank") or 0
            -- Properties from rank
            local propBonus = getRankPropertyBonus(rank)

            -- Determine which property based on item type
            local weaponType = ItemType(item:getId()):getWeaponType()
            if weaponType == WEAPON_SWORD or weaponType == WEAPON_AXE or
               weaponType == WEAPON_CLUB then
                str = str + propBonus
            elseif weaponType == WEAPON_DISTANCE then
                dex = dex + propBonus
            elseif weaponType == WEAPON_WAND then  -- if wands exist
                int = int + propBonus
            end

            -- Properties from random attributes
            str = str + (item:getCustomAttribute("rattr_strength") or 0)
            dex = dex + (item:getCustomAttribute("rattr_dexterity") or 0)
            int = int + (item:getCustomAttribute("rattr_intelligence") or 0)
        end
    end

    -- Vocation passive bonus
    local vocId = player:getVocation():getBaseId()
    local level = player:getLevel()
    if vocId == 4 then -- Knight
        str = str + math.floor(level / 10)
    elseif vocId == 3 then -- Archer
        dex = dex + math.floor(level / 10)
    elseif vocId == 1 then -- Mage
        int = int + math.floor(level / 10)
    elseif vocId == 2 then -- Druid
        int = int + math.floor(level / 15)
        str = str + math.floor(level / 30)
    end

    return str, dex, int
end
```

### 4.3 Combat Effects

| Property | Effect Per Point |
|----------|-----------------|
| STR +1 | +0.5% melee damage, +2 max carry capacity |
| DEX +1 | +0.3% dodge chance, +1 movement speed, +0.3% ranged damage |
| INT +1 | +0.5% spell damage, +5 max mana |

**Integration in combat events** (`data/events/scripts/player.lua`):

```lua
function Player:onCombat(target, primaryDamage, primaryType, secondaryDamage, secondaryType)
    local str, dex, int = getPlayerProperties(self)

    -- STR bonus to physical damage
    if primaryType == COMBAT_PHYSICALDAMAGE and primaryDamage < 0 then
        local strBonus = 1.0 + (str * 0.005)
        primaryDamage = math.floor(primaryDamage * strBonus)
    end

    -- INT bonus to magic damage
    if primaryType ~= COMBAT_PHYSICALDAMAGE and primaryDamage < 0 then
        local intBonus = 1.0 + (int * 0.005)
        primaryDamage = math.floor(primaryDamage * intBonus)
    end

    return primaryDamage, primaryType, secondaryDamage, secondaryType
end
```

---

## 5. Legendary Item Framework

### 5.1 Design

Legendary items are unique drops from elite monster variants. They have:
- Fixed (not random) powerful attributes
- Unique on-use or on-equip effects
- Special names and descriptions
- Cannot be enchanted or ranked (or have special rules)
- Very low drop rates (0.01% - 0.1%)

### 5.2 Legendary Item Data Structure

```lua
LegendaryItems = {
    [30700] = {
        name = "Blade of the Forgotten King",
        type = "sword",
        baseAttack = 52,
        baseDefense = 38,
        effects = {
            {type = "on_hit", id = "lifedrain", value = 5,
                description = "Drains 5% of damage dealt as HP"},
            {type = "on_equip", id = "speed_bonus", value = 15,
                description = "+15 movement speed"},
        },
        dropFrom = {"The Forgotten King"},
        dropChance = 0.05,  -- 0.05%
        requiredLevel = 100,
        requiredVocation = {4, 8},  -- Knight, Imperial Knight
    },
    [30701] = {
        name = "Aetherbane Crossbow",
        type = "distance",
        baseAttack = 48,
        effects = {
            {type = "on_hit", id = "mana_drain", value = 3,
                description = "3% chance to drain 50 mana from target"},
            {type = "passive", id = "critical_boost", value = 10,
                description = "+10% critical hit chance"},
        },
        dropFrom = {"Aether Dragon"},
        dropChance = 0.03,
        requiredLevel = 150,
        requiredVocation = {3, 7},  -- Archer, Royal Archer
    },
    -- ... 20+ legendary items
}
```

### 5.3 Legendary Effect Processing

```lua
-- Process legendary effects during combat
function processLegendaryEffects(player, target, damage)
    local weapon = player:getSlotItem(CONST_SLOT_LEFT)
    if not weapon then return damage end

    local legendary = LegendaryItems[weapon:getId()]
    if not legendary then return damage end

    for _, effect in ipairs(legendary.effects) do
        if effect.type == "on_hit" then
            if effect.id == "lifedrain" then
                local healAmount = math.floor(math.abs(damage) * effect.value / 100)
                player:addHealth(healAmount)
            elseif effect.id == "mana_drain" then
                if math.random(1, 100) <= effect.value then
                    local targetPlayer = target:getPlayer()
                    if targetPlayer then
                        targetPlayer:addMana(-50)
                        player:addMana(50)
                    end
                end
            end
        end
    end

    return damage
end

-- Apply passive effects on equip
function onEquipLegendary(player, item)
    local legendary = LegendaryItems[item:getId()]
    if not legendary then return end

    for _, effect in ipairs(legendary.effects) do
        if effect.type == "on_equip" or effect.type == "passive" then
            if effect.id == "speed_bonus" then
                local condition = Condition(CONDITION_SPEED)
                condition:setTicks(-1)  -- permanent while equipped
                condition:setParameter(CONDITION_PARAM_SPEED, effect.value)
                player:addCondition(condition)
            elseif effect.id == "critical_boost" then
                -- Store as a player storage value checked during combat
                player:setStorageValue(STORAGE_LEGENDARY_CRIT, effect.value)
            end
        end
    end
end
```

### 5.4 Elite Monster Variants

Create "elite" versions of existing monsters that have:
- 3x HP
- 2x damage
- 2x XP
- Guaranteed rare loot + legendary drop chance
- Special name prefix ("Elite ", "Ancient ", "Legendary ")
- Rare spawn (1-5% chance to replace a normal spawn)

```lua
-- In monster spawn script or global event
function onMonsterSpawn(monster)
    if math.random(1, 100) <= 3 then  -- 3% elite chance
        -- Transform to elite variant
        local baseHP = monster:getMaxHealth()
        monster:setMaxHealth(baseHP * 3)
        monster:addHealth(baseHP * 2)
        -- Visual indicator
        monster:setSkull(SKULL_RED)
        -- Mark as elite for loot purposes
        monster:setStorageValue(STORAGE_ELITE_MONSTER, 1)
    end
end
```

---

## 6. Files to Modify Summary

### C++ Files:

| File | Change | Priority |
|------|--------|----------|
| `src/player.cpp` | Read `rattr_armor`, `rattr_defense` in `getArmor()`, `getDefense()` | HIGH |
| `src/player.cpp` | Read `rattr_lean` for speed calculation in `getStepSpeed()` | MEDIUM |
| `src/player.cpp` | Read `rattr_fortitude`/`rattr_wisdom` for max HP/mana | MEDIUM |
| `src/combat.cpp` | Read attack attributes for damage modification | HIGH |
| `src/item.cpp` | Modify `getDescription()` to display random attributes and rank | HIGH |

### Lua Files:

| File | Change |
|------|--------|
| `data/lib/itemattributes.lua` | NEW: Attribute generation library |
| `data/lib/itemranks.lua` | NEW: Rank upgrade system |
| `data/lib/properties.lua` | NEW: STR/DEX/INT calculation |
| `data/lib/legendary.lua` | NEW: Legendary item definitions and effects |
| `data/events/scripts/monster.lua` | Hook attribute generation into loot drops |
| `data/events/scripts/player.lua` | Hook attribute effects into combat |

### Data Files:

| File | Change |
|------|--------|
| `data/items/items.xml` | Add legendary item definitions (IDs 30700+) |
| `data/monsters/*.xml` | Add legendary drop chance to elite monster loot tables |

---

## 7. Implementation Order

1. **Custom attribute reading in item descriptions** -- so players can see attributes
2. **Random attribute generation on loot** -- the core feature
3. **Combat integration for attack/defense attributes** -- attributes actually do something
4. **Item rank system** -- upgrade mechanic
5. **Properties system (STR/DEX/INT)** -- derived stat layer
6. **Legendary items** -- unique content
7. **Elite monsters** -- legendary item sources

Steps 1-3 form the minimum viable attribute system. Steps 4-7 can be added incrementally.
