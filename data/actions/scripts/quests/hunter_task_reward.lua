-- Hunter Task Reward Chest
-- Players who complete hunter tasks from Artemis can open this chest for bonus rewards
local STORAGE_TASK = 50300
local STORAGE_TASK_COUNT = 50301

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local taskState = player:getStorageValue(STORAGE_TASK)
	local taskCount = player:getStorageValue(STORAGE_TASK_COUNT)
	
	if taskState > 0 and taskCount >= 10 then
		player:addItem(2152, 5) -- 5 platinum coins
		player:addExperience(3000, true)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found a hunter's cache! 5 platinum coins and 3000 experience!")
		return true
	end
	
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This chest is sealed. Complete hunter tasks to unlock it.")
	return true
end
