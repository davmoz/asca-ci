-- Dragon Quest Treasure Chest
local STORAGE_DRAGON_QUEST = 50900
local STORAGE_DRAGON_REWARD = 50901

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(STORAGE_DRAGON_REWARD) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already looted the dragon's hoard.")
		return true
	end
	
	if player:getStorageValue(STORAGE_DRAGON_QUEST) >= 2 then
		player:addItem(2160, 3) -- 3 crystal coins
		player:addItem(2432, 1) -- fire axe
		player:addExperience(15000, true)
		player:setStorageValue(STORAGE_DRAGON_REWARD, 1)
		player:getPosition():sendMagicEffect(CONST_ME_FIREAREA)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You plundered the dragon's hoard! Fire axe, 3 crystal coins, and 15000 experience!")
		return true
	end
	
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The dragon guards this treasure. Complete the dragon quest first.")
	return true
end
