-- ============================================================================
-- Smithing Action Script - Phase 2.5
-- ============================================================================
-- Use a metal bar on an anvil to forge equipment.
-- The script finds the best matching recipe based on the bar used and
-- the player's inventory. Requires smithing skill for higher-tier gear.
-- Quality (basic/fine/superior/masterwork) is determined by skill level.
-- A blacksmith hammer or master hammer must be in the player's inventory.
-- ============================================================================

local SMITH_EFFECT_SUCCESS = CONST_ME_FIREAREA
local SMITH_EFFECT_FAIL    = CONST_ME_HITAREA
local SMITH_EFFECT_QUALITY = CONST_ME_FIREWORK_YELLOW
local SMITH_COOLDOWN       = 2500 -- ms

local SMITHING_COOLDOWN_STORAGE = 45203

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- The bar (item) is used on an anvil (target)
	if type(target) ~= "userdata" or not target.getId then
		return false
	end

	-- Check if target is an anvil
	if not Smithing.isAnvil(target:getId()) then
		return false
	end

	-- Cooldown
	local now = os.mtime and os.mtime() or (os.time() * 1000)
	local lastSmith = player:getStorageValue(SMITHING_COOLDOWN_STORAGE)
	if lastSmith > 0 and (now - lastSmith) < SMITH_COOLDOWN then
		player:sendCancelMessage("You need to wait before forging again.")
		return true
	end

	-- Check the player has a hammer
	local hammerBonus = 0
	local hasHammer = false
	for hammerId, hammerData in pairs(Smithing.Hammers) do
		if player:getItemCount(hammerId) > 0 then
			hasHammer = true
			if hammerData.bonus > hammerBonus then
				hammerBonus = hammerData.bonus
			end
		end
	end

	if not hasHammer then
		player:sendCancelMessage("You need a blacksmith hammer to forge equipment.")
		return true
	end

	local smithingLevel = Smithing.getSkillLevel(player)
	local usedItemId = item:getId()

	-- Check if the used item is a bar
	if not Smithing.isBar(usedItemId) then
		player:sendCancelMessage("You can't forge anything with that.")
		return true
	end

	-- Find the best recipe the player can craft with this bar
	local matchedRecipe = Smithing.findBestRecipe(player, smithingLevel, usedItemId)

	if not matchedRecipe then
		-- Determine why: skill too low or missing materials?
		local allRecipesForBar = Smithing.RecipesByBar[usedItemId] or {}
		local neededLevel = 0

		for _, recipe in ipairs(allRecipesForBar) do
			if recipe.requiredSkill > smithingLevel and recipe.requiredSkill > neededLevel then
				neededLevel = recipe.requiredSkill
			end
		end

		if neededLevel > 0 then
			player:sendCancelMessage("You need smithing level " .. neededLevel ..
				" to forge with these bars. Your level is " .. smithingLevel .. ".")
		else
			player:sendCancelMessage("You don't have enough bars to forge anything. " ..
				"Check your inventory for the required materials.")
		end
		return true
	end

	-- Set cooldown
	player:setStorageValue(SMITHING_COOLDOWN_STORAGE, now)

	-- Consume ingredients
	for _, ing in ipairs(matchedRecipe.ingredients) do
		player:removeItem(ing[1], ing[2])
	end

	-- Anvil strike animation
	toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)

	-- Roll for success
	local chance = Smithing.getSuccessChance(matchedRecipe, smithingLevel, hammerBonus)
	local roll = math.random(1, 100)

	if roll <= chance then
		-- Success: determine quality
		local quality = Smithing.rollQuality(smithingLevel, matchedRecipe.requiredSkill, hammerBonus)
		local qualityName = Smithing.QualityNames[quality]
		local qualityPrefix = Smithing.QualityColors[quality]

		-- Give crafted item
		local craftedItem = player:addItem(matchedRecipe.result, 1)
		if craftedItem then
			-- Stamp quality as a custom attribute
			craftedItem:setCustomAttribute("smithing_quality", quality)
			craftedItem:setCustomAttribute("crafted_by", player:getName())

			-- Update item description with quality
			if quality > Smithing.Quality.BASIC then
				local desc = craftedItem:getSpecialDescription() or ""
				if desc ~= "" then
					desc = desc .. "\n"
				end
				desc = desc .. "[" .. qualityName .. " Quality - Forged by " .. player:getName() .. "]"
				craftedItem:setSpecialDescription(desc)
			end

			toPosition:sendMagicEffect(SMITH_EFFECT_SUCCESS)

			-- Extra fireworks for superior/masterwork
			if quality >= Smithing.Quality.SUPERIOR then
				toPosition:sendMagicEffect(SMITH_EFFECT_QUALITY)
			end

			local qualityMsg = ""
			if quality > Smithing.Quality.BASIC then
				qualityMsg = " (" .. qualityName .. " quality!)"
			end

			player:sendTextMessage(MESSAGE_INFO_DESCR,
				"You forged " .. qualityPrefix .. matchedRecipe.name .. qualityMsg ..
				"! [Smithing: " .. smithingLevel .. "]")

			Smithing.addSkillTries(player, matchedRecipe.triesReward)
		else
			player:sendCancelMessage("You don't have enough room for the forged item.")
			-- Refund ingredients
			for _, ing in ipairs(matchedRecipe.ingredients) do
				player:addItem(ing[1], ing[2])
			end
		end
	else
		-- Failed: materials are lost
		toPosition:sendMagicEffect(SMITH_EFFECT_FAIL)
		player:sendCancelMessage(
			"The forging failed! The bars were ruined in the process. [Smithing: " ..
			smithingLevel .. "]")
		-- Award partial XP on failure
		Smithing.addSkillTries(player, math.max(1, math.floor(matchedRecipe.triesReward / 3)))
	end

	return true
end
