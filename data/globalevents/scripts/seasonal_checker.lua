-- Seasonal Event Checker
-- Runs on server startup and daily to check/apply seasonal events
-- Phase 4.6 + 5.5

-- Track previously active events to detect transitions
local previouslyActiveEvents = {}

local function checkSeasonalEvents()
	if not SeasonalEvents or not SeasonalEvents.EVENTS then
		print("[SeasonalChecker] WARNING: SeasonalEvents system not loaded")
		return
	end

	local activeEvents = SeasonalEvents.getActiveEvents()
	local currentKeys = {}

	-- Check for newly activated events
	for _, entry in ipairs(activeEvents) do
		currentKeys[entry.key] = true

		if not previouslyActiveEvents[entry.key] then
			-- Event just became active
			print("[SeasonalChecker] Event STARTED: " .. entry.event.name)

			-- Broadcast start message
			if entry.event.broadcastStart then
				Game.broadcastMessage(entry.event.broadcastStart, MESSAGE_STATUS_WARNING)
			end

			-- Log modifier info
			local mods = entry.event.modifiers
			if mods then
				if mods.expBonus and mods.expBonus > 1.0 then
					print(string.format("[SeasonalChecker]   XP Bonus: +%d%%", (mods.expBonus - 1.0) * 100))
				end
				if mods.lootBonus and mods.lootBonus > 1.0 then
					print(string.format("[SeasonalChecker]   Loot Bonus: +%d%%", (mods.lootBonus - 1.0) * 100))
				end
				if mods.spawnRateMultiplier and mods.spawnRateMultiplier > 1.0 then
					print(string.format("[SeasonalChecker]   Spawn Rate: +%d%%", (mods.spawnRateMultiplier - 1.0) * 100))
				end
			end
		end
	end

	-- Check for ended events
	for key, _ in pairs(previouslyActiveEvents) do
		if not currentKeys[key] then
			local event = SeasonalEvents.EVENTS[key]
			if event then
				print("[SeasonalChecker] Event ENDED: " .. event.name)

				-- Broadcast end message
				if event.broadcastEnd then
					Game.broadcastMessage(event.broadcastEnd, MESSAGE_STATUS_WARNING)
				end
			end
		end
	end

	-- Update tracking
	previouslyActiveEvents = currentKeys

	-- Log overall status
	if #activeEvents > 0 then
		local totalExp = SeasonalEvents.getExpBonus()
		local totalLoot = SeasonalEvents.getLootBonus()
		print(string.format("[SeasonalChecker] Active events: %d | Total XP bonus: %.0f%% | Total Loot bonus: %.0f%%",
			#activeEvents,
			(totalExp - 1.0) * 100,
			(totalLoot - 1.0) * 100))
	else
		print("[SeasonalChecker] No seasonal events currently active")
	end
end

-- Startup handler: runs when server starts
function onStartup()
	print("[SeasonalChecker] Initializing seasonal event checker...")
	checkSeasonalEvents()
	return true
end

-- Timer handler: runs daily at midnight to check event transitions
function onTime(interval)
	print("[SeasonalChecker] Running daily seasonal event check...")
	checkSeasonalEvents()

	-- Broadcast active event reminders to online players
	local activeEvents = SeasonalEvents.getActiveEvents()
	if #activeEvents > 0 then
		for _, entry in ipairs(activeEvents) do
			local mods = entry.event.modifiers
			local bonusStr = ""
			if mods.expBonus and mods.expBonus > 1.0 then
				bonusStr = bonusStr .. string.format("+%d%% XP ", (mods.expBonus - 1.0) * 100)
			end
			if mods.lootBonus and mods.lootBonus > 1.0 then
				bonusStr = bonusStr .. string.format("+%d%% Loot ", (mods.lootBonus - 1.0) * 100)
			end
			local msg = string.format("[Event] %s is active! %s", entry.event.name, bonusStr)
			Game.broadcastMessage(msg, MESSAGE_EVENT_ADVANCE)
		end
	end

	return true
end
