-- ============================================================================
-- PvP Enhancement Systems (Phase 1.3 + 5)
-- ============================================================================
-- Implements PvP enhancement features:
--   - Arena/duel system (challenge, instanced fight)
--   - Bounty system (place/collect bounties)
--   - PvP rankings (kill/death tracking, ELO-like rating)
--   - Anti-grief protection for players under level 50
-- ============================================================================

PvPSystems = {}

-- ============================================================================
-- Configuration
-- ============================================================================
PvPSystems.config = {
	-- Duel system
	duelEnabled = true,
	duelRequestTimeout = 60,    -- seconds to accept a duel
	duelMinLevel = 20,          -- minimum level to duel
	duelCooldown = 120,         -- seconds between duels

	-- Bounty system
	bountyEnabled = true,
	bountyMinAmount = 1000,     -- minimum bounty in gold
	bountyMaxAmount = 10000000, -- maximum bounty (10M)
	bountyMaxPerTarget = 3,     -- max active bounties per target
	bountyTaxPercent = 10,      -- tax on placing bounties

	-- PvP rankings
	rankingsEnabled = true,
	defaultElo = 1000,
	eloKFactor = 32,

	-- Anti-grief
	antiGriefLevel = 50,
	antiGriefEnabled = true,
}

-- Storage keys
PvPSystems.STORAGE = {
	ELO_RATING         = 57000,
	PVP_KILLS          = 57001,
	PVP_DEATHS         = 57002,
	DUEL_PENDING       = 57003, -- stores target player ID
	DUEL_COOLDOWN      = 57004,
	DUEL_ACTIVE        = 57005,
	BOUNTY_PLACED      = 57006, -- number of bounties placed by player
}

-- ============================================================================
-- Active state (in-memory, resets on server restart)
-- ============================================================================
PvPSystems.pendingDuels = {}   -- [challengerId] = {targetId, expireTime}
PvPSystems.activeDuels = {}    -- [playerId] = opponentId (bidirectional)
PvPSystems.activeBounties = {} -- list of {targetName, placedBy, amount, timestamp}

-- ============================================================================
-- Duel System
-- ============================================================================

--- Send a duel challenge to another player
-- @param challenger Player The challenging player
-- @param targetName string Name of the target player
-- @return boolean, string Success and message
function PvPSystems.challengeDuel(challenger, targetName)
	if not PvPSystems.config.duelEnabled then
		return false, "The duel system is currently disabled."
	end

	if challenger:getLevel() < PvPSystems.config.duelMinLevel then
		return false, "You must be at least level " .. PvPSystems.config.duelMinLevel .. " to duel."
	end

	-- Check cooldown
	local cooldown = challenger:getStorageValue(PvPSystems.STORAGE.DUEL_COOLDOWN)
	if cooldown > 0 and os.time() < cooldown then
		local remaining = cooldown - os.time()
		return false, "You must wait " .. remaining .. " seconds before challenging again."
	end

	-- Check if already in a duel
	if PvPSystems.activeDuels[challenger:getId()] then
		return false, "You are already in a duel."
	end

	-- Check if already has pending challenge
	if PvPSystems.pendingDuels[challenger:getId()] then
		return false, "You already have a pending duel challenge."
	end

	local target = Player(targetName)
	if not target then
		return false, "Player '" .. targetName .. "' is not online."
	end

	if target:getId() == challenger:getId() then
		return false, "You cannot challenge yourself."
	end

	if target:getLevel() < PvPSystems.config.duelMinLevel then
		return false, target:getName() .. " is below the minimum duel level."
	end

	if PvPSystems.activeDuels[target:getId()] then
		return false, target:getName() .. " is already in a duel."
	end

	-- Store pending duel
	PvPSystems.pendingDuels[challenger:getId()] = {
		targetId = target:getId(),
		expireTime = os.time() + PvPSystems.config.duelRequestTimeout,
	}

	target:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
		challenger:getName() .. " has challenged you to a duel! Type '!duel accept' to accept or '!duel decline' to decline.")

	return true, "Duel challenge sent to " .. target:getName() .. ". Waiting for response..."
end

--- Accept a pending duel challenge
-- @param target Player The target player accepting
-- @return boolean, string Success and message
function PvPSystems.acceptDuel(target)
	-- Find the pending duel for this target
	local challengerId = nil
	for cId, duel in pairs(PvPSystems.pendingDuels) do
		if duel.targetId == target:getId() and os.time() < duel.expireTime then
			challengerId = cId
			break
		end
	end

	if not challengerId then
		return false, "You have no pending duel challenges."
	end

	local challenger = Player(challengerId)
	if not challenger then
		PvPSystems.pendingDuels[challengerId] = nil
		return false, "The challenger is no longer online."
	end

	-- Start the duel
	PvPSystems.pendingDuels[challengerId] = nil
	PvPSystems.activeDuels[challenger:getId()] = target:getId()
	PvPSystems.activeDuels[target:getId()] = challenger:getId()

	challenger:setStorageValue(PvPSystems.STORAGE.DUEL_ACTIVE, 1)
	target:setStorageValue(PvPSystems.STORAGE.DUEL_ACTIVE, 1)

	-- Notify both players
	local msg = "Duel started! Fight to the death (or until one yields)."
	challenger:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, msg)
	target:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, msg)

	-- Apply duel visual effects
	challenger:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
	target:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)

	return true, "Duel accepted! Fight!"
end

--- Decline a pending duel
-- @param target Player The target declining
-- @return boolean, string Success and message
function PvPSystems.declineDuel(target)
	local challengerId = nil
	for cId, duel in pairs(PvPSystems.pendingDuels) do
		if duel.targetId == target:getId() then
			challengerId = cId
			break
		end
	end

	if not challengerId then
		return false, "You have no pending duel challenges."
	end

	PvPSystems.pendingDuels[challengerId] = nil

	local challenger = Player(challengerId)
	if challenger then
		challenger:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
			target:getName() .. " has declined your duel challenge.")
	end

	return true, "Duel challenge declined."
end

--- End a duel (called when one player dies or yields)
-- @param loser Player The losing player
-- @param winner Player The winning player
function PvPSystems.endDuel(loser, winner)
	if not loser or not winner then return end

	PvPSystems.activeDuels[loser:getId()] = nil
	PvPSystems.activeDuels[winner:getId()] = nil

	loser:setStorageValue(PvPSystems.STORAGE.DUEL_ACTIVE, -1)
	winner:setStorageValue(PvPSystems.STORAGE.DUEL_ACTIVE, -1)

	-- Set cooldowns
	local cooldownTime = os.time() + PvPSystems.config.duelCooldown
	loser:setStorageValue(PvPSystems.STORAGE.DUEL_COOLDOWN, cooldownTime)
	winner:setStorageValue(PvPSystems.STORAGE.DUEL_COOLDOWN, cooldownTime)

	-- Notify
	winner:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
		"You have won the duel against " .. loser:getName() .. "!")
	loser:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
		"You have lost the duel against " .. winner:getName() .. ".")

	-- Update ELO
	if PvPSystems.config.rankingsEnabled then
		PvPSystems.updateElo(winner, loser)
	end

	-- Visual effects
	winner:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
end

--- Check if two players are in a duel with each other
-- @param player1 Player First player
-- @param player2 Player Second player
-- @return boolean True if they are dueling each other
function PvPSystems.areInDuel(player1, player2)
	return PvPSystems.activeDuels[player1:getId()] == player2:getId()
end

-- ============================================================================
-- Bounty System
-- ============================================================================

--- Place a bounty on a player
-- @param player Player The player placing the bounty
-- @param targetName string Name of the bounty target
-- @param amount number Gold amount for the bounty
-- @return boolean, string Success and message
function PvPSystems.placeBounty(player, targetName, amount)
	if not PvPSystems.config.bountyEnabled then
		return false, "The bounty system is currently disabled."
	end

	amount = math.floor(tonumber(amount) or 0)

	if amount < PvPSystems.config.bountyMinAmount then
		return false, "Minimum bounty is " .. PvPSystems.config.bountyMinAmount .. " gold."
	end

	if amount > PvPSystems.config.bountyMaxAmount then
		return false, "Maximum bounty is " .. PvPSystems.config.bountyMaxAmount .. " gold."
	end

	-- Calculate tax
	local tax = math.floor(amount * PvPSystems.config.bountyTaxPercent / 100)
	local totalCost = amount + tax

	if player:getMoney() < totalCost then
		return false, "You need " .. totalCost .. " gold (" .. amount ..
			" bounty + " .. tax .. " tax)."
	end

	-- Check if target exists
	local targetNameLower = targetName:lower()
	local result = db.storeQuery("SELECT `name` FROM `players` WHERE LOWER(`name`) = " ..
		db.escapeString(targetNameLower))
	if not result then
		return false, "Player '" .. targetName .. "' does not exist."
	end
	local actualName = result:getString("name")
	result:free()

	if actualName:lower() == player:getName():lower() then
		return false, "You cannot place a bounty on yourself."
	end

	-- Count existing bounties on target
	local bountyCount = 0
	for _, bounty in ipairs(PvPSystems.activeBounties) do
		if bounty.targetName:lower() == targetNameLower then
			bountyCount = bountyCount + 1
		end
	end

	if bountyCount >= PvPSystems.config.bountyMaxPerTarget then
		return false, "Maximum bounties on this player reached (" ..
			PvPSystems.config.bountyMaxPerTarget .. ")."
	end

	-- Deduct gold and place bounty
	player:removeMoney(totalCost)

	table.insert(PvPSystems.activeBounties, {
		targetName = actualName,
		placedBy = player:getName(),
		amount = amount,
		timestamp = os.time(),
	})

	-- Announce
	local onlineTarget = Player(actualName)
	if onlineTarget then
		onlineTarget:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
			"A bounty of " .. amount .. " gold has been placed on your head!")
	end

	return true, "Bounty of " .. amount .. " gold placed on " .. actualName ..
		" (tax: " .. tax .. " gold)."
end

--- Check and collect bounties on a killed player
-- @param killer Player The killer
-- @param target Player The killed player
-- @return number Total bounty collected
function PvPSystems.collectBounties(killer, target)
	if not PvPSystems.config.bountyEnabled then return 0 end
	if not killer or not target then return 0 end
	if killer:getId() == target:getId() then return 0 end

	local targetName = target:getName():lower()
	local totalCollected = 0
	local remaining = {}

	for _, bounty in ipairs(PvPSystems.activeBounties) do
		if bounty.targetName:lower() == targetName and
		   bounty.placedBy:lower() ~= killer:getName():lower() then
			-- Collect this bounty
			killer:addMoney(bounty.amount)
			totalCollected = totalCollected + bounty.amount

			killer:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
				"You collected a bounty of " .. bounty.amount ..
				" gold on " .. target:getName() .. "!")
		else
			table.insert(remaining, bounty)
		end
	end

	PvPSystems.activeBounties = remaining
	return totalCollected
end

--- Get active bounties for display
-- @param limit number Max bounties to return
-- @return table List of active bounties
function PvPSystems.getActiveBounties(limit)
	limit = limit or 10
	local bounties = {}

	-- Aggregate bounties by target
	local byTarget = {}
	for _, bounty in ipairs(PvPSystems.activeBounties) do
		local key = bounty.targetName:lower()
		if not byTarget[key] then
			byTarget[key] = {
				targetName = bounty.targetName,
				totalAmount = 0,
				count = 0,
			}
		end
		byTarget[key].totalAmount = byTarget[key].totalAmount + bounty.amount
		byTarget[key].count = byTarget[key].count + 1
	end

	for _, entry in pairs(byTarget) do
		table.insert(bounties, entry)
	end

	table.sort(bounties, function(a, b)
		return a.totalAmount > b.totalAmount
	end)

	-- Trim to limit
	while #bounties > limit do
		table.remove(bounties)
	end

	return bounties
end

-- ============================================================================
-- PvP Rankings (ELO System)
-- ============================================================================

--- Get a player's ELO rating
-- @param player Player The player
-- @return number ELO rating
function PvPSystems.getElo(player)
	local elo = player:getStorageValue(PvPSystems.STORAGE.ELO_RATING)
	if elo < 0 then
		return PvPSystems.config.defaultElo
	end
	return elo
end

--- Get a player's PvP kill count
-- @param player Player The player
-- @return number Kill count
function PvPSystems.getKills(player)
	local kills = player:getStorageValue(PvPSystems.STORAGE.PVP_KILLS)
	return kills > 0 and kills or 0
end

--- Get a player's PvP death count
-- @param player Player The player
-- @return number Death count
function PvPSystems.getDeaths(player)
	local deaths = player:getStorageValue(PvPSystems.STORAGE.PVP_DEATHS)
	return deaths > 0 and deaths or 0
end

--- Update ELO ratings after a PvP kill
-- @param winner Player The winner
-- @param loser Player The loser
function PvPSystems.updateElo(winner, loser)
	local winnerElo = PvPSystems.getElo(winner)
	local loserElo = PvPSystems.getElo(loser)
	local K = PvPSystems.config.eloKFactor

	-- Expected scores
	local expectedWinner = 1 / (1 + 10 ^ ((loserElo - winnerElo) / 400))
	local expectedLoser = 1 / (1 + 10 ^ ((winnerElo - loserElo) / 400))

	-- New ratings
	local newWinnerElo = math.floor(winnerElo + K * (1 - expectedWinner))
	local newLoserElo = math.max(0, math.floor(loserElo + K * (0 - expectedLoser)))

	winner:setStorageValue(PvPSystems.STORAGE.ELO_RATING, newWinnerElo)
	loser:setStorageValue(PvPSystems.STORAGE.ELO_RATING, newLoserElo)

	-- Update kill/death counts
	local winnerKills = PvPSystems.getKills(winner)
	winner:setStorageValue(PvPSystems.STORAGE.PVP_KILLS, winnerKills + 1)

	local loserDeaths = PvPSystems.getDeaths(loser)
	loser:setStorageValue(PvPSystems.STORAGE.PVP_DEATHS, loserDeaths + 1)
end

--- Record a PvP kill for rankings (non-duel)
-- @param killer Player The killer
-- @param target Player The killed player
function PvPSystems.recordPvPKill(killer, target)
	if not PvPSystems.config.rankingsEnabled then return end
	if not killer or not target then return end

	PvPSystems.updateElo(killer, target)
end

--- Get PvP rankings
-- @param limit number Max players to return (default 10)
-- @return table List of ranking entries
function PvPSystems.getRankings(limit)
	limit = limit or 10

	local rankings = {}
	local result = db.storeQuery(
		"SELECT p.`name`, p.`level`, p.`vocation`, " ..
		"ps_elo.`value` as elo, ps_kills.`value` as kills, ps_deaths.`value` as deaths " ..
		"FROM `players` p " ..
		"LEFT JOIN `player_storage` ps_elo ON p.`id` = ps_elo.`player_id` AND ps_elo.`key` = " ..
			PvPSystems.STORAGE.ELO_RATING .. " " ..
		"LEFT JOIN `player_storage` ps_kills ON p.`id` = ps_kills.`player_id` AND ps_kills.`key` = " ..
			PvPSystems.STORAGE.PVP_KILLS .. " " ..
		"LEFT JOIN `player_storage` ps_deaths ON p.`id` = ps_deaths.`player_id` AND ps_deaths.`key` = " ..
			PvPSystems.STORAGE.PVP_DEATHS .. " " ..
		"WHERE ps_kills.`value` > 0 OR ps_elo.`value` > 0 " ..
		"ORDER BY COALESCE(ps_elo.`value`, " .. PvPSystems.config.defaultElo .. ") DESC " ..
		"LIMIT " .. limit)

	if result then
		repeat
			local elo = result:getNumber("elo")
			if elo <= 0 then elo = PvPSystems.config.defaultElo end
			local kills = result:getNumber("kills")
			if kills < 0 then kills = 0 end
			local deaths = result:getNumber("deaths")
			if deaths < 0 then deaths = 0 end

			table.insert(rankings, {
				name = result:getString("name"),
				level = result:getNumber("level"),
				vocation = result:getNumber("vocation"),
				elo = elo,
				kills = kills,
				deaths = deaths,
				kd = deaths > 0 and string.format("%.2f", kills / deaths) or tostring(kills) .. ".00",
			})
		until not result:next()
		result:free()
	end

	return rankings
end

-- ============================================================================
-- Anti-Grief Protection
-- ============================================================================

--- Check if a player is grief-protected
-- @param player Player The player to check
-- @return boolean True if protected from grief attacks
function PvPSystems.isGriefProtected(player)
	if not PvPSystems.config.antiGriefEnabled then
		return false
	end

	return player:getLevel() < PvPSystems.config.antiGriefLevel
end

--- Check if an attack should be blocked by anti-grief
-- @param attacker Player The attacker
-- @param target Player The target
-- @return boolean, string True if blocked, with reason
function PvPSystems.checkAntiGrief(attacker, target)
	if not PvPSystems.config.antiGriefEnabled then
		return false, nil
	end

	-- Protect low-level players from high-level attackers
	if PvPSystems.isGriefProtected(target) and not PvPSystems.isGriefProtected(attacker) then
		return true, "You cannot attack players below level " ..
			PvPSystems.config.antiGriefLevel .. "."
	end

	return false, nil
end

--- Clean up expired duel requests (call periodically)
function PvPSystems.cleanupExpiredDuels()
	local now = os.time()
	local expired = {}

	for challengerId, duel in pairs(PvPSystems.pendingDuels) do
		if now >= duel.expireTime then
			table.insert(expired, challengerId)

			local challenger = Player(challengerId)
			if challenger then
				challenger:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
					"Your duel challenge has expired.")
			end

			local target = Player(duel.targetId)
			if target then
				target:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
					"A duel challenge from has expired.")
			end
		end
	end

	for _, id in ipairs(expired) do
		PvPSystems.pendingDuels[id] = nil
	end
end

-- ============================================================================
-- Utility: Format rankings for display
-- ============================================================================

--- Get formatted PvP rankings string
-- @param limit number Max entries
-- @return string Formatted rankings
function PvPSystems.getFormattedRankings(limit)
	local rankings = PvPSystems.getRankings(limit)

	if #rankings == 0 then
		return "No PvP rankings data available yet."
	end

	local msg = "=== PvP Rankings ===\n"
	msg = msg .. string.format("%-4s %-20s %-6s %-6s %-6s %-6s\n",
		"#", "Name", "ELO", "Kills", "Deaths", "K/D")
	msg = msg .. string.rep("-", 52) .. "\n"

	for i, entry in ipairs(rankings) do
		msg = msg .. string.format("%-4d %-20s %-6d %-6d %-6d %-6s\n",
			i, entry.name, entry.elo, entry.kills, entry.deaths, entry.kd)
	end

	return msg
end

--- Get formatted bounty list string
-- @return string Formatted bounty list
function PvPSystems.getFormattedBounties()
	local bounties = PvPSystems.getActiveBounties(10)

	if #bounties == 0 then
		return "No active bounties."
	end

	local msg = "=== Active Bounties ===\n"
	for i, bounty in ipairs(bounties) do
		msg = msg .. string.format("%d. %s - %d gold (%d bounties)\n",
			i, bounty.targetName, bounty.totalAmount, bounty.count)
	end

	return msg
end

print(">> PvP enhancement systems loaded")
