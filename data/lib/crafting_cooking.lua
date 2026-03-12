-- ============================================================================
-- Cooking System Library - Phase 2.3
-- ============================================================================
-- Defines cooking recipes, food buff system, and cooking station mechanics.
-- Uses the shared Crafting framework from crafting.lua.
-- ============================================================================

Cooking = {}

-- ---------------------------------------------------------------------------
-- Storage Keys (range: 40200-40299, registered in crafting.lua STORAGE_FOOD_BUFF)
-- ---------------------------------------------------------------------------
Cooking.Storage = {
	skillLevel    = 40201, -- uses Crafting.STORAGE_SKILL_BASE + SKILL_COOKING
	lastCookTime  = 40210, -- anti-spam cooldown
	activeBuffId  = 40211, -- currently active food buff item ID
	buffExpiry    = 40212, -- buff expiration timestamp
}

-- ---------------------------------------------------------------------------
-- Item IDs (range: 30200-30299)
-- ---------------------------------------------------------------------------
Cooking.Items = {
	-- Raw ingredients (from farming or drops)
	RAW_MEAT        = 2666,  -- existing TFS item
	RAW_FISH        = 2667,  -- existing TFS item
	FLOUR           = 2692,  -- existing TFS item
	CHEESE          = 2696,  -- existing TFS item
	EGG             = 2695,  -- existing TFS item

	-- Cooking stations
	OVEN            = 1786,  -- existing TFS oven
	CAMPFIRE        = 1423,  -- existing TFS campfire

	-- Cooked outputs
	GRILLED_MEAT    = 30200,
	FISH_STEW       = 30201,
	HEARTY_BREAD    = 30202,
	CHEESE_OMELETTE = 30203,
	ROYAL_FEAST     = 30204,
	BATTLE_RATION   = 30205,
	MANA_BREW       = 30206,
	SPEED_PIE       = 30207,
	DEFENSE_STEW    = 30208,
	WARRIORS_MEAL   = 30209,
	ARCHERS_DELIGHT = 30210,
	MYSTIC_SOUP     = 30211,
	DRUIDS_TEA      = 30212,
	HUNTERS_WRAP    = 30213,
	IMPERIAL_ROAST  = 30214,
	GOLDEN_SOUP     = 30215,
	ELIXIR_CAKE     = 30216,
	STAMINA_JERKY   = 30217,
	FORTIFIED_STEW  = 30218,
	ENCHANTERS_PIE  = 30219,
}

-- ---------------------------------------------------------------------------
-- Food Buffs
-- ---------------------------------------------------------------------------
-- Each cooked food provides a temporary buff when consumed.
-- Duration in seconds, stats are flat bonuses.
Cooking.Buffs = {
	[Cooking.Items.GRILLED_MEAT]    = {name = "Well Fed",        duration = 600,  health = 5, mana = 0},
	[Cooking.Items.FISH_STEW]       = {name = "Fish Oil",        duration = 600,  health = 0, mana = 5},
	[Cooking.Items.HEARTY_BREAD]    = {name = "Hearty",          duration = 900,  health = 3, mana = 3},
	[Cooking.Items.CHEESE_OMELETTE] = {name = "Nourished",       duration = 600,  health = 4, mana = 4},
	[Cooking.Items.ROYAL_FEAST]     = {name = "Royal Feast",     duration = 1800, health = 10, mana = 10},
	[Cooking.Items.BATTLE_RATION]   = {name = "Battle Ready",    duration = 900,  health = 8, mana = 2},
	[Cooking.Items.MANA_BREW]       = {name = "Mana Surge",      duration = 900,  health = 0, mana = 10},
	[Cooking.Items.SPEED_PIE]       = {name = "Swift",           duration = 600,  speed = 20},
	[Cooking.Items.DEFENSE_STEW]    = {name = "Fortified",       duration = 900,  armor = 3},
	[Cooking.Items.WARRIORS_MEAL]   = {name = "Warrior's Might", duration = 900,  melee = 5},
	[Cooking.Items.ARCHERS_DELIGHT] = {name = "Eagle Eye",       duration = 900,  distance = 5},
	[Cooking.Items.MYSTIC_SOUP]     = {name = "Arcane Focus",    duration = 900,  magic = 3},
}

-- ---------------------------------------------------------------------------
-- Recipes
-- ---------------------------------------------------------------------------
-- Each recipe: {name, ingredients, result, requiredLevel, skillTries, station}

local function registerRecipes()
	-- Tier 1: Beginner (level 1-10)
	Crafting.registerRecipe("cooking", {
		name = "Grilled Meat",
		id = "cook_grilled_meat",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 1,
		skillTries = 2,
		successChance = 90,
		ingredients = {{2666, 1}}, -- 1 raw meat
		results = {{Cooking.Items.GRILLED_MEAT, 1}},
		stationItemId = Cooking.Items.CAMPFIRE,
	})

	Crafting.registerRecipe("cooking", {
		name = "Fish Stew",
		id = "cook_fish_stew",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 3,
		skillTries = 3,
		successChance = 85,
		ingredients = {{2667, 2}}, -- 2 raw fish
		results = {{Cooking.Items.FISH_STEW, 1}},
		stationItemId = Cooking.Items.CAMPFIRE,
	})

	-- Tier 2: Intermediate (level 10-30)
	Crafting.registerRecipe("cooking", {
		name = "Hearty Bread",
		id = "cook_hearty_bread",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 10,
		skillTries = 4,
		successChance = 80,
		ingredients = {{2692, 2}, {2695, 1}}, -- 2 flour, 1 egg
		results = {{Cooking.Items.HEARTY_BREAD, 1}},
		stationItemId = Cooking.Items.OVEN,
	})

	Crafting.registerRecipe("cooking", {
		name = "Cheese Omelette",
		id = "cook_cheese_omelette",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 15,
		skillTries = 5,
		successChance = 80,
		ingredients = {{2695, 2}, {2696, 1}}, -- 2 eggs, 1 cheese
		results = {{Cooking.Items.CHEESE_OMELETTE, 1}},
		stationItemId = Cooking.Items.CAMPFIRE,
	})

	Crafting.registerRecipe("cooking", {
		name = "Battle Ration",
		id = "cook_battle_ration",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 20,
		skillTries = 6,
		successChance = 75,
		ingredients = {{2666, 2}, {2692, 1}}, -- 2 meat, 1 flour
		results = {{Cooking.Items.BATTLE_RATION, 1}},
		stationItemId = Cooking.Items.OVEN,
	})

	-- Tier 3: Advanced (level 30-60)
	Crafting.registerRecipe("cooking", {
		name = "Mana Brew",
		id = "cook_mana_brew",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 30,
		skillTries = 8,
		successChance = 70,
		ingredients = {{2667, 3}, {2695, 1}}, -- 3 fish, 1 egg
		results = {{Cooking.Items.MANA_BREW, 1}},
		stationItemId = Cooking.Items.CAMPFIRE,
	})

	Crafting.registerRecipe("cooking", {
		name = "Speed Pie",
		id = "cook_speed_pie",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 35,
		skillTries = 10,
		successChance = 65,
		ingredients = {{2692, 2}, {2695, 2}, {2696, 1}}, -- 2 flour, 2 eggs, 1 cheese
		results = {{Cooking.Items.SPEED_PIE, 1}},
		stationItemId = Cooking.Items.OVEN,
	})

	Crafting.registerRecipe("cooking", {
		name = "Defense Stew",
		id = "cook_defense_stew",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 40,
		skillTries = 10,
		successChance = 65,
		ingredients = {{2666, 2}, {2667, 1}, {2696, 1}}, -- 2 meat, 1 fish, 1 cheese
		results = {{Cooking.Items.DEFENSE_STEW, 1}},
		stationItemId = Cooking.Items.CAMPFIRE,
	})

	Crafting.registerRecipe("cooking", {
		name = "Warrior's Meal",
		id = "cook_warriors_meal",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 45,
		skillTries = 12,
		successChance = 60,
		ingredients = {{2666, 3}, {2692, 1}, {2695, 1}}, -- 3 meat, 1 flour, 1 egg
		results = {{Cooking.Items.WARRIORS_MEAL, 1}},
		stationItemId = Cooking.Items.OVEN,
	})

	Crafting.registerRecipe("cooking", {
		name = "Archer's Delight",
		id = "cook_archers_delight",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 45,
		skillTries = 12,
		successChance = 60,
		ingredients = {{2667, 3}, {2696, 1}, {2695, 1}}, -- 3 fish, 1 cheese, 1 egg
		results = {{Cooking.Items.ARCHERS_DELIGHT, 1}},
		stationItemId = Cooking.Items.CAMPFIRE,
	})

	Crafting.registerRecipe("cooking", {
		name = "Mystic Soup",
		id = "cook_mystic_soup",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 50,
		skillTries = 14,
		successChance = 55,
		ingredients = {{2667, 2}, {2695, 2}, {2692, 1}}, -- 2 fish, 2 eggs, 1 flour
		results = {{Cooking.Items.MYSTIC_SOUP, 1}},
		stationItemId = Cooking.Items.OVEN,
	})

	-- Tier 4: Expert (level 60-100)
	Crafting.registerRecipe("cooking", {
		name = "Royal Feast",
		id = "cook_royal_feast",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 70,
		skillTries = 20,
		successChance = 50,
		ingredients = {{2666, 3}, {2667, 3}, {2695, 2}, {2696, 2}, {2692, 2}},
		results = {{Cooking.Items.ROYAL_FEAST, 1}},
		stationItemId = Cooking.Items.OVEN,
	})

	Crafting.registerRecipe("cooking", {
		name = "Imperial Roast",
		id = "cook_imperial_roast",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 80,
		skillTries = 25,
		successChance = 45,
		ingredients = {{2666, 5}, {2692, 2}, {2696, 2}}, -- 5 meat, 2 flour, 2 cheese
		results = {{Cooking.Items.IMPERIAL_ROAST, 1}},
		stationItemId = Cooking.Items.OVEN,
	})

	Crafting.registerRecipe("cooking", {
		name = "Golden Soup",
		id = "cook_golden_soup",
		craftingSkill = Crafting.SKILL_COOKING,
		requiredSkillLevel = 90,
		skillTries = 30,
		successChance = 40,
		ingredients = {{2667, 5}, {2695, 3}, {2696, 2}, {2692, 1}},
		results = {{Cooking.Items.GOLDEN_SOUP, 1}},
		stationItemId = Cooking.Items.CAMPFIRE,
	})
end

-- ---------------------------------------------------------------------------
-- Buff Application
-- ---------------------------------------------------------------------------
function Cooking.applyBuff(player, foodItemId)
	local buff = Cooking.Buffs[foodItemId]
	if not buff then
		return false
	end

	-- Remove previous food buff if any
	Cooking.removeBuff(player)

	-- Store buff state
	player:setStorageValue(Cooking.Storage.activeBuffId, foodItemId)
	player:setStorageValue(Cooking.Storage.buffExpiry, os.time() + buff.duration)

	-- Apply stat conditions
	if buff.health and buff.health > 0 then
		player:setMaxHealth(player:getMaxHealth() + buff.health)
	end
	if buff.mana and buff.mana > 0 then
		player:setMaxMana(player:getMaxMana() + buff.mana)
	end
	if buff.speed and buff.speed > 0 then
		player:changeSpeed(buff.speed)
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"You feel " .. buff.name .. "! (+" .. buff.duration .. "s)")

	return true
end

function Cooking.removeBuff(player)
	local activeId = player:getStorageValue(Cooking.Storage.activeBuffId)
	if activeId <= 0 then return end

	local buff = Cooking.Buffs[activeId]
	if buff then
		if buff.health and buff.health > 0 then
			player:setMaxHealth(math.max(150, player:getMaxHealth() - buff.health))
		end
		if buff.mana and buff.mana > 0 then
			player:setMaxMana(math.max(0, player:getMaxMana() - buff.mana))
		end
		if buff.speed and buff.speed > 0 then
			player:changeSpeed(-buff.speed)
		end
	end

	player:setStorageValue(Cooking.Storage.activeBuffId, -1)
	player:setStorageValue(Cooking.Storage.buffExpiry, -1)
end

function Cooking.isBuffActive(player)
	local expiry = player:getStorageValue(Cooking.Storage.buffExpiry)
	if expiry <= 0 then return false end
	return os.time() < expiry
end

-- Initialize recipes on load
registerRecipes()
