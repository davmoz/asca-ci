-- ============================================================================
-- Mining Action Script - Phase 2.4
-- ============================================================================
-- Use a pickaxe on an ore vein (target must have a mining action ID).
-- Pickaxe tiers affect success rate and cooldown.
-- ============================================================================

local MINE_COOLDOWN_DEFAULT = 3000 -- ms
local DEPLETED_EFFECT = CONST_ME_POFF
local MINING_EFFECT   = CONST_ME_BLOCKHIT
local SUCCESS_EFFECT  = CONST_ME_FIREWORK_BLUE
local GEM_EFFECT      = CONST_ME_FIREWORK_YELLOW

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- Validate pickaxe
	local pickaxe = Mining.Pickaxes[item:getId()]
	if not pickaxe then
		return false
	end

	-- Target must be an item with a mining action ID
	if type(target) ~= "userdata" or not target.getActionId then
		player:sendCancelMessage("You can't mine that.")
		return true
	end

	local actionId = target:getActionId()
	local vein = Mining.VeinTypes[actionId]
	if not vein then
		-- Not a mining vein; let default pick behavior handle it
		return false
	end

	-- Check if vein is depleted
	local posKey = Mining.posKey(toPosition)
	local depleted = Mining.DepletedVeins[posKey]
	if depleted then
		player:sendCancelMessage("This ore vein is depleted. It needs time to regenerate.")
		toPosition:sendMagicEffect(DEPLETED_EFFECT)
		return true
	end

	-- Cooldown check (anti-spam)
	local now = os.mtime and os.mtime() or (os.time() * 1000)
	local lastMine = player:getStorageValue(Mining.Storage.lastMineTime)
	if lastMine > 0 and (now - lastMine) < pickaxe.cooldown then
		player:sendCancelMessage("You are mining too fast.")
		return true
	end
	player:setStorageValue(Mining.Storage.lastMineTime, now)

	-- Check mining skill requirement
	local miningLevel = Mining.getSkillLevel(player)
	if miningLevel < vein.minSkill then
		player:sendCancelMessage("You need mining level " .. vein.minSkill .. " to mine this vein.")
		toPosition:sendMagicEffect(DEPLETED_EFFECT)
		return true
	end

	-- Mining effect (sparks)
	toPosition:sendMagicEffect(MINING_EFFECT)

	-- Calculate success
	local chance = Mining.getSuccessChance(miningLevel, pickaxe.bonus)
	local roll = math.random(1, 100)

	if roll > chance then
		-- Failed attempt
		player:sendCancelMessage("You swing your pickaxe but fail to extract any ore.")
		Mining.addSkillTries(player, 1) -- small XP on failure
		return true
	end

	-- Success: roll for ore type from pool
	local ore = Mining.rollOre(vein.pool, miningLevel)
	if not ore then
		player:sendCancelMessage("The vein crumbles but yields nothing useful.")
		Mining.addSkillTries(player, 1)
		return true
	end

	-- Give ore to player
	local oreItem = player:addItem(ore.id, 1)
	if not oreItem then
		player:sendCancelMessage("You don't have enough room to carry more ore.")
		return true
	end

	toPosition:sendMagicEffect(SUCCESS_EFFECT)
	player:sendTextMessage(MESSAGE_INFO_DESCR,
		"You mined " .. ore.name .. "! [Mining: " .. miningLevel .. "]")

	-- Award mining XP
	Mining.addSkillTries(player, ore.tries)

	-- Bonus gem chance
	for _, gem in ipairs(Mining.GemDrops) do
		if math.random() * 100 < gem.chance then
			local gemItem = player:addItem(gem.id, 1)
			if gemItem then
				toPosition:sendMagicEffect(GEM_EFFECT)
				player:sendTextMessage(MESSAGE_INFO_DESCR,
					"You also found " .. gem.name .. "!")
			end
			break -- only one gem per mine action
		end
	end

	-- Track vein depletion
	local uses = target:getCustomAttribute("mining_uses") or 0
	uses = uses + 1

	if uses >= vein.depleteAfter then
		-- Deplete the vein
		Mining.DepletedVeins[posKey] = true
		target:setCustomAttribute("mining_uses", 0)
		toPosition:sendMagicEffect(DEPLETED_EFFECT)
		player:sendTextMessage(MESSAGE_INFO_DESCR, "The ore vein has been depleted.")

		-- Schedule respawn
		addEvent(function(key)
			Mining.respawnVein(key)
		end, vein.respawnTime * 1000, posKey)
	else
		target:setCustomAttribute("mining_uses", uses)
	end

	return true
end
