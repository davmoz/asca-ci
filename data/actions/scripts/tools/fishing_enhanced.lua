-- Enhanced Fishing System (Phase 2.1)
-- Skill-based fishing with 12+ species, rod tiers, time-of-day modifiers,
-- location-based catches, treasure finds, and proper progression.

-- Water tile IDs where fishing is allowed
local waterIds = {
	493, 4608, 4609, 4610, 4611, 4612, 4613, 4614, 4615, 4616,
	4617, 4618, 4619, 4620, 4621, 4622, 4623, 4624, 4625,
	7236, 10499, 15401, 15402
}

---------------------------------------------------------------------------
-- Fish species definitions
-- Each entry: { itemId, name, minSkill, weight (catch weight, higher = rarer) }
---------------------------------------------------------------------------
local FISH_TIER_COMMON = {
	{id = 30001, name = "sardine",   minSkill = 0,  weight = 40},
	{id = 30002, name = "herring",   minSkill = 0,  weight = 35},
	{id = 30003, name = "cod",       minSkill = 0,  weight = 25},
	{id = 2667,  name = "fish",      minSkill = 0,  weight = 50},  -- original TFS fish
}

local FISH_TIER_UNCOMMON = {
	{id = 30004, name = "salmon",  minSkill = 20, weight = 35},
	{id = 30005, name = "trout",   minSkill = 20, weight = 35},
	{id = 30006, name = "bass",    minSkill = 20, weight = 30},
}

local FISH_TIER_RARE = {
	{id = 30007, name = "swordfish", minSkill = 50, weight = 35},
	{id = 30008, name = "tuna",      minSkill = 50, weight = 35},
	{id = 30009, name = "lobster",   minSkill = 50, weight = 30},
}

local FISH_TIER_EPIC = {
	{id = 30010, name = "golden carp",           minSkill = 80, weight = 40},
	{id = 30011, name = "giant squid tentacle",   minSkill = 80, weight = 30},
	{id = 30012, name = "crystal fish",           minSkill = 80, weight = 30},
}

---------------------------------------------------------------------------
-- Junk / trash catches (low skill or bad luck)
---------------------------------------------------------------------------
local JUNK_ITEMS = {
	{id = 30030, name = "waterlogged boot"},
	{id = 30031, name = "rusty tin can"},
	{id = 30032, name = "seaweed clump"},
}

---------------------------------------------------------------------------
-- Treasure catches (very rare bonus loot)
---------------------------------------------------------------------------
local TREASURE_ITEMS = {
	{id = 2148, name = "gold coin",        count = {5, 25}},   -- 5-25 gold
	{id = 2152, name = "platinum coin",    count = {1, 3}},    -- 1-3 plat
	{id = 30033, name = "barnacle-encrusted chest", count = {1, 1}},
	{id = 2143, name = "diamond",          count = {1, 1}},
	{id = 7588, name = "strong mana potion", count = {1, 3}},
}

---------------------------------------------------------------------------
-- Fishing rod tiers
-- Rod itemId -> { name, catchBonus (%), skillBonus (extra skill tries) }
---------------------------------------------------------------------------
local ROD_TIERS = {
	[2580]  = {name = "fishing rod",          catchBonus = 0,  skillBonus = 0, tier = 1},
	[30020] = {name = "improved fishing rod", catchBonus = 10, skillBonus = 1, tier = 2},
	[30021] = {name = "master fishing rod",   catchBonus = 25, skillBonus = 2, tier = 3},
}

---------------------------------------------------------------------------
-- Location-based fishing zones (via action ID on water tiles)
-- Action ID 0 or unset = default/freshwater
-- These can be set on map water tiles in the map editor.
---------------------------------------------------------------------------
local ZONE_DEFAULT    = 0   -- freshwater (ponds, rivers, lakes)
local ZONE_OCEAN      = 1   -- coastal ocean water
local ZONE_DEEP_SEA   = 2   -- deep ocean, far from shore
local ZONE_MAGICAL    = 3   -- enchanted pools, underground magical water

-- Zone modifiers: which tiers are available and bonus/penalty
local ZONE_CONFIG = {
	[ZONE_DEFAULT] = {
		name = "freshwater",
		tierWeights = {common = 60, uncommon = 30, rare = 8, epic = 2},
		catchMod = 0,
	},
	[ZONE_OCEAN] = {
		name = "ocean",
		tierWeights = {common = 45, uncommon = 30, rare = 18, epic = 7},
		catchMod = 5,
	},
	[ZONE_DEEP_SEA] = {
		name = "deep sea",
		tierWeights = {common = 25, uncommon = 30, rare = 30, epic = 15},
		catchMod = 10,
	},
	[ZONE_MAGICAL] = {
		name = "magical waters",
		tierWeights = {common = 20, uncommon = 25, rare = 30, epic = 25},
		catchMod = 15,
	},
}

---------------------------------------------------------------------------
-- Time-of-day modifiers
-- TFS os.date uses server local time. Dawn/dusk are prime fishing hours.
---------------------------------------------------------------------------
local function getTimeOfDayModifier()
	local hour = tonumber(os.date("%H"))
	-- Dawn (5-7): +15% catch chance
	if hour >= 5 and hour <= 7 then
		return 15, "The early morning light dances on the water..."
	-- Dusk (18-20): +10% catch chance
	elseif hour >= 18 and hour <= 20 then
		return 10, "The fading light creates perfect fishing conditions..."
	-- Night (21-4): -10% catch chance, but +5% rare chance
	elseif hour >= 21 or hour <= 4 then
		return -10, nil
	-- Midday (11-14): -5% catch chance (fish hide from sun)
	elseif hour >= 11 and hour <= 14 then
		return -5, nil
	end
	-- Normal hours
	return 0, nil
end

---------------------------------------------------------------------------
-- Calculate base catch chance from fishing skill
-- Formula: starts at 15% at skill 0, scales up to ~75% at skill 100
---------------------------------------------------------------------------
local function getBaseCatchChance(fishingSkill)
	return math.min(75, 15 + fishingSkill * 0.6)
end

---------------------------------------------------------------------------
-- Select a fish tier based on skill level and zone weights
---------------------------------------------------------------------------
local function selectTier(fishingSkill, zoneConfig)
	local weights = zoneConfig.tierWeights
	local roll = math.random(1, 100)

	-- Can only get epic if skill >= 80
	if fishingSkill >= 80 and roll <= weights.epic then
		return FISH_TIER_EPIC, "epic"
	end
	roll = roll - weights.epic

	-- Can only get rare if skill >= 50
	if fishingSkill >= 50 and roll <= weights.rare then
		return FISH_TIER_RARE, "rare"
	end
	roll = roll - weights.rare

	-- Can only get uncommon if skill >= 20
	if fishingSkill >= 20 and roll <= weights.uncommon then
		return FISH_TIER_UNCOMMON, "uncommon"
	end

	return FISH_TIER_COMMON, "common"
end

---------------------------------------------------------------------------
-- Select a specific fish from a tier using weighted random
---------------------------------------------------------------------------
local function selectFish(tier)
	local totalWeight = 0
	for _, fish in ipairs(tier) do
		totalWeight = totalWeight + fish.weight
	end

	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, fish in ipairs(tier) do
		cumulative = cumulative + fish.weight
		if roll <= cumulative then
			return fish
		end
	end
	return tier[1]  -- fallback
end

---------------------------------------------------------------------------
-- Determine skill tries awarded based on what was caught
---------------------------------------------------------------------------
local function getSkillTries(tierName, rodTier)
	local base = 1
	if tierName == "uncommon" then
		base = 2
	elseif tierName == "rare" then
		base = 3
	elseif tierName == "epic" then
		base = 5
	end
	return base + (rodTier.skillBonus or 0)
end

---------------------------------------------------------------------------
-- Check for treasure catch (independent roll after catching a fish)
---------------------------------------------------------------------------
local function rollTreasure(fishingSkill, rodTier)
	-- Base 2% chance, +0.03% per skill level, +1% per rod tier above basic
	local chance = 2 + (fishingSkill * 0.03) + ((rodTier.tier - 1) * 1)
	if math.random(1, 1000) <= (chance * 10) then
		local treasure = TREASURE_ITEMS[math.random(1, #TREASURE_ITEMS)]
		local count = 1
		if treasure.count then
			count = math.random(treasure.count[1], treasure.count[2])
		end
		return treasure, count
	end
	return nil, 0
end

---------------------------------------------------------------------------
-- Main fishing action handler
---------------------------------------------------------------------------
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local targetId = target.itemid

	-- Validate target is water
	if not table.contains(waterIds, targetId) then
		return false
	end

	-- Get rod info
	local rod = ROD_TIERS[item:getId()]
	if not rod then
		player:sendCancelMessage("This is not a valid fishing rod.")
		return false
	end

	-- Handle special water (existing TFS mechanics for item 10499)
	if targetId == 10499 then
		local owner = target:getAttribute(ITEM_ATTRIBUTE_CORPSEOWNER)
		if owner ~= 0 and owner ~= player:getId() then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "You are not the owner.")
			return true
		end

		toPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
		target:transform(targetId + 1)
		target:decay()

		-- Enhanced loot for special water based on skill
		local fishingSkill = player:getEffectiveSkillLevel(SKILL_FISHING)
		local _, tierName = selectTier(fishingSkill, ZONE_CONFIG[ZONE_OCEAN])
		local tier = FISH_TIER_COMMON
		if tierName == "uncommon" then tier = FISH_TIER_UNCOMMON
		elseif tierName == "rare" then tier = FISH_TIER_RARE
		elseif tierName == "epic" then tier = FISH_TIER_EPIC end

		local fish = selectFish(tier)
		player:addItem(fish.id, 1)
		player:sendTextMessage(MESSAGE_INFO_DESCR, "You caught " .. fish.name .. "!")
		player:addSkillTries(SKILL_FISHING, getSkillTries(tierName, rod))
		return true
	end

	-- Visual effect
	if targetId ~= 7236 then
		toPosition:sendMagicEffect(CONST_ME_LOSEENERGY)
	end

	-- Fished-out water (no fish here)
	if targetId == 493 or targetId == 15402 then
		return true
	end

	-- Get player fishing skill
	local fishingSkill = player:getEffectiveSkillLevel(SKILL_FISHING)

	-- Always award a small amount of skill tries for the attempt
	player:addSkillTries(SKILL_FISHING, 1)

	-- Determine zone from action ID on the water tile
	local zoneId = target:getActionId()
	if zoneId < 0 or zoneId > 3 then
		zoneId = ZONE_DEFAULT
	end
	local zone = ZONE_CONFIG[zoneId] or ZONE_CONFIG[ZONE_DEFAULT]

	-- Calculate catch chance
	local baseCatch = getBaseCatchChance(fishingSkill)
	local timeMod, timeMsg = getTimeOfDayModifier()
	local rodBonus = rod.catchBonus
	local zoneMod = zone.catchMod
	local totalCatchChance = math.min(85, baseCatch + timeMod + rodBonus + zoneMod)

	-- Show time-of-day flavor message occasionally
	if timeMsg and math.random(1, 10) == 1 then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, timeMsg)
	end

	-- Roll for catch
	local catchRoll = math.random(1, 100)
	if catchRoll > totalCatchChance then
		-- Failed to catch anything
		if math.random(1, 100) <= 15 then
			-- Chance for junk on failure
			local junk = JUNK_ITEMS[math.random(1, #JUNK_ITEMS)]
			player:addItem(junk.id, 1)
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "You fished up " .. junk.name .. ". Better luck next time.")
		else
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "The fish got away.")
		end
		return true
	end

	-- Check for worms (required for catch, but attempt still gives skill)
	if not player:removeItem(3976, 1) then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You need worms to catch fish. Put them in your inventory.")
		return true
	end

	-- Handle desert fishing (existing special case)
	if targetId == 15401 then
		target:transform(targetId + 1)
		target:decay()
		if math.random(1, 100) >= 97 then
			player:addItem(15405, 1)
			player:sendTextMessage(MESSAGE_INFO_DESCR, "You caught a rare desert fish!")
			return true
		end
	end

	-- Handle shimmering water (existing special case)
	if targetId == 7236 then
		target:transform(targetId + 1)
		target:decay()
	end

	-- Select tier and fish
	local tier, tierName = selectTier(fishingSkill, zone)
	local fish = selectFish(tier)

	-- Add the fish to player inventory
	player:addItem(fish.id, 1)

	-- Award skill tries based on tier
	local skillTries = getSkillTries(tierName, rod)
	player:addSkillTries(SKILL_FISHING, skillTries)

	-- Build catch message
	local tierLabel = ""
	if tierName == "uncommon" then
		tierLabel = " (uncommon)"
		toPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
	elseif tierName == "rare" then
		tierLabel = " (rare!)"
		toPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
		toPosition:sendMagicEffect(CONST_ME_FIREWORK_BLUE)
	elseif tierName == "epic" then
		tierLabel = " (EPIC!)"
		toPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
		toPosition:sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
	end

	player:sendTextMessage(MESSAGE_INFO_DESCR,
		"You caught " .. fish.name .. tierLabel .. "! [Fishing: " .. fishingSkill .. "]")

	-- Roll for bonus treasure
	local treasure, treasureCount = rollTreasure(fishingSkill, rod)
	if treasure then
		player:addItem(treasure.id, treasureCount)
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"You also found " .. treasureCount .. "x " .. treasure.name .. " tangled in your line!")
		toPosition:sendMagicEffect(CONST_ME_MAGIC_GREEN)
	end

	return true
end
