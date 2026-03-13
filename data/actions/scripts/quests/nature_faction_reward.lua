-- Nature Faction Reward Chest
local STORAGE_NATURE_QUEST = 50600
local STORAGE_NATURE_REWARD = 50602

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(STORAGE_NATURE_REWARD) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already claimed this reward.")
		return true
	end
	
	if player:getStorageValue(STORAGE_NATURE_QUEST) >= 2 then
		player:addItem(2181, 1) -- terra rod
		player:addExperience(5000, true)
		player:setStorageValue(STORAGE_NATURE_REWARD, 1)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Nature rewards your dedication! You received a terra rod and 5000 experience!")
		return true
	end
	
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This natural chest is sealed. Complete nature quests to unlock it.")
	return true
end
