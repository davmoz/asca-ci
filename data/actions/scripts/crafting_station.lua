-- ============================================================================
-- Crafting Station Action Handler
-- ============================================================================
-- Handles interaction with all crafting stations (ovens, anvils, forges, etc.)
-- This is a generic entry point that delegates to the appropriate crafting
-- subsystem (cooking or smithing) based on the station type.
--
-- Cooking stations use the Crafting framework with registered cooking recipes.
-- Smithing stations use the Smithing library for anvil-based forging.
-- ============================================================================

-- Station type mapping: item ID -> crafting subsystem
local stationTypes = {
	-- Cooking stations (ovens and stoves)
	[1786] = "cooking",  -- oven
	[1787] = "cooking",  -- oven (variant)
	[1788] = "cooking",  -- oven (variant)
	[1789] = "cooking",  -- oven (variant)
	[1790] = "cooking",  -- stove
	[1791] = "cooking",  -- stove (variant)
	[1792] = "cooking",  -- stove (variant)
	[1793] = "cooking",  -- stove (variant)

	-- Smithing stations (anvils)
	[2555] = "smithing", -- anvil
	[2556] = "smithing", -- anvil (variant)
	[30421] = "smithing", -- custom crafting anvil
}

-- ============================================================================
-- Cooking Handler
-- ============================================================================
-- Shows available cooking recipes and auto-cooks the best one the player
-- can make at this station.

local function handleCooking(player, item)
	if not Crafting.recipes or not Crafting.recipes.cooking then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "No cooking recipes are available.")
		return true
	end

	local skillLevel = Crafting.getSkillLevel(player, Crafting.SKILL_COOKING)
	local recipes = Crafting.recipes.cooking
	local availableRecipes = {}

	for _, recipe in ipairs(recipes) do
		-- Check skill level
		if skillLevel >= recipe.requiredSkillLevel then
			-- Check ingredients
			if Crafting.hasIngredients(player, recipe) then
				table.insert(availableRecipes, recipe)
			end
		end
	end

	if #availableRecipes == 0 then
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"[Cooking] You don't have ingredients for any recipes you know.\n" ..
			"Your cooking skill: " .. skillLevel)
		return true
	end

	-- Sort by required skill level descending (best recipe first)
	table.sort(availableRecipes, function(a, b)
		return a.requiredSkillLevel > b.requiredSkillLevel
	end)

	-- Show available recipes
	local msg = "[Cooking Station] Available recipes:\n"
	for i, recipe in ipairs(availableRecipes) do
		local chance = Crafting.calculateSuccessChance(player, recipe)
		msg = msg .. i .. ". " .. recipe.name ..
			" [Skill " .. recipe.requiredSkillLevel .. "] " ..
			"(" .. math.floor(chance) .. "% success)\n"
	end

	local skillTries = Crafting.getSkillTries(player, Crafting.SKILL_COOKING)
	local nextLevelTries = Crafting.getTriesForLevel(skillLevel + 1)
	msg = msg .. "\nCooking skill: " .. skillLevel ..
		" (" .. skillTries .. "/" .. nextLevelTries .. " to next level)"
	player:sendTextMessage(MESSAGE_INFO_DESCR, msg)

	-- Auto-craft the best available recipe
	local recipe = availableRecipes[1]
	local success, reason = Crafting.attempt(player, recipe)

	if success then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cooked: " .. recipe.name)
		player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_BLUE)
	else
		if reason == "failed" then
			player:sendTextMessage(MESSAGE_STATUS_SMALL,
				"You failed to cook " .. recipe.name .. ". The ingredients were wasted.")
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
		end
	end

	return true
end

-- ============================================================================
-- Smithing Handler
-- ============================================================================
-- Finds available smithing recipes the player can forge at an anvil and
-- auto-forges the best (highest skill requirement) recipe.

local function handleSmithing(player, item)
	if not Smithing or not Smithing.Recipes then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "Smithing system is not available.")
		return true
	end

	local smithingLevel = Smithing.getSkillLevel(player)
	local availableRecipes = Smithing.findAvailableRecipes(player, smithingLevel, nil)

	if #availableRecipes == 0 then
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"[Smithing] You don't have materials for any smithing recipes.\n" ..
			"Your smithing skill: " .. smithingLevel)
		return true
	end

	-- Sort by required skill descending (best recipe first)
	table.sort(availableRecipes, function(a, b)
		return a.requiredSkill > b.requiredSkill
	end)

	-- Show available recipes
	local msg = "[Smithing Station] Available recipes:\n"
	for i, recipe in ipairs(availableRecipes) do
		local chance = Smithing.getSuccessChance(recipe, smithingLevel, 0)
		msg = msg .. i .. ". " .. recipe.name ..
			" [Skill " .. recipe.requiredSkill .. "] " ..
			"(" .. math.floor(chance) .. "% success)\n"
	end

	local skillTries = Smithing.getSkillTries(player)
	local nextLevelTries = Smithing.getTriesForLevel(smithingLevel + 1)
	msg = msg .. "\nSmithing skill: " .. smithingLevel ..
		" (" .. skillTries .. "/" .. nextLevelTries .. " to next level)"
	player:sendTextMessage(MESSAGE_INFO_DESCR, msg)

	-- Check for hammer (required tool)
	local hammerBonus = 0
	local hasHammer = false
	for hammerId, hammerData in pairs(Smithing.Hammers) do
		if player:getItemCount(hammerId) > 0 then
			hasHammer = true
			hammerBonus = hammerData.bonus
			break
		end
	end

	if not hasHammer then
		player:sendTextMessage(MESSAGE_STATUS_SMALL,
			"You need a blacksmith hammer to smith at an anvil.")
		return true
	end

	-- Auto-forge the best available recipe
	local recipe = availableRecipes[1]
	local chance = Smithing.getSuccessChance(recipe, smithingLevel, hammerBonus)
	local roll = math.random(1, 100)

	-- Consume ingredients
	for _, ing in ipairs(recipe.ingredients) do
		player:removeItem(ing[1], ing[2])
	end

	if roll <= chance then
		-- Success
		local quality = Smithing.rollQuality(smithingLevel, recipe.requiredSkill, hammerBonus)
		local qualityPrefix = Smithing.QualityColors[quality] or ""
		local qualityName = Smithing.QualityNames[quality] or "Basic"

		local craftedItem = player:addItem(recipe.result, 1)
		if craftedItem and quality > 1 then
			craftedItem:setCustomAttribute("quality", quality)
			craftedItem:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION,
				qualityPrefix .. recipe.name .. " (" .. qualityName .. " quality)")
		end

		player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
			"You smithed: " .. qualityPrefix .. recipe.name ..
			" (" .. qualityName .. " quality)")
		player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_BLUE)
		Smithing.addSkillTries(player, recipe.triesReward)
	else
		-- Failure
		player:sendTextMessage(MESSAGE_STATUS_SMALL,
			"You failed to smith " .. recipe.name .. ". The materials were lost.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		Smithing.addSkillTries(player, math.floor(recipe.triesReward / 3))
	end

	return true
end

-- ============================================================================
-- Main Action Handler
-- ============================================================================

-- Exhaustion storage key for crafting stations
local CRAFTING_EXHAUST_KEY = 40111
local CRAFTING_EXHAUST_SECONDS = 3

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Crafting then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "Crafting system is not available.")
		return true
	end

	-- Exhaustion check (anti-spam)
	local now = os.time()
	if player:getStorageValue(CRAFTING_EXHAUST_KEY) > now then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You must wait before doing this again.")
		return true
	end

	local craftType = stationTypes[item.itemid]
	if not craftType then
		return false
	end

	local result = false
	if craftType == "cooking" then
		result = handleCooking(player, item)
	elseif craftType == "smithing" then
		result = handleSmithing(player, item)
	end

	-- Set exhaustion after successful use
	player:setStorageValue(CRAFTING_EXHAUST_KEY, now + CRAFTING_EXHAUST_SECONDS)

	return result
end
