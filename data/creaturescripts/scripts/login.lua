nextUseStaminaTime = nextUseStaminaTime or {}

function onLogin(player)
	local loginStr = "Welcome to " .. configManager.getString(configKeys.SERVER_NAME) .. "!"
	if player:getLastLoginSaved() <= 0 then
		loginStr = loginStr .. " Please choose your outfit."
		player:sendOutfitWindow()
	else
		if loginStr ~= "" then
			player:sendTextMessage(MESSAGE_STATUS_DEFAULT, loginStr)
		end

		loginStr = string.format("Your last visit was on %s.", os.date("%a %b %d %X %Y", player:getLastLoginSaved()))
	end
	player:sendTextMessage(MESSAGE_STATUS_DEFAULT, loginStr)

	-- Stamina
	nextUseStaminaTime[player.uid] = 0

	-- Promotion
	local vocation = player:getVocation()
	local promotion = vocation:getPromotion()
	if player:isPremium() then
		local value = player:getStorageValue(PlayerStorageKeys.promotion)
		if not promotion and value ~= 1 then
			player:setStorageValue(PlayerStorageKeys.promotion, 1)
		elseif value == 1 then
			player:setVocation(promotion)
		end
	elseif not promotion then
		player:setVocation(vocation:getDemotion())
	end

	-- Events
	player:registerEvent("PlayerDeath")
	player:registerEvent("DropLoot")
	player:registerEvent("LootAttributes")
	player:registerEvent("KillTracker")

	-- Check level-based achievements on login
	if AchievementSystem then
		AchievementSystem.checkLevelAchievements(player)
	end

	-- Daily rewards check
	if DailyRewards and DailyRewards.onLogin then
		DailyRewards.onLogin(player)
	end

	-- Register PvP events
	player:registerEvent("PvPKill")
	player:registerEvent("PvPDeath")
	player:registerEvent("TaskKill")
	player:registerEvent("AchievementCheck")

	-- Check expired cooking buffs
	if Cooking and Cooking.isBuffActive then
		if not Cooking.isBuffActive(player) then
			Cooking.removeBuff(player)
		end
	end

	return true
end
