-- ============================================================================
-- Server Monitor Global Event (Phase 6.5)
-- ============================================================================
-- Runs every 30 minutes to collect and log server metrics.
-- Also handles daily summary generation and economy health checks.
-- ============================================================================

-- Track last daily summary date to avoid duplicates
local lastDailySummaryDate = ""

-- ============================================================================
-- Startup: Initialize monitoring
-- ============================================================================

function onStartup()
	if not ServerMonitor then
		print("[ServerMonitorEvent] WARNING: ServerMonitor library not loaded")
		return true
	end

	-- Ensure log directory exists
	os.execute("mkdir -p data/logs")

	-- Initialize startup metrics
	ServerMonitor.metrics.server.startTime = os.time()
	ServerMonitor.metrics.server.playerCount = 0

	ServerMonitor.log("Server monitor initialized. Collection interval: " ..
		ServerMonitor.CONFIG.collectionInterval .. "s")

	return true
end

-- ============================================================================
-- Timer: Periodic metrics collection (every 30 minutes)
-- ============================================================================

function onThink(interval)
	if not ServerMonitor then
		return true
	end

	-- Collect metrics
	ServerMonitor.collectMetrics()

	-- Check if it's time for daily summary
	local currentDate = os.date("%Y-%m-%d")
	local currentHour = tonumber(os.date("%H"))

	if currentDate ~= lastDailySummaryDate and currentHour >= ServerMonitor.CONFIG.dailySummaryHour then
		lastDailySummaryDate = currentDate
		ServerMonitor.log("Generating daily summary...")
		ServerMonitor.generateDailySummary()
	end

	-- Economy health check
	local health = ServerMonitor.economyHealthCheck()
	if health.health ~= "HEALTHY" then
		ServerMonitor.log("Economy health: " .. health.health)
		for _, issue in ipairs(health.issues) do
			ServerMonitor.log("  Issue: " .. issue)
		end
	end

	-- Log watchlist activity
	if ServerMonitor.watchlist then
		for name, info in pairs(ServerMonitor.watchlist) do
			local target = Player(name)
			if target then
				ServerMonitor.log(string.format("WATCHLIST ACTIVE: '%s' is online at position %s",
					target:getName(), tostring(target:getPosition())))
			end
		end
	end

	return true
end

-- ============================================================================
-- Time-based: Daily summary at configured hour
-- ============================================================================

function onTime(interval)
	if not ServerMonitor then
		return true
	end

	local currentDate = os.date("%Y-%m-%d")
	if currentDate ~= lastDailySummaryDate then
		lastDailySummaryDate = currentDate
		ServerMonitor.log("Daily summary triggered by timer...")
		ServerMonitor.generateDailySummary()

		-- Economy health check
		local health = ServerMonitor.economyHealthCheck()
		if health.health ~= "HEALTHY" then
			local issueStr = table.concat(health.issues, "; ")
			ServerMonitor.alertAdmins("Daily economy health: " .. health.health .. " - " .. issueStr)
		end
	end

	return true
end
