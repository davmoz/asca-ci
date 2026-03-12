-- Dungeon Boss Reward Chest
local STORAGE_DUNGEON_ACCESS = 51100
local STORAGE_DUNGEON_BOSS = 51102

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(STORAGE_DUNGEON_BOSS) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already claimed this dungeon reward.")
		return true
	end
	
	if player:getStorageValue(STORAGE_DUNGEON_ACCESS) >= 1 then
		player:addItem(2472, 1) -- magic plate armor
		player:addItem(2160, 5) -- 5 crystal coins
		player:addExperience(50000, true)
		player:setStorageValue(STORAGE_DUNGEON_BOSS, 1)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The dungeon boss is defeated! Magic plate armor, 5 crystal coins, and 50000 experience!")
		return true
	end
	
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This chest is locked. You need dungeon access from Karthus.")
	return true
end
