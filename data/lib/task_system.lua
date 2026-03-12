-- ============================================================================
-- Hunter's Guild Task System (Phase 4)
-- ============================================================================
-- Provides hunting tasks across 5 difficulty tiers with kill tracking,
-- rewards, task points, and a daily active-task limit.
-- Storage layout:
--   50000-50999  task state (0=not started, 1=active, 2=completed)
--   51000-51999  task kill progress
--   52000        active task count
--   52001        total task points earned
--   52002        daily task reset timestamp
-- ============================================================================

TaskSystem = {}

-- ============================================================================
-- Constants
-- ============================================================================

TaskSystem.STORAGE_STATE_BASE    = 50000
TaskSystem.STORAGE_PROGRESS_BASE = 51000
TaskSystem.STORAGE_ACTIVE_COUNT  = 52000
TaskSystem.STORAGE_TASK_POINTS   = 52001
TaskSystem.STORAGE_DAILY_RESET   = 52002

TaskSystem.MAX_ACTIVE_TASKS = 3

TaskSystem.STATE_NONE      = 0
TaskSystem.STATE_ACTIVE    = 1
TaskSystem.STATE_COMPLETED = 2

-- Task categories
TaskSystem.CATEGORY_HUNTING   = "hunting"
TaskSystem.CATEGORY_BOSS      = "boss"
TaskSystem.CATEGORY_GATHERING = "gathering"

-- Difficulty tiers
TaskSystem.TIER_BEGINNER     = 1  -- lvl 1-30
TaskSystem.TIER_INTERMEDIATE = 2  -- lvl 30-80
TaskSystem.TIER_ADVANCED     = 3  -- lvl 80-150
TaskSystem.TIER_EXPERT       = 4  -- lvl 150-250
TaskSystem.TIER_MASTER       = 5  -- lvl 250+

TaskSystem.TIER_NAMES = {
	[1] = "Beginner",
	[2] = "Intermediate",
	[3] = "Advanced",
	[4] = "Expert",
	[5] = "Master",
}

TaskSystem.TIER_LEVEL_RANGES = {
	[1] = {min = 1,   max = 30},
	[2] = {min = 30,  max = 80},
	[3] = {min = 80,  max = 150},
	[4] = {min = 150, max = 250},
	[5] = {min = 250, max = 9999},
}

-- ============================================================================
-- Task Definitions (50+ tasks)
-- ============================================================================
-- Fields: id, name, tier, category, monster, killCount, xpReward, goldReward,
--         itemReward (optional: {id, count}), taskPoints, description

TaskSystem.tasks = {
	-- ========================================================================
	-- BEGINNER TASKS (Tier 1, lvl 1-30)
	-- ========================================================================
	{id = 1,  name = "Rat Exterminator",       tier = 1, category = "hunting",   monster = "rat",              killCount = 50,  xpReward = 500,    goldReward = 200,   taskPoints = 1, description = "Clear the sewers of rats."},
	{id = 2,  name = "Spider Squasher",         tier = 1, category = "hunting",   monster = "spider",           killCount = 50,  xpReward = 600,    goldReward = 250,   taskPoints = 1, description = "Eliminate spiders from the caves."},
	{id = 3,  name = "Bug Buster",              tier = 1, category = "hunting",   monster = "bug",              killCount = 40,  xpReward = 400,    goldReward = 150,   taskPoints = 1, description = "Squash the oversized bugs."},
	{id = 4,  name = "Wolf Hunter",             tier = 1, category = "hunting",   monster = "wolf",             killCount = 40,  xpReward = 700,    goldReward = 300,   taskPoints = 1, description = "Thin the wolf population."},
	{id = 5,  name = "Troll Trouble",           tier = 1, category = "hunting",   monster = "troll",            killCount = 50,  xpReward = 800,    goldReward = 350,   taskPoints = 1, description = "Deal with the troll menace."},
	{id = 6,  name = "Skeleton Smasher",        tier = 1, category = "hunting",   monster = "skeleton",         killCount = 60,  xpReward = 900,    goldReward = 400,   taskPoints = 1, description = "Put the undead to rest."},
	{id = 7,  name = "Rotworm Removal",         tier = 1, category = "hunting",   monster = "rotworm",          killCount = 50,  xpReward = 750,    goldReward = 300,   taskPoints = 1, description = "Clear rotworm tunnels."},
	{id = 8,  name = "Wasp Warden",             tier = 1, category = "hunting",   monster = "wasp",             killCount = 40,  xpReward = 500,    goldReward = 200,   taskPoints = 1, description = "Destroy the wasp nests."},
	{id = 9,  name = "Snake Slayer",            tier = 1, category = "hunting",   monster = "snake",            killCount = 50,  xpReward = 450,    goldReward = 180,   taskPoints = 1, description = "Clear the snakes from the path."},
	{id = 10, name = "Minotaur Patrol",         tier = 1, category = "hunting",   monster = "minotaur",         killCount = 40,  xpReward = 1000,   goldReward = 500,   taskPoints = 2, description = "Patrol the minotaur territory."},

	-- ========================================================================
	-- INTERMEDIATE TASKS (Tier 2, lvl 30-80)
	-- ========================================================================
	{id = 11, name = "Orc Offensive",           tier = 2, category = "hunting",   monster = "orc",              killCount = 80,  xpReward = 3000,   goldReward = 1200,  taskPoints = 2, description = "Push back the orc raiders."},
	{id = 12, name = "Cyclops Crusher",         tier = 2, category = "hunting",   monster = "cyclops",          killCount = 60,  xpReward = 4000,   goldReward = 1500,  taskPoints = 2, description = "Defeat the one-eyed giants."},
	{id = 13, name = "Dragon Hatchling Hunt",   tier = 2, category = "hunting",   monster = "dragon hatchling", killCount = 50,  xpReward = 3500,   goldReward = 1300,  taskPoints = 2, description = "Cull the young dragons."},
	{id = 14, name = "Dwarf Defender",          tier = 2, category = "hunting",   monster = "dwarf guard",      killCount = 70,  xpReward = 3800,   goldReward = 1400,  taskPoints = 2, description = "Defend against the dwarf incursion."},
	{id = 15, name = "Amazon Ambush",           tier = 2, category = "hunting",   monster = "amazon",           killCount = 80,  xpReward = 3200,   goldReward = 1100,  taskPoints = 2, description = "Repel the amazon war band."},
	{id = 16, name = "Elf Elimination",         tier = 2, category = "hunting",   monster = "elf arcanist",     killCount = 60,  xpReward = 4200,   goldReward = 1600,  taskPoints = 2, description = "Deal with rogue elf arcanists."},
	{id = 17, name = "Mummy Masher",            tier = 2, category = "hunting",   monster = "mummy",            killCount = 50,  xpReward = 3600,   goldReward = 1300,  taskPoints = 2, description = "Destroy the ancient mummies."},
	{id = 18, name = "Necromancer Nemesis",      tier = 2, category = "hunting",   monster = "necromancer",      killCount = 40,  xpReward = 5000,   goldReward = 2000,  taskPoints = 3, description = "Stop the dark necromancers."},
	{id = 19, name = "Giant Spider Slayer",     tier = 2, category = "hunting",   monster = "giant spider",     killCount = 50,  xpReward = 4500,   goldReward = 1800,  taskPoints = 3, description = "Clear giant spider lairs."},
	{id = 20, name = "Bonebeast Breaker",       tier = 2, category = "hunting",   monster = "bonebeast",        killCount = 60,  xpReward = 4800,   goldReward = 1900,  taskPoints = 3, description = "Shatter the bonebeasts."},

	-- ========================================================================
	-- ADVANCED TASKS (Tier 3, lvl 80-150)
	-- ========================================================================
	{id = 21, name = "Dragon Slayer",           tier = 3, category = "hunting",   monster = "dragon",           killCount = 100, xpReward = 15000,  goldReward = 5000,  taskPoints = 4, description = "Slay the fearsome dragons."},
	{id = 22, name = "Dragon Lord Purge",       tier = 3, category = "hunting",   monster = "dragon lord",      killCount = 80,  xpReward = 20000,  goldReward = 7000,  taskPoints = 5, description = "Eliminate the dragon lords."},
	{id = 23, name = "Hydra Hunter",            tier = 3, category = "hunting",   monster = "hydra",            killCount = 80,  xpReward = 22000,  goldReward = 7500,  taskPoints = 5, description = "Cut down the multi-headed hydras."},
	{id = 24, name = "Behemoth Bane",           tier = 3, category = "hunting",   monster = "behemoth",         killCount = 60,  xpReward = 25000,  goldReward = 8000,  taskPoints = 5, description = "Topple the mighty behemoths."},
	{id = 25, name = "Serpent Spawn Sweep",     tier = 3, category = "hunting",   monster = "serpent spawn",    killCount = 70,  xpReward = 23000,  goldReward = 7500,  taskPoints = 5, description = "Eradicate the serpent spawns."},
	{id = 26, name = "Warlock Warfare",         tier = 3, category = "hunting",   monster = "warlock",          killCount = 60,  xpReward = 28000,  goldReward = 9000,  taskPoints = 6, description = "Defeat the powerful warlocks."},
	{id = 27, name = "Banshee Banisher",        tier = 3, category = "hunting",   monster = "banshee",          killCount = 60,  xpReward = 18000,  goldReward = 6000,  taskPoints = 4, description = "Silence the wailing banshees."},
	{id = 28, name = "Hero Hacker",             tier = 3, category = "hunting",   monster = "hero",             killCount = 70,  xpReward = 20000,  goldReward = 6500,  taskPoints = 5, description = "Defeat the corrupted heroes."},
	{id = 29, name = "Medusa Slayer",           tier = 3, category = "hunting",   monster = "medusa",           killCount = 60,  xpReward = 24000,  goldReward = 8000,  taskPoints = 5, description = "Slay the petrifying medusas."},
	{id = 30, name = "Wyrm Wrecker",            tier = 3, category = "hunting",   monster = "wyrm",             killCount = 80,  xpReward = 21000,  goldReward = 7000,  taskPoints = 5, description = "Bring down the wyrms."},

	-- ========================================================================
	-- EXPERT TASKS (Tier 4, lvl 150-250)
	-- ========================================================================
	{id = 31, name = "Demon Destroyer",         tier = 4, category = "hunting",   monster = "demon",            killCount = 100, xpReward = 60000,  goldReward = 20000, taskPoints = 8,  description = "Purge the demons from this world."},
	{id = 32, name = "Fury Finisher",           tier = 4, category = "hunting",   monster = "fury",             killCount = 80,  xpReward = 45000,  goldReward = 15000, taskPoints = 7,  description = "Extinguish the raging furies."},
	{id = 33, name = "Hellhound Havoc",         tier = 4, category = "hunting",   monster = "hellhound",        killCount = 80,  xpReward = 50000,  goldReward = 16000, taskPoints = 7,  description = "Put down the hellhounds."},
	{id = 34, name = "Undead Dragon Doom",      tier = 4, category = "hunting",   monster = "undead dragon",    killCount = 60,  xpReward = 55000,  goldReward = 18000, taskPoints = 8,  description = "Destroy the undead dragons."},
	{id = 35, name = "Nightmare Purge",         tier = 4, category = "hunting",   monster = "nightmare",        killCount = 80,  xpReward = 48000,  goldReward = 15000, taskPoints = 7,  description = "Cleanse the nightmares."},
	{id = 36, name = "Ghastly Dragon Hunt",     tier = 4, category = "hunting",   monster = "ghastly dragon",   killCount = 70,  xpReward = 52000,  goldReward = 17000, taskPoints = 8,  description = "Slay the ghastly dragons."},
	{id = 37, name = "Hellfire Fighter",        tier = 4, category = "hunting",   monster = "hellfire fighter",  killCount = 70,  xpReward = 50000,  goldReward = 16000, taskPoints = 7,  description = "Defeat the hellfire fighters."},
	{id = 38, name = "Plaguesmith Purge",       tier = 4, category = "hunting",   monster = "plaguesmith",      killCount = 60,  xpReward = 55000,  goldReward = 18000, taskPoints = 8,  description = "Eliminate the plaguesmiths."},
	{id = 39, name = "Lost Soul Reaper",        tier = 4, category = "hunting",   monster = "lost soul",        killCount = 80,  xpReward = 46000,  goldReward = 14000, taskPoints = 7,  description = "Release the lost souls."},
	{id = 40, name = "Juggernaut Justice",      tier = 4, category = "hunting",   monster = "juggernaut",       killCount = 50,  xpReward = 65000,  goldReward = 22000, taskPoints = 9,  description = "Bring down the juggernauts."},

	-- ========================================================================
	-- MASTER TASKS (Tier 5, lvl 250+)
	-- ========================================================================
	{id = 41, name = "Ferumbras' Minions",      tier = 5, category = "hunting",   monster = "dark torturer",    killCount = 100, xpReward = 100000, goldReward = 35000, taskPoints = 12, description = "Destroy Ferumbras' dark torturers."},
	{id = 42, name = "Grim Reaper Reckoning",   tier = 5, category = "hunting",   monster = "grim reaper",      killCount = 80,  xpReward = 120000, goldReward = 40000, taskPoints = 14, description = "Defeat the grim reapers."},
	{id = 43, name = "Hand of Cursed Fate",     tier = 5, category = "hunting",   monster = "hand of cursed fate", killCount = 80, xpReward = 110000, goldReward = 38000, taskPoints = 13, description = "Sever the hands of cursed fate."},
	{id = 44, name = "Defiler Destruction",     tier = 5, category = "hunting",   monster = "defiler",          killCount = 70,  xpReward = 115000, goldReward = 39000, taskPoints = 13, description = "Purify the vile defilers."},
	{id = 45, name = "Destroyer Decimation",    tier = 5, category = "hunting",   monster = "destroyer",        killCount = 80,  xpReward = 105000, goldReward = 36000, taskPoints = 12, description = "Smash the destroyers."},

	-- ========================================================================
	-- BOSS TASKS (various tiers)
	-- ========================================================================
	{id = 46, name = "The Horned Fox",          tier = 2, category = "boss",      monster = "the horned fox",   killCount = 1,   xpReward = 8000,   goldReward = 3000,  taskPoints = 5,  description = "Slay The Horned Fox."},
	{id = 47, name = "Demodras Must Fall",      tier = 3, category = "boss",      monster = "demodras",         killCount = 1,   xpReward = 30000,  goldReward = 10000, taskPoints = 8,  description = "Kill the dragon Demodras."},
	{id = 48, name = "Orshabaal's Demise",      tier = 4, category = "boss",      monster = "orshabaal",        killCount = 1,   xpReward = 80000,  goldReward = 30000, taskPoints = 15, description = "Defeat the arch-demon Orshabaal."},
	{id = 49, name = "Morgaroth Slain",         tier = 5, category = "boss",      monster = "morgaroth",        killCount = 1,   xpReward = 150000, goldReward = 50000, taskPoints = 20, description = "Slay the demon lord Morgaroth."},
	{id = 50, name = "Ferumbras Vanquished",    tier = 5, category = "boss",      monster = "ferumbras",        killCount = 1,   xpReward = 200000, goldReward = 75000, taskPoints = 25, description = "Vanquish the sorcerer Ferumbras."},

	-- ========================================================================
	-- GATHERING TASKS (collect drops)
	-- ========================================================================
	{id = 51, name = "Minotaur Leather",        tier = 1, category = "gathering", monster = "minotaur",         killCount = 30,  xpReward = 800,    goldReward = 400,   taskPoints = 2,  itemReward = {id = 2195, count = 1}, description = "Collect minotaur leather (kill minotaurs)."},
	{id = 52, name = "Dragon Scale Collector",   tier = 3, category = "gathering", monster = "dragon",           killCount = 50,  xpReward = 12000,  goldReward = 4000,  taskPoints = 4,  itemReward = {id = 2195, count = 3}, description = "Gather dragon scales (kill dragons)."},
	{id = 53, name = "Demon Horn Harvest",       tier = 4, category = "gathering", monster = "demon",            killCount = 40,  xpReward = 40000,  goldReward = 15000, taskPoints = 8,  itemReward = {id = 2195, count = 5}, description = "Harvest demon horns (kill demons)."},
	{id = 54, name = "Cyclops Toe Collection",   tier = 2, category = "gathering", monster = "cyclops",          killCount = 40,  xpReward = 3000,   goldReward = 1000,  taskPoints = 2,  description = "Collect cyclops toes (kill cyclops)."},
	{id = 55, name = "Ape Fur Procurement",      tier = 2, category = "gathering", monster = "kongra",           killCount = 50,  xpReward = 3500,   goldReward = 1200,  taskPoints = 2,  description = "Procure ape fur (kill kongra)."},
}

-- Build a lookup table by ID for fast access
TaskSystem.tasksById = {}
for _, task in ipairs(TaskSystem.tasks) do
	TaskSystem.tasksById[task.id] = task
end

-- Build a lookup table by monster name (lowercase) for kill tracking
TaskSystem.tasksByMonster = {}
for _, task in ipairs(TaskSystem.tasks) do
	local key = task.monster:lower()
	if not TaskSystem.tasksByMonster[key] then
		TaskSystem.tasksByMonster[key] = {}
	end
	table.insert(TaskSystem.tasksByMonster[key], task)
end

-- ============================================================================
-- Storage Helpers
-- ============================================================================

function TaskSystem.getTaskState(player, taskId)
	local v = player:getStorageValue(TaskSystem.STORAGE_STATE_BASE + taskId)
	if v < 0 then return TaskSystem.STATE_NONE end
	return v
end

function TaskSystem.setTaskState(player, taskId, state)
	player:setStorageValue(TaskSystem.STORAGE_STATE_BASE + taskId, state)
end

function TaskSystem.getTaskProgress(player, taskId)
	local v = player:getStorageValue(TaskSystem.STORAGE_PROGRESS_BASE + taskId)
	if v < 0 then return 0 end
	return v
end

function TaskSystem.setTaskProgress(player, taskId, value)
	player:setStorageValue(TaskSystem.STORAGE_PROGRESS_BASE + taskId, value)
end

function TaskSystem.getActiveTaskCount(player)
	local v = player:getStorageValue(TaskSystem.STORAGE_ACTIVE_COUNT)
	if v < 0 then return 0 end
	return v
end

function TaskSystem.setActiveTaskCount(player, count)
	player:setStorageValue(TaskSystem.STORAGE_ACTIVE_COUNT, count)
end

function TaskSystem.getTaskPoints(player)
	local v = player:getStorageValue(TaskSystem.STORAGE_TASK_POINTS)
	if v < 0 then return 0 end
	return v
end

function TaskSystem.addTaskPoints(player, points)
	local current = TaskSystem.getTaskPoints(player)
	player:setStorageValue(TaskSystem.STORAGE_TASK_POINTS, current + points)
end

-- ============================================================================
-- Core Functions
-- ============================================================================

--- Get the tier a player qualifies for based on level.
function TaskSystem.getPlayerTier(player)
	local level = player:getLevel()
	for tier = 5, 1, -1 do
		if level >= TaskSystem.TIER_LEVEL_RANGES[tier].min then
			return tier
		end
	end
	return 1
end

--- Return a list of tasks available to a player (matching tier, not yet completed or active).
function TaskSystem.getAvailableTasks(player)
	local maxTier = TaskSystem.getPlayerTier(player)
	local available = {}
	for _, task in ipairs(TaskSystem.tasks) do
		if task.tier <= maxTier then
			local state = TaskSystem.getTaskState(player, task.id)
			if state == TaskSystem.STATE_NONE then
				table.insert(available, task)
			end
		end
	end
	return available
end

--- Return a list of currently active tasks for a player.
function TaskSystem.getActiveTasks(player)
	local active = {}
	for _, task in ipairs(TaskSystem.tasks) do
		if TaskSystem.getTaskState(player, task.id) == TaskSystem.STATE_ACTIVE then
			table.insert(active, task)
		end
	end
	return active
end

--- Accept a task. Returns true on success, or false and an error message.
function TaskSystem.acceptTask(player, taskId)
	local task = TaskSystem.tasksById[taskId]
	if not task then
		return false, "Task not found."
	end

	local state = TaskSystem.getTaskState(player, taskId)
	if state == TaskSystem.STATE_ACTIVE then
		return false, "You already have this task active."
	end
	if state == TaskSystem.STATE_COMPLETED then
		return false, "You have already completed this task."
	end

	local level = player:getLevel()
	local range = TaskSystem.TIER_LEVEL_RANGES[task.tier]
	if level < range.min then
		return false, "You need to be at least level " .. range.min .. " for this task."
	end

	local activeCount = TaskSystem.getActiveTaskCount(player)
	if activeCount >= TaskSystem.MAX_ACTIVE_TASKS then
		return false, "You already have " .. TaskSystem.MAX_ACTIVE_TASKS .. " active tasks. Complete or cancel one first."
	end

	TaskSystem.setTaskState(player, taskId, TaskSystem.STATE_ACTIVE)
	TaskSystem.setTaskProgress(player, taskId, 0)
	TaskSystem.setActiveTaskCount(player, activeCount + 1)

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"[Task] Accepted: " .. task.name .. " - Kill " .. task.killCount .. " " .. task.monster .. ".")
	return true
end

--- Record a kill for a monster. Called from the kill tracker creature script.
-- Returns a list of {task, completed} pairs for any tasks affected.
function TaskSystem.onKill(player, monsterName)
	local key = monsterName:lower()
	local taskList = TaskSystem.tasksByMonster[key]
	if not taskList then
		return {}
	end

	local results = {}
	for _, task in ipairs(taskList) do
		if TaskSystem.getTaskState(player, task.id) == TaskSystem.STATE_ACTIVE then
			local progress = TaskSystem.getTaskProgress(player, task.id) + 1
			TaskSystem.setTaskProgress(player, task.id, progress)

			local completed = false
			if progress >= task.killCount then
				completed = true
			else
				-- Progress notification every 10% or every 10 kills for small tasks
				local interval = math.max(1, math.floor(task.killCount / 10))
				if progress % interval == 0 then
					player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
						"[Task] " .. task.name .. ": " .. progress .. "/" .. task.killCount .. " kills.")
				end
			end

			table.insert(results, {task = task, completed = completed})
		end
	end
	return results
end

--- Complete a task and award rewards.
function TaskSystem.completeTask(player, taskId)
	local task = TaskSystem.tasksById[taskId]
	if not task then
		return false, "Task not found."
	end

	if TaskSystem.getTaskState(player, taskId) ~= TaskSystem.STATE_ACTIVE then
		return false, "This task is not active."
	end

	local progress = TaskSystem.getTaskProgress(player, taskId)
	if progress < task.killCount then
		return false, "Task not yet complete: " .. progress .. "/" .. task.killCount .. " kills."
	end

	-- Mark completed
	TaskSystem.setTaskState(player, taskId, TaskSystem.STATE_COMPLETED)
	local activeCount = TaskSystem.getActiveTaskCount(player)
	TaskSystem.setActiveTaskCount(player, math.max(0, activeCount - 1))

	-- Award rewards
	player:addExperience(task.xpReward, false)
	player:addMoney(task.goldReward)
	TaskSystem.addTaskPoints(player, task.taskPoints)

	if task.itemReward then
		player:addItem(task.itemReward.id, task.itemReward.count)
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
		"[Task] Completed: " .. task.name .. "! Rewards: " ..
		task.xpReward .. " XP, " .. task.goldReward .. " gold, " ..
		task.taskPoints .. " task points.")

	return true
end

--- Cancel an active task (resets progress).
function TaskSystem.cancelTask(player, taskId)
	local task = TaskSystem.tasksById[taskId]
	if not task then
		return false, "Task not found."
	end

	if TaskSystem.getTaskState(player, taskId) ~= TaskSystem.STATE_ACTIVE then
		return false, "This task is not active."
	end

	TaskSystem.setTaskState(player, taskId, TaskSystem.STATE_NONE)
	TaskSystem.setTaskProgress(player, taskId, 0)
	local activeCount = TaskSystem.getActiveTaskCount(player)
	TaskSystem.setActiveTaskCount(player, math.max(0, activeCount - 1))

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"[Task] Cancelled: " .. task.name .. ". Progress has been reset.")
	return true
end
