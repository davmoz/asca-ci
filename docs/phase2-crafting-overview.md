# Phase 2: Crafting & Gathering Systems Architecture

> **Scope**: Architecture plan for 6 interconnected crafting systems: Fishing, Farming, Cooking, Mining, Smithing, Enchanting
> **Files Analyzed**: `src/actions.h`, `src/actions.cpp`, `src/item.h`, `src/items.h`, `src/enums.h`, `src/player.h`

---

## 1. Shared Crafting Framework Design

### 1.1 Architecture Overview

All 6 crafting systems share common patterns. Rather than implementing each ad-hoc, we build a shared framework.

```
                     +---------------------+
                     |  CraftingFramework   |
                     |  (Lua Library)       |
                     +---------------------+
                        |        |        |
                +-------+   +---+---+   +-------+
                |           |       |           |
           +----v----+ +---v---+ +-v--------+ +--------+
           | Fishing | |Cooking| | Mining   | |Smithing|
           +---------+ +-------+ +----------+ +--------+
                |           |         |            |
                +-----+-----+---------+            |
                      |                            |
                 +----v----+                 +-----v------+
                 | Farming |                 | Enchanting |
                 +---------+                 +------------+
```

**Ingredient Flow**:
```
Fishing -> Fish -> Cooking -> Stat-Boosting Meals
Farming -> Vegetables/Fruits -> Cooking -> Stat-Boosting Meals
Mining -> Ores -> Smithing -> Equipment
Enchanting: Crystals + Equipment -> Enchanted Equipment
```

### 1.2 Shared Crafting Library (`data/lib/crafting.lua`)

```lua
-- Core crafting library used by all 6 systems
Crafting = {}

-- Recipe data structure
Crafting.Recipe = {
    id = 0,                    -- unique recipe ID
    name = "",                 -- recipe name
    system = "",               -- "cooking", "smithing", "enchanting"
    requiredSkill = 0,         -- skill type (SKILL_COOKING, SKILL_MINING, etc.)
    requiredSkillLevel = 1,    -- minimum skill level
    requiredVocation = {},     -- empty = all vocations, or {1,2,3,4}
    ingredients = {},          -- {{itemId, count}, {itemId, count}, ...}
    tools = {},                -- {{itemId, consumeOnUse}, ...}
    results = {},              -- {{itemId, count, chance}, ...}
    skillTries = 0,            -- skill XP gained on success
    failSkillTries = 0,        -- skill XP gained on failure
    successChance = 100,       -- base success chance (%)
    skillBonusPerLevel = 1,    -- additional % per skill level above requirement
    maxSuccessChance = 100,    -- cap for success chance
    craftTime = 1000,          -- milliseconds to craft
    stationItemId = 0,         -- required workstation (0 = none, e.g., furnace, anvil)
}

-- Process a crafting attempt
function Crafting.attempt(player, recipe)
    -- 1. Check skill level
    if player:getSkillLevel(recipe.requiredSkill) < recipe.requiredSkillLevel then
        player:sendCancelMessage("You need " .. getSkillName(recipe.requiredSkill) ..
            " level " .. recipe.requiredSkillLevel .. " to craft this.")
        return false
    end

    -- 2. Check vocation
    if #recipe.requiredVocation > 0 then
        local vocId = player:getVocation():getBaseId()
        if not table.contains(recipe.requiredVocation, vocId) then
            player:sendCancelMessage("Your vocation cannot craft this.")
            return false
        end
    end

    -- 3. Check ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        if player:getItemCount(ingredient.itemId) < ingredient.count then
            player:sendCancelMessage("You don't have enough materials.")
            return false
        end
    end

    -- 4. Check tool
    for _, tool in ipairs(recipe.tools) do
        if player:getItemCount(tool.itemId) < 1 then
            player:sendCancelMessage("You need the right tools.")
            return false
        end
    end

    -- 5. Calculate success chance
    local skillLevel = player:getSkillLevel(recipe.requiredSkill)
    local bonusLevels = math.max(0, skillLevel - recipe.requiredSkillLevel)
    local successChance = math.min(recipe.maxSuccessChance,
        recipe.successChance + (bonusLevels * recipe.skillBonusPerLevel))

    -- 6. Consume ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        player:removeItem(ingredient.itemId, ingredient.count)
    end

    -- 7. Consume tool charges (if applicable)
    for _, tool in ipairs(recipe.tools) do
        if tool.consumeOnUse then
            player:removeItem(tool.itemId, 1)
        end
    end

    -- 8. Roll for success
    if math.random(1, 100) <= successChance then
        -- Success
        for _, result in ipairs(recipe.results) do
            if math.random(1, 100) <= result.chance then
                player:addItem(result.itemId, result.count)
            end
        end
        player:addSkillTries(recipe.requiredSkill, recipe.skillTries)
        return true, "success"
    else
        -- Failure
        player:addSkillTries(recipe.requiredSkill, recipe.failSkillTries)
        return false, "failed"
    end
end

-- Utility: get all recipes a player can craft at their current skill
function Crafting.getAvailableRecipes(player, system)
    local available = {}
    for _, recipe in ipairs(Crafting.recipes[system] or {}) do
        if player:getSkillLevel(recipe.requiredSkill) >= recipe.requiredSkillLevel then
            table.insert(available, recipe)
        end
    end
    return available
end

-- Recipe registries (populated by each system)
Crafting.recipes = {
    fishing = {},
    farming = {},
    cooking = {},
    mining = {},
    smithing = {},
    enchanting = {},
}
```

### 1.3 Skill Progression Curves

All crafting skills use the same exponential formula from `src/vocation.cpp`:
```
tries_needed = skillBase[skill] * pow(skillMultiplier[skill], level - 11)
```

**Proposed progression** (with base=30, multiplier=1.1):

| Skill Level | Tries Needed | Cumulative Tries | Approximate Actions |
|-------------|-------------|-----------------|---------------------|
| 10 | 27 | 27 | ~30 |
| 20 | 70 | ~400 | ~400 |
| 30 | 182 | ~1,500 | ~1,500 |
| 40 | 472 | ~5,200 | ~5,200 |
| 50 | 1,224 | ~17,000 | ~17,000 |
| 60 | 3,172 | ~52,000 | ~52,000 |
| 70 | 8,220 | ~150,000 | ~150,000 |
| 80 | 21,307 | ~430,000 | ~430,000 |
| 90 | 55,237 | ~1,200,000 | ~1,200,000 |
| 100 | 143,189 | ~3,400,000 | ~3,400,000 |

This provides a reasonable curve where reaching skill 50 requires dedicated effort, and skill 100 is a long-term goal.

---

## 2. Individual System Designs

### 2.1 Fishing System

**New Items Needed**:

| Category | Item Name | Item ID Range | Rarity |
|----------|-----------|---------------|--------|
| Fish | Trout | 30001 | Common |
| Fish | Bass | 30002 | Common |
| Fish | Cod | 30003 | Common |
| Fish | Herring | 30004 | Common |
| Fish | Salmon | 30005 | Uncommon |
| Fish | Tuna | 30006 | Uncommon |
| Fish | Swordfish | 30007 | Uncommon |
| Fish | Golden Fish | 30008 | Rare |
| Fish | Crystal Perch | 30009 | Rare |
| Fish | Deep Sea Eel | 30010 | Rare |
| Fish | Ancient Leviathan Scale | 30011 | Legendary |
| Fish | Prismatic Koi | 30012 | Legendary |
| Tool | Basic Fishing Rod | 2580 (existing) | - |
| Tool | Improved Fishing Rod | 30020 | - |
| Tool | Expert Fishing Rod | 30021 | - |
| Tool | Legendary Fishing Rod | 30022 | - |

**Fish Pool System**:
- Place water tiles with specific action IDs to mark fishing spots
- Action ID determines pool type (freshwater, ocean, deep sea, magical)
- Pools have respawn timers (deplete after X catches, respawn after Y minutes)

**Catch Table by Location & Skill**:

| Pool Type | Skill 10-30 | Skill 30-60 | Skill 60-90 | Skill 90+ |
|-----------|-------------|-------------|-------------|-----------|
| Freshwater | Trout, Bass | +Salmon | +Crystal Perch | +Prismatic Koi |
| Ocean | Cod, Herring | +Tuna, Swordfish | +Deep Sea Eel | +Ancient Scale |
| Deep Sea | Herring | +Swordfish | +Golden Fish | All rare fish |

**Lua Implementation**: Modify existing `data/actions/scripts/tools/fishing.lua`.

### 2.2 Farming System

**New Items Needed**:

| Category | Item Name | Item ID Range |
|----------|-----------|---------------|
| Seed | Carrot Seeds | 30100 |
| Seed | Potato Seeds | 30101 |
| Seed | Tomato Seeds | 30102 |
| Seed | Wheat Seeds | 30103 |
| Seed | Herb Seeds | 30104 |
| Seed | Berry Seeds | 30105 |
| Seed | Grape Seeds | 30106 |
| Seed | Pumpkin Seeds | 30107 |
| Crop | Carrot | 30110 |
| Crop | Potato | 30111 |
| Crop | Tomato | 30112 |
| Crop | Wheat Bundle | 30113 |
| Crop | Fresh Herbs | 30114 |
| Crop | Mixed Berries | 30115 |
| Crop | Grapes | 30116 |
| Crop | Pumpkin | 30117 |
| Tool | Watering Can | 30120 |
| Tool | Garden Hoe | 30121 |
| Station | Planting Pot (house) | 30130 |
| Station | Farm Plot (public) | 30131 |

**Growth Cycle**:
```
Plant Seed -> Stage 1 (sprout, 30 min) -> Stage 2 (growing, 60 min) ->
    Stage 3 (ready, 90 min) -> Harvest -> Plot returns to empty
```

**Implementation**: Use `GlobalEvent` timer to advance growth stages. Each planted crop stores its stage and timestamp via item custom attributes.

```lua
-- Farm plot action (planting)
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- target is the farm plot
    local seed = player:getSlotItem(CONST_SLOT_LEFT) -- or check for seed in hand
    if not seed or not isSeed(seed:getId()) then
        player:sendCancelMessage("You need to hold seeds to plant.")
        return false
    end

    -- Plant: transform plot to stage 1, set timer attributes
    local cropId = seedToCrop[seed:getId()]
    target:setAttribute("crop_type", cropId)
    target:setAttribute("plant_time", os.time())
    target:setAttribute("growth_stage", 1)
    target:transform(FARM_PLOT_SPROUT_ID)

    player:removeItem(seed:getId(), 1)
    player:sendTextMessage(MESSAGE_INFO_DESCR, "You planted the seeds.")
    return true
end
```

### 2.3 Cooking System

**New Items Needed**:

| Category | Item Name | ID Range | Effect |
|----------|-----------|----------|--------|
| Meal | Grilled Trout | 30200 | +10 HP regen for 10 min |
| Meal | Fish Stew | 30201 | +5 mana regen for 10 min |
| Meal | Herb-Crusted Salmon | 30202 | +15 HP regen for 15 min |
| Meal | Warrior's Feast | 30203 | +3 melee skills for 30 min |
| Meal | Archer's Ration | 30204 | +3 distance skill for 30 min |
| Meal | Mage's Brew | 30205 | +2 magic level for 30 min |
| Meal | Healer's Porridge | 30206 | +20% healing received for 30 min |
| Meal | Dragon Steak | 30207 | +5% fire resistance for 30 min |
| Meal | Deep Sea Sashimi | 30208 | +25 max HP for 30 min |
| Meal | Legendary Feast | 30209 | +3 all skills for 60 min |
| Meal | Pumpkin Pie | 30210 | +50 max mana for 30 min |
| Meal | Berry Smoothie | 30211 | +10% movement speed for 10 min |
| Station | Cooking Stove | 30220 | Workstation for cooking |
| Station | Campfire | existing | Basic cooking (limited recipes) |

**Recipe Examples**:
```lua
Crafting.recipes.cooking = {
    {
        id = 1,
        name = "Grilled Trout",
        system = "cooking",
        requiredSkill = SKILL_COOKING,
        requiredSkillLevel = 1,
        ingredients = {{30001, 1}},          -- 1 Trout
        tools = {},
        results = {{30200, 1, 100}},         -- Grilled Trout, 100% on success
        skillTries = 5,
        failSkillTries = 2,
        successChance = 80,
        skillBonusPerLevel = 2,
        maxSuccessChance = 100,
        stationItemId = 30220,               -- requires Cooking Stove
    },
    {
        id = 2,
        name = "Fish Stew",
        system = "cooking",
        requiredSkill = SKILL_COOKING,
        requiredSkillLevel = 15,
        ingredients = {{30001, 2}, {30112, 1}, {30114, 1}}, -- 2 Trout + Tomato + Herbs
        tools = {},
        results = {{30201, 1, 100}},
        skillTries = 15,
        failSkillTries = 5,
        successChance = 60,
        skillBonusPerLevel = 1,
        maxSuccessChance = 95,
        stationItemId = 30220,
    },
    {
        id = 3,
        name = "Legendary Feast",
        system = "cooking",
        requiredSkill = SKILL_COOKING,
        requiredSkillLevel = 80,
        ingredients = {{30011, 1}, {30008, 1}, {30114, 3}, {30116, 2}}, -- Ancient Scale + Golden Fish + 3 Herbs + 2 Grapes
        tools = {},
        results = {{30209, 1, 100}},
        skillTries = 100,
        failSkillTries = 30,
        successChance = 30,
        skillBonusPerLevel = 0.5,
        maxSuccessChance = 80,
        stationItemId = 30220,
    },
}
```

**Buff Implementation**: Meals apply conditions using TFS's condition system:
```lua
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local meal = mealEffects[item:getId()]
    if not meal then return false end

    -- Check if player already has a food buff
    if player:getCondition(CONDITION_ATTRIBUTES, CONDITIONID_COMBAT, meal.subId) then
        player:sendCancelMessage("You already have an active meal buff.")
        return false
    end

    local condition = Condition(CONDITION_ATTRIBUTES, CONDITIONID_COMBAT, meal.subId)
    condition:setTicks(meal.duration)
    -- Apply stat bonuses based on meal type
    for stat, value in pairs(meal.bonuses) do
        condition:setParameter(stat, value)
    end
    player:addCondition(condition)

    player:removeItem(item:getId(), 1)
    player:sendTextMessage(MESSAGE_INFO_DESCR, "You feel nourished!")
    return true
end
```

### 2.4 Mining System

**New Items Needed**:

| Category | Item Name | ID Range | Rarity | Found In |
|----------|-----------|----------|--------|----------|
| Ore | Copper Ore | 30300 | Common | Surface caves |
| Ore | Tin Ore | 30301 | Common | Surface caves |
| Ore | Iron Ore | 30302 | Common | Mid-level caves |
| Ore | Coal | 30303 | Common | Everywhere |
| Ore | Silver Ore | 30304 | Uncommon | Mid-level caves |
| Ore | Gold Ore | 30305 | Uncommon | Deep caves |
| Ore | Mithril Ore | 30306 | Rare | Deep dangerous caves |
| Ore | Adamantite Ore | 30307 | Rare | Boss areas |
| Ore | Obsidian Shard | 30308 | Rare | Volcanic areas |
| Ore | Starmetal Ore | 30309 | Very Rare | Special locations |
| Ore | Dragon Scale Ore | 30310 | Legendary | Dragon lairs |
| Tool | Basic Pickaxe | 30320 | - | - |
| Tool | Iron Pickaxe | 30321 | - | - |
| Tool | Mithril Pickaxe | 30322 | - | - |
| Map Object | Ore Vein (8 variants) | 30330-30337 | - | Placed on map |

**Ore Vein Mechanics**:
- Ore veins are actionable map objects placed in caves/mines
- Each vein has an action ID determining ore type and rarity pool
- Veins deplete after 1-5 successful mines, respawn after 5-15 minutes
- Higher mining skill = higher chance of rare ore from a vein
- Veins in more dangerous areas have better ore pools

**Implementation**:
```lua
-- data/actions/scripts/crafting/mining.lua
local oreVeins = {
    [30330] = {pool = "copper", minSkill = 1, depleteAfter = 5, respawnTime = 300},
    [30331] = {pool = "iron", minSkill = 20, depleteAfter = 4, respawnTime = 600},
    [30332] = {pool = "silver", minSkill = 40, depleteAfter = 3, respawnTime = 900},
    [30333] = {pool = "gold", minSkill = 50, depleteAfter = 3, respawnTime = 900},
    [30334] = {pool = "mithril", minSkill = 60, depleteAfter = 2, respawnTime = 1200},
    [30335] = {pool = "adamantite", minSkill = 75, depleteAfter = 2, respawnTime = 1500},
    [30336] = {pool = "starmetal", minSkill = 85, depleteAfter = 1, respawnTime = 1800},
    [30337] = {pool = "dragonscale", minSkill = 95, depleteAfter = 1, respawnTime = 3600},
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- item = pickaxe, target = ore vein
    local vein = oreVeins[target:getId()]
    if not vein then return false end

    local miningSkill = player:getSkillLevel(SKILL_MINING)
    if miningSkill < vein.minSkill then
        player:sendCancelMessage("You need mining skill " .. vein.minSkill .. " to mine here.")
        return false
    end

    -- Roll for ore
    local ore = rollOre(vein.pool, miningSkill)
    if ore then
        player:addItem(ore.itemId, 1)
        player:addSkillTries(SKILL_MINING, ore.skillTries)
        player:sendTextMessage(MESSAGE_INFO_DESCR, "You mined " .. ore.name .. ".")
    else
        player:addSkillTries(SKILL_MINING, 1)
        player:sendCancelMessage("You failed to extract any ore.")
    end

    -- Deplete vein
    local uses = (target:getAttribute("mining_uses") or 0) + 1
    if uses >= vein.depleteAfter then
        target:transform(DEPLETED_VEIN_ID)
        target:setAttribute("mining_uses", 0)
        addEvent(respawnVein, vein.respawnTime * 1000, toPosition, target:getId())
    else
        target:setAttribute("mining_uses", uses)
    end

    return true
end
```

### 2.5 Smithing System

**New Items Needed**:

| Category | Item Name | ID Range |
|----------|-----------|----------|
| Bar | Copper Bar | 30400 |
| Bar | Tin Bar | 30401 |
| Bar | Bronze Bar (copper+tin) | 30402 |
| Bar | Iron Bar | 30403 |
| Bar | Steel Bar (iron+coal) | 30404 |
| Bar | Silver Bar | 30405 |
| Bar | Gold Bar | 30406 |
| Bar | Mithril Bar | 30407 |
| Bar | Adamantite Bar | 30408 |
| Bar | Starmetal Bar | 30409 |
| Bar | Dragon Scale Bar | 30410 |
| Station | Furnace | 30420 |
| Station | Anvil | 30421 |
| Tool | Blacksmith Hammer | 30422 |
| Tool | Master Hammer | 30423 |
| Crafted | Mithril Sword | 30500 |
| Crafted | Adamantite Armor | 30501 |
| Crafted | Dragon Scale Shield | 30502 |
| ... | (20+ crafted items) | 30500-30550 |

**Two-Phase Crafting**:

**Phase 1: Smelting** (Ore -> Bars at Furnace):
```lua
-- Smelting recipes
{name = "Bronze Bar", ingredients = {{30300, 1}, {30301, 1}}, result = 30402, skill = 1, tries = 5},
{name = "Steel Bar", ingredients = {{30302, 1}, {30303, 2}}, result = 30404, skill = 30, tries = 15},
{name = "Mithril Bar", ingredients = {{30306, 2}, {30303, 1}}, result = 30407, skill = 60, tries = 40},
{name = "Dragon Scale Bar", ingredients = {{30310, 3}, {30303, 2}}, result = 30410, skill = 90, tries = 100},
```

**Phase 2: Forging** (Bars + Materials -> Equipment at Anvil):
```lua
-- Forging recipes (using SKILL_MINING for smithing, or a separate smithing skill)
{name = "Mithril Sword", ingredients = {{30407, 5}, {30404, 2}}, result = 30500, skill = 70, tries = 80},
{name = "Adamantite Armor", ingredients = {{30408, 8}, {30407, 3}}, result = 30501, skill = 80, tries = 120},
{name = "Dragon Scale Shield", ingredients = {{30410, 6}, {30408, 2}}, result = 30502, skill = 95, tries = 200},
```

**Note on Smithing Skill**: For simplicity, smithing can share the Mining skill (since they are thematically related) or we can add a `SKILL_SMITHING` as a 10th skill. The framework supports either approach -- if sharing Mining, just use `requiredSkill = SKILL_MINING` in recipes. If separate, add `SKILL_SMITHING = 9` to the enum (shifting SKILL_MAGLEVEL to 10 and SKILL_LEVEL to 11).

### 2.6 Enchanting System

**New Items Needed**:

| Category | Item Name | ID Range |
|----------|-----------|----------|
| Crystal | Small Painite Crystal | 30600 |
| Crystal | Medium Painite Crystal | 30601 |
| Crystal | Large Painite Crystal | 30602 |
| Station | Enchanting Altar | 30610 |

**Enchanting Mechanics**:
- Use a Painite Crystal on an equipment item at an Enchanting Altar
- Crystal tier determines max attribute quality
- Random attribute selected from a pool based on item type and vocation
- Success chance based on crystal tier (Small: 60%, Medium: 80%, Large: 95%)
- Failed enchantment destroys the crystal but not the item

**Attribute Pool**:

| Attribute | Effect | Applicable To |
|-----------|--------|---------------|
| Attack +1 to +5 | Flat attack bonus | Weapons |
| Defense +1 to +5 | Flat defense bonus | Shields, Armor |
| Critical Hit +1% to +5% | Crit chance increase | Weapons |
| Berserk | +X% damage when below 50% HP | Weapons (Knight/Archer) |
| Gauge | +X% damage at full HP | Weapons |
| Crushing Blow | X% chance to double hit | Club weapons |
| Dazing Blow | X% chance to slow target | Sword weapons |
| Lean | +X% movement speed | Boots |
| Fortitude | +X max HP | Armor, Helmets |
| Wisdom | +X max Mana | Armor, Helmets |

**Implementation** (uses `Item::setCustomAttribute` from `src/item.h`):
```lua
function enchantItem(player, crystal, targetItem)
    local tier = getCrystalTier(crystal:getId())  -- 1, 2, or 3
    local itemType = targetItem:getType()
    local pool = getAttributePool(itemType, player:getVocation():getBaseId())

    -- Roll success
    local successChances = {60, 80, 95}
    if math.random(1, 100) > successChances[tier] then
        player:removeItem(crystal:getId(), 1)
        player:sendTextMessage(MESSAGE_INFO_DESCR, "The enchantment failed.")
        return false
    end

    -- Roll attribute
    local attribute = pool[math.random(1, #pool)]
    local maxValue = tier * 2  -- Small: max 2, Medium: max 4, Large: max 6
    local value = math.random(1, maxValue)

    -- Apply as custom attribute on the item
    local key = "enchant_" .. attribute.name
    targetItem:setCustomAttribute(key, value)

    -- Update item description
    local desc = targetItem:getSpecialDescription()
    desc = desc .. "\n[Enchanted: " .. attribute.displayName .. " +" .. value .. "]"
    targetItem:setSpecialDescription(desc)

    player:removeItem(crystal:getId(), 1)
    player:sendTextMessage(MESSAGE_INFO_DESCR,
        "Enchantment successful! " .. attribute.displayName .. " +" .. value)
    return true
end
```

**Combat Integration** (reading enchantment in combat):
```lua
-- In events/scripts/player.lua or combat event callbacks
function onAttack(player, target)
    local weapon = player:getSlotItem(CONST_SLOT_LEFT)
    if weapon then
        local critBonus = weapon:getCustomAttribute("enchant_critical_hit") or 0
        -- Apply critical hit bonus to damage calculation
    end
end
```

---

## 3. Database Tables Needed

### 3.1 Recipe Registry (optional, can be Lua-only)

If recipes are defined purely in Lua, no database table is needed. For dynamic/admin-editable recipes:

```sql
CREATE TABLE IF NOT EXISTS `crafting_recipes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `system` ENUM('fishing','farming','cooking','mining','smithing','enchanting') NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `required_skill` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `required_skill_level` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `success_chance` TINYINT UNSIGNED NOT NULL DEFAULT 100,
    `skill_tries` INT UNSIGNED NOT NULL DEFAULT 0,
    `station_item_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `system` (`system`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `crafting_recipe_ingredients` (
    `recipe_id` INT UNSIGNED NOT NULL,
    `item_id` SMALLINT UNSIGNED NOT NULL,
    `count` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`recipe_id`, `item_id`),
    FOREIGN KEY (`recipe_id`) REFERENCES `crafting_recipes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `crafting_recipe_results` (
    `recipe_id` INT UNSIGNED NOT NULL,
    `item_id` SMALLINT UNSIGNED NOT NULL,
    `count` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `chance` TINYINT UNSIGNED NOT NULL DEFAULT 100,
    PRIMARY KEY (`recipe_id`, `item_id`),
    FOREIGN KEY (`recipe_id`) REFERENCES `crafting_recipes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3.2 Farming State (for persistent crops)

```sql
CREATE TABLE IF NOT EXISTS `farming_plots` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `pos_x` INT NOT NULL,
    `pos_y` INT NOT NULL,
    `pos_z` TINYINT NOT NULL,
    `crop_type` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `growth_stage` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `planted_at` INT UNSIGNED NOT NULL DEFAULT 0,
    `watered_at` INT UNSIGNED NOT NULL DEFAULT 0,
    `owner_id` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `position` (`pos_x`, `pos_y`, `pos_z`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3.3 Player Crafting Log (optional, for analytics)

```sql
CREATE TABLE IF NOT EXISTS `player_crafting_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `player_id` INT UNSIGNED NOT NULL,
    `recipe_id` INT UNSIGNED NOT NULL,
    `system` VARCHAR(20) NOT NULL,
    `success` TINYINT(1) NOT NULL DEFAULT 0,
    `timestamp` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `player_id` (`player_id`),
    KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 4. NPC Interactions

### 4.1 Crafting Trainer NPCs

Each crafting system needs at least one NPC who:
- Teaches basic recipes (for systems that unlock recipes)
- Sells basic tools (fishing rods, pickaxes, cooking tools, seeds)
- Explains the crafting system via dialogue

**Example NPC (Fishing Trainer)**:
```lua
-- data/npc/scripts/fishing_trainer.lua
local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
-- etc.

keywordHandler:addKeyword({"fish"}, StdModule.say, {
    npcHandler = npcHandler,
    text = "I can teach you about fishing! You need a fishing rod and some patience. "..
           "Try fishing in different waters - each location has different fish species."
})

-- Sell fishing rods
local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)
shopModule:addBuyableItem({"fishing rod"}, 2580, 20, "fishing rod")
shopModule:addBuyableItem({"improved rod"}, 30020, 500, "improved fishing rod")
shopModule:addBuyableItem({"expert rod"}, 30021, 5000, "expert fishing rod")
```

### 4.2 Required NPCs Per System

| System | NPC Name | Role | Location |
|--------|----------|------|----------|
| Fishing | Old Fisherman | Sells rods, teaches basics | Coastal city |
| Farming | Farmer Jenkins | Sells seeds & tools | Farm area |
| Cooking | Chef Gordon | Sells recipes, cooking tools | City kitchen |
| Mining | Dwarf Miner | Sells pickaxes, teaches basics | Near mines |
| Smithing | Master Smith | Forging station NPC | Smithy |
| Enchanting | Enchantress Lyra | Sells crystals, enchanting altar | Magic shop |

---

## 5. Implementation Order

1. **Shared Crafting Library** (`data/lib/crafting.lua`) -- foundation for all systems
2. **Fishing** -- upgrade existing system, easiest starting point
3. **Mining** -- standalone gathering, no dependencies
4. **Cooking** -- depends on fishing (fish as ingredients)
5. **Farming** -- standalone but feeds into cooking
6. **Smithing** -- depends on mining (ores as materials)
7. **Enchanting** -- depends on item attribute system (Phase 3)

Systems 2-4 can be developed in parallel since they are independent.

---

## 6. Item ID Range Allocation

| Range | System | Content |
|-------|--------|---------|
| 30001-30099 | Fishing | Fish species, rods, fish pools |
| 30100-30199 | Farming | Seeds, crops, farming tools |
| 30200-30299 | Cooking | Meals, cooking stations |
| 30300-30399 | Mining | Ores, pickaxes, ore veins |
| 30400-30499 | Smithing | Bars, forging tools, stations |
| 30500-30599 | Smithing | Crafted equipment |
| 30600-30699 | Enchanting | Crystals, altar, enchanted variants |
| 30700-30799 | Reserved | Future crafting expansion |

**Note**: These IDs must be added to `data/items/items.xml` with appropriate names, weights, descriptions, and sprite references. Custom sprites require OTClient art assets.
