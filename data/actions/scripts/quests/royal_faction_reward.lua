-- Royal Faction Reward Chest
local STORAGE_ROYAL_QUEST = 50400
local STORAGE_ROYAL_REWARD = 50402

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(STORAGE_ROYAL_REWARD) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already claimed this reward.")
		return true
	end
	
	if player:getStorageValue(STORAGE_ROYAL_QUEST) >= 2 then
		player:addItem(2476, 1) -- knight armor
		player:addExperience(5000, true)
		player:setStorageValue(STORAGE_ROYAL_REWARD, 1)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The crown rewards your loyalty! You received a knight armor and 5000 experience!")
		return true
	end
	
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This royal chest is sealed. Complete royal quests to unlock it.")
	return true
end
