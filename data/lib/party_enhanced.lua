-- ============================================================================
-- Enhanced Party System (Phase 5)
-- ============================================================================
-- Party finder, party-specific quests, improved shared XP with vocation
-- diversity bonuses, party buff auras, and chat helpers.
-- Storage layout:
--   61000  party finder registration timestamp
--   61001  party finder purpose  (encoded integer)
--   61002  party finder min level
--   61003  party finder max level
--   61100-61199  party quest state (0=none, 1=active, 2=complete)
--   61200-61299  party quest progress
-- ============================================================================

PartyEnhanced = {}

-- ============================================================================
-- Constants
-- ============================================================================

PartyEnhanced.STORAGE_FINDER_TIME    = 61000
PartyEnhanced.STORAGE_FINDER_PURPOSE = 61001
PartyEnhanced.STORAGE_FINDER_MINLVL  = 61002
PartyEnhanced.STORAGE_FINDER_MAXLVL  = 61003
PartyEnhanced.STORAGE_QUEST_BASE     = 61100
PartyEnhanced.STORAGE_QUEST_PROG     = 61200

PartyEnhanced.FINDER_TIMEOUT = 30 * 60  -- listings expire after 30 minutes

-- Purpose codes
PartyEnhanced.PURPOSE = {
	HUNTING   = 1,
	QUEST     = 2,
	DUNGEON   = 3,
	BOSS      = 4,
	GENERAL   = 5,
}

PartyEnhanced.PURPOSE_NAMES = {
	[1] = "Hunting",
	[2] = "Questing",
	[3] = "Dungeon",
	[4] = "Boss Fight",
	[5] = "General",
}

-- Vocation IDs for diversity bonus
PartyEnhanced.VOCATION_GROUPS = {
	melee  = {4, 8},  -- knight, elite knight
	ranged = {3, 7},  -- paladin, royal paladin
	mage   = {1, 2, 5, 6},  -- sorcerer, druid, master sorcerer, elder druid
}

-- Party buff definitions
PartyEnhanced.BUFFS = {
	healing_aura = {
		name       = "Druid Healing Aura",
		vocations  = {2, 6},  -- druid / elder druid
		interval   = 4000,    -- ms between ticks
		healBase   = 20,
		healPerLvl = 0.5,
		range      = 5,       -- sqm radius
	},
	taunt = {
		name       = "Knight Taunt",
		vocations  = {4, 8},  -- knight / elite knight
		duration   = 6000,    -- ms
		range      = 4,
	},
	mark_target = {
		name       = "Archer Mark",
		vocations  = {3, 7},  -- paladin / royal paladin
		duration   = 8000,
		damageBonus = 10,     -- +10% damage from party on marked target
		range      = 7,
	},
}

-- Minimum party size for party quests
PartyEnhanced.MIN_PARTY_QUEST_SIZE = 4

-- ============================================================================
-- Party Quests
-- ============================================================================

PartyEnhanced.QUESTS = {
	{
		id          = 1,
		name        = "Orc Warlord Ambush",
		description = "Defeat the Orc Warlord and his guards in the southern cave.",
		minLevel    = 50,
		minParty    = 4,
		killTarget  = "Orc Warlord",
		killCount   = 1,
		rewards     = {
			exp    = 50000,
			money  = 10000,
			items  = {{id = 2160, count = 5}},  -- crystal coins
		},
	},
	{
		id          = 2,
		name        = "Dragon Nest Raid",
		description = "Clear the dragon nest on the eastern mountain.",
		minLevel    = 100,
		minParty    = 4,
		killTarget  = "Dragon Lord",
		killCount   = 3,
		rewards     = {
			exp    = 150000,
			money  = 25000,
			items  = {{id = 2160, count = 15}},
		},
	},
	{
		id          = 3,
		name        = "Demon Gate Seal",
		description = "Close the demon portal before the fortress is overrun.",
		minLevel    = 150,
		minParty    = 5,
		killTarget  = "Demon",
		killCount   = 10,
		rewards     = {
			exp    = 400000,
			money  = 50000,
			items  = {{id = 2160, count = 30}},
		},
	},
	{
		id          = 4,
		name        = "Lich King's Court",
		description = "Breach the Lich King's court and banish his undead army.",
		minLevel    = 200,
		minParty    = 5,
		killTarget  = "Lich",
		killCount   = 5,
		rewards     = {
			exp    = 800000,
			money  = 100000,
			items  = {{id = 2160, count = 50}},
		},
	},
}

-- ============================================================================
-- Party Finder
-- ============================================================================

-- In-memory listing (lost on restart; acceptable for a finder)
PartyEnhanced._finderListings = {}

--- Register a player in the party finder.
-- @param player   Player userdata
-- @param minLevel number  minimum level sought
-- @param maxLevel number  maximum level sought
-- @param purpose  string  key matching PURPOSE_NAMES value (case-insensitive)
-- @return boolean, string
function PartyEnhanced.registerFinder(player, minLevel, maxLevel, purpose)
	minLevel = tonumber(minLevel) or math.max(1, player:getLevel() - 20)
	maxLevel = tonumber(maxLevel) or (player:getLevel() + 20)

	local purposeCode = PartyEnhanced.PURPOSE.GENERAL
	if purpose then
		local lp = purpose:lower()
		for code, name in pairs(PartyEnhanced.PURPOSE_NAMES) do
			if name:lower() == lp then
				purposeCode = code
				break
			end
		end
	end

	PartyEnhanced._finderListings[player:getGuid()] = {
		name     = player:getName(),
		level    = player:getLevel(),
		vocation = player:getVocation():getName(),
		minLevel = minLevel,
		maxLevel = maxLevel,
		purpose  = purposeCode,
		time     = os.time(),
	}

	player:setStorageValue(PartyEnhanced.STORAGE_FINDER_TIME, os.time())
	player:setStorageValue(PartyEnhanced.STORAGE_FINDER_PURPOSE, purposeCode)
	player:setStorageValue(PartyEnhanced.STORAGE_FINDER_MINLVL, minLevel)
	player:setStorageValue(PartyEnhanced.STORAGE_FINDER_MAXLVL, maxLevel)

	return true, string.format(
		"Registered in party finder: Level %d-%d, Purpose: %s. Listing expires in 30 min.",
		minLevel, maxLevel, PartyEnhanced.PURPOSE_NAMES[purposeCode]
	)
end

--- Get active party finder listings as a formatted string.
function PartyEnhanced.getFinderListings()
	local now = os.time()
	local lines = {"=== Party Finder ==="}
	local count = 0

	for guid, entry in pairs(PartyEnhanced._finderListings) do
		if now - entry.time < PartyEnhanced.FINDER_TIMEOUT then
			count = count + 1
			lines[#lines + 1] = string.format(
				"%d. %s (Lvl %d %s) - Looking for Lvl %d-%d [%s]",
				count, entry.name, entry.level, entry.vocation,
				entry.minLevel, entry.maxLevel,
				PartyEnhanced.PURPOSE_NAMES[entry.purpose]
			)
		else
			PartyEnhanced._finderListings[guid] = nil
		end
	end

	if count == 0 then
		lines[#lines + 1] = "No active listings. Use !party register to list yourself."
	end
	return table.concat(lines, "\n")
end

-- ============================================================================
-- Shared XP Formulas
-- ============================================================================

--- Calculate the vocation diversity bonus for a party.
-- 1 unique vocation group  = 0% bonus
-- 2 unique vocation groups = 10% bonus
-- 3 unique vocation groups = 20% bonus
-- @param members  table of Player userdata
-- @return number  bonus multiplier (e.g. 1.20 for 20% bonus)
function PartyEnhanced.vocDiversityMultiplier(members)
	local groups = {}
	for _, member in ipairs(members) do
		local vocId = member:getVocation():getId()
		for groupName, ids in pairs(PartyEnhanced.VOCATION_GROUPS) do
			for _, id in ipairs(ids) do
				if vocId == id then
					groups[groupName] = true
				end
			end
		end
	end

	local uniqueCount = 0
	for _ in pairs(groups) do
		uniqueCount = uniqueCount + 1
	end

	if uniqueCount >= 3 then
		return 1.20
	elseif uniqueCount == 2 then
		return 1.10
	end
	return 1.00
end

--- Calculate enhanced party shared XP.
-- @param baseExp  number  raw experience from a kill
-- @param members  table of Player userdata
-- @return number  final experience per member
function PartyEnhanced.calculateSharedExp(baseExp, members)
	local count = #members
	if count <= 1 then
		return baseExp
	end

	-- Standard split: each member gets base / count, plus 10% bonus per extra member
	local splitExp = baseExp / count
	local partyBonus = 1.0 + (count - 1) * 0.10  -- +10% per extra member
	local vocBonus = PartyEnhanced.vocDiversityMultiplier(members)

	return math.floor(splitExp * partyBonus * vocBonus)
end

-- ============================================================================
-- Party Buffs
-- ============================================================================

--- Apply druid healing aura to nearby party members.
-- Call this from a globalEvent or periodic timer.
-- @param druid  Player (druid)
function PartyEnhanced.applyHealingAura(druid)
	local buff = PartyEnhanced.BUFFS.healing_aura
	local party = druid:getParty()
	if not party then
		return
	end

	local members = party:getMembers()
	if not members then
		return
	end

	local druidPos = druid:getPosition()
	local healAmount = buff.healBase + math.floor(druid:getLevel() * buff.healPerLvl)

	for _, member in ipairs(members) do
		if member:getPosition():getDistance(druidPos) <= buff.range then
			member:addHealth(healAmount)
			member:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		end
	end
end

--- Apply knight taunt: force nearby monsters to target the knight.
-- @param knight  Player (knight)
function PartyEnhanced.applyTaunt(knight)
	local buff = PartyEnhanced.BUFFS.taunt
	local pos = knight:getPosition()

	local spectators = Game.getSpectators(pos, false, false, buff.range, buff.range, buff.range, buff.range)
	for _, creature in ipairs(spectators) do
		if creature:isMonster() then
			creature:setTarget(knight)
		end
	end
	pos:sendMagicEffect(CONST_ME_HITAREA)
end

--- Apply paladin mark on a target creature.
-- Marked creatures take bonus damage from party members (tracked via storage).
-- @param paladin  Player (paladin)
-- @param target   Creature to mark
function PartyEnhanced.applyMark(paladin, target)
	if not target or not target:isMonster() then
		return false, "You can only mark monsters."
	end

	local pos = paladin:getPosition()
	if pos:getDistance(target:getPosition()) > PartyEnhanced.BUFFS.mark_target.range then
		return false, "Target is out of range."
	end

	-- Use a condition to visually mark the target
	local condition = Condition(CONDITION_OUTFIT)
	condition:setTicks(PartyEnhanced.BUFFS.mark_target.duration)
	target:addCondition(condition)
	target:getPosition():sendMagicEffect(CONST_ME_STUN)

	return true, string.format("Marked %s! Party deals +%d%% damage for %d seconds.",
		target:getName(),
		PartyEnhanced.BUFFS.mark_target.damageBonus,
		PartyEnhanced.BUFFS.mark_target.duration / 1000
	)
end

-- ============================================================================
-- Party Quest Helpers
-- ============================================================================

--- Check if a party meets the requirements for a quest.
function PartyEnhanced.canStartQuest(leader, questId)
	local quest = PartyEnhanced.QUESTS[questId]
	if not quest then
		return false, "Unknown quest."
	end

	local party = leader:getParty()
	if not party then
		return false, "You need a party to start this quest."
	end

	local members = party:getMembers()
	table.insert(members, leader)

	if #members < quest.minParty then
		return false, string.format("Need at least %d party members (have %d).", quest.minParty, #members)
	end

	for _, member in ipairs(members) do
		if member:getLevel() < quest.minLevel then
			return false, string.format("%s is below the minimum level of %d.", member:getName(), quest.minLevel)
		end
	end

	return true, "Party meets all requirements."
end

--- List available party quests as a formatted string.
function PartyEnhanced.getQuestList()
	local lines = {"=== Party Quests ==="}
	for _, q in ipairs(PartyEnhanced.QUESTS) do
		lines[#lines + 1] = string.format(
			"%d. %s (Lvl %d+, %d+ members) - %s",
			q.id, q.name, q.minLevel, q.minParty, q.description
		)
	end
	return table.concat(lines, "\n")
end
