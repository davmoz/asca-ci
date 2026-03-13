-- Loot Attributes Creature Script (Phase 3)
-- Hooks into monster death to generate random attributes on equipment drops
-- and roll for legendary item drops from elite monsters.

local lootAttributes = CreatureEvent("LootAttributes")

function lootAttributes.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	if not creature or not creature:isMonster() then
		return true
	end

	if not corpse or not corpse:isContainer() then
		return true
	end

	local monster = creature
	local mType = monster:getType()
	if not mType then
		return true
	end

	-- Calculate monster level from max health
	local monsterLevel = math.max(1, math.floor(mType:getMaxHealth() / 10))

	-- If elite, double the effective level for attribute generation
	local isElite = LegendaryItems and LegendaryItems.isElite(monster)
	if isElite then
		monsterLevel = monsterLevel * 2
	end

	-- Process all items in the corpse for random attributes
	local items = corpse:getItems()
	if items then
		for _, item in pairs(items) do
			if item then
				local it = ItemType(item:getId())
				if it then
					local weaponType = it:getWeaponType()
					local isEquipment = false

					-- Check if item is equipment
					if weaponType ~= WEAPON_NONE and weaponType ~= WEAPON_AMMO then
						isEquipment = true
					elseif it:getArmor() > 0 then
						isEquipment = true
					elseif it:getDefense() > 0 then
						isEquipment = true
					end

					-- Skip legendary items - they have fixed attributes
					if LegendaryItems and LegendaryItems.isLegendary(item) then
						isEquipment = false
					end

					if isEquipment and ItemAttributes then
						ItemAttributes.generateAttributes(item, monsterLevel)
					end
				end
			end
		end
	end

	-- Elite monsters can drop legendary items
	if isElite and LegendaryItems then
		local legendaryItemId = LegendaryItems.rollLegendaryDrop(monster)
		if legendaryItemId then
			local legendaryItem = LegendaryItems.addLegendaryToCorpse(corpse, legendaryItemId)
			if legendaryItem then
				-- Announce legendary drop
				local killerPlayer = killer
				if killerPlayer and killerPlayer:isPlayer() then
					local legendaryData = LegendaryItems.items[legendaryItemId]
					if legendaryData then
						-- Broadcast to server
						local message = killerPlayer:getName() .. " has obtained the legendary item: " ..
							legendaryData.name .. "!"
						Game.broadcastMessage(message, MESSAGE_STATUS_WARNING)
					end
				end
			end
		end
	end

	return true
end

lootAttributes:register()

-- Also register for monster spawn to handle elite conversion
local eliteSpawn = CreatureEvent("EliteMonsterSpawn")

function eliteSpawn.onLogin(player)
	-- Register loot attributes event for all players
	-- so their kills trigger attribute generation
	player:registerEvent("LootAttributes")
	return true
end

eliteSpawn:register()
