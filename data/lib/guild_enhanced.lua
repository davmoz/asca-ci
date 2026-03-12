-- ============================================================================
-- Enhanced Guild System (Phase 5)
-- ============================================================================
-- Implements enhanced guild features:
--   - Guild bank (deposit/withdraw/balance via storage)
--   - Guild level system (earn XP from member activities)
--   - Guild war auto-accept on PvP engagement
--   - Guild alliance system (track allied guilds)
--   - Guild rankings/leaderboard data
-- ============================================================================

GuildEnhanced = {}

-- ============================================================================
-- Configuration
-- ============================================================================
GuildEnhanced.config = {
	-- Guild bank
	maxBankBalance = 100000000, -- 100M gold cap

	-- Guild leveling
	xpPerMemberKill = 10,       -- XP earned per monster kill by member
	xpPerMemberLevel = 500,     -- XP earned when a member levels up
	xpPerQuestComplete = 1000,  -- XP earned when a member completes a quest
	xpPerWarKill = 250,         -- XP earned per guild war kill
	maxGuildLevel = 50,

	-- Guild war auto-accept
	warAutoAcceptEnabled = true,

	-- Alliance limits
	maxAlliances = 3,
}

-- Storage keys for guild system
-- Guild storage uses a base key + guild ID offset
GuildEnhanced.STORAGE = {
	GUILD_BANK_BASE     = 59000, -- + guildId
	GUILD_XP_BASE       = 59500, -- + guildId
	GUILD_LEVEL_BASE    = 59900, -- + guildId
	GUILD_ALLIES_BASE   = 60500, -- + guildId (comma-separated list of ally guild IDs)
	GUILD_WAR_KILLS_BASE = 61000, -- + guildId

	-- Per-player guild contribution tracking
	PLAYER_GUILD_CONTRIBUTION = 61500,
}

-- XP required per guild level (cumulative)
GuildEnhanced.LEVEL_XP = {}
for i = 1, 50 do
	GuildEnhanced.LEVEL_XP[i] = i * i * 1000
end

-- ============================================================================
-- Guild Bank Functions
-- ============================================================================

--- Get guild bank balance
-- @param guildId number The guild ID
-- @return number Current balance
function GuildEnhanced.getBankBalance(guildId)
	if not guildId or guildId <= 0 then return 0 end

	local resultId = db.storeQuery("SELECT `value` FROM `guild_storage` WHERE `guild_id` = " ..
		guildId .. " AND `key` = " .. GuildEnhanced.STORAGE.GUILD_BANK_BASE)
	if resultId then
		local balance = result.getNumber(resultId, "value")
		result.free(resultId)
		return balance
	end

	return 0
end

--- Set guild bank balance (internal)
-- @param guildId number The guild ID
-- @param amount number The new balance
-- @return boolean Success
function GuildEnhanced.setBankBalance(guildId, amount)
	if not guildId or guildId <= 0 then return false end

	amount = math.max(0, math.min(amount, GuildEnhanced.config.maxBankBalance))

	local key = GuildEnhanced.STORAGE.GUILD_BANK_BASE
	db.query("INSERT INTO `guild_storage` (`guild_id`, `key`, `value`) VALUES (" ..
		guildId .. ", " .. key .. ", " .. amount ..
		") ON DUPLICATE KEY UPDATE `value` = " .. amount)
	return true
end

--- Deposit gold into guild bank
-- @param player Player The depositing player
-- @param amount number Amount to deposit
-- @return boolean, string Success and message
function GuildEnhanced.deposit(player, amount)
	if not player:getGuild() then
		return false, "You are not in a guild."
	end

	local guildId = player:getGuild():getId()
	amount = math.floor(tonumber(amount) or 0)

	if amount <= 0 then
		return false, "Invalid amount."
	end

	if player:getMoney() < amount then
		return false, "You do not have enough gold."
	end

	local balance = GuildEnhanced.getBankBalance(guildId)
	if balance + amount > GuildEnhanced.config.maxBankBalance then
		return false, "The guild bank cannot hold that much gold (max: " ..
			GuildEnhanced.config.maxBankBalance .. ")."
	end

	player:removeMoney(amount)
	GuildEnhanced.setBankBalance(guildId, balance + amount)

	-- Track contribution
	local contrib = player:getStorageValue(GuildEnhanced.STORAGE.PLAYER_GUILD_CONTRIBUTION)
	if contrib < 0 then contrib = 0 end
	player:setStorageValue(GuildEnhanced.STORAGE.PLAYER_GUILD_CONTRIBUTION, contrib + amount)

	return true, "Deposited " .. amount .. " gold into the guild bank. New balance: " ..
		(balance + amount) .. " gold."
end

--- Withdraw gold from guild bank
-- @param player Player The withdrawing player (must be guild leader or vice)
-- @param amount number Amount to withdraw
-- @return boolean, string Success and message
function GuildEnhanced.withdraw(player, amount)
	if not player:getGuild() then
		return false, "You are not in a guild."
	end

	local guild = player:getGuild()
	local guildId = guild:getId()
	local rank = player:getGuildLevel()
	amount = math.floor(tonumber(amount) or 0)

	-- Only leader (3) and vice leader (2) can withdraw
	if rank < 2 then
		return false, "Only guild leaders and vice leaders can withdraw from the bank."
	end

	if amount <= 0 then
		return false, "Invalid amount."
	end

	local balance = GuildEnhanced.getBankBalance(guildId)
	if amount > balance then
		return false, "Insufficient guild bank funds (balance: " .. balance .. " gold)."
	end

	GuildEnhanced.setBankBalance(guildId, balance - amount)
	player:addMoney(amount)

	return true, "Withdrew " .. amount .. " gold from the guild bank. Remaining: " ..
		(balance - amount) .. " gold."
end

--- Get guild bank balance as formatted string
-- @param player Player The querying player
-- @return boolean, string Success and balance message
function GuildEnhanced.checkBalance(player)
	if not player:getGuild() then
		return false, "You are not in a guild."
	end

	local guildId = player:getGuild():getId()
	local balance = GuildEnhanced.getBankBalance(guildId)

	return true, "Guild bank balance: " .. balance .. " gold."
end

-- ============================================================================
-- Guild Level System
-- ============================================================================

--- Get guild level
-- @param guildId number The guild ID
-- @return number Guild level (1-50)
function GuildEnhanced.getGuildLevel(guildId)
	if not guildId or guildId <= 0 then return 1 end

	local resultId = db.storeQuery("SELECT `value` FROM `guild_storage` WHERE `guild_id` = " ..
		guildId .. " AND `key` = " .. GuildEnhanced.STORAGE.GUILD_LEVEL_BASE)
	if resultId then
		local level = result.getNumber(resultId, "value")
		result.free(resultId)
		return math.max(1, level)
	end

	return 1
end

--- Get guild XP
-- @param guildId number The guild ID
-- @return number Current guild XP
function GuildEnhanced.getGuildXP(guildId)
	if not guildId or guildId <= 0 then return 0 end

	local resultId = db.storeQuery("SELECT `value` FROM `guild_storage` WHERE `guild_id` = " ..
		guildId .. " AND `key` = " .. GuildEnhanced.STORAGE.GUILD_XP_BASE)
	if resultId then
		local xp = result.getNumber(resultId, "value")
		result.free(resultId)
		return xp
	end

	return 0
end

--- Set guild storage value (internal helper)
-- @param guildId number The guild ID
-- @param key number Storage key
-- @param value number Value to store
function GuildEnhanced.setGuildStorage(guildId, key, value)
	db.query("INSERT INTO `guild_storage` (`guild_id`, `key`, `value`) VALUES (" ..
		guildId .. ", " .. key .. ", " .. value ..
		") ON DUPLICATE KEY UPDATE `value` = " .. value)
end

--- Add XP to a guild and handle level ups
-- @param guildId number The guild ID
-- @param xpAmount number XP to add
-- @param source string Description of XP source (for notifications)
function GuildEnhanced.addGuildXP(guildId, xpAmount, source)
	if not guildId or guildId <= 0 or xpAmount <= 0 then return end

	local currentXP = GuildEnhanced.getGuildXP(guildId)
	local currentLevel = GuildEnhanced.getGuildLevel(guildId)
	local newXP = currentXP + xpAmount

	GuildEnhanced.setGuildStorage(guildId, GuildEnhanced.STORAGE.GUILD_XP_BASE, newXP)

	-- Check for level up
	if currentLevel < GuildEnhanced.config.maxGuildLevel then
		local nextLevelXP = GuildEnhanced.LEVEL_XP[currentLevel + 1]
		if nextLevelXP and newXP >= nextLevelXP then
			local newLevel = currentLevel + 1
			GuildEnhanced.setGuildStorage(guildId, GuildEnhanced.STORAGE.GUILD_LEVEL_BASE, newLevel)

			-- Broadcast level up to guild members
			local guild = Guild(guildId)
			if guild then
				local members = guild:getMembersOnline()
				for _, member in ipairs(members) do
					member:sendTextMessage(MESSAGE_EVENT_ADVANCE,
						"Your guild has reached level " .. newLevel .. "!")
				end
			end
		end
	end
end

--- Called when a guild member earns XP for the guild
-- @param player Player The member who triggered the XP gain
-- @param xpType string Type of activity ("kill", "level", "quest", "war_kill")
function GuildEnhanced.onMemberActivity(player, xpType)
	if not player:getGuild() then return end

	local guildId = player:getGuild():getId()
	local xpGain = 0
	local source = ""

	if xpType == "kill" then
		xpGain = GuildEnhanced.config.xpPerMemberKill
		source = player:getName() .. " killed a monster"
	elseif xpType == "level" then
		xpGain = GuildEnhanced.config.xpPerMemberLevel
		source = player:getName() .. " leveled up"
	elseif xpType == "quest" then
		xpGain = GuildEnhanced.config.xpPerQuestComplete
		source = player:getName() .. " completed a quest"
	elseif xpType == "war_kill" then
		xpGain = GuildEnhanced.config.xpPerWarKill
		source = player:getName() .. " scored a guild war kill"
	end

	if xpGain > 0 then
		GuildEnhanced.addGuildXP(guildId, xpGain, source)
	end
end

-- ============================================================================
-- Guild War Auto-Accept
-- ============================================================================

--- Check and auto-accept guild war when a kill occurs
-- @param killer Player The player who killed
-- @param target Player The player who was killed
function GuildEnhanced.checkWarAutoAccept(killer, target)
	if not GuildEnhanced.config.warAutoAcceptEnabled then return end

	if not killer or not target then return end
	if not killer:getGuild() or not target:getGuild() then return end

	local killerGuildId = killer:getGuild():getId()
	local targetGuildId = target:getGuild():getId()

	if killerGuildId == targetGuildId then return end

	-- Check for pending war between these guilds (status = 0 means pending)
	local resultId = db.storeQuery(
		"SELECT `id` FROM `guild_wars` WHERE `status` = 0 AND " ..
		"((guild1 = " .. killerGuildId .. " AND guild2 = " .. targetGuildId .. ") OR " ..
		"(guild1 = " .. targetGuildId .. " AND guild2 = " .. killerGuildId .. "))")

	if resultId then
		local warId = result.getNumber(resultId, "id")
		result.free(resultId)

		-- Auto-accept the war
		db.query("UPDATE `guild_wars` SET `status` = 1, `started` = " .. os.time() ..
			" WHERE `id` = " .. warId)

		-- Notify both guilds
		local killerGuild = killer:getGuild()
		local targetGuild = target:getGuild()

		local notifyMessage = function(guild, enemyName)
			local members = guild:getMembersOnline()
			for _, member in ipairs(members) do
				member:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
					"War with " .. enemyName .. " has been auto-accepted due to PvP engagement!")
			end
		end

		notifyMessage(killerGuild, targetGuild:getName())
		notifyMessage(targetGuild, killerGuild:getName())
	end
end

-- ============================================================================
-- Guild Alliance System
-- ============================================================================

--- Get allied guild IDs
-- @param guildId number The guild ID
-- @return table List of allied guild IDs
function GuildEnhanced.getAllies(guildId)
	if not guildId or guildId <= 0 then return {} end

	local resultId = db.storeQuery("SELECT `value` FROM `guild_storage` WHERE `guild_id` = " ..
		guildId .. " AND `key` = " .. GuildEnhanced.STORAGE.GUILD_ALLIES_BASE)
	if resultId then
		local allyStr = result.getString(resultId, "value")
		result.free(resultId)

		local allies = {}
		if allyStr and allyStr ~= "" then
			for id in allyStr:gmatch("(%d+)") do
				table.insert(allies, tonumber(id))
			end
		end
		return allies
	end

	return {}
end

--- Check if two guilds are allied
-- @param guildId1 number First guild ID
-- @param guildId2 number Second guild ID
-- @return boolean True if allied
function GuildEnhanced.areAllied(guildId1, guildId2)
	local allies = GuildEnhanced.getAllies(guildId1)
	for _, allyId in ipairs(allies) do
		if allyId == guildId2 then
			return true
		end
	end
	return false
end

--- Add an alliance between two guilds
-- @param guildId1 number First guild ID
-- @param guildId2 number Second guild ID
-- @return boolean, string Success and message
function GuildEnhanced.addAlliance(guildId1, guildId2)
	if GuildEnhanced.areAllied(guildId1, guildId2) then
		return false, "These guilds are already allied."
	end

	local allies1 = GuildEnhanced.getAllies(guildId1)
	local allies2 = GuildEnhanced.getAllies(guildId2)

	if #allies1 >= GuildEnhanced.config.maxAlliances then
		return false, "Your guild has reached the maximum number of alliances."
	end

	if #allies2 >= GuildEnhanced.config.maxAlliances then
		return false, "The other guild has reached the maximum number of alliances."
	end

	-- Add to both guilds
	table.insert(allies1, guildId2)
	table.insert(allies2, guildId1)

	local function saveAllies(guildId, allies)
		local str = table.concat(allies, ",")
		db.query("INSERT INTO `guild_storage` (`guild_id`, `key`, `value`) VALUES (" ..
			guildId .. ", " .. GuildEnhanced.STORAGE.GUILD_ALLIES_BASE .. ", '" .. str ..
			"') ON DUPLICATE KEY UPDATE `value` = '" .. str .. "'")
	end

	saveAllies(guildId1, allies1)
	saveAllies(guildId2, allies2)

	return true, "Alliance established."
end

--- Remove an alliance between two guilds
-- @param guildId1 number First guild ID
-- @param guildId2 number Second guild ID
-- @return boolean, string Success and message
function GuildEnhanced.removeAlliance(guildId1, guildId2)
	if not GuildEnhanced.areAllied(guildId1, guildId2) then
		return false, "These guilds are not allied."
	end

	local function removeFromList(guildId, removeId)
		local allies = GuildEnhanced.getAllies(guildId)
		local newAllies = {}
		for _, id in ipairs(allies) do
			if id ~= removeId then
				table.insert(newAllies, id)
			end
		end
		local str = table.concat(newAllies, ",")
		db.query("INSERT INTO `guild_storage` (`guild_id`, `key`, `value`) VALUES (" ..
			guildId .. ", " .. GuildEnhanced.STORAGE.GUILD_ALLIES_BASE .. ", '" .. str ..
			"') ON DUPLICATE KEY UPDATE `value` = '" .. str .. "'")
	end

	removeFromList(guildId1, guildId2)
	removeFromList(guildId2, guildId1)

	return true, "Alliance dissolved."
end

-- ============================================================================
-- Guild Rankings / Leaderboard
-- ============================================================================

--- Get guild rankings data
-- @param limit number Maximum number of guilds to return (default 10)
-- @return table List of guild ranking entries
function GuildEnhanced.getRankings(limit)
	limit = limit or 10

	local rankings = {}
	local resultId = db.storeQuery(
		"SELECT g.`id`, g.`name`, " ..
		"(SELECT COUNT(*) FROM `guild_membership` gm WHERE gm.`guild_id` = g.`id`) as `member_count` " ..
		"FROM `guilds` g ORDER BY `member_count` DESC LIMIT " .. limit)

	if resultId then
		repeat
			local guildId = result.getNumber(resultId, "id")
			local entry = {
				id = guildId,
				name = result.getString(resultId, "name"),
				memberCount = result.getNumber(resultId, "member_count"),
				level = GuildEnhanced.getGuildLevel(guildId),
				xp = GuildEnhanced.getGuildXP(guildId),
				balance = GuildEnhanced.getBankBalance(guildId),
			}
			table.insert(rankings, entry)
		until not result.next(resultId)
		result.free(resultId)
	end

	-- Sort by guild level, then XP
	table.sort(rankings, function(a, b)
		if a.level ~= b.level then
			return a.level > b.level
		end
		return a.xp > b.xp
	end)

	return rankings
end

--- Get formatted guild info string
-- @param player Player The querying player
-- @return string Formatted guild information
function GuildEnhanced.getGuildInfo(player)
	if not player:getGuild() then
		return "You are not in a guild."
	end

	local guild = player:getGuild()
	local guildId = guild:getId()
	local level = GuildEnhanced.getGuildLevel(guildId)
	local xp = GuildEnhanced.getGuildXP(guildId)
	local balance = GuildEnhanced.getBankBalance(guildId)
	local allies = GuildEnhanced.getAllies(guildId)
	local nextLevelXP = GuildEnhanced.LEVEL_XP[level + 1] or 0

	local msg = "=== " .. guild:getName() .. " ===\n"
	msg = msg .. "Level: " .. level
	if nextLevelXP > 0 then
		msg = msg .. " (XP: " .. xp .. "/" .. nextLevelXP .. ")"
	else
		msg = msg .. " (MAX)"
	end
	msg = msg .. "\n"
	msg = msg .. "Bank: " .. balance .. " gold\n"
	msg = msg .. "Online: " .. #guild:getMembersOnline() .. " members\n"

	if #allies > 0 then
		msg = msg .. "Allies: "
		local allyNames = {}
		for _, allyId in ipairs(allies) do
			local allyGuild = Guild(allyId)
			if allyGuild then
				table.insert(allyNames, allyGuild:getName())
			end
		end
		msg = msg .. table.concat(allyNames, ", ") .. "\n"
	end

	return msg
end

print(">> Enhanced guild system loaded")
