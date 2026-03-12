-- ============================================================================
-- Prey / Hunting Bonus System
-- ============================================================================
-- Allows each player to select up to 3 prey creatures from their bestiary.
-- Each active prey grants a configurable bonus (XP, loot, damage, or defense)
-- for 2 hours of play-time.  Prey slots can be rerolled for gold.
-- Storage layout:
--   64100-64102  prey creature name hash (per slot 0-2)
--   64103-64105  prey bonus type         (per slot 0-2)
--   64106-64108  prey bonus tier         (per slot 0-2)
--   64109-64111  prey activation time    (per slot 0-2)
--   64112-64114  prey reroll count       (per slot 0-2)
-- ============================================================================

PreySystem = {}

-- ============================================================================
-- Constants
-- ============================================================================

PreySystem.MAX_SLOTS = 3

-- Storage key bases (each spans MAX_SLOTS keys: +0, +1, +2)
PreySystem.STORAGE_NAME_BASE       = 64100   -- creature name hash
PreySystem.STORAGE_BONUS_TYPE_BASE = 64103   -- bonus type enum
PreySystem.STORAGE_BONUS_TIER_BASE = 64106   -- bonus tier 1-3
PreySystem.STORAGE_ACTIVATE_BASE   = 64109   -- os.time() of activation
PreySystem.STORAGE_REROLL_BASE     = 64112   -- cumulative reroll count

PreySystem.DURATION = 7200  -- 2 hours in seconds

-- Bonus type enums
PreySystem.BONUS_NONE    = 0
PreySystem.BONUS_XP      = 1
PreySystem.BONUS_LOOT    = 2
PreySystem.BONUS_DAMAGE  = 3
PreySystem.BONUS_DEFENSE = 4

PreySystem.BONUS_NAMES = {
	[0] = "None",
	[1] = "Experience",
	[2] = "Loot",
	[3] = "Damage",
	[4] = "Defense",
}

-- Bonus values per tier (percentage)
PreySystem.BONUS_VALUES = {
	[PreySystem.BONUS_XP]      = {20, 40, 60},
	[PreySystem.BONUS_LOOT]    = {15, 30, 50},
	[PreySystem.BONUS_DAMAGE]  = {10, 20, 30},
	[PreySystem.BONUS_DEFENSE] = {10, 20, 30},
}

-- Reroll cost scales with slot index (1-indexed for display, 0-indexed internally)
PreySystem.REROLL_COSTS = {1000, 5000, 10000}

-- ============================================================================
-- Name Hashing
-- ============================================================================
-- Creature names are stored as a simple djb2 hash so they fit in a single
-- storage integer.  Collisions are astronomically unlikely for the small
-- bestiary pool.

local function hashName(name)
	local h = 5381
	for i = 1, #name do
		h = ((h * 33) + string.byte(name, i)) % 2147483647
	end
	return h
end

--- Reverse-lookup: find the bestiary creature whose hash matches.
local function nameFromHash(hash)
	if not Bestiary or not Bestiary.creatures then return nil end
	for name, _ in pairs(Bestiary.creatures) do
		if hashName(name) == hash then
			return name
		end
	end
	return nil
end

-- ============================================================================
-- Internal Helpers
-- ============================================================================

local function validateSlot(slot)
	return slot >= 0 and slot < PreySystem.MAX_SLOTS
end

local function getStorage(player, base, slot)
	local v = player:getStorageValue(base + slot)
	if v < 0 then return 0 end
	return v
end

local function setStorage(player, base, slot, value)
	player:setStorageValue(base + slot, value)
end

--- Return a random bonus type (1-4).
local function randomBonusType()
	return math.random(1, 4)
end

--- Return a random tier (1-3).
local function randomBonusTier()
	return math.random(1, 3)
end

--- Get the list of bestiary creatures the player has killed at least once.
local function getAvailablePrey(player)
	if not Bestiary or not Bestiary.creatures then return {} end
	local available = {}
	for name, _ in pairs(Bestiary.creatures) do
		if Bestiary.getKillCount(player, name) > 0 then
			available[#available + 1] = name
		end
	end
	return available
end

-- ============================================================================
-- Core Functions
-- ============================================================================

--- Check whether a prey slot is still active (within DURATION seconds).
-- @param player  Player userdata
-- @param slot    Slot index (0-2)
-- @return boolean
function PreySystem.checkActive(player, slot)
	if not validateSlot(slot) then return false end

	local nameHash = getStorage(player, PreySystem.STORAGE_NAME_BASE, slot)
	if nameHash == 0 then return false end

	local activated = getStorage(player, PreySystem.STORAGE_ACTIVATE_BASE, slot)
	if activated == 0 then return false end

	return (os.time() - activated) < PreySystem.DURATION
end

--- Get full information about a prey slot.
-- @param player  Player userdata
-- @param slot    Slot index (0-2)
-- @return table or nil
function PreySystem.getPreyInfo(player, slot)
	if not validateSlot(slot) then return nil end

	local nameHash = getStorage(player, PreySystem.STORAGE_NAME_BASE, slot)
	if nameHash == 0 then
		return {slot = slot, active = false, creature = nil}
	end

	local creature   = nameFromHash(nameHash)
	local bonusType  = getStorage(player, PreySystem.STORAGE_BONUS_TYPE_BASE, slot)
	local bonusTier  = getStorage(player, PreySystem.STORAGE_BONUS_TIER_BASE, slot)
	local activated  = getStorage(player, PreySystem.STORAGE_ACTIVATE_BASE, slot)
	local rerolls    = getStorage(player, PreySystem.STORAGE_REROLL_BASE, slot)

	local remaining = 0
	local active = false
	if activated > 0 then
		remaining = math.max(0, PreySystem.DURATION - (os.time() - activated))
		active = remaining > 0
	end

	local bonusValue = 0
	if bonusType > 0 and bonusTier > 0 then
		local tierValues = PreySystem.BONUS_VALUES[bonusType]
		if tierValues then
			bonusValue = tierValues[bonusTier] or 0
		end
	end

	return {
		slot        = slot,
		active      = active,
		creature    = creature,
		bonusType   = bonusType,
		bonusName   = PreySystem.BONUS_NAMES[bonusType] or "None",
		bonusTier   = bonusTier,
		bonusValue  = bonusValue,
		remaining   = remaining,
		rerolls     = rerolls,
	}
end

--- Select a prey creature for a given slot.
-- The creature must be in the player's bestiary (at least 1 kill).
-- A random bonus type and tier are assigned upon selection.
-- @param player      Player userdata
-- @param slot        Slot index (0-2)
-- @param monsterName Creature name (case-insensitive)
-- @return boolean, string  success flag and status message
function PreySystem.selectPrey(player, slot, monsterName)
	if not validateSlot(slot) then
		return false, "Invalid prey slot."
	end

	monsterName = monsterName:lower()

	-- Must exist in bestiary registry
	if not Bestiary or not Bestiary.creatures or not Bestiary.creatures[monsterName] then
		return false, "That creature is not in the bestiary."
	end

	-- Must have been killed at least once
	if Bestiary.getKillCount(player, monsterName) < 1 then
		return false, "You must kill at least one " .. monsterName .. " before selecting it as prey."
	end

	-- Cannot have the same creature in two slots
	for s = 0, PreySystem.MAX_SLOTS - 1 do
		if s ~= slot then
			local otherHash = getStorage(player, PreySystem.STORAGE_NAME_BASE, s)
			if otherHash ~= 0 and otherHash == hashName(monsterName) then
				return false, "That creature is already set as prey in another slot."
			end
		end
	end

	-- Assign prey
	local bonusType = randomBonusType()
	local bonusTier = randomBonusTier()

	setStorage(player, PreySystem.STORAGE_NAME_BASE, slot, hashName(monsterName))
	setStorage(player, PreySystem.STORAGE_BONUS_TYPE_BASE, slot, bonusType)
	setStorage(player, PreySystem.STORAGE_BONUS_TIER_BASE, slot, bonusTier)
	setStorage(player, PreySystem.STORAGE_ACTIVATE_BASE, slot, os.time())

	local tierValues = PreySystem.BONUS_VALUES[bonusType]
	local pct = tierValues and tierValues[bonusTier] or 0

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
		"[Prey] Slot " .. (slot + 1) .. ": " .. monsterName ..
		" selected. Bonus: " .. PreySystem.BONUS_NAMES[bonusType] ..
		" +" .. pct .. "% (tier " .. bonusTier .. ") for 2 hours.")

	return true, "Prey selected."
end

--- Reroll a prey slot: clears the current creature and randomly assigns a new
-- one from the player's bestiary along with a fresh bonus and timer.
-- Costs gold based on the slot index.
-- @param player  Player userdata
-- @param slot    Slot index (0-2)
-- @return boolean, string
function PreySystem.rerollPrey(player, slot)
	if not validateSlot(slot) then
		return false, "Invalid prey slot."
	end

	local cost = PreySystem.REROLL_COSTS[slot + 1] or 10000

	-- Check gold
	if player:getMoney() < cost then
		return false, "You need " .. cost .. " gold to reroll this prey slot."
	end

	-- Get available creatures
	local available = getAvailablePrey(player)
	if #available == 0 then
		return false, "You have no creatures unlocked in the bestiary."
	end

	-- Exclude creatures already assigned to other slots
	local occupied = {}
	for s = 0, PreySystem.MAX_SLOTS - 1 do
		if s ~= slot then
			local h = getStorage(player, PreySystem.STORAGE_NAME_BASE, s)
			if h ~= 0 then occupied[h] = true end
		end
	end

	local candidates = {}
	for _, name in ipairs(available) do
		if not occupied[hashName(name)] then
			candidates[#candidates + 1] = name
		end
	end

	if #candidates == 0 then
		return false, "No other bestiary creatures available for reroll."
	end

	-- Deduct gold
	player:removeMoney(cost)

	-- Pick random creature + bonus
	local chosen = candidates[math.random(#candidates)]
	local bonusType = randomBonusType()
	local bonusTier = randomBonusTier()

	setStorage(player, PreySystem.STORAGE_NAME_BASE, slot, hashName(chosen))
	setStorage(player, PreySystem.STORAGE_BONUS_TYPE_BASE, slot, bonusType)
	setStorage(player, PreySystem.STORAGE_BONUS_TIER_BASE, slot, bonusTier)
	setStorage(player, PreySystem.STORAGE_ACTIVATE_BASE, slot, os.time())

	-- Increment reroll counter
	local rerolls = getStorage(player, PreySystem.STORAGE_REROLL_BASE, slot)
	setStorage(player, PreySystem.STORAGE_REROLL_BASE, slot, rerolls + 1)

	local tierValues = PreySystem.BONUS_VALUES[bonusType]
	local pct = tierValues and tierValues[bonusTier] or 0

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
		"[Prey] Slot " .. (slot + 1) .. " rerolled: " .. chosen ..
		". Bonus: " .. PreySystem.BONUS_NAMES[bonusType] ..
		" +" .. pct .. "% (tier " .. bonusTier .. "). Cost: " .. cost .. " gold.")

	return true, "Prey rerolled."
end

--- Get the active prey bonus for a specific monster across all slots.
-- Returns a table with bonusType, bonusValue (percentage), and bonusTier,
-- or nil if no active prey matches the given monster.
-- @param player      Player userdata
-- @param monsterName Creature name (case-insensitive)
-- @return table or nil
function PreySystem.getPreyBonus(player, monsterName)
	monsterName = monsterName:lower()
	local targetHash = hashName(monsterName)

	for slot = 0, PreySystem.MAX_SLOTS - 1 do
		local nameHash = getStorage(player, PreySystem.STORAGE_NAME_BASE, slot)
		if nameHash == targetHash and PreySystem.checkActive(player, slot) then
			local bonusType = getStorage(player, PreySystem.STORAGE_BONUS_TYPE_BASE, slot)
			local bonusTier = getStorage(player, PreySystem.STORAGE_BONUS_TIER_BASE, slot)

			local bonusValue = 0
			if bonusType > 0 and bonusTier > 0 then
				local tierValues = PreySystem.BONUS_VALUES[bonusType]
				if tierValues then
					bonusValue = tierValues[bonusTier] or 0
				end
			end

			return {
				bonusType  = bonusType,
				bonusName  = PreySystem.BONUS_NAMES[bonusType] or "None",
				bonusTier  = bonusTier,
				bonusValue = bonusValue,
				slot       = slot,
			}
		end
	end

	return nil
end

--- Clear an expired or manually dismissed prey slot.
-- @param player  Player userdata
-- @param slot    Slot index (0-2)
function PreySystem.clearSlot(player, slot)
	if not validateSlot(slot) then return end

	setStorage(player, PreySystem.STORAGE_NAME_BASE, slot, 0)
	setStorage(player, PreySystem.STORAGE_BONUS_TYPE_BASE, slot, 0)
	setStorage(player, PreySystem.STORAGE_BONUS_TIER_BASE, slot, 0)
	setStorage(player, PreySystem.STORAGE_ACTIVATE_BASE, slot, 0)
	-- reroll count is intentionally preserved
end

--- Get a summary of all 3 prey slots for display.
-- @param player  Player userdata
-- @return table  Array of slot info tables (indices 1-3)
function PreySystem.getSummary(player)
	local slots = {}
	for slot = 0, PreySystem.MAX_SLOTS - 1 do
		slots[#slots + 1] = PreySystem.getPreyInfo(player, slot)
	end
	return slots
end

print(">> Prey system loaded")
