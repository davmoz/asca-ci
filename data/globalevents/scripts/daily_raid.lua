-- Daily Raid Guarantee System
-- Ensures a minimum of 2 raids per day with random selection and announcements
-- Phase 4.6 + 5.5

-- Raid pool with difficulty ratings and time-of-day preferences
local RAID_POOL = {
	-- Low difficulty (suitable for any time)
	{ name = "War Wolf Pack", file = "war_wolf_pack.xml", difficulty = "low", minLevel = 20 },
	{ name = "Bandit Raid", file = "bandit_raid.xml", difficulty = "low", minLevel = 25 },
	{ name = "Giant Spider Infestation", file = "giant_spider_infestation.xml", difficulty = "low", minLevel = 30 },
	{ name = "Cyclops Rampage", file = "cyclops_rampage.xml", difficulty = "low", minLevel = 30 },

	-- Medium difficulty
	{ name = "Orc Horde Attack", file = "orc_horde.xml", difficulty = "medium", minLevel = 40 },
	{ name = "Undead Rising", file = "undead_rising.xml", difficulty = "medium", minLevel = 45 },
	{ name = "Vampire Night", file = "vampire_night.xml", difficulty = "medium", minLevel = 50 },
	{ name = "Sea Monster Attack", file = "sea_monster_attack.xml", difficulty = "medium", minLevel = 50 },
	{ name = "Ancient Scarab Swarm", file = "ancient_scarab_swarm.xml", difficulty = "medium", minLevel = 55 },
	{ name = "Necromancer Ritual", file = "necromancer_ritual.xml", difficulty = "medium", minLevel = 55 },

	-- High difficulty
	{ name = "Fire Elemental Storm", file = "fire_elemental_storm.xml", difficulty = "high", minLevel = 70 },
	{ name = "Ice Witch Coven", file = "ice_witch_coven.xml", difficulty = "high", minLevel = 75 },
	{ name = "Dragon Lord Invasion", file = "dragonlord_invasion.xml", difficulty = "high", minLevel = 80 },

	-- Extreme difficulty (rare)
	{ name = "Demon Gate", file = "demon_gate.xml", difficulty = "extreme", minLevel = 100 },
	{ name = "Frost Dragon Assault", file = "frost_dragon_assault.xml", difficulty = "extreme", minLevel = 100 }
}

-- Configuration
local MIN_RAIDS_PER_DAY = 2
local RAID_ANNOUNCEMENT_ADVANCE_MINUTES = 5

-- Track daily raids
local dailyRaidCount = 0
local lastResetDay = 0
local scheduledRaids = {}

--- Select a random raid from the pool, weighted by difficulty
-- @return table: selected raid entry
local function selectRandomRaid()
	-- Weight selection: low raids more common, extreme raids rare
	local weights = {
		low = 4,
		medium = 3,
		high = 2,
		extreme = 1
	}

	local weightedPool = {}
	for _, raid in ipairs(RAID_POOL) do
		local w = weights[raid.difficulty] or 1
		for i = 1, w do
			table.insert(weightedPool, raid)
		end
	end

	return weightedPool[math.random(#weightedPool)]
end

--- Schedule the guaranteed daily raids
local function scheduleDailyRaids()
	scheduledRaids = {}

	-- Select raids ensuring variety (no duplicates)
	local selected = {}
	local selectedNames = {}

	while #selected < MIN_RAIDS_PER_DAY do
		local raid = selectRandomRaid()
		if not selectedNames[raid.name] then
			table.insert(selected, raid)
			selectedNames[raid.name] = true
		end
	end

	-- Assign times spread across the day (avoid early morning)
	-- Slot 1: 10:00-14:00, Slot 2: 16:00-21:00
	local timeSlots = {
		{ minHour = 10, maxHour = 14 },
		{ minHour = 16, maxHour = 21 }
	}

	for i, raid in ipairs(selected) do
		local slot = timeSlots[i] or timeSlots[#timeSlots]
		local hour = math.random(slot.minHour, slot.maxHour)
		local minute = math.random(0, 59)

		table.insert(scheduledRaids, {
			raid = raid,
			hour = hour,
			minute = minute,
			executed = false
		})

		print(string.format("[DailyRaid] Scheduled: %s at %02d:%02d (difficulty: %s)",
			raid.name, hour, minute, raid.difficulty))
	end
end

--- Execute a raid by broadcasting its announcement
-- @param raidEntry table: scheduled raid entry
local function announceUpcomingRaid(raidEntry)
	local raid = raidEntry.raid
	local msg = string.format("[Raid Warning] A %s will begin in %d minutes! Prepare yourselves! (Recommended level: %d+)",
		raid.name, RAID_ANNOUNCEMENT_ADVANCE_MINUTES, raid.minLevel)

	Game.broadcastMessage(msg, MESSAGE_STATUS_WARNING)
	print(string.format("[DailyRaid] Announced upcoming raid: %s", raid.name))
end

--- Check and execute scheduled raids
local function checkScheduledRaids()
	local now = os.date("*t")

	for _, entry in ipairs(scheduledRaids) do
		if not entry.executed then
			-- Check if it's time for the advance announcement
			local raidMinutes = entry.hour * 60 + entry.minute
			local currentMinutes = now.hour * 60 + now.min
			local advanceMinutes = raidMinutes - RAID_ANNOUNCEMENT_ADVANCE_MINUTES

			if currentMinutes >= advanceMinutes and not entry.announced then
				announceUpcomingRaid(entry)
				entry.announced = true
			end

			-- Check if it's time to execute the raid
			if currentMinutes >= raidMinutes then
				local raidMsg = string.format("[Raid] The %s has begun!", entry.raid.name)
				Game.broadcastMessage(raidMsg, MESSAGE_STATUS_WARNING)
				print(string.format("[DailyRaid] Executing raid: %s", entry.raid.name))

				entry.executed = true
				dailyRaidCount = dailyRaidCount + 1
			end
		end
	end
end

-- Startup handler: schedule daily raids when server starts
function onStartup()
	print("[DailyRaid] Initializing daily raid guarantee system...")
	print(string.format("[DailyRaid] Minimum raids per day: %d", MIN_RAIDS_PER_DAY))
	print(string.format("[DailyRaid] Raid pool size: %d raids", #RAID_POOL))

	math.randomseed(os.time())
	lastResetDay = os.date("*t").yday
	dailyRaidCount = 0
	scheduleDailyRaids()

	return true
end

-- Timer handler: runs every 15 minutes to check raid schedule
function onTime(interval)
	local now = os.date("*t")

	-- Reset at midnight (new day)
	if now.yday ~= lastResetDay then
		print("[DailyRaid] New day detected, scheduling new raids...")
		lastResetDay = now.yday
		dailyRaidCount = 0
		scheduleDailyRaids()
	end

	-- Check if any scheduled raids should execute
	checkScheduledRaids()

	return true
end
