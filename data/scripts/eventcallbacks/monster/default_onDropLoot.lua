local ec = EventCallback

ec.onDropLoot = function(self, corpse)
	if configManager.getNumber(configKeys.RATE_LOOT) == 0 then
		return
	end

	local player = Player(corpse:getCorpseOwner())
	local mType = self:getType()
	if not player or player:getStamina() > 840 then
		local monsterLoot = mType:getLoot()
		for i = 1, #monsterLoot do
			local item = corpse:createLootItem(monsterLoot[i])
			if not item then
				print('[Warning] DropLoot:', 'Could not add loot item to corpse.')
			end
		end

		-- Phase 3: Generate random attributes on equipment loot
		if ItemAttributes then
			ItemAttributes.onLootDrop(self, corpse)
		end

		-- Phase 3: Roll for legendary drops from elite monsters
		if LegendaryItems and LegendaryItems.isElite(self) then
			local legendaryItemId = LegendaryItems.rollLegendaryDrop(self)
			if legendaryItemId then
				local legendaryItem = LegendaryItems.addLegendaryToCorpse(corpse, legendaryItemId)
				if legendaryItem and player then
					local legendaryData = LegendaryItems.items[legendaryItemId]
					if legendaryData then
						Game.broadcastMessage(
							player:getName() .. " has obtained the legendary item: " .. legendaryData.name .. "!",
							MESSAGE_STATUS_WARNING
						)
					end
				end
			end
		end

		if player then
			local text = ("Loot of %s: %s"):format(mType:getNameDescription(), corpse:getContentDescription())
			local party = player:getParty()
			if party then
				party:broadcastPartyLoot(text)
			else
				player:sendTextMessage(MESSAGE_LOOT, text)
			end
		end
	else
		local text = ("Loot of %s: nothing (due to low stamina)"):format(mType:getNameDescription())
		local party = player:getParty()
		if party then
			party:broadcastPartyLoot(text)
		else
			player:sendTextMessage(MESSAGE_LOOT, text)
		end
	end
end
