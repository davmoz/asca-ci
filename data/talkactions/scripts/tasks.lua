-- ============================================================================
-- Task, Bestiary, and Achievement Talkaction Commands (Phase 4)
-- ============================================================================
-- !tasks     - show available and active tasks
-- !bestiary  - show bestiary progress
-- !achievements - show achievement progress
-- ============================================================================

function onSay(player, words, param, channel)
	if words == "!tasks" then
		return handleTasks(player, param)
	elseif words == "!bestiary" then
		return handleBestiary(player, param)
	elseif words == "!achievements" then
		return handleAchievements(player, param)
	end
	return false
end

-- ============================================================================
-- !tasks [accept ID | cancel ID | info ID | points]
-- ============================================================================
function handleTasks(player, param)
	if not TaskSystem then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Task system is not available.")
		return false
	end

	-- Parse subcommand
	local args = {}
	for word in param:gmatch("%S+") do
		table.insert(args, word)
	end

	local subcommand = args[1] and args[1]:lower() or ""

	-- !tasks accept <id>
	if subcommand == "accept" then
		local taskId = tonumber(args[2])
		if not taskId then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: !tasks accept <task_id>")
			return false
		end
		local success, msg = TaskSystem.acceptTask(player, taskId)
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg or (success and "Task accepted!" or "Failed to accept task."))
		return false
	end

	-- !tasks cancel <id>
	if subcommand == "cancel" then
		local taskId = tonumber(args[2])
		if not taskId then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: !tasks cancel <task_id>")
			return false
		end
		local success, msg = TaskSystem.cancelTask(player, taskId)
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg or (success and "Task cancelled." or "Failed to cancel task."))
		return false
	end

	-- !tasks info <id>
	if subcommand == "info" then
		local taskId = tonumber(args[2])
		if not taskId then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: !tasks info <task_id>")
			return false
		end
		local task = TaskSystem.tasksById[taskId]
		if not task then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Task not found.")
			return false
		end
		local state = TaskSystem.getTaskState(player, taskId)
		local progress = TaskSystem.getTaskProgress(player, taskId)
		local stateStr = "Not started"
		if state == TaskSystem.STATE_ACTIVE then stateStr = "Active" end
		if state == TaskSystem.STATE_COMPLETED then stateStr = "Completed" end

		local msg = "[Task #" .. taskId .. "] " .. task.name .. "\n" ..
			"  Tier: " .. TaskSystem.TIER_NAMES[task.tier] .. " | Category: " .. task.category .. "\n" ..
			"  Target: " .. task.monster .. " x" .. task.killCount .. "\n" ..
			"  Status: " .. stateStr .. " (" .. progress .. "/" .. task.killCount .. ")\n" ..
			"  Rewards: " .. task.xpReward .. " XP, " .. task.goldReward .. " gold, " .. task.taskPoints .. " pts\n" ..
			"  " .. task.description
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- !tasks points
	if subcommand == "points" then
		local pts = TaskSystem.getTaskPoints(player)
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Tasks] Total task points: " .. pts)
		return false
	end

	-- Default: show active tasks + available count
	local activeTasks = TaskSystem.getActiveTasks(player)
	local available = TaskSystem.getAvailableTasks(player)
	local points = TaskSystem.getTaskPoints(player)

	local msg = "=== Hunter's Guild Tasks ===\n"
	msg = msg .. "Task Points: " .. points .. " | Active: " ..
		#activeTasks .. "/" .. TaskSystem.MAX_ACTIVE_TASKS .. "\n\n"

	if #activeTasks > 0 then
		msg = msg .. "-- Active Tasks --\n"
		for _, task in ipairs(activeTasks) do
			local progress = TaskSystem.getTaskProgress(player, task.id)
			msg = msg .. "  [" .. task.id .. "] " .. task.name ..
				" (" .. progress .. "/" .. task.killCount .. " " .. task.monster .. ")\n"
		end
		msg = msg .. "\n"
	end

	msg = msg .. "Available tasks: " .. #available .. " (use !tasks accept <id>)\n"

	-- Show a few available grouped by tier
	local byTier = {}
	for _, task in ipairs(available) do
		if not byTier[task.tier] then byTier[task.tier] = {} end
		table.insert(byTier[task.tier], task)
	end

	for tier = 1, 5 do
		if byTier[tier] and #byTier[tier] > 0 then
			msg = msg .. "\n[" .. TaskSystem.TIER_NAMES[tier] .. "]\n"
			local count = 0
			for _, task in ipairs(byTier[tier]) do
				if count < 5 then
					msg = msg .. "  [" .. task.id .. "] " .. task.name ..
						" - " .. task.monster .. " x" .. task.killCount ..
						" (" .. task.xpReward .. " XP)\n"
					count = count + 1
				end
			end
			if #byTier[tier] > 5 then
				msg = msg .. "  ... and " .. (#byTier[tier] - 5) .. " more\n"
			end
		end
	end

	msg = msg .. "\nCommands: !tasks accept/cancel/info <id> | !tasks points"
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end

-- ============================================================================
-- !bestiary [creature_name]
-- ============================================================================
function handleBestiary(player, param)
	if not Bestiary then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Bestiary system is not available.")
		return false
	end

	-- If a creature name is provided, show specific info
	if param and param ~= "" then
		local name = param:lower()
		local info = Bestiary.getBestiaryInfo(player, name)
		if not info then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Bestiary] Creature not found in bestiary: " .. param)
			return false
		end

		local msg = "[Bestiary] " .. param .. "\n"
		msg = msg .. "  Kills: " .. info.kills .. " | Tier: " .. info.tierName .. "\n"

		if info.tier >= 1 then
			msg = msg .. "  Category: " .. info.category .. " | Difficulty: " .. info.difficulty .. "\n"
		end

		if info.lootRevealed then
			msg = msg .. "  Loot table: Revealed (check monster loot in-game)\n"
		end

		if info.weaknesses then
			msg = msg .. "  Weaknesses: " .. table.concat(info.weaknesses, ", ") .. "\n"
			if #info.strengths > 0 then
				msg = msg .. "  Resistances: " .. table.concat(info.strengths, ", ") .. "\n"
			end
			if #info.immunities > 0 then
				msg = msg .. "  Immunities: " .. table.concat(info.immunities, ", ") .. "\n"
			end
		end

		-- Show next tier threshold
		local nextTier = info.tier + 1
		if nextTier <= 3 then
			local needed = Bestiary.TIER_THRESHOLDS[nextTier] - info.kills
			msg = msg .. "  Next tier (" .. Bestiary.TIER_NAMES[nextTier] .. "): " .. needed .. " more kills"
		else
			msg = msg .. "  Fully unlocked!"
		end

		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- Default: show summary
	local summary = Bestiary.getProgressSummary(player)
	local charms = Bestiary.getCharmPoints(player)

	local msg = "=== Bestiary Progress ===\n"
	msg = msg .. "Charm Points: " .. charms .. "\n"
	msg = msg .. "Entries: " .. summary.basic .. " Basic, " ..
		summary.detailed .. " Detailed, " ..
		summary.complete .. " Complete (of " .. summary.total .. " total)\n\n"

	-- Group by category
	local byCategory = {}
	for name, info in pairs(Bestiary.creatures) do
		if not byCategory[info.category] then
			byCategory[info.category] = {}
		end
		local tier = Bestiary.getUnlockTier(player, name)
		if tier > 0 then
			local kills = Bestiary.getKillCount(player, name)
			table.insert(byCategory[info.category], {
				name = name, tier = tier, kills = kills
			})
		end
	end

	for cat, entries in pairs(byCategory) do
		if #entries > 0 then
			msg = msg .. "[" .. cat .. "]\n"
			for _, entry in ipairs(entries) do
				msg = msg .. "  " .. entry.name .. " - " ..
					Bestiary.TIER_NAMES[entry.tier] .. " (" .. entry.kills .. " kills)\n"
			end
		end
	end

	msg = msg .. "\nUse: !bestiary <creature_name> for details"
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end

-- ============================================================================
-- !achievements [category]
-- ============================================================================
function handleAchievements(player, param)
	if not AchievementSystem then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Achievement system is not available.")
		return false
	end

	local unlocked, total = AchievementSystem.getProgress(player)
	local points = AchievementSystem.getAchievementPoints(player)
	local titleName = AchievementSystem.getSelectedTitleName(player) or "None"

	-- If a category is specified, show those achievements
	if param and param ~= "" then
		local cat = param:sub(1, 1):upper() .. param:sub(2):lower()
		local achs = AchievementSystem.getByCategory(cat)
		if #achs == 0 then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"[Achievements] Unknown category: " .. param ..
				". Categories: Combat, Exploration, Crafting, Social, Quests, Bestiary, Tasks, General")
			return false
		end

		local msg = "=== " .. cat .. " Achievements ===\n"
		for _, ach in ipairs(achs) do
			local status = AchievementSystem.hasAchievement(player, ach.id) and "[X]" or "[ ]"
			msg = msg .. status .. " " .. ach.name .. " (" .. ach.points .. " pts) - " .. ach.description .. "\n"
		end
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- Default: summary view
	local msg = "=== Achievement Progress ===\n"
	msg = msg .. "Unlocked: " .. unlocked .. "/" .. total ..
		" | Points: " .. points .. " | Title: " .. titleName .. "\n\n"

	-- Count per category
	local categories = {"Combat", "Exploration", "Crafting", "Social", "Quests", "Bestiary", "Tasks", "General"}
	for _, cat in ipairs(categories) do
		local catAchs = AchievementSystem.getByCategory(cat)
		local catUnlocked = 0
		for _, ach in ipairs(catAchs) do
			if AchievementSystem.hasAchievement(player, ach.id) then
				catUnlocked = catUnlocked + 1
			end
		end
		msg = msg .. cat .. ": " .. catUnlocked .. "/" .. #catAchs .. "\n"
	end

	-- Show earned titles
	local titles = AchievementSystem.getEarnedTitles(player)
	if #titles > 0 then
		msg = msg .. "\nEarned Titles:\n"
		for _, t in ipairs(titles) do
			msg = msg .. "  " .. t.name .. "\n"
		end
	end

	msg = msg .. "\nUse: !achievements <category> for details"
	msg = msg .. "\nCategories: Combat, Exploration, Crafting, Social, Quests, Bestiary, Tasks, General"
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end
