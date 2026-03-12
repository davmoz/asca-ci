-- ============================================================================
-- Smelting Action Script - Phase 2.4
-- ============================================================================
-- Use ore on a furnace to smelt it into bars.
-- The script finds the best matching recipe based on the ore used and
-- the player's inventory. Requires mining skill for higher-tier bars.
-- Coal is consumed as fuel for recipes that require it.
-- ============================================================================

local SMELT_EFFECT_SUCCESS = CONST_ME_FIREAREA
local SMELT_EFFECT_FAIL    = CONST_ME_SMOKE
local SMELT_COOLDOWN       = 2000 -- ms

local SMELTING_COOLDOWN_STORAGE = 45103

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- The ore (item) is used on a furnace (target)
	if type(target) ~= "userdata" or not target.getId then
		return false
	end

	-- Check if target is a furnace
	if not Mining.isFurnace(target:getId()) then
		return false
	end

	-- Cooldown
	local now = os.mtime and os.mtime() or (os.time() * 1000)
	local lastSmelt = player:getStorageValue(SMELTING_COOLDOWN_STORAGE)
	if lastSmelt > 0 and (now - lastSmelt) < SMELT_COOLDOWN then
		player:sendCancelMessage("You need to wait before smelting again.")
		return true
	end

	local miningLevel = Mining.getSkillLevel(player)
	local usedItemId = item:getId()

	-- Find recipes that use the item the player is holding
	local matchedRecipe = nil
	for _, recipe in ipairs(Mining.SmeltingRecipes) do
		if miningLevel >= recipe.requiredSkill then
			-- Check if the used item is part of this recipe's ingredients
			local usesThisItem = false
			for _, ing in ipairs(recipe.ingredients) do
				if ing[1] == usedItemId then
					usesThisItem = true
					break
				end
			end

			if usesThisItem then
				-- Verify all ingredients are available
				local hasAll = true
				for _, ing in ipairs(recipe.ingredients) do
					if player:getItemCount(ing[1]) < ing[2] then
						hasAll = false
						break
					end
				end
				-- Check coal
				if hasAll and recipe.requireCoal then
					if player:getItemCount(Mining.Items.COAL) < 1 then
						hasAll = false
					end
				end
				if hasAll then
					matchedRecipe = recipe
					break
				end
			end
		end
	end

	if not matchedRecipe then
		-- Check if the item is an ore at all
		local isOre = false
		for _, recipe in ipairs(Mining.SmeltingRecipes) do
			for _, ing in ipairs(recipe.ingredients) do
				if ing[1] == usedItemId then
					isOre = true
					break
				end
			end
			if isOre then break end
		end

		if isOre then
			-- Player has the right idea but is missing something
			local neededLevel = 0
			for _, recipe in ipairs(Mining.SmeltingRecipes) do
				for _, ing in ipairs(recipe.ingredients) do
					if ing[1] == usedItemId then
						if recipe.requiredSkill > miningLevel then
							neededLevel = recipe.requiredSkill
						end
					end
				end
			end

			if neededLevel > 0 then
				player:sendCancelMessage("You need mining level " .. neededLevel ..
					" to smelt this ore.")
			else
				player:sendCancelMessage("You don't have enough materials to smelt anything.")
			end
		else
			player:sendCancelMessage("You can't smelt that.")
		end
		return true
	end

	-- Set cooldown
	player:setStorageValue(SMELTING_COOLDOWN_STORAGE, now)

	-- Consume ingredients
	for _, ing in ipairs(matchedRecipe.ingredients) do
		player:removeItem(ing[1], ing[2])
	end

	-- Consume coal fuel if needed
	if matchedRecipe.requireCoal then
		player:removeItem(Mining.Items.COAL, 1)
	end

	-- Roll for success
	local chance = Mining.getSmeltingChance(matchedRecipe, miningLevel)
	local roll = math.random(1, 100)

	if roll <= chance then
		-- Success
		local bar = player:addItem(matchedRecipe.result[1], matchedRecipe.result[2])
		if bar then
			toPosition:sendMagicEffect(SMELT_EFFECT_SUCCESS)
			player:sendTextMessage(MESSAGE_INFO_DESCR,
				"You smelted " .. matchedRecipe.name .. "! [Mining: " .. miningLevel .. "]")
			Mining.addSkillTries(player, matchedRecipe.triesReward)
		else
			player:sendCancelMessage("You don't have enough room for the bar.")
			-- Refund ingredients on full inventory
			for _, ing in ipairs(matchedRecipe.ingredients) do
				player:addItem(ing[1], ing[2])
			end
			if matchedRecipe.requireCoal then
				player:addItem(Mining.Items.COAL, 1)
			end
		end
	else
		-- Failed: ingredients are lost
		toPosition:sendMagicEffect(SMELT_EFFECT_FAIL)
		player:sendCancelMessage("The smelting failed. The materials were consumed in the process.")
		Mining.addSkillTries(player, math.max(1, math.floor(matchedRecipe.triesReward / 3)))
	end

	return true
end
