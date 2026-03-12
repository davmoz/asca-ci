-- ============================================================================
-- PvP Talkaction Commands (Phase 1.3 + 5)
-- ============================================================================
-- !duel [player|accept|decline] - Challenge/accept/decline duels
-- !bounty [player] [amount]     - Place a bounty on a player
-- !pvprank                      - Show PvP rankings
-- !guildbank deposit/withdraw/balance - Guild bank management
-- !bountylist                   - Show active bounties
-- ============================================================================

function onSay(player, words, param, channel)
	if words == "!duel" then
		return handleDuel(player, param)
	elseif words == "!bounty" then
		return handleBounty(player, param)
	elseif words == "!pvprank" then
		return handlePvPRank(player, param)
	elseif words == "!guildbank" then
		return handleGuildBank(player, param)
	elseif words == "!bountylist" then
		return handleBountyList(player, param)
	end
	return false
end

-- ============================================================================
-- !duel [player|accept|decline]
-- ============================================================================
function handleDuel(player, param)
	if not PvPSystems then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "PvP systems are not available.")
		return false
	end

	local args = {}
	for word in param:gmatch("%S+") do
		table.insert(args, word)
	end

	local subcommand = args[1] and args[1]:lower() or ""

	-- !duel accept
	if subcommand == "accept" then
		local success, msg = PvPSystems.acceptDuel(player)
		player:sendTextMessage(
			success and MESSAGE_STATUS_CONSOLE_RED or MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- !duel decline
	if subcommand == "decline" or subcommand == "reject" then
		local success, msg = PvPSystems.declineDuel(player)
		player:sendTextMessage(
			success and MESSAGE_STATUS_CONSOLE_RED or MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- !duel (no args) - show help
	if subcommand == "" then
		local msg = "=== Duel System ===\n"
		msg = msg .. "!duel <player> - Challenge a player to a duel\n"
		msg = msg .. "!duel accept   - Accept a pending duel challenge\n"
		msg = msg .. "!duel decline  - Decline a pending duel challenge\n"
		msg = msg .. "\nMin level: " .. PvPSystems.config.duelMinLevel

		-- Show own stats
		local elo = PvPSystems.getElo(player)
		local kills = PvPSystems.getKills(player)
		local deaths = PvPSystems.getDeaths(player)
		msg = msg .. "\nYour stats - ELO: " .. elo ..
			" | Kills: " .. kills .. " | Deaths: " .. deaths

		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- !duel <player> - challenge
	local targetName = param
	local success, msg = PvPSystems.challengeDuel(player, targetName)
	player:sendTextMessage(
		success and MESSAGE_STATUS_CONSOLE_RED or MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end

-- ============================================================================
-- !bounty [player] [amount]
-- ============================================================================
function handleBounty(player, param)
	if not PvPSystems then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "PvP systems are not available.")
		return false
	end

	local args = {}
	for word in param:gmatch("%S+") do
		table.insert(args, word)
	end

	if #args < 2 then
		local msg = "=== Bounty System ===\n"
		msg = msg .. "!bounty <player> <amount> - Place a bounty on a player\n"
		msg = msg .. "!bountylist               - View active bounties\n"
		msg = msg .. "\nMin bounty: " .. PvPSystems.config.bountyMinAmount .. " gold\n"
		msg = msg .. "Tax: " .. PvPSystems.config.bountyTaxPercent .. "%"
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- Last arg is amount, everything before is the player name
	local amount = tonumber(args[#args])
	if not amount then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			"Usage: !bounty <player> <amount>")
		return false
	end

	-- Player name is everything except the last arg
	table.remove(args)
	local targetName = table.concat(args, " ")

	local success, msg = PvPSystems.placeBounty(player, targetName, amount)
	player:sendTextMessage(
		success and MESSAGE_STATUS_CONSOLE_RED or MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end

-- ============================================================================
-- !pvprank
-- ============================================================================
function handlePvPRank(player, param)
	if not PvPSystems then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "PvP systems are not available.")
		return false
	end

	local msg = PvPSystems.getFormattedRankings(10)

	-- Append player's own ranking
	local elo = PvPSystems.getElo(player)
	local kills = PvPSystems.getKills(player)
	local deaths = PvPSystems.getDeaths(player)
	local kd = deaths > 0 and string.format("%.2f", kills / deaths) or tostring(kills) .. ".00"

	msg = msg .. "\n--- Your Stats ---\n"
	msg = msg .. "ELO: " .. elo .. " | Kills: " .. kills ..
		" | Deaths: " .. deaths .. " | K/D: " .. kd

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end

-- ============================================================================
-- !guildbank deposit/withdraw/balance
-- ============================================================================
function handleGuildBank(player, param)
	if not GuildEnhanced then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Guild system is not available.")
		return false
	end

	local args = {}
	for word in param:gmatch("%S+") do
		table.insert(args, word)
	end

	local subcommand = args[1] and args[1]:lower() or ""

	-- !guildbank deposit <amount>
	if subcommand == "deposit" then
		local amount = tonumber(args[2])
		if not amount then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"Usage: !guildbank deposit <amount>")
			return false
		end
		local success, msg = GuildEnhanced.deposit(player, amount)
		player:sendTextMessage(
			success and MESSAGE_STATUS_CONSOLE_RED or MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- !guildbank withdraw <amount>
	if subcommand == "withdraw" then
		local amount = tonumber(args[2])
		if not amount then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"Usage: !guildbank withdraw <amount>")
			return false
		end
		local success, msg = GuildEnhanced.withdraw(player, amount)
		player:sendTextMessage(
			success and MESSAGE_STATUS_CONSOLE_RED or MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- !guildbank balance (or no args)
	if subcommand == "balance" or subcommand == "" then
		local success, msg = GuildEnhanced.checkBalance(player)
		if not success then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
			return false
		end

		-- Show full guild info if available
		local info = GuildEnhanced.getGuildInfo(player)
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, info)
		return false
	end

	-- Unknown subcommand
	local msg = "=== Guild Bank ===\n"
	msg = msg .. "!guildbank deposit <amount>  - Deposit gold\n"
	msg = msg .. "!guildbank withdraw <amount> - Withdraw gold (leader/vice only)\n"
	msg = msg .. "!guildbank balance           - Check balance and guild info"
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end

-- ============================================================================
-- !bountylist
-- ============================================================================
function handleBountyList(player, param)
	if not PvPSystems then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "PvP systems are not available.")
		return false
	end

	local msg = PvPSystems.getFormattedBounties()
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end
