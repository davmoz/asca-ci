-- ============================================================================
-- Bestiary System (Phase 4)
-- ============================================================================
-- Tracks per-creature kill counts and unlocks progressive information tiers.
-- Storage layout:
--   53000-53999  kill counts per creature (indexed by creature hash)
--   54000        total charm points
-- ============================================================================

Bestiary = {}

-- ============================================================================
-- Constants
-- ============================================================================

Bestiary.STORAGE_KILLS_BASE  = 53000
Bestiary.STORAGE_CHARM_POINTS = 54000

-- Maximum number of distinct creatures we can track (storage key range)
Bestiary.MAX_CREATURES = 999

-- Unlock tiers
Bestiary.TIER_NONE     = 0
Bestiary.TIER_BASIC    = 1   -- 10 kills: name + look
Bestiary.TIER_DETAILED = 2   -- 100 kills: loot table
Bestiary.TIER_COMPLETE = 3   -- 500 kills: weaknesses/resistances + charm points

Bestiary.TIER_THRESHOLDS = {
	[1] = 10,
	[2] = 100,
	[3] = 500,
}

Bestiary.TIER_NAMES = {
	[0] = "Unknown",
	[1] = "Basic",
	[2] = "Detailed",
	[3] = "Complete",
}

-- Charm points awarded at each tier unlock
Bestiary.CHARM_REWARDS = {
	[1] = 1,   -- Basic unlock
	[2] = 3,   -- Detailed unlock
	[3] = 10,  -- Complete unlock
}

-- ============================================================================
-- Creature Registry
-- ============================================================================
-- Maps creature names to a stable numeric index for storage.
-- Add creatures here as needed. The index must remain stable across updates.

Bestiary.creatures = {
	-- Beginner creatures
	["rat"]              = {index = 1,   category = "Vermin",    difficulty = "Trivial",   charmBonus = 5},
	["cave rat"]         = {index = 2,   category = "Vermin",    difficulty = "Trivial",   charmBonus = 5},
	["spider"]           = {index = 3,   category = "Vermin",    difficulty = "Trivial",   charmBonus = 5},
	["bug"]              = {index = 4,   category = "Vermin",    difficulty = "Trivial",   charmBonus = 5},
	["wolf"]             = {index = 5,   category = "Mammals",   difficulty = "Easy",      charmBonus = 10},
	["bear"]             = {index = 6,   category = "Mammals",   difficulty = "Easy",      charmBonus = 10},
	["troll"]            = {index = 7,   category = "Humanoids", difficulty = "Easy",      charmBonus = 10},
	["skeleton"]         = {index = 8,   category = "Undead",    difficulty = "Easy",      charmBonus = 10},
	["rotworm"]          = {index = 9,   category = "Vermin",    difficulty = "Easy",      charmBonus = 10},
	["wasp"]             = {index = 10,  category = "Vermin",    difficulty = "Trivial",   charmBonus = 5},
	["snake"]            = {index = 11,  category = "Reptiles",  difficulty = "Trivial",   charmBonus = 5},
	["minotaur"]         = {index = 12,  category = "Humanoids", difficulty = "Easy",      charmBonus = 10},
	["ghoul"]            = {index = 13,  category = "Undead",    difficulty = "Easy",      charmBonus = 10},
	["poison spider"]    = {index = 14,  category = "Vermin",    difficulty = "Easy",      charmBonus = 10},
	["orc"]              = {index = 15,  category = "Humanoids", difficulty = "Easy",      charmBonus = 10},

	-- Intermediate creatures
	["cyclops"]          = {index = 16,  category = "Giants",    difficulty = "Medium",    charmBonus = 15},
	["dragon hatchling"] = {index = 17,  category = "Dragons",   difficulty = "Medium",    charmBonus = 15},
	["dwarf guard"]      = {index = 18,  category = "Humanoids", difficulty = "Medium",    charmBonus = 15},
	["amazon"]           = {index = 19,  category = "Humanoids", difficulty = "Medium",    charmBonus = 15},
	["elf arcanist"]     = {index = 20,  category = "Humanoids", difficulty = "Medium",    charmBonus = 15},
	["mummy"]            = {index = 21,  category = "Undead",    difficulty = "Medium",    charmBonus = 15},
	["necromancer"]      = {index = 22,  category = "Humans",    difficulty = "Medium",    charmBonus = 20},
	["giant spider"]     = {index = 23,  category = "Vermin",    difficulty = "Medium",    charmBonus = 20},
	["bonebeast"]        = {index = 24,  category = "Undead",    difficulty = "Medium",    charmBonus = 20},
	["vampire"]          = {index = 25,  category = "Undead",    difficulty = "Medium",    charmBonus = 20},
	["kongra"]           = {index = 26,  category = "Mammals",   difficulty = "Medium",    charmBonus = 15},
	["witch"]            = {index = 27,  category = "Humans",    difficulty = "Medium",    charmBonus = 15},
	["beholder"]         = {index = 28,  category = "Magical",   difficulty = "Medium",    charmBonus = 20},
	["wyvern"]           = {index = 29,  category = "Reptiles",  difficulty = "Medium",    charmBonus = 20},
	["ancient scarab"]   = {index = 30,  category = "Vermin",    difficulty = "Medium",    charmBonus = 20},

	-- Advanced creatures
	["dragon"]           = {index = 31,  category = "Dragons",   difficulty = "Hard",      charmBonus = 25},
	["dragon lord"]      = {index = 32,  category = "Dragons",   difficulty = "Hard",      charmBonus = 30},
	["hydra"]            = {index = 33,  category = "Reptiles",  difficulty = "Hard",      charmBonus = 30},
	["behemoth"]         = {index = 34,  category = "Giants",    difficulty = "Hard",      charmBonus = 30},
	["serpent spawn"]    = {index = 35,  category = "Reptiles",  difficulty = "Hard",      charmBonus = 30},
	["warlock"]          = {index = 36,  category = "Humans",    difficulty = "Hard",      charmBonus = 35},
	["banshee"]          = {index = 37,  category = "Undead",    difficulty = "Hard",      charmBonus = 25},
	["hero"]             = {index = 38,  category = "Humans",    difficulty = "Hard",      charmBonus = 30},
	["medusa"]           = {index = 39,  category = "Magical",   difficulty = "Hard",      charmBonus = 30},
	["wyrm"]             = {index = 40,  category = "Dragons",   difficulty = "Hard",      charmBonus = 30},
	["sea serpent"]      = {index = 41,  category = "Reptiles",  difficulty = "Hard",      charmBonus = 25},
	["lich"]             = {index = 42,  category = "Undead",    difficulty = "Hard",      charmBonus = 30},
	["energy elemental"] = {index = 43,  category = "Elemental", difficulty = "Hard",      charmBonus = 25},
	["plaguesmith"]      = {index = 44,  category = "Demons",    difficulty = "Hard",      charmBonus = 35},

	-- Expert creatures
	["demon"]            = {index = 45,  category = "Demons",    difficulty = "Challenging", charmBonus = 50},
	["fury"]             = {index = 46,  category = "Demons",    difficulty = "Challenging", charmBonus = 40},
	["hellhound"]        = {index = 47,  category = "Demons",    difficulty = "Challenging", charmBonus = 40},
	["undead dragon"]    = {index = 48,  category = "Dragons",   difficulty = "Challenging", charmBonus = 50},
	["nightmare"]        = {index = 49,  category = "Magical",   difficulty = "Challenging", charmBonus = 40},
	["ghastly dragon"]   = {index = 50,  category = "Dragons",   difficulty = "Challenging", charmBonus = 50},
	["hellfire fighter"]  = {index = 51,  category = "Demons",    difficulty = "Challenging", charmBonus = 40},
	["lost soul"]        = {index = 52,  category = "Undead",    difficulty = "Challenging", charmBonus = 40},
	["juggernaut"]       = {index = 53,  category = "Demons",    difficulty = "Challenging", charmBonus = 50},
	["dark torturer"]    = {index = 54,  category = "Demons",    difficulty = "Challenging", charmBonus = 50},

	-- Master creatures
	["grim reaper"]      = {index = 55,  category = "Undead",    difficulty = "Extreme",   charmBonus = 60},
	["hand of cursed fate"] = {index = 56, category = "Undead",  difficulty = "Extreme",   charmBonus = 60},
	["defiler"]          = {index = 57,  category = "Demons",    difficulty = "Extreme",   charmBonus = 60},
	["destroyer"]        = {index = 58,  category = "Demons",    difficulty = "Extreme",   charmBonus = 60},

	-- Bosses
	["the horned fox"]   = {index = 59,  category = "Bosses",    difficulty = "Boss",      charmBonus = 25},
	["demodras"]         = {index = 60,  category = "Bosses",    difficulty = "Boss",      charmBonus = 50},
	["orshabaal"]        = {index = 61,  category = "Bosses",    difficulty = "Boss",      charmBonus = 100},
	["morgaroth"]        = {index = 62,  category = "Bosses",    difficulty = "Boss",      charmBonus = 150},
	["ferumbras"]        = {index = 63,  category = "Bosses",    difficulty = "Boss",      charmBonus = 200},
}

-- ============================================================================
-- Creature Element Info (revealed at Complete tier)
-- ============================================================================

Bestiary.elementInfo = {
	["rat"]            = {weak = {"fire"}, strong = {}, immune = {}},
	["spider"]         = {weak = {"fire"}, strong = {}, immune = {}},
	["wolf"]           = {weak = {"fire"}, strong = {}, immune = {}},
	["troll"]          = {weak = {"fire", "energy"}, strong = {}, immune = {}},
	["skeleton"]       = {weak = {"fire", "holy"}, strong = {"death"}, immune = {}},
	["minotaur"]       = {weak = {"fire"}, strong = {"earth"}, immune = {}},
	["orc"]            = {weak = {"fire", "energy"}, strong = {}, immune = {}},
	["cyclops"]        = {weak = {"energy", "earth"}, strong = {"physical"}, immune = {}},
	["dragon"]         = {weak = {"ice"}, strong = {"fire", "energy"}, immune = {"fire"}},
	["dragon lord"]    = {weak = {"ice"}, strong = {"fire", "energy", "earth"}, immune = {"fire"}},
	["hydra"]          = {weak = {"fire", "energy"}, strong = {"ice", "earth"}, immune = {}},
	["behemoth"]       = {weak = {"fire", "ice"}, strong = {"physical", "energy", "earth"}, immune = {}},
	["warlock"]        = {weak = {"physical"}, strong = {"fire", "energy"}, immune = {}},
	["demon"]          = {weak = {"ice", "holy"}, strong = {"fire", "energy", "death"}, immune = {"fire"}},
	["grim reaper"]    = {weak = {"holy", "fire"}, strong = {"death", "ice"}, immune = {}},
	["necromancer"]    = {weak = {"fire", "holy"}, strong = {"death"}, immune = {}},
	["vampire"]        = {weak = {"fire", "holy"}, strong = {"death"}, immune = {}},
	["giant spider"]   = {weak = {"fire"}, strong = {"earth"}, immune = {"earth"}},
	["undead dragon"]  = {weak = {"holy"}, strong = {"death", "fire", "energy", "ice"}, immune = {"death"}},
	["fury"]           = {weak = {"ice", "holy"}, strong = {"fire"}, immune = {"fire"}},
	["hellhound"]      = {weak = {"ice"}, strong = {"fire"}, immune = {"fire"}},
	["juggernaut"]     = {weak = {"ice", "earth"}, strong = {"fire", "energy", "physical"}, immune = {}},
}

-- ============================================================================
-- Core Functions
-- ============================================================================

--- Get the storage key for a creature's kill count.
local function getCreatureStorageKey(creatureName)
	local info = Bestiary.creatures[creatureName:lower()]
	if not info then
		return nil
	end
	return Bestiary.STORAGE_KILLS_BASE + info.index
end

--- Record a kill and return the new kill count plus any tier that was just unlocked.
function Bestiary.addKill(player, creatureName)
	local key = getCreatureStorageKey(creatureName)
	if not key then
		return 0, nil
	end

	local current = player:getStorageValue(key)
	if current < 0 then current = 0 end
	local newCount = current + 1
	player:setStorageValue(key, newCount)

	-- Check if a new tier was just unlocked
	local previousTier = Bestiary.getTierForCount(current)
	local newTier = Bestiary.getTierForCount(newCount)

	local unlockedTier = nil
	if newTier > previousTier then
		unlockedTier = newTier
		-- Award charm points
		local charmReward = Bestiary.CHARM_REWARDS[newTier] or 0
		local creatureInfo = Bestiary.creatures[creatureName:lower()]
		if creatureInfo then
			charmReward = charmReward + math.floor(creatureInfo.charmBonus / 10)
		end
		Bestiary.addCharmPoints(player, charmReward)

		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
			"[Bestiary] " .. creatureName .. " - " .. Bestiary.TIER_NAMES[newTier] ..
			" tier unlocked! (+" .. charmReward .. " charm points)")
	end

	return newCount, unlockedTier
end

--- Get the kill count for a creature.
function Bestiary.getKillCount(player, creatureName)
	local key = getCreatureStorageKey(creatureName)
	if not key then return 0 end
	local v = player:getStorageValue(key)
	if v < 0 then return 0 end
	return v
end

--- Get the unlocked tier based on a kill count number.
function Bestiary.getTierForCount(count)
	if count >= Bestiary.TIER_THRESHOLDS[3] then
		return Bestiary.TIER_COMPLETE
	elseif count >= Bestiary.TIER_THRESHOLDS[2] then
		return Bestiary.TIER_DETAILED
	elseif count >= Bestiary.TIER_THRESHOLDS[1] then
		return Bestiary.TIER_BASIC
	end
	return Bestiary.TIER_NONE
end

--- Get the unlock tier for a player and creature.
function Bestiary.getUnlockTier(player, creatureName)
	local count = Bestiary.getKillCount(player, creatureName)
	return Bestiary.getTierForCount(count)
end

--- Get bestiary info for a creature (respecting the player's unlock tier).
function Bestiary.getBestiaryInfo(player, creatureName)
	local key = creatureName:lower()
	local creatureInfo = Bestiary.creatures[key]
	if not creatureInfo then
		return nil
	end

	local kills = Bestiary.getKillCount(player, creatureName)
	local tier = Bestiary.getTierForCount(kills)

	local info = {
		name = creatureName,
		kills = kills,
		tier = tier,
		tierName = Bestiary.TIER_NAMES[tier],
		category = creatureInfo.category,
		difficulty = creatureInfo.difficulty,
	}

	-- Tier 1 (Basic): name + category + difficulty
	-- (always included above if tier >= 1)

	-- Tier 2 (Detailed): add loot info hint
	if tier >= Bestiary.TIER_DETAILED then
		info.lootRevealed = true
	end

	-- Tier 3 (Complete): add weaknesses/resistances
	if tier >= Bestiary.TIER_COMPLETE then
		local elements = Bestiary.elementInfo[key]
		if elements then
			info.weaknesses = elements.weak
			info.strengths = elements.strong
			info.immunities = elements.immune
		end
		info.charmPointsEarned = true
	end

	return info
end

--- Get total charm points.
function Bestiary.getCharmPoints(player)
	local v = player:getStorageValue(Bestiary.STORAGE_CHARM_POINTS)
	if v < 0 then return 0 end
	return v
end

--- Add charm points.
function Bestiary.addCharmPoints(player, points)
	local current = Bestiary.getCharmPoints(player)
	player:setStorageValue(Bestiary.STORAGE_CHARM_POINTS, current + points)
end

--- Get bestiary progress summary: how many creatures at each tier.
function Bestiary.getProgressSummary(player)
	local summary = {total = 0, basic = 0, detailed = 0, complete = 0}
	for name, info in pairs(Bestiary.creatures) do
		summary.total = summary.total + 1
		local tier = Bestiary.getUnlockTier(player, name)
		if tier >= Bestiary.TIER_BASIC then summary.basic = summary.basic + 1 end
		if tier >= Bestiary.TIER_DETAILED then summary.detailed = summary.detailed + 1 end
		if tier >= Bestiary.TIER_COMPLETE then summary.complete = summary.complete + 1 end
	end
	return summary
end
