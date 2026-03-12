-- Arena Champion Reward
local STORAGE_ARENA_WINS = 51200
local STORAGE_ARENA_CHAMPION = 51201

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(STORAGE_ARENA_CHAMPION) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already claimed the arena champion reward.")
		return true
	end
	
	local wins = player:getStorageValue(STORAGE_ARENA_WINS)
	if wins >= 10 then
		player:addItem(2391, 1) -- war hammer
		player:addItem(2160, 2) -- 2 crystal coins
		player:addExperience(20000, true)
		player:setStorageValue(STORAGE_ARENA_CHAMPION, 1)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Arena Champion! War hammer, 2 crystal coins, and 20000 experience! You are a true gladiator!")
		return true
	end
	
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This chest is for arena champions with 10+ victories. Current wins: " .. math.max(0, wins))
	return true
end
