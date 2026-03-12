-- ============================================================================
-- Moderation Tools (Phase 6.5)
-- ============================================================================
-- /warn [player],[reason]         - Warn a player
-- /mute [player],[minutes]        - Mute a player
-- /jail [player],[minutes]        - Jail a player
-- /freeze [player]                - Freeze player movement
-- /unfreeze [player]              - Unfreeze player movement
-- /watchlist [add|remove|show],[player] - Manage watchlist
-- ============================================================================

-- Jail position (configurable)
local JAIL_POSITION = Position(32220, 32275, 7)

-- Storage keys for moderation
local STORAGE_MUTED = 60010
local STORAGE_MUTE_UNTIL = 60011
local STORAGE_JAILED = 60012
local STORAGE_JAIL_UNTIL = 60013
local STORAGE_FROZEN = 60014
local STORAGE_WARNED = 60015
local STORAGE_JAIL_RETURN_X = 60016
local STORAGE_JAIL_RETURN_Y = 60017
local STORAGE_JAIL_RETURN_Z = 60018

function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
		return false
	end

	logCommand(player, words, param)

	if words == "/warn" then
		return handleWarn(player, param)
	elseif words == "/mute" then
		return handleMute(player, param)
	elseif words == "/jail" then
		return handleJail(player, param)
	elseif words == "/freeze" then
		return handleFreeze(player, param)
	elseif words == "/unfreeze" then
		return handleUnfreeze(player, param)
	elseif words == "/watchlist" then
		return handleWatchlist(player, param)
	end

	return false
end

-- ============================================================================
-- /warn [player],[reason] - Warn a player
-- ============================================================================

function handleWarn(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /warn [player_name],[reason]")
		return false
	end

	local name = param
	local reason = "No reason specified"

	local separatorPos = param:find(",")
	if separatorPos then
		name = string.trim(param:sub(1, separatorPos - 1))
		reason = string.trim(param:sub(separatorPos + 1))
	end

	local target = Player(name)
	if not target then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player '" .. name .. "' is not online.")
		return false
	end

	-- Increment warning count
	local warnings = target:getStorageValue(STORAGE_WARNED)
	if warnings < 0 then warnings = 0 end
	warnings = warnings + 1
	target:setStorageValue(STORAGE_WARNED, warnings)

	-- Send warning to player
	target:sendTextMessage(MESSAGE_STATUS_WARNING,
		"[WARNING #" .. warnings .. "] You have been warned by a moderator. Reason: " .. reason)

	-- Log to database
	db.asyncQuery(string.format(
		"INSERT INTO `player_warnings` (`player_id`, `reason`, `warned_by`, `warned_at`) VALUES (%d, %s, %d, %d)",
		target:getGuid(), db.escapeString(reason), player:getGuid(), os.time()
	))

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		string.format("Warned '%s' (warning #%d). Reason: %s", target:getName(), warnings, reason))

	if ServerMonitor then
		ServerMonitor.log(string.format("MODERATION: %s warned %s (warning #%d): %s",
			player:getName(), target:getName(), warnings, reason))
	end

	return false
end

-- ============================================================================
-- /mute [player],[minutes] - Mute a player
-- ============================================================================

function handleMute(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /mute [player_name],[minutes]")
		return false
	end

	local name = param
	local minutes = 30 -- default 30 minutes

	local separatorPos = param:find(",")
	if separatorPos then
		name = string.trim(param:sub(1, separatorPos - 1))
		minutes = tonumber(string.trim(param:sub(separatorPos + 1))) or 30
	end

	local target = Player(name)
	if not target then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player '" .. name .. "' is not online.")
		return false
	end

	if target:getGroup():getAccess() then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You cannot mute a staff member.")
		return false
	end

	local muteUntil = os.time() + (minutes * 60)
	target:setStorageValue(STORAGE_MUTED, 1)
	target:setStorageValue(STORAGE_MUTE_UNTIL, muteUntil)

	target:sendTextMessage(MESSAGE_STATUS_WARNING,
		string.format("You have been muted for %d minutes by a moderator.", minutes))

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		string.format("Muted '%s' for %d minutes.", target:getName(), minutes))

	if ServerMonitor then
		ServerMonitor.log(string.format("MODERATION: %s muted %s for %d minutes",
			player:getName(), target:getName(), minutes))
	end

	return false
end

-- ============================================================================
-- /jail [player],[minutes] - Jail a player
-- ============================================================================

function handleJail(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /jail [player_name],[minutes]")
		return false
	end

	local name = param
	local minutes = 60 -- default 60 minutes

	local separatorPos = param:find(",")
	if separatorPos then
		name = string.trim(param:sub(1, separatorPos - 1))
		minutes = tonumber(string.trim(param:sub(separatorPos + 1))) or 60
	end

	local target = Player(name)
	if not target then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player '" .. name .. "' is not online.")
		return false
	end

	if target:getGroup():getAccess() then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You cannot jail a staff member.")
		return false
	end

	-- Save return position
	local returnPos = target:getPosition()
	target:setStorageValue(STORAGE_JAIL_RETURN_X, returnPos.x)
	target:setStorageValue(STORAGE_JAIL_RETURN_Y, returnPos.y)
	target:setStorageValue(STORAGE_JAIL_RETURN_Z, returnPos.z)

	-- Set jail status
	local jailUntil = os.time() + (minutes * 60)
	target:setStorageValue(STORAGE_JAILED, 1)
	target:setStorageValue(STORAGE_JAIL_UNTIL, jailUntil)

	-- Teleport to jail
	target:teleportTo(JAIL_POSITION)

	target:sendTextMessage(MESSAGE_STATUS_WARNING,
		string.format("You have been jailed for %d minutes by a moderator.", minutes))

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		string.format("Jailed '%s' for %d minutes.", target:getName(), minutes))

	if ServerMonitor then
		ServerMonitor.log(string.format("MODERATION: %s jailed %s for %d minutes",
			player:getName(), target:getName(), minutes))
	end

	return false
end

-- ============================================================================
-- /freeze [player] - Freeze player movement
-- ============================================================================

function handleFreeze(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /freeze [player_name]")
		return false
	end

	local target = Player(param)
	if not target then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player '" .. param .. "' is not online.")
		return false
	end

	if target:getGroup():getAccess() then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You cannot freeze a staff member.")
		return false
	end

	-- Set frozen condition - use CONDITION_PARALYZE to prevent movement
	local condition = Condition(CONDITION_PARALYZE)
	condition:setParameter(CONDITION_PARAM_TICKS, -1) -- infinite duration
	condition:setParameter(CONDITION_PARAM_SPEED, -target:getBaseSpeed())
	target:addCondition(condition)

	target:setStorageValue(STORAGE_FROZEN, 1)

	target:sendTextMessage(MESSAGE_STATUS_WARNING,
		"You have been frozen by a moderator. You cannot move.")

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"Frozen player '" .. target:getName() .. "'. Use /unfreeze to release.")

	if ServerMonitor then
		ServerMonitor.log(string.format("MODERATION: %s froze %s",
			player:getName(), target:getName()))
	end

	return false
end

-- ============================================================================
-- /unfreeze [player] - Unfreeze player movement
-- ============================================================================

function handleUnfreeze(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /unfreeze [player_name]")
		return false
	end

	local target = Player(param)
	if not target then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player '" .. param .. "' is not online.")
		return false
	end

	target:removeCondition(CONDITION_PARALYZE)
	target:setStorageValue(STORAGE_FROZEN, 0)

	target:sendTextMessage(MESSAGE_EVENT_ADVANCE,
		"You have been unfrozen by a moderator. You can move again.")

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"Unfroze player '" .. target:getName() .. "'.")

	if ServerMonitor then
		ServerMonitor.log(string.format("MODERATION: %s unfroze %s",
			player:getName(), target:getName()))
	end

	return false
end

-- ============================================================================
-- /watchlist [add|remove|show],[player] - Manage watchlist
-- ============================================================================

function handleWatchlist(player, param)
	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			"Usage: /watchlist [add|remove|show],[player_name]\n  /watchlist show")
		return false
	end

	local args = {}
	for part in param:gmatch("[^,]+") do
		table.insert(args, string.trim(part))
	end

	local action = args[1] and args[1]:lower() or ""
	local targetName = args[2] or ""

	if not ServerMonitor then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Server monitor not loaded.")
		return false
	end

	if action == "show" then
		local msg = "=== Watchlist ===\n"
		local count = 0
		for name, info in pairs(ServerMonitor.watchlist) do
			count = count + 1
			local online = Player(name) and " [ONLINE]" or ""
			msg = msg .. string.format("  %d. %s%s - Added by %s on %s\n     Reason: %s\n",
				count, name, online,
				info.addedBy, os.date("%Y-%m-%d %H:%M", info.addedAt),
				info.reason or "No reason")
		end
		if count == 0 then
			msg = msg .. "  (empty)\n"
		end
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	if action == "add" then
		if targetName == "" then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /watchlist add,[player_name],[reason]")
			return false
		end

		local reason = args[3] or "No reason specified"
		local lowerName = targetName:lower()

		ServerMonitor.watchlist[lowerName] = {
			addedBy = player:getName(),
			addedAt = os.time(),
			reason = reason,
		}

		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			"Added '" .. targetName .. "' to watchlist. Reason: " .. reason)

		ServerMonitor.log(string.format("WATCHLIST: %s added '%s' - Reason: %s",
			player:getName(), targetName, reason))
		return false
	end

	if action == "remove" then
		if targetName == "" then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /watchlist remove,[player_name]")
			return false
		end

		local lowerName = targetName:lower()
		if ServerMonitor.watchlist[lowerName] then
			ServerMonitor.watchlist[lowerName] = nil
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"Removed '" .. targetName .. "' from watchlist.")
			ServerMonitor.log(string.format("WATCHLIST: %s removed '%s'",
				player:getName(), targetName))
		else
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"'" .. targetName .. "' is not on the watchlist.")
		end
		return false
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"Unknown action. Use: add, remove, or show")
	return false
end
