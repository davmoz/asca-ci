-- =============================================================================
-- Cooking System - Phase 2.3
-- =============================================================================
-- Players use cooking stations (stoves, campfires, ovens) to craft meals from
-- raw ingredients. Meals provide temporary stat buffs. Only one food buff may
-- be active at a time. Cooking skill progresses with each attempt.
--
-- Usage: Player uses a cooking station (right-click stove/campfire/oven).
--        A recipe window is shown, or the system auto-detects the best recipe
--        the player can craft from their inventory.
-- =============================================================================

-- ============================================================================
-- Item IDs (from docs/phase2-crafting-overview.md ID range 30200-30299)
-- ============================================================================

-- Raw ingredient IDs
local ITEM = {
	-- Fish (from fishing system, 30001-30012)
	TROUT          = 30001,
	BASS           = 30002,
	COD            = 30003,
	HERRING        = 30004,
	SALMON         = 30005,
	TUNA           = 30006,
	SWORDFISH      = 30007,
	GOLDEN_FISH    = 30008,
	CRYSTAL_PERCH  = 30009,
	DEEP_SEA_EEL   = 30010,
	ANCIENT_SCALE  = 30011,
	PRISMATIC_KOI  = 30012,

	-- Farming crops (30110-30117)
	CARROT         = 30110,
	POTATO         = 30111,
	TOMATO         = 30112,
	WHEAT          = 30113,
	FRESH_HERBS    = 30114,
	MIXED_BERRIES  = 30115,
	GRAPES         = 30116,
	PUMPKIN        = 30117,

	-- Existing Tibia items used as cooking ingredients
	MEAT           = 2666,
	FISH           = 2667,
	HAM            = 2671,
	DRAGON_HAM     = 2672,
	CHICKEN        = 2671,   -- ham serves as poultry equivalent
	BREAD          = 2689,
	EGG            = 2695,
	CHEESE         = 2696,
	MUSHROOM       = 2789,

	-- Cooking-specific supplies (30250-30260)
	COOKING_OIL    = 30250,
	SALT           = 30251,
	SPICES         = 30252,
	FLOUR          = 30253,
	SUGAR          = 30254,
	RARE_HERB      = 30255,
	WATER_FLASK    = 30256,
	MILK_FLASK     = 30257,
	HONEY          = 30258,
	VINEGAR        = 30259,
	BUTTER         = 30260,

	-- Cooked meal output IDs (30200-30230)
	GRILLED_TROUT       = 30200,
	FISH_STEW           = 30201,
	HERB_CRUSTED_SALMON = 30202,
	WARRIORS_FEAST      = 30203,
	ARCHERS_RATION      = 30204,
	MAGES_BREW          = 30205,
	HEALERS_PORRIDGE    = 30206,
	DRAGON_STEAK        = 30207,
	DEEP_SEA_SASHIMI    = 30208,
	LEGENDARY_FEAST     = 30209,
	PUMPKIN_PIE         = 30210,
	BERRY_SMOOTHIE      = 30211,
	FRIED_FISH          = 30212,
	GRILLED_MEAT        = 30213,
	ROASTED_CHICKEN     = 30214,
	MUSHROOM_SOUP       = 30215,
	BAKED_POTATO        = 30216,
	TUNA_STEAK          = 30217,
	VEGGIE_WRAP         = 30218,
	CHEESE_OMELETTE     = 30219,
	SWORDFISH_GRILL     = 30220,
	HONEY_GLAZED_HAM    = 30221,
	SPICED_BASS         = 30222,
	GRAPE_SALAD         = 30223,
	GOLDEN_FISH_PLATE   = 30224,
	CRYSTAL_PERCH_FILLET = 30225,
	EEL_KEBAB           = 30226,

	-- Cooking stations
	COOKING_STOVE  = 30240,
	CAMPFIRE       = 1423,   -- existing campfire item
	OVEN           = 1786,   -- existing oven item
	STOVE_ALT      = 1791,   -- existing stove variant
}

-- ============================================================================
-- Buff Definitions
-- ============================================================================
-- Each meal provides a unique buff. Only one food buff active at a time.
-- subId is used to identify the food buff condition category.
-- We use a single subId (100) so that any new food buff replaces the old one.

local FOOD_BUFF_SUBID = 100

-- Buff types mapped to condition parameters
local BUFF_HP_REGEN   = 1  -- extra HP regen per tick
local BUFF_MANA_REGEN = 2  -- extra mana regen per tick
local BUFF_SPEED      = 3  -- movement speed bonus
local BUFF_MELEE      = 4  -- melee skill boost
local BUFF_DISTANCE   = 5  -- distance skill boost
local BUFF_MAGIC      = 6  -- magic level boost
local BUFF_MAX_HP     = 7  -- max HP bonus
local BUFF_MAX_MANA   = 8  -- max mana bonus

-- Meal effect definitions: what each cooked meal does when eaten
local mealEffects = {
	-- =========================================================================
	-- Basic Meals (Cooking 1-10)
	-- =========================================================================
	[ITEM.FRIED_FISH] = {
		name = "Fried Fish",
		message = "The crispy fish restores your energy.",
		duration = 10 * 60 * 1000,  -- 10 minutes
		buffType = BUFF_HP_REGEN,
		buffValue = 5,
		food = 15,
	},
	[ITEM.GRILLED_MEAT] = {
		name = "Grilled Meat",
		message = "The charred meat fills you with warmth.",
		duration = 10 * 60 * 1000,
		buffType = BUFF_HP_REGEN,
		buffValue = 8,
		food = 20,
	},
	[ITEM.GRILLED_TROUT] = {
		name = "Grilled Trout",
		message = "The fresh trout invigorates you.",
		duration = 10 * 60 * 1000,
		buffType = BUFF_HP_REGEN,
		buffValue = 10,
		food = 18,
	},
	[ITEM.BAKED_POTATO] = {
		name = "Baked Potato",
		message = "The warm potato is comforting.",
		duration = 10 * 60 * 1000,
		buffType = BUFF_MANA_REGEN,
		buffValue = 3,
		food = 12,
	},
	[ITEM.CHEESE_OMELETTE] = {
		name = "Cheese Omelette",
		message = "A hearty omelette fills your belly.",
		duration = 10 * 60 * 1000,
		buffType = BUFF_HP_REGEN,
		buffValue = 7,
		food = 16,
	},
	[ITEM.SPICED_BASS] = {
		name = "Spiced Bass",
		message = "The spiced fish tingles your senses.",
		duration = 10 * 60 * 1000,
		buffType = BUFF_SPEED,
		buffValue = 5,
		food = 14,
	},

	-- =========================================================================
	-- Intermediate Meals (Cooking 15-35)
	-- =========================================================================
	[ITEM.FISH_STEW] = {
		name = "Fish Stew",
		message = "The rich stew warms your spirit.",
		duration = 15 * 60 * 1000,
		buffType = BUFF_MANA_REGEN,
		buffValue = 5,
		food = 25,
	},
	[ITEM.MUSHROOM_SOUP] = {
		name = "Mushroom Soup",
		message = "The earthy soup clears your mind.",
		duration = 15 * 60 * 1000,
		buffType = BUFF_MANA_REGEN,
		buffValue = 7,
		food = 22,
	},
	[ITEM.ROASTED_CHICKEN] = {
		name = "Roasted Chicken",
		message = "The roasted chicken gives you strength.",
		duration = 15 * 60 * 1000,
		buffType = BUFF_MELEE,
		buffValue = 1,
		food = 28,
	},
	[ITEM.VEGGIE_WRAP] = {
		name = "Veggie Wrap",
		message = "A fresh wrap invigorates you.",
		duration = 15 * 60 * 1000,
		buffType = BUFF_SPEED,
		buffValue = 10,
		food = 18,
	},
	[ITEM.TUNA_STEAK] = {
		name = "Tuna Steak",
		message = "The thick tuna steak empowers you.",
		duration = 20 * 60 * 1000,
		buffType = BUFF_MELEE,
		buffValue = 2,
		food = 30,
	},
	[ITEM.GRAPE_SALAD] = {
		name = "Grape Salad",
		message = "The sweet salad refreshes your mind.",
		duration = 15 * 60 * 1000,
		buffType = BUFF_MANA_REGEN,
		buffValue = 8,
		food = 15,
	},
	[ITEM.HONEY_GLAZED_HAM] = {
		name = "Honey-Glazed Ham",
		message = "The sweet ham revitalizes you.",
		duration = 20 * 60 * 1000,
		buffType = BUFF_HP_REGEN,
		buffValue = 15,
		food = 35,
	},
	[ITEM.BERRY_SMOOTHIE] = {
		name = "Berry Smoothie",
		message = "You feel light on your feet!",
		duration = 10 * 60 * 1000,
		buffType = BUFF_SPEED,
		buffValue = 15,
		food = 10,
	},

	-- =========================================================================
	-- Advanced Meals (Cooking 40-60)
	-- =========================================================================
	[ITEM.HERB_CRUSTED_SALMON] = {
		name = "Herb-Crusted Salmon",
		message = "The herbed salmon restores your vitality.",
		duration = 20 * 60 * 1000,
		buffType = BUFF_HP_REGEN,
		buffValue = 15,
		food = 35,
	},
	[ITEM.WARRIORS_FEAST] = {
		name = "Warrior's Feast",
		message = "You feel the strength of a warrior!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MELEE,
		buffValue = 3,
		food = 40,
	},
	[ITEM.ARCHERS_RATION] = {
		name = "Archer's Ration",
		message = "Your aim sharpens!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_DISTANCE,
		buffValue = 3,
		food = 40,
	},
	[ITEM.MAGES_BREW] = {
		name = "Mage's Brew",
		message = "Arcane energy surges through you!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MAGIC,
		buffValue = 2,
		food = 40,
	},
	[ITEM.HEALERS_PORRIDGE] = {
		name = "Healer's Porridge",
		message = "A soothing warmth flows through your body.",
		duration = 30 * 60 * 1000,
		buffType = BUFF_HP_REGEN,
		buffValue = 20,
		food = 40,
	},
	[ITEM.SWORDFISH_GRILL] = {
		name = "Swordfish Grill",
		message = "The mighty swordfish empowers you!",
		duration = 25 * 60 * 1000,
		buffType = BUFF_MAX_HP,
		buffValue = 20,
		food = 38,
	},
	[ITEM.PUMPKIN_PIE] = {
		name = "Pumpkin Pie",
		message = "The sweet pie expands your magical reserves.",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MAX_MANA,
		buffValue = 50,
		food = 35,
	},
	[ITEM.EEL_KEBAB] = {
		name = "Eel Kebab",
		message = "The exotic eel invigorates your body!",
		duration = 25 * 60 * 1000,
		buffType = BUFF_SPEED,
		buffValue = 20,
		food = 32,
	},

	-- =========================================================================
	-- Expert Meals (Cooking 65-85)
	-- =========================================================================
	[ITEM.DRAGON_STEAK] = {
		name = "Dragon Steak",
		message = "Dragonfire burns within you!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MAX_HP,
		buffValue = 40,
		food = 50,
	},
	[ITEM.DEEP_SEA_SASHIMI] = {
		name = "Deep Sea Sashimi",
		message = "The rare sashimi enhances your vitality!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MAX_HP,
		buffValue = 25,
		food = 45,
	},
	[ITEM.GOLDEN_FISH_PLATE] = {
		name = "Golden Fish Plate",
		message = "The golden fish fills you with radiant energy!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MAX_MANA,
		buffValue = 75,
		food = 50,
	},
	[ITEM.CRYSTAL_PERCH_FILLET] = {
		name = "Crystal Perch Fillet",
		message = "Crystal energy sharpens your mind!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MAGIC,
		buffValue = 3,
		food = 48,
	},

	-- =========================================================================
	-- Legendary Meals (Cooking 80+)
	-- =========================================================================
	[ITEM.LEGENDARY_FEAST] = {
		name = "Legendary Feast",
		message = "You feel the power of legends coursing through you!",
		duration = 60 * 60 * 1000,
		buffType = BUFF_MELEE,  -- primary buff; this meal is special
		buffValue = 5,
		food = 60,
		isLegendary = true,
	},
}

-- ============================================================================
-- Cooking Recipe Definitions (26 recipes)
-- ============================================================================
-- Categories: Basic, Fish, Vegetable, Special
-- Format: {itemId, count} for ingredients, {itemId, count, chance} for results

local cookingRecipes = {
	-- =========================================================================
	-- BASIC MEALS (Cooking skill 1-10) -- Campfire-compatible
	-- =========================================================================
	{
		id = 1,
		name = "Fried Fish",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 1,
		ingredients = {{ITEM.FISH, 1}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.FRIED_FISH, 1, 100}},
		skillTries = 3,
		successChance = 90,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 2,
		name = "Grilled Meat",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 1,
		ingredients = {{ITEM.MEAT, 1}},
		results = {{ITEM.GRILLED_MEAT, 1, 100}},
		skillTries = 3,
		successChance = 90,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 3,
		name = "Grilled Trout",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 3,
		ingredients = {{ITEM.TROUT, 1}, {ITEM.SALT, 1}},
		results = {{ITEM.GRILLED_TROUT, 1, 100}},
		skillTries = 4,
		successChance = 85,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 4,
		name = "Baked Potato",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 3,
		ingredients = {{ITEM.POTATO, 2}, {ITEM.BUTTER, 1}},
		results = {{ITEM.BAKED_POTATO, 1, 100}},
		skillTries = 4,
		successChance = 90,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 5,
		name = "Cheese Omelette",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 5,
		ingredients = {{ITEM.EGG, 2}, {ITEM.CHEESE, 1}, {ITEM.BUTTER, 1}},
		results = {{ITEM.CHEESE_OMELETTE, 1, 100}},
		skillTries = 5,
		successChance = 85,
		skillBonusPerLevel = 2,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 6,
		name = "Spiced Bass",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 8,
		ingredients = {{ITEM.BASS, 1}, {ITEM.SPICES, 1}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.SPICED_BASS, 1, 100}},
		skillTries = 6,
		successChance = 80,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},

	-- =========================================================================
	-- FISH DISHES (Cooking skill 15-50)
	-- =========================================================================
	{
		id = 7,
		name = "Fish Stew",
		category = "fish",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 15,
		ingredients = {{ITEM.TROUT, 2}, {ITEM.TOMATO, 1}, {ITEM.FRESH_HERBS, 1}, {ITEM.WATER_FLASK, 1}},
		results = {{ITEM.FISH_STEW, 1, 100}},
		skillTries = 10,
		successChance = 70,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 8,
		name = "Tuna Steak",
		category = "fish",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 25,
		ingredients = {{ITEM.TUNA, 1}, {ITEM.SPICES, 1}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.TUNA_STEAK, 1, 100}},
		skillTries = 15,
		successChance = 65,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 9,
		name = "Herb-Crusted Salmon",
		category = "fish",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 35,
		ingredients = {{ITEM.SALMON, 1}, {ITEM.FRESH_HERBS, 2}, {ITEM.BUTTER, 1}, {ITEM.SALT, 1}},
		results = {{ITEM.HERB_CRUSTED_SALMON, 1, 100}},
		skillTries = 20,
		successChance = 60,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 10,
		name = "Swordfish Grill",
		category = "fish",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 45,
		ingredients = {{ITEM.SWORDFISH, 1}, {ITEM.SPICES, 2}, {ITEM.COOKING_OIL, 1}, {ITEM.FRESH_HERBS, 1}},
		results = {{ITEM.SWORDFISH_GRILL, 1, 100}},
		skillTries = 25,
		successChance = 55,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 11,
		name = "Deep Sea Sashimi",
		category = "fish",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 55,
		ingredients = {{ITEM.DEEP_SEA_EEL, 1}, {ITEM.VINEGAR, 1}, {ITEM.SALT, 1}, {ITEM.FRESH_HERBS, 1}},
		results = {{ITEM.DEEP_SEA_SASHIMI, 1, 100}},
		skillTries = 35,
		successChance = 45,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 12,
		name = "Eel Kebab",
		category = "fish",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 50,
		ingredients = {{ITEM.DEEP_SEA_EEL, 1}, {ITEM.TOMATO, 1}, {ITEM.SPICES, 1}},
		results = {{ITEM.EEL_KEBAB, 1, 100}},
		skillTries = 30,
		successChance = 50,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 13,
		name = "Golden Fish Plate",
		category = "fish",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 65,
		ingredients = {{ITEM.GOLDEN_FISH, 1}, {ITEM.FRESH_HERBS, 2}, {ITEM.BUTTER, 1}, {ITEM.SPICES, 2}},
		results = {{ITEM.GOLDEN_FISH_PLATE, 1, 100}},
		skillTries = 50,
		successChance = 40,
		skillBonusPerLevel = 0.5,
		maxSuccessChance = 90,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 14,
		name = "Crystal Perch Fillet",
		category = "fish",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 70,
		ingredients = {{ITEM.CRYSTAL_PERCH, 1}, {ITEM.RARE_HERB, 1}, {ITEM.SALT, 1}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.CRYSTAL_PERCH_FILLET, 1, 100}},
		skillTries = 60,
		successChance = 35,
		skillBonusPerLevel = 0.5,
		maxSuccessChance = 85,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},

	-- =========================================================================
	-- VEGETABLE DISHES (Cooking skill 10-40)
	-- =========================================================================
	{
		id = 15,
		name = "Mushroom Soup",
		category = "vegetable",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 10,
		ingredients = {{ITEM.MUSHROOM, 3}, {ITEM.WATER_FLASK, 1}, {ITEM.SALT, 1}},
		results = {{ITEM.MUSHROOM_SOUP, 1, 100}},
		skillTries = 8,
		successChance = 75,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 16,
		name = "Veggie Wrap",
		category = "vegetable",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 20,
		ingredients = {{ITEM.CARROT, 1}, {ITEM.TOMATO, 1}, {ITEM.FRESH_HERBS, 1}, {ITEM.BREAD, 1}},
		results = {{ITEM.VEGGIE_WRAP, 1, 100}},
		skillTries = 12,
		successChance = 70,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 17,
		name = "Grape Salad",
		category = "vegetable",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 18,
		ingredients = {{ITEM.GRAPES, 2}, {ITEM.FRESH_HERBS, 1}, {ITEM.VINEGAR, 1}},
		results = {{ITEM.GRAPE_SALAD, 1, 100}},
		skillTries = 10,
		successChance = 75,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 18,
		name = "Berry Smoothie",
		category = "vegetable",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 25,
		ingredients = {{ITEM.MIXED_BERRIES, 3}, {ITEM.HONEY, 1}, {ITEM.MILK_FLASK, 1}},
		results = {{ITEM.BERRY_SMOOTHIE, 1, 100}},
		skillTries = 14,
		successChance = 70,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 19,
		name = "Pumpkin Pie",
		category = "vegetable",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 40,
		ingredients = {{ITEM.PUMPKIN, 2}, {ITEM.FLOUR, 1}, {ITEM.EGG, 1}, {ITEM.SUGAR, 1}, {ITEM.BUTTER, 1}},
		results = {{ITEM.PUMPKIN_PIE, 1, 100}},
		skillTries = 22,
		successChance = 55,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},

	-- =========================================================================
	-- SPECIAL DISHES (Cooking skill 30-80+)
	-- =========================================================================
	{
		id = 20,
		name = "Roasted Chicken",
		category = "special",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 20,
		ingredients = {{ITEM.CHICKEN, 1}, {ITEM.SPICES, 1}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.ROASTED_CHICKEN, 1, 100}},
		skillTries = 12,
		successChance = 70,
		skillBonusPerLevel = 1,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 21,
		name = "Honey-Glazed Ham",
		category = "special",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 30,
		ingredients = {{ITEM.HAM, 1}, {ITEM.HONEY, 2}, {ITEM.SPICES, 1}},
		results = {{ITEM.HONEY_GLAZED_HAM, 1, 100}},
		skillTries = 18,
		successChance = 60,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 22,
		name = "Warrior's Feast",
		category = "special",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 40,
		ingredients = {{ITEM.MEAT, 3}, {ITEM.POTATO, 2}, {ITEM.SPICES, 2}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.WARRIORS_FEAST, 1, 100}},
		skillTries = 25,
		successChance = 50,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 23,
		name = "Archer's Ration",
		category = "special",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 40,
		ingredients = {{ITEM.TUNA, 1}, {ITEM.CARROT, 2}, {ITEM.FRESH_HERBS, 2}, {ITEM.BREAD, 1}},
		results = {{ITEM.ARCHERS_RATION, 1, 100}},
		skillTries = 25,
		successChance = 50,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 24,
		name = "Mage's Brew",
		category = "special",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 45,
		ingredients = {{ITEM.FRESH_HERBS, 3}, {ITEM.MUSHROOM, 2}, {ITEM.HONEY, 1}, {ITEM.WATER_FLASK, 1}},
		results = {{ITEM.MAGES_BREW, 1, 100}},
		skillTries = 28,
		successChance = 45,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 25,
		name = "Healer's Porridge",
		category = "special",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 45,
		ingredients = {{ITEM.WHEAT, 2}, {ITEM.MILK_FLASK, 1}, {ITEM.HONEY, 1}, {ITEM.FRESH_HERBS, 2}},
		results = {{ITEM.HEALERS_PORRIDGE, 1, 100}},
		skillTries = 28,
		successChance = 45,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 26,
		name = "Dragon Steak",
		category = "special",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 65,
		ingredients = {{ITEM.DRAGON_HAM, 1}, {ITEM.SPICES, 2}, {ITEM.RARE_HERB, 1}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.DRAGON_STEAK, 1, 100}},
		skillTries = 45,
		successChance = 35,
		skillBonusPerLevel = 0.5,
		maxSuccessChance = 85,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 27,
		name = "Legendary Feast",
		category = "special",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 80,
		ingredients = {
			{ITEM.ANCIENT_SCALE, 1},
			{ITEM.GOLDEN_FISH, 1},
			{ITEM.FRESH_HERBS, 3},
			{ITEM.GRAPES, 2},
			{ITEM.RARE_HERB, 2},
			{ITEM.SPICES, 3},
		},
		results = {{ITEM.LEGENDARY_FEAST, 1, 100}},
		skillTries = 100,
		failSkillTries = 30,
		successChance = 30,
		skillBonusPerLevel = 0.5,
		maxSuccessChance = 80,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
}

-- ============================================================================
-- Register all recipes with the Crafting framework
-- ============================================================================

for _, recipe in ipairs(cookingRecipes) do
	Crafting.registerRecipe("cooking", recipe)
end

-- ============================================================================
-- Cooking Station IDs (stoves, campfires, ovens that trigger cooking)
-- ============================================================================

local cookingStations = {
	[ITEM.COOKING_STOVE] = true,  -- custom cooking stove
	[ITEM.CAMPFIRE]      = true,  -- standard campfire (1423)
	[1424]               = true,  -- campfire variant
	[1425]               = true,  -- campfire variant
	[ITEM.OVEN]          = true,  -- oven (1786)
	[1787]               = true,  -- oven variant
	[1788]               = true,  -- oven variant
	[1789]               = true,  -- oven variant
	[ITEM.STOVE_ALT]     = true,  -- stove (1791)
	[1792]               = true,  -- stove variant
	[1793]               = true,  -- stove variant
}

local function isCampfire(itemId)
	return itemId == ITEM.CAMPFIRE or itemId == 1424 or itemId == 1425
end

-- ============================================================================
-- Apply Meal Buff (eating a cooked meal)
-- ============================================================================
-- This function is called when a player uses (eats) a cooked meal item.
-- Only one food buff can be active at a time. New buffs replace old ones.

local function applyMealBuff(player, item)
	local meal = mealEffects[item:getId()]
	if not meal then
		return false
	end

	-- Check for existing food buff -- only one allowed at a time
	local existingBuff = player:getStorageValue(Crafting.STORAGE_FOOD_BUFF)
	if existingBuff > 0 then
		-- Remove old buff condition before applying new one
		player:removeCondition(CONDITION_ATTRIBUTES, CONDITIONID_COMBAT, FOOD_BUFF_SUBID)
	end

	-- Build and apply the condition
	local condition = Condition(CONDITION_ATTRIBUTES, CONDITIONID_COMBAT)
	condition:setTicks(meal.duration)

	-- Apply the appropriate stat bonus based on buff type
	if meal.buffType == BUFF_HP_REGEN then
		condition:setParameter(CONDITION_PARAM_HEALTHGAIN, meal.buffValue)
		condition:setParameter(CONDITION_PARAM_HEALTHTICKS, 2000)
	elseif meal.buffType == BUFF_MANA_REGEN then
		condition:setParameter(CONDITION_PARAM_MANAGAIN, meal.buffValue)
		condition:setParameter(CONDITION_PARAM_MANATICKS, 2000)
	elseif meal.buffType == BUFF_SPEED then
		condition:setParameter(CONDITION_PARAM_SPEED, meal.buffValue)
	elseif meal.buffType == BUFF_MELEE then
		condition:setParameter(CONDITION_PARAM_SKILL_SWORD, meal.buffValue)
		condition:setParameter(CONDITION_PARAM_SKILL_AXE, meal.buffValue)
		condition:setParameter(CONDITION_PARAM_SKILL_CLUB, meal.buffValue)
	elseif meal.buffType == BUFF_DISTANCE then
		condition:setParameter(CONDITION_PARAM_SKILL_DISTANCE, meal.buffValue)
	elseif meal.buffType == BUFF_MAGIC then
		condition:setParameter(CONDITION_PARAM_STAT_MAGICPOINTS, meal.buffValue)
	elseif meal.buffType == BUFF_MAX_HP then
		condition:setParameter(CONDITION_PARAM_STAT_MAXHITPOINTS, meal.buffValue)
	elseif meal.buffType == BUFF_MAX_MANA then
		condition:setParameter(CONDITION_PARAM_STAT_MAXMANAPOINTS, meal.buffValue)
	end

	-- For legendary meals, apply additional bonuses
	if meal.isLegendary then
		condition:setParameter(CONDITION_PARAM_SKILL_SWORD, meal.buffValue)
		condition:setParameter(CONDITION_PARAM_SKILL_AXE, meal.buffValue)
		condition:setParameter(CONDITION_PARAM_SKILL_CLUB, meal.buffValue)
		condition:setParameter(CONDITION_PARAM_SKILL_DISTANCE, meal.buffValue)
		condition:setParameter(CONDITION_PARAM_SKILL_SHIELD, meal.buffValue)
		condition:setParameter(CONDITION_PARAM_STAT_MAGICPOINTS, 2)
	end

	player:addCondition(condition)

	-- Track active buff via storage
	player:setStorageValue(Crafting.STORAGE_FOOD_BUFF, item:getId())

	-- Also feed the player normally
	if meal.food and meal.food > 0 then
		player:feed(meal.food * 12)
	end

	-- Remove the meal item
	item:remove(1)

	-- Visual and text feedback
	player:say(meal.message, TALKTYPE_MONSTER_SAY)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	player:sendTextMessage(MESSAGE_INFO_DESCR, "You ate " .. meal.name .. ".")

	return true
end

-- ============================================================================
-- Find Best Recipe for Player at Station
-- ============================================================================

local function findCraftableRecipes(player, stationItemId)
	local results = {}
	local isCampfireStation = isCampfire(stationItemId)

	for _, recipe in ipairs(Crafting.recipes.cooking) do
		-- If using campfire, only campfire-allowed recipes
		if isCampfireStation and not recipe.campfireAllowed then
			goto continue
		end

		-- Check skill level
		local skillLevel = Crafting.getSkillLevel(player, Crafting.SKILL_COOKING)
		if skillLevel < recipe.requiredSkillLevel then
			goto continue
		end

		-- Check ingredients
		if Crafting.hasIngredients(player, recipe) then
			table.insert(results, recipe)
		end

		::continue::
	end

	return results
end

-- ============================================================================
-- Show Recipe List to Player
-- ============================================================================

local function showRecipeList(player, recipes, stationItemId)
	if #recipes == 0 then
		local skillLevel = Crafting.getSkillLevel(player, Crafting.SKILL_COOKING)
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"[Cooking] You don't have ingredients for any recipe you know.\n" ..
			"Your cooking skill: " .. skillLevel)
		return
	end

	local msg = "[Cooking] Available recipes:\n"
	for i, recipe in ipairs(recipes) do
		local chance = Crafting.calculateSuccessChance(player, recipe)
		msg = msg .. i .. ". " .. recipe.name ..
			" [Skill " .. recipe.requiredSkillLevel .. "] " ..
			"(" .. math.floor(chance) .. "% success)\n"
	end

	local skillLevel = Crafting.getSkillLevel(player, Crafting.SKILL_COOKING)
	local skillTries = Crafting.getSkillTries(player, Crafting.SKILL_COOKING)
	local nextLevelTries = Crafting.getTriesForLevel(skillLevel + 1)
	msg = msg .. "\nCooking skill: " .. skillLevel ..
		" (" .. skillTries .. "/" .. nextLevelTries .. " to next level)\n"
	msg = msg .. "Say the recipe number to cook it."

	player:sendTextMessage(MESSAGE_INFO_DESCR, msg)
end

-- ============================================================================
-- Cook a Recipe
-- ============================================================================

local function cookRecipe(player, recipe, stationItemId)
	-- Validate campfire restriction
	if isCampfire(stationItemId) and not recipe.campfireAllowed then
		player:sendCancelMessage("This recipe requires a proper cooking stove or oven.")
		return false
	end

	-- Use the shared crafting framework
	local success, reason = Crafting.attempt(player, recipe)

	if success then
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"[Cooking] You successfully prepared " .. recipe.name .. "!")
		player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_BLUE)
		player:say("*cooks*", TALKTYPE_MONSTER_SAY)
		return true
	else
		if reason == "failed" then
			player:sendTextMessage(MESSAGE_INFO_DESCR,
				"[Cooking] You failed to prepare " .. recipe.name ..
				". The ingredients were wasted.")
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
			player:say("*burns the food*", TALKTYPE_MONSTER_SAY)
		end
		-- Other reasons (skill, ingredients, etc.) are handled by Crafting.attempt
		return false
	end
end

-- ============================================================================
-- Pending cooking actions (player -> {recipes, stationItemId})
-- Tracks when a player has opened a cooking station and is selecting a recipe.
-- ============================================================================

local pendingCooking = {}

-- ============================================================================
-- Action Handler: Using a Cooking Station
-- ============================================================================
-- When the player right-clicks a stove/campfire/oven, this handler fires.
-- It shows the available recipes. The player then says a number to select one.

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local stationId = 0

	-- Determine if the player used an item ON a station, or used the station directly
	if target and target:getId() and cookingStations[target:getId()] then
		stationId = target:getId()
	elseif cookingStations[item:getId()] then
		stationId = item:getId()
	end

	-- If no cooking station involved, check if this is a meal being eaten
	if stationId == 0 then
		if mealEffects[item:getId()] then
			return applyMealBuff(player, item)
		end
		return false
	end

	-- Find all recipes the player can cook at this station
	local recipes = findCraftableRecipes(player, stationId)

	if #recipes == 0 then
		local skillLevel = Crafting.getSkillLevel(player, Crafting.SKILL_COOKING)
		if isCampfire(stationId) then
			player:sendTextMessage(MESSAGE_INFO_DESCR,
				"[Cooking] You approach the campfire but lack ingredients for any campfire recipes.\n" ..
				"Your cooking skill: " .. skillLevel)
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR,
				"[Cooking] You examine the cooking station but lack ingredients for any known recipes.\n" ..
				"Your cooking skill: " .. skillLevel)
		end
		return true
	end

	-- If only one recipe is available, cook it directly
	if #recipes == 1 then
		cookRecipe(player, recipes[1], stationId)
		return true
	end

	-- Multiple recipes available: cook the highest-skill one the player can make
	-- Sort by required skill level descending to prioritize the best recipe
	table.sort(recipes, function(a, b)
		return a.requiredSkillLevel > b.requiredSkillLevel
	end)

	-- Show what is being cooked and cook the best available recipe
	showRecipeList(player, recipes, stationId)

	-- Auto-cook the best recipe (highest skill requirement that player meets)
	cookRecipe(player, recipes[1], stationId)
	return true
end
