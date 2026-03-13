-- ============================================================================
-- Admin Panel Commands (Phase 6.5)
-- ============================================================================
-- /admin           - show admin panel help
-- /economy         - show economy statistics
-- /serverstats     - show server statistics
-- /playerinfo      - detailed player information
-- /teleportall     - teleport all players to position
-- /eventstart      - manually start a seasonal event
-- /eventstop       - stop a seasonal event
-- /raidstart       - manually trigger a raid
-- /craftingstats   - show crafting statistics
-- /taskreset       - reset player task cooldowns
-- /grantachievement - grant achievement to player
-- ============================================================================

function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
		return false
	end

	logCommand(player, words, param)

	if words == "/admin" then
		return handleAdmin(player)
	elseif words == "/economy" then
		return handleEconomy(player)
	elseif words == "/serverstats" then
		return handleServerStats(player)
	elseif words == "/playerinfo" then
		return handlePlayerInfo(player, param)
	elseif words == "/teleportall" then
		return handleTeleportAll(player, param)
	elseif words == "/eventstart" then
		return handleEventStart(player, param)
	elseif words == "/eventstop" then
		return handleEventStop(player, param)
	elseif words == "/raidstart" then
		return handleRaidStart(player, param)
	elseif words == "/craftingstats" then
		return handleCraftingStats(player)
	elseif words == "/taskreset" then
		return handleTaskReset(player, param)
	elseif words == "/grantachievement" then
		return handleGrantAchievement(player, param)
	end

	return false
end

-- ============================================================================
-- /admin - Show admin panel help
-- ============================================================================

function handleAdmin(player)
	local msg = "=== Admin Panel (Phase 6.5) ===\n\n"
	msg = msg .. "-- Server Monitoring --\n"
	msg = msg .. "  /economy - Economy stats (gold, market, wealthy players)\n"
	msg = msg .. "  /serverstats - Server statistics (players, uptime, memory)\n"
	msg = msg .. "  /craftingstats - Crafting system statistics\n\n"
	msg = msg .. "-- Player Management --\n"
	msg = msg .. "  /playerinfo [name] - Detailed player information\n"
	msg = msg .. "  /teleportall [x,y,z] - Teleport all players to position\n"
	msg = msg .. "  /taskreset [name] - Reset player task cooldowns\n"
	msg = msg .. "  /grantachievement [name],[id] - Grant achievement\n\n"
	msg = msg .. "-- Event Management --\n"
	msg = msg .. "  /eventstart [name] - Start a seasonal event\n"
	msg = msg .. "  /eventstop [name] - Stop a seasonal event\n"
	msg = msg .. "  /raidstart [name] - Trigger a raid\n\n"
	msg = msg .. "-- Moderation --\n"
	msg = msg .. "  /warn [name],[reason] - Warn a player\n"
	msg = msg .. "  /mute [name],[minutes] - Mute a player\n"
	msg = msg .. "  /jail [name],[minutes] - Jail a player\n"
	msg = msg .. "  /freeze [name] - Freeze player movement\n"
	msg = msg .. "  /unfreeze [name] - Unfreeze player\n"
	msg = msg .. "  /watchlist [add|remove|show],[name] - Manage watchlist\n"

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end

-- ============================================================================
-- /economy - Show economy statistics
-- ============================================================================

function handleEconomy(player)
	if not ServerMonitor then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Server monitor not loaded.")
		return false
	end

	-- Refresh gold calculation
	ServerMonitor.metrics.economy.totalGoldCirculation = ServerMonitor.calculateTotalGold()
	ServerMonitor.calculateInflation()

	local report = ServerMonitor.getEconomyReport()
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, report)
	return false
end

-- ============================================================================
-- /serverstats - Show server statistics
-- ============================================================================

function handleServerStats(player)
	if not ServerMonitor then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Server monitor not loaded.")
		return false
	end

	local report = ServerMonitor.getServerStatsReport()
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, report)
	return false
end

-- ============================================================================
-- /playerinfo [name] - Detailed player information
-- ============================================================================

function handlePlayerInfo(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /playerinfo [player_name]")
		return false
	end

	local target = Player(param)
	if not target then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player '" .. param .. "' is not online.")
		return false
	end

	local pos = target:getPosition()
	local guild = target:getGuild()
	local guildName = guild and guild:getName() or "None"
	local guildRank = target:getGuildLevel() or 0

	local msg = "=== Player Info: " .. target:getName() .. " ===\n"
	msg = msg .. string.format("Level: %d | Experience: %d\n", target:getLevel(), target:getExperience())
	msg = msg .. string.format("Health: %d/%d | Mana: %d/%d\n",
		target:getHealth(), target:getMaxHealth(), target:getMana(), target:getMaxMana())
	msg = msg .. string.format("Vocation: %s | Soul: %d | Stamina: %d\n",
		target:getVocation():getName(), target:getSoul(), target:getStamina())
	msg = msg .. string.format("Guild: %s (Rank Level: %d)\n", guildName, guildRank)
	msg = msg .. string.format("Position: %d, %d, %d\n", pos.x, pos.y, pos.z)

	-- Skills
	msg = msg .. "\nSkills:\n"
	local skillNames = {
		[SKILL_FIST] = "Fist", [SKILL_CLUB] = "Club", [SKILL_SWORD] = "Sword",
		[SKILL_AXE] = "Axe", [SKILL_DISTANCE] = "Distance", [SKILL_SHIELD] = "Shield",
		[SKILL_FISHING] = "Fishing", [SKILL_MAGLEVEL] = "Magic Level",
	}
	for skillId, skillName in pairs(skillNames) do
		msg = msg .. string.format("  %s: %d\n", skillName, target:getSkillLevel(skillId))
	end

	-- Wealth
	local gold = target:getMoney()
	local bank = target:getBankBalance()
	msg = msg .. string.format("\nWealth: %s gold (carried) + %s (bank) = %s total\n",
		ServerMonitor and ServerMonitor.formatGold(gold) or tostring(gold),
		ServerMonitor and ServerMonitor.formatGold(bank) or tostring(bank),
		ServerMonitor and ServerMonitor.formatGold(gold + bank) or tostring(gold + bank))

	-- Crafting skills if available
	if Crafting and Crafting.SKILL_NAMES then
		msg = msg .. "\nCrafting Skills:\n"
		for id, name in pairs(Crafting.SKILL_NAMES) do
			local level = target:getStorageValue(Crafting.STORAGE_SKILL_BASE + id)
			if level < 0 then level = 1 end
			msg = msg .. string.format("  %s: %d\n", name, level)
		end
	end

	-- Task points if available
	if TaskSystem then
		local pts = TaskSystem.getTaskPoints(target)
		msg = msg .. string.format("\nTask Points: %d\n", pts)
	end

	-- Achievement points if available
	if AchievementSystem then
		local unlocked, total = AchievementSystem.getProgress(target)
		local achPts = AchievementSystem.getAchievementPoints(target)
		msg = msg .. string.format("Achievements: %d/%d (%d points)\n", unlocked, total, achPts)
	end

	-- IP and account info for admins
	msg = msg .. string.format("\nIP: %s | Account Type: %d\n",
		Game.convertIpToString(target:getIp()), target:getAccountType())

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end

-- ============================================================================
-- /teleportall [x,y,z] - Teleport all players to position
-- ============================================================================

function handleTeleportAll(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /teleportall [x,y,z]")
		return false
	end

	local coords = {}
	for num in param:gmatch("(%d+)") do
		table.insert(coords, tonumber(num))
	end

	if #coords < 3 then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Invalid position. Usage: /teleportall [x,y,z]")
		return false
	end

	local destination = Position(coords[1], coords[2], coords[3])
	local players = Game.getPlayers()
	local count = 0

	for _, target in ipairs(players) do
		if target:getGuid() ~= player:getGuid() then
			target:teleportTo(destination)
			target:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have been teleported by an administrator.")
			count = count + 1
		end
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		string.format("Teleported %d players to position %d, %d, %d.", count, coords[1], coords[2], coords[3]))
	Game.broadcastMessage(string.format("All players have been teleported by %s.", player:getName()), MESSAGE_STATUS_WARNING)
	return false
end

-- ============================================================================
-- /eventstart [name] - Start a seasonal event
-- ============================================================================

function handleEventStart(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /eventstart [event_name]\nAvailable events:")
		if SeasonalEvents and SeasonalEvents.EVENTS then
			for key, event in pairs(SeasonalEvents.EVENTS) do
				player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "  " .. key .. " - " .. event.name)
			end
		end
		return false
	end

	if not SeasonalEvents or not SeasonalEvents.EVENTS then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Seasonal events system not loaded.")
		return false
	end

	local eventKey = param:upper():gsub("%s+", "_")
	local event = SeasonalEvents.EVENTS[eventKey]
	if not event then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Event '" .. param .. "' not found.")
		return false
	end

	-- Force-activate the event by temporarily modifying its dates
	if not SeasonalEvents._forcedEvents then
		SeasonalEvents._forcedEvents = {}
	end
	SeasonalEvents._forcedEvents[eventKey] = true

	-- Broadcast
	if event.broadcastStart then
		Game.broadcastMessage(event.broadcastStart, MESSAGE_STATUS_WARNING)
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"Event '" .. event.name .. "' has been manually started.")

	if ServerMonitor then
		ServerMonitor.log("Admin " .. player:getName() .. " manually started event: " .. event.name)
	end

	return false
end

-- ============================================================================
-- /eventstop [name] - Stop a seasonal event
-- ============================================================================

function handleEventStop(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /eventstop [event_name]")
		return false
	end

	if not SeasonalEvents or not SeasonalEvents.EVENTS then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Seasonal events system not loaded.")
		return false
	end

	local eventKey = param:upper():gsub("%s+", "_")
	local event = SeasonalEvents.EVENTS[eventKey]
	if not event then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Event '" .. param .. "' not found.")
		return false
	end

	-- Force-deactivate
	if not SeasonalEvents._forcedStops then
		SeasonalEvents._forcedStops = {}
	end
	SeasonalEvents._forcedStops[eventKey] = true

	-- Remove from forced starts if present
	if SeasonalEvents._forcedEvents then
		SeasonalEvents._forcedEvents[eventKey] = nil
	end

	-- Broadcast
	if event.broadcastEnd then
		Game.broadcastMessage(event.broadcastEnd, MESSAGE_STATUS_WARNING)
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"Event '" .. event.name .. "' has been manually stopped.")

	if ServerMonitor then
		ServerMonitor.log("Admin " .. player:getName() .. " manually stopped event: " .. event.name)
	end

	return false
end

-- ============================================================================
-- /raidstart [name] - Trigger a raid
-- ============================================================================

function handleRaidStart(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /raidstart [raid_name]")
		return false
	end

	local returnValue = Game.startRaid(param)
	if returnValue ~= RETURNVALUE_NOERROR then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			"Failed to start raid '" .. param .. "': " .. Game.getReturnMessage(returnValue))
	else
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			"Raid '" .. param .. "' started successfully.")
		if ServerMonitor then
			ServerMonitor.log("Admin " .. player:getName() .. " started raid: " .. param)
		end
	end
	return false
end

-- ============================================================================
-- /craftingstats - Show crafting statistics
-- ============================================================================

function handleCraftingStats(player)
	if not ServerMonitor then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Server monitor not loaded.")
		return false
	end

	local report = ServerMonitor.getCraftingStatsReport()
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, report)
	return false
end

-- ============================================================================
-- /taskreset [player] - Reset task cooldowns
-- ============================================================================

function handleTaskReset(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /taskreset [player_name]")
		return false
	end

	if not TaskSystem then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Task system not loaded.")
		return false
	end

	local target = Player(param)
	if not target then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player '" .. param .. "' is not online.")
		return false
	end

	-- Reset daily task timestamp
	target:setStorageValue(TaskSystem.STORAGE_DAILY_RESET, 0)
	-- Reset active task count
	target:setStorageValue(TaskSystem.STORAGE_ACTIVE_COUNT, 0)

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"Task cooldowns reset for player '" .. target:getName() .. "'.")
	target:sendTextMessage(MESSAGE_EVENT_ADVANCE,
		"Your task cooldowns have been reset by an administrator.")

	if ServerMonitor then
		ServerMonitor.log("Admin " .. player:getName() .. " reset task cooldowns for: " .. target:getName())
	end

	return false
end

-- ============================================================================
-- /grantachievement [player],[id] - Grant achievement
-- ============================================================================

function handleGrantAchievement(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /grantachievement [player_name],[achievement_id]")
		return false
	end

	if not AchievementSystem then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Achievement system not loaded.")
		return false
	end

	local separatorPos = param:find(",")
	if not separatorPos then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /grantachievement [player_name],[achievement_id]")
		return false
	end

	local targetName = string.trim(param:sub(1, separatorPos - 1))
	local achId = tonumber(string.trim(param:sub(separatorPos + 1)))

	if not achId then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Invalid achievement ID.")
		return false
	end

	local target = Player(targetName)
	if not target then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player '" .. targetName .. "' is not online.")
		return false
	end

	-- Check if achievement exists
	local ach = nil
	if AchievementSystem.ACHIEVEMENTS then
		for _, a in ipairs(AchievementSystem.ACHIEVEMENTS) do
			if a.id == achId then
				ach = a
				break
			end
		end
	end

	if not ach then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Achievement ID " .. achId .. " not found.")
		return false
	end

	-- Grant it
	if AchievementSystem.hasAchievement(target, achId) then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			target:getName() .. " already has achievement '" .. ach.name .. "'.")
		return false
	end

	AchievementSystem.grantAchievement(target, achId)
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"Granted achievement '" .. ach.name .. "' to " .. target:getName() .. ".")
	target:sendTextMessage(MESSAGE_EVENT_ADVANCE,
		"You have been granted the achievement '" .. ach.name .. "' by an administrator.")

	if ServerMonitor then
		ServerMonitor.log("Admin " .. player:getName() .. " granted achievement " .. ach.name ..
			" (ID: " .. achId .. ") to " .. target:getName())
	end

	return false
end
