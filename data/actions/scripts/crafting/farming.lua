-- ============================================================================
-- Farming Action Script - Phase 2.2
-- ============================================================================
-- Handles three farming actions:
--   1. Plant seeds: Use seeds on a planting pot or farm plot
--   2. Water crops: Use a water container on a planted crop
--   3. Harvest crops: Use a garden hoe on a ready crop, or use bare hand
--
-- Seeds are used on the plot/pot. The plot transforms through visual stages
-- (planted -> sprouting -> growing -> ready) on a timer. Watering a crop
-- increases yield by 50% and speeds growth by 25%. Harvesting a ready crop
-- yields the crop item(s) and awards farming skill XP.
-- ============================================================================

local PLANT_COOLDOWN  = 2000  -- ms between planting actions
local WATER_COOLDOWN  = 3000  -- ms between watering actions

-- Effects
local PLANT_EFFECT    = CONST_ME_MAGIC_GREEN
local WATER_EFFECT    = CONST_ME_LOSEENERGY
local HARVEST_EFFECT  = CONST_ME_FIREWORK_BLUE
local FAIL_EFFECT     = CONST_ME_POFF
local BONUS_EFFECT    = CONST_ME_FIREWORK_YELLOW

-- ============================================================================
-- Plant Seeds
-- ============================================================================
local function plantSeed(player, seedItem, target, toPosition)
	local seedId = seedItem:getId()
	local seed = Farming.Seeds[seedId]
	if not seed then
		return false
	end

	-- Check if target is a plantable surface
	if not Farming.isPlantable(target) then
		player:sendCancelMessage("You can only plant seeds in a planting pot or farm plot.")
		return true
	end

	-- Check if plot is already occupied
	if Farming.isPlotOccupied(target) then
		player:sendCancelMessage("Something is already growing here.")
		return true
	end

	-- Cooldown check
	local now = os.mtime and os.mtime() or (os.time() * 1000)
	local lastTime = player:getStorageValue(Farming.Storage.lastFarmTime)
	if lastTime > 0 and (now - lastTime) < PLANT_COOLDOWN then
		player:sendCancelMessage("You need to wait before planting again.")
		return true
	end
	player:setStorageValue(Farming.Storage.lastFarmTime, now)

	-- Check farming skill requirement
	local farmLevel = Farming.getSkillLevel(player)
	if farmLevel < seed.minSkill then
		player:sendCancelMessage("You need farming level " .. seed.minSkill ..
			" to plant " .. seed.name .. " seeds.")
		toPosition:sendMagicEffect(FAIL_EFFECT)
		return true
	end

	-- Roll for planting success
	local chance = Farming.getPlantingChance(farmLevel, seed.rarity)
	local roll = math.random(1, 100)

	if roll > chance then
		-- Failed planting: seed consumed, small XP
		seedItem:remove(1)
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"[Farming] The " .. seed.name .. " seeds failed to take root.")
		toPosition:sendMagicEffect(FAIL_EFFECT)
		Farming.addSkillTries(player, 1)
		return true
	end

	-- Success: plant the seed
	seedItem:remove(1)

	-- Store crop data on the plot item
	target:setCustomAttribute("farm_stage", Farming.STAGE_PLANTED)
	target:setCustomAttribute("farm_seed_id", seedId)
	target:setCustomAttribute("farm_plant_time", os.time())
	target:setCustomAttribute("farm_stage_time", os.time())
	target:setCustomAttribute("farm_watered", 0)
	target:setCustomAttribute("farm_owner", player:getGuid())

	-- Store location action ID for bonus calculations
	local locActionId = target:getActionId()
	if locActionId > 0 then
		target:setCustomAttribute("farm_location_aid", locActionId)
	end

	-- Transform to planted visual
	local plantedItemId = Farming.StageItems[Farming.STAGE_PLANTED]
	if plantedItemId then
		target:transform(plantedItemId)
	end

	-- Track this active plot
	local posKey = Farming.posKey(toPosition)
	Farming.ActivePlots[posKey] = {
		seedId = seedId,
		plantTime = os.time(),
		owner = player:getGuid(),
	}

	-- Schedule first growth stage transition
	local watered = false
	local growthTime = Farming.getGrowthTime(seed, watered)
	growthTime = Farming.applySeasonGrowthTime(growthTime)

	-- Apply location modifier
	local locBonus = Farming.getLocationBonus(locActionId)
	if locBonus then
		growthTime = math.floor(growthTime * locBonus.growthMultiplier)
	end

	addEvent(Farming.advanceGrowth, growthTime * 1000,
		{x = toPosition.x, y = toPosition.y, z = toPosition.z})

	-- Feedback
	toPosition:sendMagicEffect(PLANT_EFFECT)
	player:sendTextMessage(MESSAGE_INFO_DESCR,
		"[Farming] You planted " .. seed.name .. " seeds. " ..
		"Growth time: ~" .. math.floor(growthTime / 60) .. " minutes per stage. " ..
		"Water the crop for faster growth and better yield!")
	player:say("*plants seeds*", TALKTYPE_MONSTER_SAY)

	-- Award small XP for planting
	Farming.addSkillTries(player, math.max(1, math.floor(seed.skillTries / 3)))

	-- Show current skill info
	local skillLevel = Farming.getSkillLevel(player)
	local skillTries = Farming.getSkillTries(player)
	local nextLevelTries = Farming.getTriesForLevel(skillLevel + 1)
	player:sendTextMessage(MESSAGE_INFO_DESCR,
		"[Farming] Skill: " .. skillLevel ..
		" (" .. skillTries .. "/" .. nextLevelTries .. " to next level)")

	return true
end

-- ============================================================================
-- Water Crops
-- ============================================================================
local function waterCrop(player, waterItem, target, toPosition)
	-- Check if target has a growing crop
	local stage = target:getCustomAttribute("farm_stage") or 0
	if stage < Farming.STAGE_PLANTED or stage >= Farming.STAGE_READY then
		if stage >= Farming.STAGE_READY then
			player:sendCancelMessage("This crop is ready to harvest, not water!")
		else
			player:sendCancelMessage("There is nothing growing here to water.")
		end
		return true
	end

	-- Check if already watered
	local watered = target:getCustomAttribute("farm_watered") or 0
	if watered == 1 then
		player:sendCancelMessage("This crop has already been watered.")
		return true
	end

	-- Cooldown check
	local now = os.mtime and os.mtime() or (os.time() * 1000)
	local lastTime = player:getStorageValue(Farming.Storage.lastFarmTime)
	if lastTime > 0 and (now - lastTime) < WATER_COOLDOWN then
		player:sendCancelMessage("You need to wait before watering again.")
		return true
	end
	player:setStorageValue(Farming.Storage.lastFarmTime, now)

	-- Mark as watered
	target:setCustomAttribute("farm_watered", 1)

	-- Consume water from the watering can or flask
	local waterItemId = waterItem:getId()
	if waterItemId == Farming.Items.WATERING_CAN then
		-- Watering can has charges (durability) -- reduce by 1 use
		-- If no charge system, watering can is not consumed
	elseif waterItemId == Farming.Items.WATER_FLASK then
		waterItem:remove(1)
	else
		-- Other fluid containers: remove 1
		waterItem:remove(1)
	end

	-- Feedback
	toPosition:sendMagicEffect(WATER_EFFECT)
	local seedId = target:getCustomAttribute("farm_seed_id")
	local seed = Farming.Seeds[seedId]
	local seedName = seed and seed.name or "crop"

	player:sendTextMessage(MESSAGE_INFO_DESCR,
		"[Farming] You watered the " .. seedName .. ". " ..
		"It will grow 25% faster and yield 50% more at harvest!")
	player:say("*waters the crop*", TALKTYPE_MONSTER_SAY)

	-- Small XP for tending
	Farming.addSkillTries(player, 1)

	return true
end

-- ============================================================================
-- Harvest Crops
-- ============================================================================
local function harvestCrop(player, item, target, toPosition)
	-- Determine which item is the crop plot
	local plotItem = nil
	local plotPos = nil

	-- The player might be using a hoe on the plot, or using bare hand on the plot
	if target and target.getCustomAttribute then
		local stage = target:getCustomAttribute("farm_stage") or 0
		if stage > 0 then
			plotItem = target
			plotPos = toPosition
		end
	end

	-- Also check if the item itself is the plot (right-click on it directly)
	if not plotItem and item.getCustomAttribute then
		local stage = item:getCustomAttribute("farm_stage") or 0
		if stage > 0 then
			plotItem = item
			plotPos = item:getPosition()
		end
	end

	if not plotItem then
		return false
	end

	local stage = plotItem:getCustomAttribute("farm_stage") or 0

	-- Show growth status if not ready
	if stage < Farming.STAGE_READY then
		local seedId = plotItem:getCustomAttribute("farm_seed_id")
		local seed = Farming.Seeds[seedId]
		local stageName = Farming.STAGE_NAMES[stage] or "unknown"
		local seedName = seed and seed.name or "crop"
		local watered = (plotItem:getCustomAttribute("farm_watered") or 0) == 1

		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"[Farming] " .. seedName .. " - Stage: " .. stageName ..
			(watered and " (watered)" or " (not watered)") ..
			". Not ready for harvest yet.")
		return true
	end

	-- Crop is ready to harvest!
	local seedId = plotItem:getCustomAttribute("farm_seed_id")
	local seed = Farming.Seeds[seedId]
	if not seed then
		player:sendCancelMessage("Something went wrong with this crop.")
		return true
	end

	local farmLevel = Farming.getSkillLevel(player)
	local watered = (plotItem:getCustomAttribute("farm_watered") or 0) == 1

	-- Calculate yield
	local yield = Farming.calculateYield(seed, farmLevel, watered)
	yield = Farming.applySeasonYield(yield)

	-- Apply location modifier
	local locActionId = plotItem:getCustomAttribute("farm_location_aid") or 0
	local locBonus = Farming.getLocationBonus(locActionId)
	if locBonus then
		yield = math.max(1, math.floor(yield * locBonus.yieldMultiplier))
	end

	-- Give crops to player
	local cropItem = player:addItem(seed.cropId, yield)
	if not cropItem then
		player:sendCancelMessage("You don't have enough room to carry the harvest.")
		return true
	end

	-- Award farming XP
	Farming.addSkillTries(player, seed.skillTries)

	-- Bonus harvest chance (extra crop)
	local bonusChance = Farming.getHarvestBonusChance(farmLevel, seed.minSkill)
	local bonusYield = 0
	if math.random(1, 100) <= bonusChance then
		bonusYield = 1
		local bonusItem = player:addItem(seed.cropId, bonusYield)
		if bonusItem then
			plotPos:sendMagicEffect(BONUS_EFFECT)
			player:sendTextMessage(MESSAGE_INFO_DESCR,
				"[Farming] Bonus harvest! You got an extra " .. seed.name .. "!")
			Farming.addSkillTries(player, math.floor(seed.skillTries / 2))
		end
	end

	-- Reset the plot
	plotItem:setCustomAttribute("farm_stage", 0)
	plotItem:setCustomAttribute("farm_seed_id", 0)
	plotItem:setCustomAttribute("farm_plant_time", 0)
	plotItem:setCustomAttribute("farm_stage_time", 0)
	plotItem:setCustomAttribute("farm_watered", 0)
	plotItem:setCustomAttribute("farm_owner", 0)
	plotItem:setCustomAttribute("farm_location_aid", 0)

	-- Transform back to empty plot
	plotItem:transform(Farming.Items.FARM_PLOT_EMPTY)

	-- Clean up tracking
	local posKey = Farming.posKey(plotPos)
	Farming.ActivePlots[posKey] = nil

	-- Feedback
	plotPos:sendMagicEffect(HARVEST_EFFECT)
	local totalYield = yield + bonusYield
	local seasonName = ({"Winter", "Spring", "Summer", "Autumn"})[Farming.getCurrentSeason()] or "Unknown"
	player:sendTextMessage(MESSAGE_INFO_DESCR,
		"[Farming] You harvested " .. totalYield .. "x " .. seed.name ..
		"! (Season: " .. seasonName ..
		(watered and ", Watered" or "") ..
		(locBonus and ", " .. locBonus.name or "") .. ")")
	player:say("*harvests crops*", TALKTYPE_MONSTER_SAY)

	-- Show skill progress
	local skillLevel = Farming.getSkillLevel(player)
	local skillTries = Farming.getSkillTries(player)
	local nextLevelTries = Farming.getTriesForLevel(skillLevel + 1)
	player:sendTextMessage(MESSAGE_INFO_DESCR,
		"[Farming] Skill: " .. skillLevel ..
		" (" .. skillTries .. "/" .. nextLevelTries .. " to next level)")

	return true
end

-- ============================================================================
-- Main Action Handler
-- ============================================================================
-- This handler is triggered when:
--   - A seed item is used (player uses seed on target)
--   - A water container is used on a crop
--   - A garden hoe is used on a crop
--   - A farm plot or planting pot is used directly (to check/harvest)

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local itemId = item:getId()

	-- Case 1: Player uses a seed on a target (planting)
	if Farming.isSeed(itemId) then
		if target and target.getCustomAttribute then
			return plantSeed(player, item, target, toPosition)
		else
			player:sendCancelMessage("You need to use the seeds on a planting pot or farm plot.")
			return true
		end
	end

	-- Case 2: Player uses a water container on a target (watering)
	if Farming.isWaterContainer(itemId) then
		if target and target.getCustomAttribute then
			local stage = target:getCustomAttribute("farm_stage") or 0
			if stage > 0 then
				return waterCrop(player, item, target, toPosition)
			end
		end
		-- Not a crop target; let default fluid behavior handle it
		return false
	end

	-- Case 3: Player uses garden hoe on a target (harvesting/checking)
	if itemId == Farming.Items.GARDEN_HOE then
		if target and target.getCustomAttribute then
			return harvestCrop(player, item, target, toPosition)
		end
		player:sendCancelMessage("Use the garden hoe on a farm plot or planting pot.")
		return true
	end

	-- Case 4: Player right-clicks a farm plot or planting pot directly
	-- Check if the item itself or the target is a plot with a crop
	if item.getCustomAttribute then
		local stage = item:getCustomAttribute("farm_stage") or 0
		if stage > 0 then
			return harvestCrop(player, item, nil, item:getPosition())
		end
	end

	if target and target.getCustomAttribute then
		local stage = target:getCustomAttribute("farm_stage") or 0
		if stage > 0 then
			return harvestCrop(player, item, target, toPosition)
		end
	end

	return false
end
