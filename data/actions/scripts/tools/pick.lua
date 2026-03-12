function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- Check if target is a mining ore vein (Phase 2.4)
	if type(target) == "userdata" and target.getActionId then
		local actionId = target:getActionId()
		if Mining and Mining.VeinTypes and Mining.VeinTypes[actionId] then
			-- Delegate to mining system (vanilla pick works as worst-tier pickaxe)
			local pickaxe = Mining.Pickaxes[item:getId()]
			if not pickaxe then
				player:sendCancelMessage("This pick is too crude for proper mining. Try a pickaxe.")
				return true
			end
			-- Re-use the mining script logic inline
			local vein = Mining.VeinTypes[actionId]
			local posKey = Mining.posKey(toPosition)
			if Mining.DepletedVeins[posKey] then
				player:sendCancelMessage("This ore vein is depleted. It needs time to regenerate.")
				toPosition:sendMagicEffect(CONST_ME_POFF)
				return true
			end
			local miningLevel = Mining.getSkillLevel(player)
			if miningLevel < vein.minSkill then
				player:sendCancelMessage("You need mining level " .. vein.minSkill .. " to mine this vein.")
				return true
			end
			toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
			local chance = Mining.getSuccessChance(miningLevel, pickaxe.bonus)
			if math.random(1, 100) > chance then
				player:sendCancelMessage("You swing your pick but fail to extract any ore.")
				Mining.addSkillTries(player, 1)
				return true
			end
			local ore = Mining.rollOre(vein.pool, miningLevel)
			if ore then
				local oreItem = player:addItem(ore.id, 1)
				if oreItem then
					toPosition:sendMagicEffect(CONST_ME_FIREWORK_BLUE)
					player:sendTextMessage(MESSAGE_INFO_DESCR, "You mined " .. ore.name .. "!")
					Mining.addSkillTries(player, ore.tries)
				end
			end
			local uses = (target:getCustomAttribute("mining_uses") or 0) + 1
			if uses >= vein.depleteAfter then
				Mining.DepletedVeins[posKey] = true
				target:setCustomAttribute("mining_uses", 0)
				toPosition:sendMagicEffect(CONST_ME_POFF)
				player:sendTextMessage(MESSAGE_INFO_DESCR, "The ore vein has been depleted.")
				addEvent(function(key) Mining.respawnVein(key) end, vein.respawnTime * 1000, posKey)
			else
				target:setCustomAttribute("mining_uses", uses)
			end
			return true
		end
	end

	-- Default pick behavior (e.g., breaking rocks/walls)
	return onUsePick(player, item, fromPosition, target, toPosition, isHotkey)
end
