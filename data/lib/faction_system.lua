-- ============================================================================
-- Faction / Reputation System
-- ============================================================================
-- Four factions with opposing pairs, reputation tracking, and tiered unlocks.
-- Storage layout:
--   64300  Royal Guard reputation
--   64301  Shadow Council reputation
--   64302  Arcane Circle reputation
--   64303  Wildborn reputation
-- ============================================================================

FactionSystem = {}

-- ============================================================================
-- Constants
-- ============================================================================

FactionSystem.STORAGE_BASE = 64300

-- Faction identifiers
FactionSystem.FACTION_ROYAL_GUARD    = 1
FactionSystem.FACTION_SHADOW_COUNCIL = 2
FactionSystem.FACTION_ARCANE_CIRCLE  = 3
FactionSystem.FACTION_WILDBORN       = 4

-- Opposing faction penalty: gaining rep with one faction reduces the opposing
-- faction's reputation by this fraction of the gain.
FactionSystem.OPPOSING_PENALTY_RATIO = 0.25

-- Reputation level thresholds (inclusive lower bounds)
FactionSystem.LEVEL_HOSTILE    = 1
FactionSystem.LEVEL_UNFRIENDLY = 2
FactionSystem.LEVEL_NEUTRAL    = 3
FactionSystem.LEVEL_FRIENDLY   = 4
FactionSystem.LEVEL_HONORED    = 5
FactionSystem.LEVEL_REVERED    = 6
FactionSystem.LEVEL_EXALTED    = 7

FactionSystem.LEVEL_NAMES = {
	[1] = "Hostile",
	[2] = "Unfriendly",
	[3] = "Neutral",
	[4] = "Friendly",
	[5] = "Honored",
	[6] = "Revered",
	[7] = "Exalted",
}

-- Min reputation value for each level
FactionSystem.LEVEL_THRESHOLDS = {
	{min = -1000, max =  -500, level = 1},  -- Hostile
	{min =  -499, max =    -1, level = 2},  -- Unfriendly
	{min =     0, max =   499, level = 3},  -- Neutral
	{min =   500, max =  1999, level = 4},  -- Friendly
	{min =  2000, max =  4999, level = 5},  -- Honored
	{min =  5000, max =  9999, level = 6},  -- Revered
	{min = 10000, max = 99999, level = 7},  -- Exalted
}

-- ============================================================================
-- Faction Definitions
-- ============================================================================

FactionSystem.factions = {
	[1] = {
		id       = 1,
		name     = "The Royal Guard",
		theme    = "lawful, city-focused",
		opposing = 2,
		title    = "Royal",
		storageKey = 64300,
	},
	[2] = {
		id       = 2,
		name     = "The Shadow Council",
		theme    = "stealth, underground",
		opposing = 1,
		title    = "Shadow",
		storageKey = 64301,
	},
	[3] = {
		id       = 3,
		name     = "The Arcane Circle",
		theme    = "magic, knowledge-focused",
		opposing = 4,
		title    = "Arcane",
		storageKey = 64302,
	},
	[4] = {
		id       = 4,
		name     = "The Wildborn",
		theme    = "nature, wilderness-focused",
		opposing = 3,
		title    = "Wildborn",
		storageKey = 64303,
	},
}

-- ============================================================================
-- Monster Reputation Rewards
-- ============================================================================
-- Maps monster names to {factionId, reputation gained}.
-- Killing these creatures grants reputation with the specified faction.

FactionSystem.monsterRewards = {
	-- Royal Guard: lawful enemies
	["bandit"]             = {factionId = 1, reputation = 5},
	["smuggler"]           = {factionId = 1, reputation = 5},
	["assassin"]           = {factionId = 1, reputation = 10},
	["dark monk"]          = {factionId = 1, reputation = 8},
	["renegade knight"]    = {factionId = 1, reputation = 15},

	-- Shadow Council: establishment targets
	["war wolf"]           = {factionId = 2, reputation = 5},
	["monk"]               = {factionId = 2, reputation = 5},
	["crusader"]           = {factionId = 2, reputation = 10},
	["paladin"]            = {factionId = 2, reputation = 8},
	["hero"]               = {factionId = 2, reputation = 15},

	-- Arcane Circle: magical creatures
	["bonelord"]           = {factionId = 3, reputation = 5},
	["braindeath"]         = {factionId = 3, reputation = 10},
	["elder bonelord"]     = {factionId = 3, reputation = 8},
	["warlock"]            = {factionId = 3, reputation = 15},
	["fury"]               = {factionId = 3, reputation = 12},

	-- Wildborn: unnatural abominations
	["mutated rat"]        = {factionId = 4, reputation = 5},
	["mutated bat"]        = {factionId = 4, reputation = 5},
	["slime"]              = {factionId = 4, reputation = 8},
	["nightmare"]          = {factionId = 4, reputation = 12},
	["plaguesmith"]        = {factionId = 4, reputation = 15},
}

-- ============================================================================
-- Task Reputation Rewards
-- ============================================================================
-- Flat reputation values awarded when a faction task is turned in.

FactionSystem.TASK_REPUTATION = {
	easy   = 50,
	medium = 100,
	hard   = 250,
	elite  = 500,
}

-- ============================================================================
-- Donation Reputation Rates
-- ============================================================================
-- Gold-to-reputation conversion: 1 reputation per this many gold coins.

FactionSystem.GOLD_PER_REP = 100

-- Item donations: itemId -> reputation value
FactionSystem.itemDonations = {
	-- Royal Guard values armaments
	[2376] = 20,   -- sword
	[2509] = 30,   -- steel shield

	-- Shadow Council values poisons and tools
	[2874] = 10,   -- rope
	[2546] = 15,   -- short sword

	-- Arcane Circle values spell components
	[2260] = 10,   -- blank rune
	[2170] = 25,   -- magic plate armor

	-- Wildborn values herbs and natural items
	[2006] = 5,    -- small health potion
	[5896] = 15,   -- bear paw
}

-- ============================================================================
-- Reputation Unlocks
-- ============================================================================

FactionSystem.UNLOCK_FRIENDLY_SHOP    = FactionSystem.LEVEL_FRIENDLY   -- 500+
FactionSystem.UNLOCK_HONORED_MOUNT    = FactionSystem.LEVEL_HONORED    -- 2000+
FactionSystem.UNLOCK_REVERED_TITLE    = FactionSystem.LEVEL_REVERED    -- 5000+
FactionSystem.UNLOCK_EXALTED_QUEST    = FactionSystem.LEVEL_EXALTED    -- 10000+

-- ============================================================================
-- Core Functions
-- ============================================================================

--- Returns the storage key for a given faction.
-- @param factionId number  Faction identifier (1-4)
-- @return number  Storage key
local function getStorageKey(factionId)
	local faction = FactionSystem.factions[factionId]
	if not faction then
		return nil
	end
	return faction.storageKey
end

--- Get raw reputation value for a player in a faction.
-- @param player   userdata  Player object
-- @param factionId number   Faction identifier (1-4)
-- @return number  Current reputation (default 0)
function FactionSystem.getReputation(player, factionId)
	local key = getStorageKey(factionId)
	if not key then
		return 0
	end
	local value = player:getStorageValue(key)
	if value == -1 then
		return 0
	end
	return value
end

--- Add (or subtract) reputation for a player in a faction.
-- Automatically applies the opposing-faction penalty.
-- @param player    userdata  Player object
-- @param factionId number    Faction identifier (1-4)
-- @param amount    number    Reputation to add (can be negative)
function FactionSystem.addReputation(player, factionId, amount)
	local key = getStorageKey(factionId)
	if not key then
		return
	end

	-- Apply reputation gain
	local current = FactionSystem.getReputation(player, factionId)
	local newRep = current + amount
	-- Clamp to valid range
	newRep = math.max(-1000, math.min(99999, newRep))
	player:setStorageValue(key, newRep)

	-- Apply opposing faction penalty (only when gaining positive reputation)
	if amount > 0 then
		local faction = FactionSystem.factions[factionId]
		if faction and faction.opposing then
			local opposingKey = getStorageKey(faction.opposing)
			if opposingKey then
				local oppCurrent = FactionSystem.getReputation(player, faction.opposing)
				local penalty = math.floor(amount * FactionSystem.OPPOSING_PENALTY_RATIO)
				local oppNew = math.max(-1000, oppCurrent - penalty)
				player:setStorageValue(opposingKey, oppNew)
			end
		end
	end
end

--- Determine the reputation level for a player in a faction.
-- @param player    userdata  Player object
-- @param factionId number    Faction identifier (1-4)
-- @return number  Level constant (LEVEL_HOSTILE .. LEVEL_EXALTED)
-- @return string  Level name
function FactionSystem.getReputationLevel(player, factionId)
	local rep = FactionSystem.getReputation(player, factionId)
	for _, t in ipairs(FactionSystem.LEVEL_THRESHOLDS) do
		if rep >= t.min and rep <= t.max then
			return t.level, FactionSystem.LEVEL_NAMES[t.level]
		end
	end
	-- Fallback: if above max threshold treat as Exalted
	if rep >= 10000 then
		return FactionSystem.LEVEL_EXALTED, "Exalted"
	end
	-- Below -1000 treat as Hostile
	return FactionSystem.LEVEL_HOSTILE, "Hostile"
end

--- Get the display name of a faction.
-- @param factionId number  Faction identifier (1-4)
-- @return string  Faction name or "Unknown"
function FactionSystem.getFactionName(factionId)
	local faction = FactionSystem.factions[factionId]
	if not faction then
		return "Unknown"
	end
	return faction.name
end

--- Check whether a player may access a faction's shop (Friendly+).
-- @param player    userdata  Player object
-- @param factionId number    Faction identifier (1-4)
-- @return boolean
function FactionSystem.canAccessShop(player, factionId)
	local level = FactionSystem.getReputationLevel(player, factionId)
	return level >= FactionSystem.UNLOCK_FRIENDLY_SHOP
end

--- Check whether a player may start the faction mount quest (Honored+).
-- @param player    userdata  Player object
-- @param factionId number    Faction identifier (1-4)
-- @return boolean
function FactionSystem.canAccessMountQuest(player, factionId)
	local level = FactionSystem.getReputationLevel(player, factionId)
	return level >= FactionSystem.UNLOCK_HONORED_MOUNT
end

--- Get the faction title prefix for a player (requires Revered+).
-- Returns nil if the player has not reached Revered.
-- @param player    userdata  Player object
-- @param factionId number    Faction identifier (1-4)
-- @return string|nil  Title prefix or nil
function FactionSystem.getTitle(player, factionId)
	local level = FactionSystem.getReputationLevel(player, factionId)
	if level < FactionSystem.UNLOCK_REVERED_TITLE then
		return nil
	end
	local faction = FactionSystem.factions[factionId]
	if not faction then
		return nil
	end
	return faction.title
end

--- Check whether a player may start the faction legendary quest (Exalted).
-- @param player    userdata  Player object
-- @param factionId number    Faction identifier (1-4)
-- @return boolean
function FactionSystem.canAccessLegendaryQuest(player, factionId)
	local level = FactionSystem.getReputationLevel(player, factionId)
	return level >= FactionSystem.UNLOCK_EXALTED_QUEST
end

-- ============================================================================
-- Event Helpers
-- ============================================================================

--- Called from creature scripts on kill. Checks if the killed monster grants
-- reputation and awards it to the killer.
-- @param killer userdata  Player who dealt the killing blow
-- @param monsterName string  Lowercase name of the killed creature
function FactionSystem.onKill(killer, monsterName)
	local reward = FactionSystem.monsterRewards[monsterName:lower()]
	if not reward then
		return
	end
	FactionSystem.addReputation(killer, reward.factionId, reward.reputation)
	killer:sendTextMessage(MESSAGE_STATUS_SMALL,
		string.format("You gained %d reputation with %s.",
			reward.reputation,
			FactionSystem.getFactionName(reward.factionId)))
end

--- Process a gold donation to a faction NPC.
-- @param player    userdata  Player object
-- @param factionId number    Faction identifier (1-4)
-- @param goldAmount number   Gold coins donated
-- @return number  Reputation gained
function FactionSystem.donateGold(player, factionId, goldAmount)
	local rep = math.floor(goldAmount / FactionSystem.GOLD_PER_REP)
	if rep <= 0 then
		return 0
	end
	FactionSystem.addReputation(player, factionId, rep)
	player:sendTextMessage(MESSAGE_STATUS_SMALL,
		string.format("You donated %d gold and gained %d reputation with %s.",
			goldAmount, rep,
			FactionSystem.getFactionName(factionId)))
	return rep
end

--- Process an item donation to a faction NPC.
-- @param player    userdata  Player object
-- @param factionId number    Faction identifier (1-4)
-- @param itemId    number    Item type ID
-- @return number  Reputation gained (0 if item not accepted)
function FactionSystem.donateItem(player, factionId, itemId)
	local rep = FactionSystem.itemDonations[itemId]
	if not rep then
		return 0
	end
	FactionSystem.addReputation(player, factionId, rep)
	player:sendTextMessage(MESSAGE_STATUS_SMALL,
		string.format("You donated an item and gained %d reputation with %s.",
			rep,
			FactionSystem.getFactionName(factionId)))
	return rep
end

--- Award reputation for completing a faction task.
-- @param player    userdata  Player object
-- @param factionId number    Faction identifier (1-4)
-- @param difficulty string   Task difficulty key ("easy","medium","hard","elite")
-- @return number  Reputation gained
function FactionSystem.completeTask(player, factionId, difficulty)
	local rep = FactionSystem.TASK_REPUTATION[difficulty]
	if not rep then
		rep = FactionSystem.TASK_REPUTATION.easy
	end
	FactionSystem.addReputation(player, factionId, rep)
	player:sendTextMessage(MESSAGE_STATUS_SMALL,
		string.format("Task complete! You gained %d reputation with %s.",
			rep,
			FactionSystem.getFactionName(factionId)))
	return rep
end

--- Get a formatted summary of all faction standings for a player.
-- @param player userdata  Player object
-- @return string  Multi-line summary
function FactionSystem.getSummary(player)
	local lines = {"-- Faction Standings --"}
	for id = 1, 4 do
		local rep = FactionSystem.getReputation(player, id)
		local _, levelName = FactionSystem.getReputationLevel(player, id)
		local name = FactionSystem.getFactionName(id)
		table.insert(lines, string.format("  %s: %d (%s)", name, rep, levelName))
	end
	return table.concat(lines, "\n")
end

print(">> Faction system loaded")
