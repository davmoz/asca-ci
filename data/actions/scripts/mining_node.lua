-- ============================================================================
-- Mining Node Action Handler
-- ============================================================================
-- Handles direct interaction with mining node objects on the map.
-- Unlike the main mining.lua (which is triggered by using a pickaxe ON a vein),
-- this script handles using the ore node directly (right-click on node).
-- It checks the player's inventory for a pickaxe and delegates to the
-- Mining system for ore rolls, skill progression, and vein depletion.
-- ============================================================================

-- Mining node item IDs -> ore pool configuration
-- These are decorative rock/ore objects placed on the map
local miningNodes = {
	[8637] = { pool = "copper",     minSkill = 0,   depleteAfter = 5,  respawnTime = 300  },
	[8638] = { pool = "iron",       minSkill = 10,  depleteAfter = 4,  respawnTime = 600  },
	[8639] = { pool = "silver",     minSkill = 25,  depleteAfter = 3,  respawnTime = 900  },
	[8640] = { pool = "gold",       minSkill = 35,  depleteAfter = 3,  respawnTime = 900  },
	[8641] = { pool = "mithril",    minSkill = 50,  depleteAfter = 2,  respawnTime = 1200 },
}

-- Visual effects
local DEPLETED_EFFECT = CONST_ME_POFF
local MINING_EFFECT   = CONST_ME_BLOCKHIT
local SUCCESS_EFFECT  = CONST_ME_FIREWORK_BLUE
local GEM_EFFECT      = CONST_ME_FIREWORK_YELLOW

-- Cooldown storage key (shared with Mining system)
local EXHAUST_STORAGE = 40110

-- ============================================================================
-- Find the best pickaxe in the player's inventory
-- ============================================================================

local function findPickaxe(player)
	if not Mining or not Mining.Pickaxes then
		-- Fallback: check for vanilla pick
		if player:getItemCount(2553) > 0 then
			return 2553, { name = "pick", bonus = -5, cooldown = 3500 }
		end
		return nil, nil
	end

	-- Check pickaxes from best to worst
	local bestPickaxe = nil
	local bestData = nil
	for pickId, pickData in pairs(Mining.Pickaxes) do
		if player:getItemCount(pickId) > 0 then
			if not bestData or pickData.bonus > bestData.bonus then
				bestPickaxe = pickId
				bestData = pickData
			end
		end
	end

	return bestPickaxe, bestData
end

-- ============================================================================
-- Main Action Handler
-- ============================================================================

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Mining then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "Mining system is not available.")
		return true
	end

	local node = miningNodes[item.itemid]
	if not node then
		return false
	end

	-- Check for pickaxe in inventory
	local pickaxeId, pickaxeData = findPickaxe(player)
	if not pickaxeId then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You need a pickaxe to mine.")
		return true
	end

	-- Cooldown check (anti-spam)
	local now = os.mtime and os.mtime() or (os.time() * 1000)
	local cooldown = pickaxeData.cooldown or 3000
	local lastMine = player:getStorageValue(EXHAUST_STORAGE)
	if lastMine > 0 and (now - lastMine) < cooldown then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You are mining too fast.")
		return true
	end
	player:setStorageValue(EXHAUST_STORAGE, now)

	-- Check mining skill requirement
	local miningLevel = Mining.getSkillLevel(player)
	if miningLevel < node.minSkill then
		player:sendTextMessage(MESSAGE_STATUS_SMALL,
			"You need mining level " .. node.minSkill .. " to mine this node.")
		fromPosition:sendMagicEffect(DEPLETED_EFFECT)
		return true
	end

	-- Check if node is depleted
	local posKey = Mining.posKey(fromPosition)
	if Mining.DepletedVeins[posKey] then
		player:sendTextMessage(MESSAGE_STATUS_SMALL,
			"This mining node is depleted. It needs time to regenerate.")
		fromPosition:sendMagicEffect(DEPLETED_EFFECT)
		return true
	end

	-- Mining animation
	fromPosition:sendMagicEffect(MINING_EFFECT)

	-- Calculate success chance
	local chance = Mining.getSuccessChance(miningLevel, pickaxeData.bonus)
	local roll = math.random(1, 100)

	if roll > chance then
		-- Failed attempt
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You failed to mine anything useful.")
		Mining.addSkillTries(player, 1)
		return true
	end

	-- Success: roll for ore type from pool
	local ore = Mining.rollOre(node.pool, miningLevel)
	if not ore then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "The rock crumbles but yields nothing useful.")
		Mining.addSkillTries(player, 1)
		return true
	end

	-- Give ore to player
	local oreItem = player:addItem(ore.id, 1)
	if not oreItem then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You don't have enough room to carry more ore.")
		return true
	end

	fromPosition:sendMagicEffect(SUCCESS_EFFECT)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
		"You mined " .. ore.name .. "! [Mining: " .. miningLevel .. "]")

	-- Award mining skill tries
	Mining.addSkillTries(player, ore.tries)

	-- Bonus gem chance
	for _, gem in ipairs(Mining.GemDrops) do
		if math.random() * 100 < gem.chance then
			local gemItem = player:addItem(gem.id, 1)
			if gemItem then
				fromPosition:sendMagicEffect(GEM_EFFECT)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
					"You also found " .. gem.name .. "!")
			end
			break -- only one gem per mine action
		end
	end

	-- Track node depletion
	local uses = item:getCustomAttribute("mining_uses") or 0
	uses = uses + 1

	if uses >= node.depleteAfter then
		-- Deplete the node
		Mining.DepletedVeins[posKey] = true
		item:setCustomAttribute("mining_uses", 0)
		fromPosition:sendMagicEffect(DEPLETED_EFFECT)
		player:sendTextMessage(MESSAGE_INFO_DESCR, "The mining node has been depleted.")

		-- Schedule respawn
		addEvent(function(key)
			Mining.respawnVein(key)
		end, node.respawnTime * 1000, posKey)
	else
		item:setCustomAttribute("mining_uses", uses)
	end

	return true
end
