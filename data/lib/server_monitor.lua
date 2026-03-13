-- ============================================================================
-- Server Monitoring System (Phase 6.5)
-- ============================================================================
-- Tracks economy metrics, player activity, crafting activity, and PvP stats.
-- Provides alert thresholds and periodic logging.
--
-- Storage layout:
--   Global storage keys 60000-60099 reserved for server monitor
-- ============================================================================

ServerMonitor = ServerMonitor or {}

-- ============================================================================
-- Configuration
-- ============================================================================

ServerMonitor.CONFIG = {
	-- How often metrics are collected (in seconds)
	collectionInterval = 1800, -- 30 minutes

	-- Alert thresholds
	alerts = {
		goldInflationRate = 10,       -- alert if gold inflation > 10%
		playerDeathSpike = 20,        -- alert if deaths in period > 20
		memoryUsageMB = 2048,         -- alert if memory usage > 2GB
		onlinePlayerDrop = 50,        -- alert if online count drops by 50%
	},

	-- Log file path (relative to server root)
	logFile = "data/logs/server_monitor.log",

	-- Daily summary time (hour in 24h format)
	dailySummaryHour = 23,
}

-- ============================================================================
-- Metrics Storage (in-memory, reset on restart)
-- ============================================================================

ServerMonitor.metrics = {
	-- Economy
	economy = {
		totalGoldCirculation = 0,
		goldSources = 0,          -- gold entering the economy this period
		goldSinks = 0,            -- gold leaving the economy this period
		marketTransactions = 0,
		marketVolume = 0,
		previousGoldCirculation = 0,
		inflationRate = 0,
	},

	-- Player Activity
	players = {
		logins = 0,
		logouts = 0,
		deaths = 0,
		levelsGained = 0,
		peakOnline = 0,
		totalPlaytime = 0,      -- in seconds
	},

	-- Crafting Activity
	crafting = {
		itemsCrafted = 0,
		resourcesGathered = 0,
		craftingBySkill = {
			cooking = 0,
			mining = 0,
			smithing = 0,
			farming = 0,
			enchanting = 0,
		},
	},

	-- PvP Activity
	pvp = {
		kills = 0,
		duels = 0,
		guildWars = 0,
		bountiesClaimed = 0,
	},

	-- Server Health
	server = {
		startTime = os.time(),
		lastCollectionTime = os.time(),
		creatureCount = 0,
		playerCount = 0,
	},
}

-- Daily aggregates (reset at daily summary)
ServerMonitor.daily = {
	economy = { goldSources = 0, goldSinks = 0, marketTransactions = 0, marketVolume = 0 },
	players = { logins = 0, logouts = 0, deaths = 0, levelsGained = 0, peakOnline = 0 },
	crafting = { itemsCrafted = 0, resourcesGathered = 0 },
	pvp = { kills = 0, duels = 0 },
}

-- Watchlist for suspicious players (managed by moderation)
ServerMonitor.watchlist = {}

-- Alert history
ServerMonitor.alertHistory = {}

-- ============================================================================
-- Logging
-- ============================================================================

function ServerMonitor.log(message)
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local logLine = "[" .. timestamp .. "] " .. message
	print("[ServerMonitor] " .. message)

	-- Append to log file
	local file = io.open(ServerMonitor.CONFIG.logFile, "a")
	if file then
		file:write(logLine .. "\n")
		file:close()
	end
end

-- ============================================================================
-- Economy Tracking
-- ============================================================================

function ServerMonitor.trackGoldSource(amount, source)
	ServerMonitor.metrics.economy.goldSources = ServerMonitor.metrics.economy.goldSources + amount
	ServerMonitor.daily.economy.goldSources = ServerMonitor.daily.economy.goldSources + amount
end

function ServerMonitor.trackGoldSink(amount, sink)
	ServerMonitor.metrics.economy.goldSinks = ServerMonitor.metrics.economy.goldSinks + amount
	ServerMonitor.daily.economy.goldSinks = ServerMonitor.daily.economy.goldSinks + amount
end

function ServerMonitor.trackMarketTransaction(price)
	ServerMonitor.metrics.economy.marketTransactions = ServerMonitor.metrics.economy.marketTransactions + 1
	ServerMonitor.metrics.economy.marketVolume = ServerMonitor.metrics.economy.marketVolume + price
	ServerMonitor.daily.economy.marketTransactions = ServerMonitor.daily.economy.marketTransactions + 1
	ServerMonitor.daily.economy.marketVolume = ServerMonitor.daily.economy.marketVolume + price
end

function ServerMonitor.calculateTotalGold()
	local totalGold = 0
	local players = Game.getPlayers()
	for _, player in ipairs(players) do
		totalGold = totalGold + player:getMoney()
		-- Count bank balance if available
		totalGold = totalGold + player:getBankBalance()
	end
	return totalGold
end

function ServerMonitor.calculateInflation()
	local current = ServerMonitor.metrics.economy.totalGoldCirculation
	local previous = ServerMonitor.metrics.economy.previousGoldCirculation
	if previous > 0 then
		ServerMonitor.metrics.economy.inflationRate = ((current - previous) / previous) * 100
	else
		ServerMonitor.metrics.economy.inflationRate = 0
	end
end

function ServerMonitor.getTopWealthyPlayers(count)
	count = count or 5
	local players = Game.getPlayers()
	local wealth = {}
	for _, player in ipairs(players) do
		local total = player:getMoney() + player:getBankBalance()
		table.insert(wealth, { name = player:getName(), gold = total })
	end
	table.sort(wealth, function(a, b) return a.gold > b.gold end)

	local top = {}
	for i = 1, math.min(count, #wealth) do
		table.insert(top, wealth[i])
	end
	return top
end

-- ============================================================================
-- Player Activity Tracking
-- ============================================================================

function ServerMonitor.trackLogin(player)
	ServerMonitor.metrics.players.logins = ServerMonitor.metrics.players.logins + 1
	ServerMonitor.daily.players.logins = ServerMonitor.daily.players.logins + 1

	local online = #Game.getPlayers()
	if online > ServerMonitor.metrics.players.peakOnline then
		ServerMonitor.metrics.players.peakOnline = online
	end
	if online > ServerMonitor.daily.players.peakOnline then
		ServerMonitor.daily.players.peakOnline = online
	end

	-- Check watchlist
	if player and ServerMonitor.watchlist[player:getName():lower()] then
		ServerMonitor.log("WATCHLIST: Player '" .. player:getName() .. "' has logged in.")
		ServerMonitor.alertAdmins("Watchlist player '" .. player:getName() .. "' has logged in.")
	end
end

function ServerMonitor.trackLogout(player)
	ServerMonitor.metrics.players.logouts = ServerMonitor.metrics.players.logouts + 1
	ServerMonitor.daily.players.logouts = ServerMonitor.daily.players.logouts + 1
end

function ServerMonitor.trackDeath(player, killer)
	ServerMonitor.metrics.players.deaths = ServerMonitor.metrics.players.deaths + 1
	ServerMonitor.daily.players.deaths = ServerMonitor.daily.players.deaths + 1
end

function ServerMonitor.trackLevelGain(player, newLevel)
	ServerMonitor.metrics.players.levelsGained = ServerMonitor.metrics.players.levelsGained + 1
	ServerMonitor.daily.players.levelsGained = ServerMonitor.daily.players.levelsGained + 1
end

-- ============================================================================
-- Crafting Activity Tracking
-- ============================================================================

function ServerMonitor.trackCraft(skillName, itemName)
	ServerMonitor.metrics.crafting.itemsCrafted = ServerMonitor.metrics.crafting.itemsCrafted + 1
	ServerMonitor.daily.crafting.itemsCrafted = ServerMonitor.daily.crafting.itemsCrafted + 1

	local skill = skillName and skillName:lower() or "unknown"
	if ServerMonitor.metrics.crafting.craftingBySkill[skill] then
		ServerMonitor.metrics.crafting.craftingBySkill[skill] = ServerMonitor.metrics.crafting.craftingBySkill[skill] + 1
	end
end

function ServerMonitor.trackGather(resourceName)
	ServerMonitor.metrics.crafting.resourcesGathered = ServerMonitor.metrics.crafting.resourcesGathered + 1
	ServerMonitor.daily.crafting.resourcesGathered = ServerMonitor.daily.crafting.resourcesGathered + 1
end

-- ============================================================================
-- PvP Activity Tracking
-- ============================================================================

function ServerMonitor.trackPvPKill(killer, victim)
	ServerMonitor.metrics.pvp.kills = ServerMonitor.metrics.pvp.kills + 1
	ServerMonitor.daily.pvp.kills = ServerMonitor.daily.pvp.kills + 1
end

function ServerMonitor.trackDuel(winner, loser)
	ServerMonitor.metrics.pvp.duels = ServerMonitor.metrics.pvp.duels + 1
	ServerMonitor.daily.pvp.duels = ServerMonitor.daily.pvp.duels + 1
end

function ServerMonitor.trackGuildWar()
	ServerMonitor.metrics.pvp.guildWars = ServerMonitor.metrics.pvp.guildWars + 1
end

function ServerMonitor.trackBountyClaimed()
	ServerMonitor.metrics.pvp.bountiesClaimed = ServerMonitor.metrics.pvp.bountiesClaimed + 1
end

-- ============================================================================
-- Server Health
-- ============================================================================

function ServerMonitor.getUptime()
	return os.time() - ServerMonitor.metrics.server.startTime
end

function ServerMonitor.getFormattedUptime()
	local uptime = ServerMonitor.getUptime()
	local days = math.floor(uptime / 86400)
	local hours = math.floor((uptime % 86400) / 3600)
	local minutes = math.floor((uptime % 3600) / 60)
	return string.format("%dd %dh %dm", days, hours, minutes)
end

function ServerMonitor.getMemoryUsage()
	-- Lua memory usage in KB
	return collectgarbage("count")
end

-- ============================================================================
-- Alert System
-- ============================================================================

function ServerMonitor.alertAdmins(message)
	local timestamp = os.date("%H:%M:%S")
	local alertMsg = "[ALERT " .. timestamp .. "] " .. message

	-- Send to all online admins/GMs
	local players = Game.getPlayers()
	for _, player in ipairs(players) do
		if player:getGroup():getAccess() then
			player:sendTextMessage(MESSAGE_STATUS_WARNING, alertMsg)
		end
	end

	-- Log the alert
	ServerMonitor.log("ALERT: " .. message)

	-- Store in alert history
	table.insert(ServerMonitor.alertHistory, {
		time = os.time(),
		message = message,
	})

	-- Keep only last 50 alerts
	while #ServerMonitor.alertHistory > 50 do
		table.remove(ServerMonitor.alertHistory, 1)
	end
end

function ServerMonitor.checkAlerts()
	local config = ServerMonitor.CONFIG.alerts

	-- Check gold inflation
	if math.abs(ServerMonitor.metrics.economy.inflationRate) > config.goldInflationRate then
		ServerMonitor.alertAdmins(string.format(
			"Gold inflation rate is %.1f%% (threshold: %d%%)",
			ServerMonitor.metrics.economy.inflationRate,
			config.goldInflationRate
		))
	end

	-- Check death spike
	if ServerMonitor.metrics.players.deaths > config.playerDeathSpike then
		ServerMonitor.alertAdmins(string.format(
			"Death spike detected: %d deaths this period (threshold: %d)",
			ServerMonitor.metrics.players.deaths,
			config.playerDeathSpike
		))
	end

	-- Check memory usage
	local memMB = ServerMonitor.getMemoryUsage() / 1024
	if memMB > config.memoryUsageMB then
		ServerMonitor.alertAdmins(string.format(
			"High memory usage: %.0f MB (threshold: %d MB)",
			memMB,
			config.memoryUsageMB
		))
	end
end

-- ============================================================================
-- Metrics Collection (called periodically)
-- ============================================================================

function ServerMonitor.collectMetrics()
	-- Update server stats
	ServerMonitor.metrics.server.playerCount = #Game.getPlayers()
	ServerMonitor.metrics.server.lastCollectionTime = os.time()

	-- Update economy
	ServerMonitor.metrics.economy.previousGoldCirculation = ServerMonitor.metrics.economy.totalGoldCirculation
	ServerMonitor.metrics.economy.totalGoldCirculation = ServerMonitor.calculateTotalGold()
	ServerMonitor.calculateInflation()

	-- Log metrics
	ServerMonitor.log(string.format(
		"Metrics: Players=%d | Gold=%d | Sources=%d | Sinks=%d | Inflation=%.1f%% | Deaths=%d | Crafted=%d | PvP Kills=%d",
		ServerMonitor.metrics.server.playerCount,
		ServerMonitor.metrics.economy.totalGoldCirculation,
		ServerMonitor.metrics.economy.goldSources,
		ServerMonitor.metrics.economy.goldSinks,
		ServerMonitor.metrics.economy.inflationRate,
		ServerMonitor.metrics.players.deaths,
		ServerMonitor.metrics.crafting.itemsCrafted,
		ServerMonitor.metrics.pvp.kills
	))

	-- Check alerts
	ServerMonitor.checkAlerts()

	-- Reset period counters
	ServerMonitor.metrics.economy.goldSources = 0
	ServerMonitor.metrics.economy.goldSinks = 0
	ServerMonitor.metrics.economy.marketTransactions = 0
	ServerMonitor.metrics.economy.marketVolume = 0
	ServerMonitor.metrics.players.deaths = 0
	ServerMonitor.metrics.players.logins = 0
	ServerMonitor.metrics.players.logouts = 0
	ServerMonitor.metrics.players.levelsGained = 0
	ServerMonitor.metrics.crafting.itemsCrafted = 0
	ServerMonitor.metrics.crafting.resourcesGathered = 0
	ServerMonitor.metrics.pvp.kills = 0
	ServerMonitor.metrics.pvp.duels = 0
end

-- ============================================================================
-- Daily Summary
-- ============================================================================

function ServerMonitor.generateDailySummary()
	local d = ServerMonitor.daily

	local summary = "=== Daily Server Summary (" .. os.date("%Y-%m-%d") .. ") ===\n"
	summary = summary .. "\n-- Economy --\n"
	summary = summary .. string.format("  Gold Sources: %d | Gold Sinks: %d | Net: %d\n",
		d.economy.goldSources, d.economy.goldSinks, d.economy.goldSources - d.economy.goldSinks)
	summary = summary .. string.format("  Market Transactions: %d | Volume: %d gold\n",
		d.economy.marketTransactions, d.economy.marketVolume)

	summary = summary .. "\n-- Player Activity --\n"
	summary = summary .. string.format("  Logins: %d | Logouts: %d | Peak Online: %d\n",
		d.players.logins, d.players.logouts, d.players.peakOnline)
	summary = summary .. string.format("  Deaths: %d | Levels Gained: %d\n",
		d.players.deaths, d.players.levelsGained)

	summary = summary .. "\n-- Crafting --\n"
	summary = summary .. string.format("  Items Crafted: %d | Resources Gathered: %d\n",
		d.crafting.itemsCrafted, d.crafting.resourcesGathered)

	summary = summary .. "\n-- PvP --\n"
	summary = summary .. string.format("  Kills: %d | Duels: %d\n",
		d.pvp.kills, d.pvp.duels)

	summary = summary .. "\n-- Server Health --\n"
	summary = summary .. string.format("  Uptime: %s | Memory: %.1f MB\n",
		ServerMonitor.getFormattedUptime(), ServerMonitor.getMemoryUsage() / 1024)

	-- Log the summary
	ServerMonitor.log(summary)

	-- Send to online admins
	local players = Game.getPlayers()
	for _, player in ipairs(players) do
		if player:getGroup():getAccess() then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, summary)
		end
	end

	-- Reset daily counters
	ServerMonitor.daily = {
		economy = { goldSources = 0, goldSinks = 0, marketTransactions = 0, marketVolume = 0 },
		players = { logins = 0, logouts = 0, deaths = 0, levelsGained = 0, peakOnline = 0 },
		crafting = { itemsCrafted = 0, resourcesGathered = 0 },
		pvp = { kills = 0, duels = 0 },
	}
end

-- ============================================================================
-- Economy Health Check
-- ============================================================================

function ServerMonitor.economyHealthCheck()
	local eco = ServerMonitor.metrics.economy
	local health = "HEALTHY"
	local issues = {}

	-- Check inflation
	if math.abs(eco.inflationRate) > 10 then
		health = "WARNING"
		table.insert(issues, string.format("Inflation rate: %.1f%%", eco.inflationRate))
	end

	-- Check gold balance (sources vs sinks)
	local dailyNet = ServerMonitor.daily.economy.goldSources - ServerMonitor.daily.economy.goldSinks
	if dailyNet > 0 and ServerMonitor.daily.economy.goldSources > 0 then
		local ratio = dailyNet / ServerMonitor.daily.economy.goldSources
		if ratio > 0.5 then
			health = "WARNING"
			table.insert(issues, string.format("Gold sinks only absorbing %.0f%% of sources", (1 - ratio) * 100))
		end
	end

	local result = {
		health = health,
		issues = issues,
		totalGold = eco.totalGoldCirculation,
		inflationRate = eco.inflationRate,
		dailyNetGold = dailyNet,
	}

	return result
end

-- ============================================================================
-- Formatting Helpers
-- ============================================================================

function ServerMonitor.formatGold(amount)
	if amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	end
	return tostring(amount)
end

function ServerMonitor.getEconomyReport()
	local eco = ServerMonitor.metrics.economy
	local top = ServerMonitor.getTopWealthyPlayers(5)

	local msg = "=== Economy Report ===\n"
	msg = msg .. string.format("Total Gold in Circulation: %s\n", ServerMonitor.formatGold(eco.totalGoldCirculation))
	msg = msg .. string.format("Inflation Rate: %.1f%%\n", eco.inflationRate)
	msg = msg .. string.format("Market Activity: %d transactions (%s volume)\n",
		ServerMonitor.daily.economy.marketTransactions,
		ServerMonitor.formatGold(ServerMonitor.daily.economy.marketVolume))
	msg = msg .. string.format("Gold Sources (today): %s | Sinks: %s\n",
		ServerMonitor.formatGold(ServerMonitor.daily.economy.goldSources),
		ServerMonitor.formatGold(ServerMonitor.daily.economy.goldSinks))

	if #top > 0 then
		msg = msg .. "\nTop Wealthy Players (online):\n"
		for i, p in ipairs(top) do
			msg = msg .. string.format("  %d. %s - %s gold\n", i, p.name, ServerMonitor.formatGold(p.gold))
		end
	end

	local healthCheck = ServerMonitor.economyHealthCheck()
	msg = msg .. "\nEconomy Health: " .. healthCheck.health
	if #healthCheck.issues > 0 then
		for _, issue in ipairs(healthCheck.issues) do
			msg = msg .. "\n  ! " .. issue
		end
	end

	return msg
end

function ServerMonitor.getServerStatsReport()
	local players = Game.getPlayers()
	local msg = "=== Server Statistics ===\n"
	msg = msg .. string.format("Players Online: %d (Peak: %d)\n",
		#players, ServerMonitor.metrics.players.peakOnline)
	msg = msg .. string.format("Uptime: %s\n", ServerMonitor.getFormattedUptime())
	msg = msg .. string.format("Lua Memory: %.1f MB\n", ServerMonitor.getMemoryUsage() / 1024)
	msg = msg .. string.format("Logins Today: %d | Logouts: %d\n",
		ServerMonitor.daily.players.logins, ServerMonitor.daily.players.logouts)
	msg = msg .. string.format("Deaths Today: %d | Levels Gained: %d\n",
		ServerMonitor.daily.players.deaths, ServerMonitor.daily.players.levelsGained)
	msg = msg .. string.format("PvP Kills Today: %d | Duels: %d\n",
		ServerMonitor.daily.pvp.kills, ServerMonitor.daily.pvp.duels)

	if #ServerMonitor.alertHistory > 0 then
		msg = msg .. "\nRecent Alerts:\n"
		local start = math.max(1, #ServerMonitor.alertHistory - 4)
		for i = start, #ServerMonitor.alertHistory do
			local alert = ServerMonitor.alertHistory[i]
			msg = msg .. "  " .. os.date("%H:%M", alert.time) .. " - " .. alert.message .. "\n"
		end
	end

	return msg
end

function ServerMonitor.getCraftingStatsReport()
	local c = ServerMonitor.metrics.crafting
	local msg = "=== Crafting Statistics ===\n"
	msg = msg .. string.format("Items Crafted (total): %d\n", c.itemsCrafted)
	msg = msg .. string.format("Resources Gathered (total): %d\n", c.resourcesGathered)
	msg = msg .. "\nBy Skill:\n"
	for skill, count in pairs(c.craftingBySkill) do
		msg = msg .. string.format("  %s: %d items\n", skill:sub(1,1):upper() .. skill:sub(2), count)
	end

	msg = msg .. "\nToday:\n"
	msg = msg .. string.format("  Crafted: %d | Gathered: %d\n",
		ServerMonitor.daily.crafting.itemsCrafted,
		ServerMonitor.daily.crafting.resourcesGathered)

	return msg
end

print("[ServerMonitor] Server monitoring system loaded.")
