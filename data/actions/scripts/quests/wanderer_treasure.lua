-- Wanderer's Hidden Treasure (behind waterfall)
local STORAGE_WANDERER_QUEST = 50700
local STORAGE_WANDERER_TREASURE = 50702

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(STORAGE_WANDERER_TREASURE) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already found the wanderer's treasure.")
		return true
	end
	
	if player:getStorageValue(STORAGE_WANDERER_QUEST) >= 3 then
		player:addItem(2160, 5) -- 5 crystal coins
		player:addItem(2195, 1) -- boots of haste
		player:addExperience(30000, true)
		player:setStorageValue(STORAGE_WANDERER_TREASURE, 1)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found the wanderer's hidden treasure! Boots of haste, 5 crystal coins, and 30000 experience!")
		return true
	end
	
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You see a hidden alcove behind the waterfall. Something is here, but you cannot reach it yet. Speak to The Wanderer.")
	return true
end
