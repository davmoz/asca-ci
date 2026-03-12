-- Enhanced Fishing System (Phase 2.1)
-- Skill-based fishing with 12+ species across 4 tiers, rod tier bonuses,
-- time-of-day modifiers (dawn/dusk), location zones, treasure/junk catches,
-- and proper skill advancement through the native SKILL_FISHING.
--
-- Fish Tiers:
--   Common   (skill 0+):  Sardine, Herring, Cod
--   Uncommon (skill 20+): Salmon, Trout, Bass
--   Rare     (skill 50+): Swordfish, Tuna, Lobster
--   Epic     (skill 80+): Golden Carp, Giant Squid, Crystal Fish
--
-- Rod Tiers:
--   Basic (2580)       - 1.00x catch rate
--   Improved (30020)   - 1.25x catch rate
--   Master (30021)     - 1.50x catch rate

-- =========================================================================
-- Water tile IDs where fishing is allowed
-- =========================================================================
local waterIds = {
	493, 4608, 4609, 4610, 4611, 4612, 4613, 4614, 4615, 4616,
	4617, 4618, 4619, 4620, 4621, 4622, 4623, 4624, 4625,
	7236, 10499, 15401, 15402
}

-- =========================================================================
-- Fish species definitions
-- {id, name, minSkill, weight} -- weight controls relative rarity within tier
-- =========================================================================
local FISH_TIER_COMMON = {
	{id = 30001, name = "sardine",  minSkill = 0,  weight = 40},
	{id = 30002, name = "herring",  minSkill = 0,  weight = 35},
	{id = 30003, name = "cod",      minSkill = 0,  weight = 25},
	{id = 2667,  name = "fish",     minSkill = 0,  weight = 50},  -- vanilla TFS fish
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
	{id = 30010, name = "golden carp",   minSkill = 80, weight = 40},
	{id = 30011, name = "giant squid",   minSkill = 80, weight = 30},
	{id = 30012, name = "crystal fish",  minSkill = 80, weight = 30},
}

-- =========================================================================
-- Junk catches (bad luck / low skill)
-- =========================================================================
local JUNK_ITEMS = {
	{id = 30030, name = "waterlogged boot"},
	{id = 30031, name = "rusty tin can"},
	{id = 30032, name = "seaweed clump"},
	{id = 2234,  name = "old bone"},
}

-- =========================================================================
-- Treasure catches (very rare bonus loot, rolled independently on success)
-- =========================================================================
local TREASURE_ITEMS = {
	{id = 2148,  name = "gold coin",            count = {5, 25}},
	{id = 2152,  name = "platinum coin",         count = {1, 3}},
	{id = 30033, name = "barnacle-encrusted chest", count = {1, 1}},
	{id = 2143,  name = "diamond",               count = {1, 1}},
	{id = 7588,  name = "strong mana potion",    count = {1, 3}},
	{id = 2146,  name = "sapphire",              count = {1, 1}},
}

-- =========================================================================
-- Fishing rod tiers
-- catchMultiplier: applied to base catch chance (1.0 / 1.25 / 1.5)
-- skillBonus: extra skill tries per successful catch
-- =========================================================================
local ROD_TIERS = {
	[2580]  = {name = "fishing rod",          catchMultiplier = 1.00, skillBonus = 0, tier = 1},
	[30020] = {name = "improved fishing rod", catchMultiplier = 1.25, skillBonus = 1, tier = 2},
	[30021] = {name = "master fishing rod",   catchMultiplier = 1.50, skillBonus = 2, tier = 3},
}

-- =========================================================================
-- Location-based fishing zones (via actionId on water tiles)
-- actionId 0 or unset = freshwater (default)
-- Map editors set these on water tiles to create distinct fishing areas.
-- =========================================================================
local ZONE_DEFAULT    = 0   -- freshwater: ponds, rivers, lakes
local ZONE_OCEAN      = 1   -- coastal ocean water
local ZONE_DEEP_SEA   = 2   -- deep ocean, far from shore
local ZONE_MAGICAL    = 3   -- enchanted pools, underground magical water

local ZONE_CONFIG = {
	[ZONE_DEFAULT] = {
		name = "freshwater",
		tierWeights = {common = 60, uncommon = 30, rare = 8,  epic = 2},
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

-- =========================================================================
-- Time-of-day modifiers (server local time)
-- Dawn and dusk are prime fishing hours; midday and night penalize.
-- Night also shifts tier weights toward rarer fish.
-- =========================================================================
local function getTimeOfDayModifier()
	local hour = tonumber(os.date("%H"))
	-- Dawn (5-7): +15% catch chance
	if hour >= 5 and hour <= 7 then
		return 15, "The early morning light dances on the water..."
	-- Dusk (18-20): +10% catch chance
	elseif hour >= 18 and hour <= 20 then
		return 10, "The fading light creates perfect fishing conditions..."
	-- Night (21-4): -10% catch chance but rarer fish are more likely
	elseif hour >= 21 or hour <= 4 then
		return -10, nil
	-- Midday (11-14): -5% catch chance (fish hide from the sun)
	elseif hour >= 11 and hour <= 14 then
		return -5, nil
	end
	return 0, nil
end

-- Is it nighttime? (used to boost rare tier weights)
local function isNightTime()
	local hour = tonumber(os.date("%H"))
	return hour >= 21 or hour <= 4
end

-- =========================================================================
-- Base catch chance from fishing skill
-- Starts at 15% at skill 0, scales to ~75% at skill 100
-- =========================================================================
local function getBaseCatchChance(fishingSkill)
	return math.min(75, 15 + fishingSkill * 0.6)
end

-- =========================================================================
-- Tier selection based on skill level, zone weights, and time of day
-- =========================================================================
local function selectTier(fishingSkill, zoneConfig)
	local weights = {}
	for k, v in pairs(zoneConfig.tierWeights) do
		weights[k] = v
	end

	-- Night bonus: shift 5% from common to rare/epic
	if isNightTime() then
		weights.common = weights.common - 5
		weights.rare = weights.rare + 3
		weights.epic = weights.epic + 2
	end

	local roll = math.random(1, 100)

	-- Epic: only if skill >= 80
	if fishingSkill >= 80 and roll <= weights.epic then
		return FISH_TIER_EPIC, "epic"
	end
	roll = roll - weights.epic

	-- Rare: only if skill >= 50
	if fishingSkill >= 50 and roll <= weights.rare then
		return FISH_TIER_RARE, "rare"
	end
	roll = roll - weights.rare

	-- Uncommon: only if skill >= 20
	if fishingSkill >= 20 and roll <= weights.uncommon then
		return FISH_TIER_UNCOMMON, "uncommon"
	end

	return FISH_TIER_COMMON, "common"
end

-- =========================================================================
-- Weighted random fish selection within a tier
-- =========================================================================
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

-- =========================================================================
-- Skill tries awarded per catch (higher tiers = more advancement)
-- =========================================================================
local function getSkillTries(tierName, rod)
	local base = 1
	if tierName == "uncommon" then
		base = 2
	elseif tierName == "rare" then
		base = 4
	elseif tierName == "epic" then
		base = 6
	end
	return base + (rod.skillBonus or 0)
end

-- =========================================================================
-- Treasure roll (independent bonus after a successful catch)
-- Base 2%, +0.03% per skill level, +1% per rod tier above basic
-- =========================================================================
local function rollTreasure(fishingSkill, rod)
	local chance = 2 + (fishingSkill * 0.03) + ((rod.tier - 1) * 1)
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

-- =========================================================================
-- Junk roll (on failed catch, chance to fish up garbage)
-- Base 15%, decreases slightly with higher skill
-- =========================================================================
local function rollJunk(fishingSkill)
	local junkChance = math.max(5, 15 - math.floor(fishingSkill / 10))
	if math.random(1, 100) <= junkChance then
		return JUNK_ITEMS[math.random(1, #JUNK_ITEMS)]
	end
	return nil
end

-- =========================================================================
-- Main fishing action handler
-- =========================================================================
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
		local tier, tierName = selectTier(fishingSkill, ZONE_CONFIG[ZONE_OCEAN])
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

	-- Always award a baseline skill try for the attempt itself
	player:addSkillTries(SKILL_FISHING, 1)

	-- Determine fishing zone from the water tile's actionId
	local zoneId = target:getActionId()
	if zoneId < 0 or zoneId > 3 then
		zoneId = ZONE_DEFAULT
	end
	local zone = ZONE_CONFIG[zoneId] or ZONE_CONFIG[ZONE_DEFAULT]

	-- Calculate total catch chance
	-- base chance * rod multiplier + time modifier + zone modifier, capped at 85%
	local baseCatch = getBaseCatchChance(fishingSkill)
	local timeMod, timeMsg = getTimeOfDayModifier()
	local zoneMod = zone.catchMod
	local totalCatchChance = math.min(85, math.floor(baseCatch * rod.catchMultiplier) + timeMod + zoneMod)

	-- Show time-of-day flavor message occasionally (10% of attempts)
	if timeMsg and math.random(1, 10) == 1 then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, timeMsg)
	end

	-- Roll for catch
	if math.random(1, 100) > totalCatchChance then
		-- Failed catch: chance for junk
		local junk = rollJunk(fishingSkill)
		if junk then
			player:addItem(junk.id, 1)
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "You fished up " .. junk.name .. ". Better luck next time.")
		else
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "The fish got away.")
		end
		return true
	end

	-- Worms required for an actual catch (attempt still gave skill XP above)
	if not player:removeItem(3976, 1) then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You need worms to catch fish. Put them in your inventory.")
		return true
	end

	-- Handle desert fishing (existing TFS special case)
	if targetId == 15401 then
		target:transform(targetId + 1)
		target:decay()
		if math.random(1, 100) >= 97 then
			player:addItem(15405, 1)
			player:sendTextMessage(MESSAGE_INFO_DESCR, "You caught a rare desert fish!")
			return true
		end
	end

	-- Handle shimmering water (existing TFS special case)
	if targetId == 7236 then
		target:transform(targetId + 1)
		target:decay()
	end

	-- Select tier and specific fish
	local tier, tierName = selectTier(fishingSkill, zone)
	local fish = selectFish(tier)

	-- Give the fish to the player
	player:addItem(fish.id, 1)

	-- Award skill tries (tier-dependent + rod bonus)
	local skillTries = getSkillTries(tierName, rod)
	player:addSkillTries(SKILL_FISHING, skillTries)

	-- Build catch message with tier label and visual effects
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
		-- Epic catches deserve a server-wide announcement
		local msg = player:getName() .. " just caught a legendary " .. fish.name .. "!"
		Game.broadcastMessage(msg, MESSAGE_STATUS_WARNING)
	end

	player:sendTextMessage(MESSAGE_INFO_DESCR,
		"You caught " .. fish.name .. tierLabel .. "! [Fishing: " .. fishingSkill .. "]")

	-- Independent treasure roll on every successful catch
	local treasure, treasureCount = rollTreasure(fishingSkill, rod)
	if treasure then
		player:addItem(treasure.id, treasureCount)
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"You also found " .. treasureCount .. "x " .. treasure.name .. " tangled in your line!")
		toPosition:sendMagicEffect(CONST_ME_MAGIC_GREEN)
	end

	return true
end
