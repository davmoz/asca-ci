-- Shadow Faction Reward Chest
local STORAGE_SHADOW_QUEST = 50500
local STORAGE_SHADOW_REWARD = 50502

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(STORAGE_SHADOW_REWARD) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already claimed this reward.")
		return true
	end
	
	if player:getStorageValue(STORAGE_SHADOW_QUEST) >= 2 then
		player:addItem(2165, 1) -- stealth ring
		player:addItem(2152, 15) -- 15 platinum
		player:addExperience(8000, true)
		player:setStorageValue(STORAGE_SHADOW_REWARD, 1)
		player:getPosition():sendMagicEffect(CONST_ME_MORTAREA)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The shadows reward your cunning! You received a stealth ring, 15 platinum, and 8000 experience!")
		return true
	end
	
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This shadowy chest is sealed. Complete shadow quests to unlock it.")
	return true
end
