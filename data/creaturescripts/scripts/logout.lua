function onLogout(player)
	local playerId = player:getId()
	if nextUseStaminaTime and nextUseStaminaTime[playerId] then
		nextUseStaminaTime[playerId] = nil
	end
	return true
end
