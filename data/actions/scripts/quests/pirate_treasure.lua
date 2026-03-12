-- Pirate Buried Treasure
local STORAGE_PIRATE_QUEST = 51000
local STORAGE_PIRATE_TREASURE = 51001

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(STORAGE_PIRATE_TREASURE) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already dug up this treasure.")
		return true
	end
	
	if player:getStorageValue(STORAGE_PIRATE_QUEST) >= 1 then
		player:addItem(2152, 30) -- 30 platinum coins
		player:addItem(2159, 5) -- 5 scarab coins
		player:addExperience(10000, true)
		player:setStorageValue(STORAGE_PIRATE_TREASURE, 1)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Yarr! Pirate treasure! 30 platinum coins, 5 scarab coins, and 10000 experience!")
		return true
	end
	
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You see a spot that looks like buried treasure. Talk to Blackbeard first.")
	return true
end
