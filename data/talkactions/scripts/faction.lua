-- ============================================================================
-- Faction System Talkaction (Issue #220)
-- ============================================================================
-- !faction              - show current faction and reputation
-- !faction list         - show all factions
-- !faction join <name>  - join a faction
-- ============================================================================

-- Storage key for primary faction membership
local STORAGE_PRIMARY_FACTION = 64310

function onSay(player, words, param, channel)
	if not FactionSystem then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Faction system is not available.")
		return false
	end

	-- Parse arguments
	local args = {}
	for word in param:gmatch("%S+") do
		table.insert(args, word)
	end

	local subcommand = args[1] and args[1]:lower() or ""

	-- !faction list
	if subcommand == "list" then
		local msg = "=== Available Factions ===\n"

		for id = 1, 4 do
			local faction = FactionSystem.factions[id]
			if faction then
				local rep = FactionSystem.getReputation(player, id)
				local _, levelName = FactionSystem.getReputationLevel(player, id)
				local opposing = FactionSystem.factions[faction.opposing]
				local opposingName = opposing and opposing.name or "None"

				msg = msg .. "[" .. id .. "] " .. faction.name .. "\n"
				msg = msg .. "  Theme: " .. faction.theme .. "\n"
				msg = msg .. "  Opposing: " .. opposingName .. "\n"
				msg = msg .. "  Your standing: " .. rep .. " (" .. levelName .. ")\n"
			end
		end

		msg = msg .. "\nUse !faction join <faction name> to join a faction."
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- !faction join <name>
	if subcommand == "join" then
		if not args[2] then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"Usage: !faction join <faction name>\nUse !faction list to see available factions.")
			return false
		end

		local factionName = table.concat(args, " ", 2):lower()

		-- Find faction by name (partial match)
		local targetId = nil
		for id = 1, 4 do
			local faction = FactionSystem.factions[id]
			if faction then
				local name = faction.name:lower()
				-- Match full name, or name without "the ", or short name
				local shortName = name:gsub("^the%s+", "")
				if name == factionName or shortName == factionName or
				   name:find(factionName, 1, true) or shortName:find(factionName, 1, true) then
					targetId = id
					break
				end
			end
		end

		if not targetId then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"[Faction] Unknown faction: " .. table.concat(args, " ", 2) ..
				". Use !faction list to see available factions.")
			return false
		end

		-- Check if already in this faction
		local currentFaction = player:getStorageValue(STORAGE_PRIMARY_FACTION)
		if currentFaction == targetId then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"[Faction] You are already a member of " .. FactionSystem.getFactionName(targetId) .. ".")
			return false
		end

		-- Check if player is in an opposing faction with Friendly+ standing
		if currentFaction >= 1 and currentFaction <= 4 then
			local oldFaction = FactionSystem.factions[currentFaction]
			if oldFaction then
				local _, levelName = FactionSystem.getReputationLevel(player, currentFaction)
				player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
					"[Faction] You have left " .. oldFaction.name .. " (" .. levelName .. ").")
			end
		end

		-- Join the faction
		player:setStorageValue(STORAGE_PRIMARY_FACTION, targetId)

		-- Give initial reputation boost if neutral
		local rep = FactionSystem.getReputation(player, targetId)
		if rep == 0 then
			FactionSystem.addReputation(player, targetId, 100)
		end

		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
			"[Faction] You have joined " .. FactionSystem.getFactionName(targetId) .. "! " ..
			"Kill monsters and complete tasks to earn reputation.")
		return false
	end

	-- Default: show current faction and reputation overview
	local primaryFaction = player:getStorageValue(STORAGE_PRIMARY_FACTION)

	local msg = "=== Faction Status ===\n"

	if primaryFaction >= 1 and primaryFaction <= 4 then
		local faction = FactionSystem.factions[primaryFaction]
		local rep = FactionSystem.getReputation(player, primaryFaction)
		local level, levelName = FactionSystem.getReputationLevel(player, primaryFaction)

		msg = msg .. "Current faction: " .. faction.name .. "\n"
		msg = msg .. "Reputation: " .. rep .. " (" .. levelName .. ")\n"

		-- Show unlocks
		msg = msg .. "\nUnlocks:\n"
		local unlocks = {
			{FactionSystem.LEVEL_FRIENDLY, "Faction Shop"},
			{FactionSystem.LEVEL_HONORED, "Faction Mount Quest"},
			{FactionSystem.LEVEL_REVERED, "Faction Title"},
			{FactionSystem.LEVEL_EXALTED, "Legendary Quest"},
		}
		for _, unlock in ipairs(unlocks) do
			local status = level >= unlock[1] and "[X]" or "[ ]"
			msg = msg .. "  " .. status .. " " .. unlock[2] ..
				" (" .. FactionSystem.LEVEL_NAMES[unlock[1]] .. ")\n"
		end

		-- Show title if earned
		local title = FactionSystem.getTitle(player, primaryFaction)
		if title then
			msg = msg .. "\nEarned title: " .. title .. "\n"
		end
	else
		msg = msg .. "You are not a member of any faction.\n"
		msg = msg .. "Use !faction list to see available factions.\n"
	end

	msg = msg .. "\n" .. FactionSystem.getSummary(player) .. "\n"

	msg = msg .. "\nCommands:\n"
	msg = msg .. "  !faction list - view all factions\n"
	msg = msg .. "  !faction join <name> - join a faction"
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end
