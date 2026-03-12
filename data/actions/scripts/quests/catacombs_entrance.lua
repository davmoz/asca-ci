-- Catacombs Entrance Gate
local STORAGE_CATACOMBS_ACCESS = 50800

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(STORAGE_CATACOMBS_ACCESS) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The gate opens with a ghostly creak. You may pass.")
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		return true
	end
	
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The gate is sealed by spectral energy. Seek the Spectral Scholar for access.")
	return true
end
