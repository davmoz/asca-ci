-- ============================================================================
-- Weekly Dungeon System (Phase 5)
-- ============================================================================
-- Five themed weekly dungeons with level requirements, 7-day cooldowns,
-- boss encounters, and special loot tables.
-- Storage layout:
--   62000-62004  dungeon cooldown timestamps (one per dungeon)
--   62100-62104  dungeon completion count (lifetime)
--   62200        prerequisite quest flag (generic)
-- ============================================================================

WeeklyDungeons = {}

-- ============================================================================
-- Constants
-- ============================================================================

WeeklyDungeons.STORAGE_COOLDOWN_BASE   = 62000
WeeklyDungeons.STORAGE_COMPLETION_BASE = 62100
WeeklyDungeons.STORAGE_PREREQ_BASE     = 62200

WeeklyDungeons.COOLDOWN_SECONDS = 7 * 24 * 3600  -- 7 days

WeeklyDungeons.MIN_PARTY_SIZE = 3  -- minimum party members to enter

-- ============================================================================
-- Dungeon Definitions
-- ============================================================================

WeeklyDungeons.DUNGEONS = {
	[1] = {
		id          = 1,
		name        = "Crypts of the Damned",
		theme       = "undead",
		minLevel    = 50,
		description = "Ancient catacombs teeming with restless undead.",
		entrance    = Position(1000, 1000, 7),  -- configure per map
		exitPos     = Position(1001, 1005, 7),
		bossRoom    = Position(1000, 1020, 7),
		monsters    = {"Skeleton", "Ghoul", "Mummy", "Vampire", "Lich"},
		boss        = {
			name   = "Archlich Vrethul",
			health = 120000,
			exp    = 80000,
			loot   = {
				{id = 2160, count = 10, chance = 100},   -- crystal coins
				{id = 2195, count = 1,  chance = 15},     -- boots of haste
				{id = 2514, count = 1,  chance = 8},      -- mastermind shield
				{id = 2466, count = 1,  chance = 5},      -- golden armor
			},
		},
		prerequisite = nil,  -- no quest prerequisite
	},
	[2] = {
		id          = 2,
		name        = "Dragon's Lair",
		theme       = "dragons",
		minLevel    = 100,
		description = "A volcanic cavern where ancient dragons nest.",
		entrance    = Position(2000, 1000, 7),
		exitPos     = Position(2001, 1005, 7),
		bossRoom    = Position(2000, 1020, 7),
		monsters    = {"Dragon", "Dragon Lord", "Dragon Hatchling", "Fire Elemental"},
		boss        = {
			name   = "Elder Wyrm Kaelthas",
			health = 250000,
			exp    = 200000,
			loot   = {
				{id = 2160, count = 25, chance = 100},
				{id = 2472, count = 1,  chance = 12},     -- magic plate armor
				{id = 2436, count = 1,  chance = 10},     -- skullcrusher
				{id = 7382, count = 1,  chance = 6},      -- demonrage sword
			},
		},
		prerequisite = nil,
	},
	[3] = {
		id          = 3,
		name        = "Demon Fortress",
		theme       = "demons",
		minLevel    = 150,
		description = "A hellish stronghold ruled by an archdemon.",
		entrance    = Position(3000, 1000, 7),
		exitPos     = Position(3001, 1005, 7),
		bossRoom    = Position(3000, 1020, 7),
		monsters    = {"Demon", "Fire Devil", "Dark Torturer", "Hellhound", "Diabolic Imp"},
		boss        = {
			name   = "Archdemon Zar'goth",
			health = 500000,
			exp    = 400000,
			loot   = {
				{id = 2160, count = 50,  chance = 100},
				{id = 2400, count = 1,   chance = 10},    -- magic sword
				{id = 2470, count = 1,   chance = 8},     -- golden legs
				{id = 2522, count = 1,   chance = 5},     -- great shield
			},
		},
		prerequisite = nil,
	},
	[4] = {
		id          = 4,
		name        = "Ice Caverns",
		theme       = "ice",
		minLevel    = 80,
		description = "Frozen tunnels haunted by ice creatures from the north.",
		entrance    = Position(4000, 1000, 7),
		exitPos     = Position(4001, 1005, 7),
		bossRoom    = Position(4000, 1020, 7),
		monsters    = {"Ice Witch", "Crystal Spider", "Frost Dragon", "Ice Golem", "Winter Wolf"},
		boss        = {
			name   = "Frostlord Hrimmur",
			health = 180000,
			exp    = 120000,
			loot   = {
				{id = 2160, count = 15,  chance = 100},
				{id = 2498, count = 1,   chance = 12},    -- royal helmet
				{id = 7449, count = 1,   chance = 10},    -- crystal sword
				{id = 2471, count = 1,   chance = 6},     -- golden armor (legs variant)
			},
		},
		prerequisite = nil,
	},
	[5] = {
		id          = 5,
		name        = "Shadow Realm",
		theme       = "shadow",
		minLevel    = 200,
		description = "A dimension between worlds where shadows come alive.",
		entrance    = Position(5000, 1000, 7),
		exitPos     = Position(5001, 1005, 7),
		bossRoom    = Position(5000, 1020, 7),
		monsters    = {"Nightmare", "Plaguesmith", "Hand of Cursed Fate", "Lost Soul", "Betrayed Wraith"},
		boss        = {
			name   = "The Void Sovereign",
			health = 1000000,
			exp    = 800000,
			loot   = {
				{id = 2160, count = 100, chance = 100},
				{id = 8851, count = 1,   chance = 8},     -- fire axe (placeholder legendary)
				{id = 2472, count = 1,   chance = 10},    -- magic plate armor
				{id = 2522, count = 1,   chance = 3},     -- great shield
				{id = 2470, count = 1,   chance = 4},     -- golden legs
			},
		},
		prerequisite = nil,
	},
}

-- ============================================================================
-- Cooldown Management
-- ============================================================================

--- Check if a player's dungeon cooldown has expired.
-- @param player     Player userdata
-- @param dungeonId  integer 1-5
-- @return boolean   true if the player may enter
function WeeklyDungeons.isReady(player, dungeonId)
	local storageKey = WeeklyDungeons.STORAGE_COOLDOWN_BASE + (dungeonId - 1)
	local lastEntry = player:getStorageValue(storageKey)
	if lastEntry <= 0 then
		return true
	end
	return os.time() - lastEntry >= WeeklyDungeons.COOLDOWN_SECONDS
end

--- Get the remaining cooldown in seconds (0 if ready).
function WeeklyDungeons.getRemainingCooldown(player, dungeonId)
	local storageKey = WeeklyDungeons.STORAGE_COOLDOWN_BASE + (dungeonId - 1)
	local lastEntry = player:getStorageValue(storageKey)
	if lastEntry <= 0 then
		return 0
	end
	local remaining = (lastEntry + WeeklyDungeons.COOLDOWN_SECONDS) - os.time()
	return math.max(0, remaining)
end

--- Start the cooldown for a player after entering a dungeon.
function WeeklyDungeons.startCooldown(player, dungeonId)
	local storageKey = WeeklyDungeons.STORAGE_COOLDOWN_BASE + (dungeonId - 1)
	player:setStorageValue(storageKey, os.time())
end

--- Increment lifetime completion counter.
function WeeklyDungeons.recordCompletion(player, dungeonId)
	local storageKey = WeeklyDungeons.STORAGE_COMPLETION_BASE + (dungeonId - 1)
	local current = math.max(0, player:getStorageValue(storageKey))
	player:setStorageValue(storageKey, current + 1)
end

-- ============================================================================
-- Entry Requirements
-- ============================================================================

--- Full entry check: level, cooldown, party size, and optional prerequisite.
-- @param player     Player userdata
-- @param dungeonId  integer 1-5
-- @return boolean, string
function WeeklyDungeons.canEnter(player, dungeonId)
	local dungeon = WeeklyDungeons.DUNGEONS[dungeonId]
	if not dungeon then
		return false, "Unknown dungeon."
	end

	-- Level check
	if player:getLevel() < dungeon.minLevel then
		return false, string.format("You need level %d to enter %s.", dungeon.minLevel, dungeon.name)
	end

	-- Cooldown check
	if not WeeklyDungeons.isReady(player, dungeonId) then
		local remaining = WeeklyDungeons.getRemainingCooldown(player, dungeonId)
		local days  = math.floor(remaining / 86400)
		local hours = math.floor((remaining % 86400) / 3600)
		return false, string.format(
			"%s is on cooldown. Resets in %dd %dh.",
			dungeon.name, days, hours
		)
	end

	-- Party size check
	local party = player:getParty()
	local memberCount = 1
	if party then
		memberCount = #party:getMembers() + 1  -- +1 for leader
	end
	if memberCount < WeeklyDungeons.MIN_PARTY_SIZE then
		return false, string.format(
			"You need at least %d party members to enter %s (have %d).",
			WeeklyDungeons.MIN_PARTY_SIZE, dungeon.name, memberCount
		)
	end

	-- Prerequisite quest check
	if dungeon.prerequisite then
		local questVal = player:getStorageValue(WeeklyDungeons.STORAGE_PREREQ_BASE + dungeonId)
		if questVal < 1 then
			return false, string.format("You must complete a prerequisite quest before entering %s.", dungeon.name)
		end
	end

	return true, "All requirements met."
end

-- ============================================================================
-- Teleportation
-- ============================================================================

--- Teleport a full party into the dungeon and start cooldowns.
-- @param leader     Player (party leader)
-- @param dungeonId  integer 1-5
-- @return boolean, string
function WeeklyDungeons.enterDungeon(leader, dungeonId)
	local dungeon = WeeklyDungeons.DUNGEONS[dungeonId]
	if not dungeon then
		return false, "Unknown dungeon."
	end

	local party = leader:getParty()
	local members = {}
	if party then
		members = party:getMembers()
		table.insert(members, leader)
	else
		members = {leader}
	end

	-- Validate every member
	for _, member in ipairs(members) do
		local ok, msg = WeeklyDungeons.canEnter(member, dungeonId)
		if not ok then
			return false, string.format("%s cannot enter: %s", member:getName(), msg)
		end
	end

	-- Teleport all members and start cooldowns
	for _, member in ipairs(members) do
		member:teleportTo(dungeon.entrance)
		member:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		WeeklyDungeons.startCooldown(member, dungeonId)
		member:sendTextMessage(MESSAGE_INFO_DESCR,
			string.format("You have entered %s. Defeat the boss to claim your rewards!", dungeon.name))
	end

	return true, string.format("Party entered %s!", dungeon.name)
end

-- ============================================================================
-- Boss Loot
-- ============================================================================

--- Roll loot from a dungeon boss and add to a player's inventory.
-- @param player     Player userdata
-- @param dungeonId  integer 1-5
function WeeklyDungeons.rollBossLoot(player, dungeonId)
	local dungeon = WeeklyDungeons.DUNGEONS[dungeonId]
	if not dungeon or not dungeon.boss then
		return
	end

	local lootGained = {}
	for _, entry in ipairs(dungeon.boss.loot) do
		local roll = math.random(1, 100)
		if roll <= entry.chance then
			player:addItem(entry.id, entry.count)
			local itemType = ItemType(entry.id)
			lootGained[#lootGained + 1] = string.format("%dx %s", entry.count, itemType:getName())
		end
	end

	player:addExperience(dungeon.boss.exp, true)
	WeeklyDungeons.recordCompletion(player, dungeonId)

	if #lootGained > 0 then
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			string.format("Boss loot: %s", table.concat(lootGained, ", ")))
	else
		player:sendTextMessage(MESSAGE_INFO_DESCR, "The boss dropped nothing of value this time.")
	end
end

-- ============================================================================
-- Display Helpers
-- ============================================================================

--- List all weekly dungeons with status for a given player.
function WeeklyDungeons.getDungeonList(player)
	local lines = {"=== Weekly Dungeons ==="}
	for _, dungeon in ipairs(WeeklyDungeons.DUNGEONS) do
		local status
		if player:getLevel() < dungeon.minLevel then
			status = string.format("LOCKED (need lvl %d)", dungeon.minLevel)
		elseif not WeeklyDungeons.isReady(player, dungeon.id) then
			local rem = WeeklyDungeons.getRemainingCooldown(player, dungeon.id)
			local d = math.floor(rem / 86400)
			local h = math.floor((rem % 86400) / 3600)
			status = string.format("COOLDOWN (%dd %dh)", d, h)
		else
			status = "AVAILABLE"
		end

		local completions = math.max(0, player:getStorageValue(
			WeeklyDungeons.STORAGE_COMPLETION_BASE + (dungeon.id - 1)))

		lines[#lines + 1] = string.format(
			"%d. %s [%s] (Lvl %d+, %s) - Completed: %d | Boss: %s",
			dungeon.id, dungeon.name, dungeon.theme,
			dungeon.minLevel, status, completions, dungeon.boss.name
		)
	end
	lines[#lines + 1] = string.format("\nParty of %d+ required to enter.", WeeklyDungeons.MIN_PARTY_SIZE)
	return table.concat(lines, "\n")
end

--- Get formatted weekly reset information.
function WeeklyDungeons.getResetInfo()
	return "Dungeon cooldowns reset 7 days after your last entry to each dungeon."
end
