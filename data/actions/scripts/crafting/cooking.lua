-- =============================================================================
-- Cooking System - Phase 2.3 (Revised)
-- =============================================================================
-- Players use cooking stations (stoves, campfires, ovens) to craft meals from
-- raw ingredients. Meals provide temporary stat buffs. Only one food buff may
-- be active at a time. Cooking skill progresses with each attempt.
--
-- Usage: Player uses a cooking station (right-click stove/campfire/oven).
--        A recipe list is shown and the best craftable recipe is auto-cooked.
--        Eating a cooked meal grants a timed stat buff.
-- =============================================================================

-- ============================================================================
-- Item IDs
-- ============================================================================

-- Raw ingredient IDs aligned with fishing system (Phase 2.1)
local ITEM = {
	-- Fish from fishing_enhanced.lua
	SARDINE        = 30001,  -- common
	HERRING        = 30002,  -- common
	COD            = 30003,  -- common
	FISH           = 2667,   -- original TFS fish (common)
	SALMON         = 30004,  -- uncommon
	TROUT          = 30005,  -- uncommon
	BASS           = 30006,  -- uncommon
	SWORDFISH      = 30007,  -- rare
	TUNA           = 30008,  -- rare
	LOBSTER        = 30009,  -- rare
	GOLDEN_CARP    = 30010,  -- epic
	SQUID_TENTACLE = 30011,  -- epic
	CRYSTAL_FISH   = 30012,  -- epic

	-- Existing Tibia items used as ingredients
	MEAT           = 2666,
	HAM            = 2671,
	DRAGON_HAM     = 2672,
	BREAD          = 2689,
	EGG            = 2695,
	CHEESE         = 2696,
	MUSHROOM       = 2789,

	-- Farming crops (must match Farming.Items in crafting_farming.lua)
	CARROT         = 30143,
	POTATO         = 30142,
	TOMATO         = 30144,
	WHEAT          = 30140,
	FRESH_HERBS    = 30154,
	MIXED_BERRIES  = 30152,
	GRAPES         = 30153,
	PUMPKIN        = 30148,

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
	ENCHANTED_DUST = 30261,
	CELESTIAL_SALT = 30262,

	-- Cooked meal output IDs (30200-30230)
	FRIED_FISH          = 30200,
	GRILLED_MEAT        = 30201,
	BAKED_BREAD         = 30202,
	SIMPLE_SOUP         = 30203,
	GRILLED_TROUT       = 30204,
	CHEESE_OMELETTE     = 30205,
	SPICED_BASS         = 30206,
	BAKED_POTATO        = 30207,
	FISH_STEW           = 30208,
	ROASTED_CHICKEN     = 30209,
	VEGETABLE_PIE       = 30210,
	SALMON_ROLL         = 30211,
	HONEY_GLAZED_HAM    = 30212,
	BERRY_SMOOTHIE      = 30213,
	MUSHROOM_SOUP       = 30214,
	TUNA_STEAK          = 30215,
	ROYAL_FEAST         = 30216,
	DRAGON_STEAK        = 30217,
	MAGIC_FISH_PIE      = 30218,
	ENCHANTED_STEW      = 30219,
	SWORDFISH_GRILL     = 30220,
	GOLDEN_CARP_SUSHI   = 30221,
	CELESTIAL_BANQUET   = 30222,
	CRYSTAL_FISH_TARTARE = 30223,
	WARRIORS_FEAST      = 30224,
	ARCHERS_RATION      = 30225,
	MAGES_BREW          = 30226,

	-- Burnt food (failure result)
	BURNT_FOOD     = 30230,

	-- Cooking stations
	COOKING_STOVE  = 30240,
	CAMPFIRE       = 1423,
	OVEN           = 1786,
	STOVE_ALT      = 1791,
}

-- ============================================================================
-- Buff Definitions
-- ============================================================================

local FOOD_BUFF_SUBID = 100

local BUFF_HP_REGEN   = 1
local BUFF_MANA_REGEN = 2
local BUFF_SPEED      = 3
local BUFF_MELEE      = 4
local BUFF_DISTANCE   = 5
local BUFF_MAGIC      = 6
local BUFF_MAX_HP     = 7
local BUFF_MAX_MANA   = 8

-- Meal effects: what each cooked meal does when eaten
local mealEffects = {
	-- =========================================================================
	-- Basic Meals (Cooking skill 0+)
	-- =========================================================================
	[ITEM.FRIED_FISH] = {
		name = "Fried Fish",
		message = "The crispy fish restores your energy.",
		duration = 10 * 60 * 1000,
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
	[ITEM.BAKED_BREAD] = {
		name = "Baked Bread",
		message = "The warm bread is comforting and nourishing.",
		duration = 8 * 60 * 1000,
		buffType = BUFF_HP_REGEN,
		buffValue = 3,
		food = 12,
	},
	[ITEM.SIMPLE_SOUP] = {
		name = "Simple Soup",
		message = "The hot soup warms your belly.",
		duration = 10 * 60 * 1000,
		buffType = BUFF_MANA_REGEN,
		buffValue = 3,
		food = 14,
	},
	[ITEM.GRILLED_TROUT] = {
		name = "Grilled Trout",
		message = "The fresh trout invigorates you.",
		duration = 10 * 60 * 1000,
		buffType = BUFF_HP_REGEN,
		buffValue = 10,
		food = 18,
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
	[ITEM.BAKED_POTATO] = {
		name = "Baked Potato",
		message = "The warm potato is comforting.",
		duration = 10 * 60 * 1000,
		buffType = BUFF_MANA_REGEN,
		buffValue = 4,
		food = 12,
	},

	-- =========================================================================
	-- Intermediate Meals (Cooking skill 20+)
	-- =========================================================================
	[ITEM.FISH_STEW] = {
		name = "Fish Stew",
		message = "The rich stew warms your spirit.",
		duration = 15 * 60 * 1000,
		buffType = BUFF_MANA_REGEN,
		buffValue = 6,
		food = 25,
	},
	[ITEM.ROASTED_CHICKEN] = {
		name = "Roasted Chicken",
		message = "The roasted chicken gives you strength.",
		duration = 15 * 60 * 1000,
		buffType = BUFF_MELEE,
		buffValue = 1,
		food = 28,
	},
	[ITEM.VEGETABLE_PIE] = {
		name = "Vegetable Pie",
		message = "The hearty pie restores body and mind.",
		duration = 15 * 60 * 1000,
		buffType = BUFF_MAX_HP,
		buffValue = 15,
		food = 24,
	},
	[ITEM.SALMON_ROLL] = {
		name = "Salmon Roll",
		message = "The delicate salmon roll sharpens your reflexes.",
		duration = 15 * 60 * 1000,
		buffType = BUFF_SPEED,
		buffValue = 12,
		food = 20,
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
	[ITEM.MUSHROOM_SOUP] = {
		name = "Mushroom Soup",
		message = "The earthy soup clears your mind.",
		duration = 15 * 60 * 1000,
		buffType = BUFF_MANA_REGEN,
		buffValue = 7,
		food = 22,
	},
	[ITEM.TUNA_STEAK] = {
		name = "Tuna Steak",
		message = "The thick tuna steak empowers you.",
		duration = 20 * 60 * 1000,
		buffType = BUFF_MELEE,
		buffValue = 2,
		food = 30,
	},

	-- =========================================================================
	-- Advanced Meals (Cooking skill 50+)
	-- =========================================================================
	[ITEM.ROYAL_FEAST] = {
		name = "Royal Feast",
		message = "You dine like royalty! All your abilities surge!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MAX_HP,
		buffValue = 30,
		food = 45,
	},
	[ITEM.DRAGON_STEAK] = {
		name = "Dragon Steak",
		message = "Dragonfire burns within you!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MAX_HP,
		buffValue = 40,
		food = 50,
	},
	[ITEM.MAGIC_FISH_PIE] = {
		name = "Magic Fish Pie",
		message = "Arcane energy flows through the pie into your veins!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MAGIC,
		buffValue = 3,
		food = 40,
	},
	[ITEM.ENCHANTED_STEW] = {
		name = "Enchanted Stew",
		message = "The enchanted stew heightens all your senses!",
		duration = 30 * 60 * 1000,
		buffType = BUFF_MANA_REGEN,
		buffValue = 12,
		food = 40,
	},
	[ITEM.SWORDFISH_GRILL] = {
		name = "Swordfish Grill",
		message = "The mighty swordfish empowers you!",
		duration = 25 * 60 * 1000,
		buffType = BUFF_MELEE,
		buffValue = 3,
		food = 38,
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

	-- =========================================================================
	-- Master Meals (Cooking skill 80+)
	-- =========================================================================
	[ITEM.GOLDEN_CARP_SUSHI] = {
		name = "Golden Carp Sushi",
		message = "The golden carp fills you with radiant energy!",
		duration = 45 * 60 * 1000,
		buffType = BUFF_MAX_MANA,
		buffValue = 100,
		food = 55,
	},
	[ITEM.CELESTIAL_BANQUET] = {
		name = "Celestial Banquet",
		message = "You feel the power of the cosmos coursing through you!",
		duration = 60 * 60 * 1000,
		buffType = BUFF_MELEE,
		buffValue = 5,
		food = 60,
		isLegendary = true,
	},
	[ITEM.CRYSTAL_FISH_TARTARE] = {
		name = "Crystal Fish Tartare",
		message = "Crystal energy sharpens every fiber of your being!",
		duration = 45 * 60 * 1000,
		buffType = BUFF_MAGIC,
		buffValue = 4,
		food = 55,
	},
}

-- ============================================================================
-- Cooking Recipe Definitions (27 recipes across 4 tiers)
-- ============================================================================

local cookingRecipes = {
	-- =========================================================================
	-- BASIC (Cooking skill 0+) -- Campfire-compatible
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
		name = "Baked Bread",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 1,
		ingredients = {{ITEM.FLOUR, 2}, {ITEM.WATER_FLASK, 1}},
		results = {{ITEM.BAKED_BREAD, 1, 100}},
		skillTries = 3,
		successChance = 95,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 4,
		name = "Simple Soup",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 1,
		ingredients = {{ITEM.POTATO, 1}, {ITEM.CARROT, 1}, {ITEM.WATER_FLASK, 1}},
		results = {{ITEM.SIMPLE_SOUP, 1, 100}},
		skillTries = 4,
		successChance = 90,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 5,
		name = "Grilled Trout",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 5,
		ingredients = {{ITEM.TROUT, 1}, {ITEM.SALT, 1}},
		results = {{ITEM.GRILLED_TROUT, 1, 100}},
		skillTries = 5,
		successChance = 85,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 6,
		name = "Cheese Omelette",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 8,
		ingredients = {{ITEM.EGG, 2}, {ITEM.CHEESE, 1}, {ITEM.BUTTER, 1}},
		results = {{ITEM.CHEESE_OMELETTE, 1, 100}},
		skillTries = 5,
		successChance = 85,
		skillBonusPerLevel = 2,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 7,
		name = "Spiced Bass",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 10,
		ingredients = {{ITEM.BASS, 1}, {ITEM.SPICES, 1}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.SPICED_BASS, 1, 100}},
		skillTries = 6,
		successChance = 80,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 8,
		name = "Baked Potato",
		category = "basic",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 5,
		ingredients = {{ITEM.POTATO, 2}, {ITEM.BUTTER, 1}},
		results = {{ITEM.BAKED_POTATO, 1, 100}},
		skillTries = 4,
		successChance = 90,
		skillBonusPerLevel = 2,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},

	-- =========================================================================
	-- INTERMEDIATE (Cooking skill 20+)
	-- =========================================================================
	{
		id = 9,
		name = "Fish Stew",
		category = "intermediate",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 20,
		ingredients = {{ITEM.TROUT, 2}, {ITEM.TOMATO, 1}, {ITEM.FRESH_HERBS, 1}, {ITEM.WATER_FLASK, 1}},
		results = {{ITEM.FISH_STEW, 1, 100}},
		skillTries = 10,
		successChance = 70,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 10,
		name = "Roasted Chicken",
		category = "intermediate",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 20,
		ingredients = {{ITEM.HAM, 1}, {ITEM.SPICES, 1}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.ROASTED_CHICKEN, 1, 100}},
		skillTries = 12,
		successChance = 70,
		skillBonusPerLevel = 1,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 11,
		name = "Vegetable Pie",
		category = "intermediate",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 25,
		ingredients = {{ITEM.CARROT, 2}, {ITEM.POTATO, 1}, {ITEM.FLOUR, 1}, {ITEM.EGG, 1}, {ITEM.BUTTER, 1}},
		results = {{ITEM.VEGETABLE_PIE, 1, 100}},
		skillTries = 14,
		successChance = 65,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 12,
		name = "Salmon Roll",
		category = "intermediate",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 28,
		ingredients = {{ITEM.SALMON, 1}, {ITEM.BREAD, 1}, {ITEM.FRESH_HERBS, 1}, {ITEM.VINEGAR, 1}},
		results = {{ITEM.SALMON_ROLL, 1, 100}},
		skillTries = 15,
		successChance = 65,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 13,
		name = "Honey-Glazed Ham",
		category = "intermediate",
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
		id = 14,
		name = "Berry Smoothie",
		category = "intermediate",
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
		id = 15,
		name = "Mushroom Soup",
		category = "intermediate",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 22,
		ingredients = {{ITEM.MUSHROOM, 3}, {ITEM.WATER_FLASK, 1}, {ITEM.SALT, 1}},
		results = {{ITEM.MUSHROOM_SOUP, 1, 100}},
		skillTries = 10,
		successChance = 75,
		skillBonusPerLevel = 1,
		campfireAllowed = true,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 16,
		name = "Tuna Steak",
		category = "intermediate",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 35,
		ingredients = {{ITEM.TUNA, 1}, {ITEM.SPICES, 1}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.TUNA_STEAK, 1, 100}},
		skillTries = 18,
		successChance = 60,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},

	-- =========================================================================
	-- ADVANCED (Cooking skill 50+)
	-- =========================================================================
	{
		id = 17,
		name = "Royal Feast",
		category = "advanced",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 50,
		ingredients = {{ITEM.MEAT, 3}, {ITEM.POTATO, 2}, {ITEM.GRAPES, 2}, {ITEM.SPICES, 2}, {ITEM.BUTTER, 1}},
		results = {{ITEM.ROYAL_FEAST, 1, 100}},
		skillTries = 30,
		successChance = 50,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 18,
		name = "Dragon Steak",
		category = "advanced",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 55,
		ingredients = {{ITEM.DRAGON_HAM, 1}, {ITEM.SPICES, 2}, {ITEM.RARE_HERB, 1}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.DRAGON_STEAK, 1, 100}},
		skillTries = 35,
		successChance = 45,
		skillBonusPerLevel = 1,
		maxSuccessChance = 90,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 19,
		name = "Magic Fish Pie",
		category = "advanced",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 55,
		ingredients = {{ITEM.SWORDFISH, 1}, {ITEM.FLOUR, 1}, {ITEM.EGG, 1}, {ITEM.FRESH_HERBS, 2}, {ITEM.ENCHANTED_DUST, 1}},
		results = {{ITEM.MAGIC_FISH_PIE, 1, 100}},
		skillTries = 35,
		successChance = 45,
		skillBonusPerLevel = 1,
		maxSuccessChance = 85,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 20,
		name = "Enchanted Stew",
		category = "advanced",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 60,
		ingredients = {{ITEM.TUNA, 1}, {ITEM.MUSHROOM, 2}, {ITEM.FRESH_HERBS, 2}, {ITEM.RARE_HERB, 1}, {ITEM.WATER_FLASK, 1}},
		results = {{ITEM.ENCHANTED_STEW, 1, 100}},
		skillTries = 40,
		successChance = 40,
		skillBonusPerLevel = 1,
		maxSuccessChance = 85,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 21,
		name = "Swordfish Grill",
		category = "advanced",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 50,
		ingredients = {{ITEM.SWORDFISH, 1}, {ITEM.SPICES, 2}, {ITEM.COOKING_OIL, 1}, {ITEM.FRESH_HERBS, 1}},
		results = {{ITEM.SWORDFISH_GRILL, 1, 100}},
		skillTries = 28,
		successChance = 50,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 22,
		name = "Warrior's Feast",
		category = "advanced",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 55,
		ingredients = {{ITEM.MEAT, 3}, {ITEM.POTATO, 2}, {ITEM.SPICES, 2}, {ITEM.COOKING_OIL, 1}},
		results = {{ITEM.WARRIORS_FEAST, 1, 100}},
		skillTries = 30,
		successChance = 45,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 23,
		name = "Archer's Ration",
		category = "advanced",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 55,
		ingredients = {{ITEM.TUNA, 1}, {ITEM.CARROT, 2}, {ITEM.FRESH_HERBS, 2}, {ITEM.BREAD, 1}},
		results = {{ITEM.ARCHERS_RATION, 1, 100}},
		skillTries = 30,
		successChance = 45,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 24,
		name = "Mage's Brew",
		category = "advanced",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 60,
		ingredients = {{ITEM.FRESH_HERBS, 3}, {ITEM.MUSHROOM, 2}, {ITEM.HONEY, 1}, {ITEM.WATER_FLASK, 1}},
		results = {{ITEM.MAGES_BREW, 1, 100}},
		skillTries = 35,
		successChance = 40,
		skillBonusPerLevel = 1,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},

	-- =========================================================================
	-- MASTER (Cooking skill 80+)
	-- =========================================================================
	{
		id = 25,
		name = "Golden Carp Sushi",
		category = "master",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 80,
		ingredients = {{ITEM.GOLDEN_CARP, 1}, {ITEM.VINEGAR, 1}, {ITEM.SALT, 1}, {ITEM.FRESH_HERBS, 2}},
		results = {{ITEM.GOLDEN_CARP_SUSHI, 1, 100}},
		skillTries = 60,
		failSkillTries = 20,
		successChance = 35,
		skillBonusPerLevel = 0.5,
		maxSuccessChance = 80,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 26,
		name = "Celestial Banquet",
		category = "master",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 85,
		ingredients = {
			{ITEM.GOLDEN_CARP, 1},
			{ITEM.SQUID_TENTACLE, 1},
			{ITEM.FRESH_HERBS, 3},
			{ITEM.GRAPES, 2},
			{ITEM.RARE_HERB, 2},
			{ITEM.CELESTIAL_SALT, 1},
		},
		results = {{ITEM.CELESTIAL_BANQUET, 1, 100}},
		skillTries = 100,
		failSkillTries = 30,
		successChance = 25,
		skillBonusPerLevel = 0.5,
		maxSuccessChance = 75,
		campfireAllowed = false,
		stationItemId = ITEM.COOKING_STOVE,
	},
	{
		id = 27,
		name = "Crystal Fish Tartare",
		category = "master",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 80,
		ingredients = {{ITEM.CRYSTAL_FISH, 1}, {ITEM.RARE_HERB, 2}, {ITEM.ENCHANTED_DUST, 1}, {ITEM.VINEGAR, 1}},
		results = {{ITEM.CRYSTAL_FISH_TARTARE, 1, 100}},
		skillTries = 65,
		failSkillTries = 20,
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
-- Cooking Station IDs
-- ============================================================================

local cookingStations = {
	[ITEM.COOKING_STOVE] = true,
	[ITEM.CAMPFIRE]      = true,
	[1424]               = true,
	[1425]               = true,
	[ITEM.OVEN]          = true,
	[1787]               = true,
	[1788]               = true,
	[1789]               = true,
	[ITEM.STOVE_ALT]     = true,
	[1792]               = true,
	[1793]               = true,
}

local function isCampfire(itemId)
	return itemId == ITEM.CAMPFIRE or itemId == 1424 or itemId == 1425
end

-- ============================================================================
-- Apply Meal Buff (eating a cooked meal)
-- ============================================================================
-- Only one food buff can be active at a time. New buffs replace old ones.

local function applyMealBuff(player, item)
	local meal = mealEffects[item:getId()]
	if not meal then
		return false
	end

	-- Remove existing food buff if any (only 1 food buff at a time)
	local existingBuff = player:getStorageValue(Crafting.STORAGE_FOOD_BUFF)
	if existingBuff > 0 then
		player:removeCondition(CONDITION_ATTRIBUTES, CONDITIONID_COMBAT, FOOD_BUFF_SUBID)
	end

	-- Build the condition
	local condition = Condition(CONDITION_ATTRIBUTES, CONDITIONID_COMBAT)
	condition:setTicks(meal.duration)

	-- Apply the stat bonus based on buff type
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

	-- Legendary meals get additional bonuses across all combat stats
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

	-- Feed the player normally
	if meal.food and meal.food > 0 then
		player:feed(meal.food * 12)
	end

	-- Remove the meal item
	item:remove(1)

	-- Feedback
	player:say(meal.message, TALKTYPE_MONSTER_SAY)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	player:sendTextMessage(MESSAGE_INFO_DESCR, "You ate " .. meal.name .. ".")

	return true
end

-- ============================================================================
-- Find Craftable Recipes at a Station
-- ============================================================================

local function findCraftableRecipes(player, stationItemId)
	local results = {}
	local isCampfireStation = isCampfire(stationItemId)

	for _, recipe in ipairs(Crafting.recipes.cooking) do
		-- Campfire restriction
		if isCampfireStation and not recipe.campfireAllowed then
			goto continue
		end

		-- Skill check
		local skillLevel = Crafting.getSkillLevel(player, Crafting.SKILL_COOKING)
		if skillLevel < recipe.requiredSkillLevel then
			goto continue
		end

		-- Ingredient check
		if Crafting.hasIngredients(player, recipe) then
			table.insert(results, recipe)
		end

		::continue::
	end

	return results
end

-- ============================================================================
-- Show Recipe List
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
		local category = recipe.category or "unknown"
		msg = msg .. i .. ". " .. recipe.name ..
			" [" .. category .. ", Skill " .. recipe.requiredSkillLevel .. "] " ..
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
	-- Campfire restriction
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
			-- On failure, give burnt food as a visual indicator
			player:addItem(ITEM.BURNT_FOOD, 1)
			player:sendTextMessage(MESSAGE_INFO_DESCR,
				"[Cooking] You failed to prepare " .. recipe.name ..
				". The ingredients were wasted and you got burnt food.")
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
			player:say("*burns the food*", TALKTYPE_MONSTER_SAY)
		end
		return false
	end
end

-- ============================================================================
-- Action Handler: Using a Cooking Station or Eating a Meal
-- ============================================================================

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

	-- Multiple recipes: sort by required skill level descending (best first)
	table.sort(recipes, function(a, b)
		return a.requiredSkillLevel > b.requiredSkillLevel
	end)

	-- Show the full list and auto-cook the best available recipe
	showRecipeList(player, recipes, stationId)
	cookRecipe(player, recipes[1], stationId)
	return true
end
