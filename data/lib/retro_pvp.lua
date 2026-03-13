-- ============================================================================
-- Retro PvP System (Phase 1.3)
-- ============================================================================
-- Implements classic retro PvP mechanics:
--   - Rune hotkey blocking (must aim runes manually)
--   - Rope hole blocking (players can block rope holes)
--   - Custom skull thresholds (white/red/black at 3/6/10)
--   - PvP damage reduction formula (level-based scaling)
--   - Death penalty adjustments for PvP vs PvE
--   - Protection zone restrictions
-- ============================================================================

RetroPvP = {}

-- ============================================================================
-- Configuration
-- ============================================================================
RetroPvP.config = {
	-- Rune hotkey blocking
	blockRuneHotkeys = true,
	runeHotkeyMessage = "You must aim runes manually in retro PvP mode.",

	-- Skull thresholds (unjustified kills)
	killsForWhiteSkull = 3,
	killsForRedSkull = 6,
	killsForBlackSkull = 10,

	-- Skull durations (in seconds)
	whiteSkullDuration = 15 * 60,       -- 15 minutes
	redSkullDuration = 30 * 24 * 3600,  -- 30 days
	blackSkullDuration = 45 * 24 * 3600, -- 45 days

	-- PvP damage reduction (percentage, 0-100)
	pvpPhysicalReduction = 50,
	pvpMagicReduction = 40,

	-- Level-based PvP scaling
	-- Lower-level players take less damage from higher-level players
	levelScalingEnabled = true,
	levelScalingMinRatio = 0.5, -- minimum damage ratio
	levelScalingMaxDiff = 100,  -- level difference for max reduction

	-- Death penalty multipliers
	pvpDeathPenalty = 0.5,  -- 50% of normal death penalty for PvP deaths
	pveDeathPenalty = 1.0,  -- 100% of normal death penalty for PvE deaths

	-- Skull-based death penalty overrides (XP loss percentage)
	skullDeathPenalty = {
		[SKULL_NONE]  = nil, -- use default
		[SKULL_WHITE] = nil, -- use default
		[SKULL_RED]   = 0.12, -- 12% XP loss
		[SKULL_BLACK] = 0.15, -- 15% XP loss
	},

	-- Protection zone level
	protectionLevel = 50,

	-- Rope hole blocking
	ropeHoleBlockingEnabled = true,
}

-- Storage keys for PvP tracking
RetroPvP.STORAGE = {
	UNJUST_KILLS      = 58000,
	WHITE_SKULL_TIME   = 58001,
	RED_SKULL_TIME     = 58002,
	BLACK_SKULL_TIME   = 58003,
	SKULL_TYPE         = 58004,
	SKULL_EXPIRE_TIME  = 58005,
	LAST_PVP_DEATH     = 58006,
	PVP_KILL_COUNT     = 58007,
	PVP_DEATH_COUNT    = 58008,
}

-- ============================================================================
-- Rune Hotkey Blocking
-- ============================================================================

-- Rune item IDs (common attack runes)
RetroPvP.RUNE_IDS = {
	-- Attack runes
	[2260] = true, -- blank rune
	[2261] = true, -- adori blank
	[2262] = true, -- sudden death rune
	[2265] = true, -- fire field rune
	[2266] = true, -- energy field rune
	[2267] = true, -- poison field rune
	[2268] = true, -- fire wall rune
	[2269] = true, -- energy wall rune
	[2270] = true, -- poison wall rune
	[2271] = true, -- explosion rune
	[2272] = true, -- fire bomb rune
	[2273] = true, -- great fireball rune
	[2274] = true, -- ultimate healing rune
	[2275] = true, -- intense healing rune
	[2277] = true, -- energy bomb rune
	[2278] = true, -- paralyze rune
	[2279] = true, -- magic wall rune
	[2280] = true, -- wild growth rune
	[2285] = true, -- heavy magic missile rune
	[2286] = true, -- light magic missile rune
	[2287] = true, -- stalagmite rune
	[2288] = true, -- stone shower rune
	[2289] = true, -- thunderstorm rune
	[2290] = true, -- fire wave rune
	[2291] = true, -- soulfire rune
	[2292] = true, -- icicle rune
	[2293] = true, -- avalanche rune
	[2304] = true, -- great fireball
	[2305] = true, -- firebomb
	[2308] = true, -- animate dead rune
	[2310] = true, -- convince creature rune
	[2311] = true, -- destroy field rune
	[2313] = true, -- disintegrate rune
	[2315] = true, -- chameleon rune
}

--- Check if an item is a rune
-- @param itemId number The item ID to check
-- @return boolean True if the item is a rune
function RetroPvP.isRune(itemId)
	return RetroPvP.RUNE_IDS[itemId] == true
end

--- Check if a rune usage should be blocked (hotkey check)
-- Called from action scripts; the 6th parameter (isHotkey) indicates hotkey usage
-- @param player Player The player using the rune
-- @param item Item The rune item being used
-- @param isHotkey boolean Whether the rune was used via hotkey
-- @return boolean True if the usage should be blocked
function RetroPvP.checkRuneHotkey(player, item, isHotkey)
	if not RetroPvP.config.blockRuneHotkeys then
		return false
	end

	if not isHotkey then
		return false
	end

	local itemId = item:getId()
	if not RetroPvP.isRune(itemId) then
		return false
	end

	player:sendCancelMessage(RetroPvP.config.runeHotkeyMessage)
	return true
end

-- ============================================================================
-- Rope Hole Blocking
-- ============================================================================

--- Check if a rope hole is blocked by a player standing on it
-- @param position Position The position of the rope hole (destination tile above)
-- @param player Player The player trying to use the rope
-- @return boolean True if the rope hole is blocked
function RetroPvP.isRopeHoleBlocked(position, player)
	if not RetroPvP.config.ropeHoleBlockingEnabled then
		return false
	end

	-- Check the tile above the rope hole for blocking players
	local upPos = Position(position.x, position.y, position.z - 1)
	local upTile = Tile(upPos)

	if not upTile then
		return false
	end

	local creatures = upTile:getCreatures()
	if not creatures then
		return false
	end

	for _, creature in ipairs(creatures) do
		if creature:isPlayer() and creature:getId() ~= player:getId() then
			player:sendCancelMessage("Someone is blocking the rope hole.")
			return true
		end
	end

	return false
end

-- ============================================================================
-- Custom Skull Thresholds
-- ============================================================================

--- Get the appropriate skull based on unjustified kill count
-- @param unjustKills number The number of unjustified kills
-- @return number The skull type constant
function RetroPvP.getSkullForKills(unjustKills)
	if unjustKills >= RetroPvP.config.killsForBlackSkull then
		return SKULL_BLACK
	elseif unjustKills >= RetroPvP.config.killsForRedSkull then
		return SKULL_RED
	elseif unjustKills >= RetroPvP.config.killsForWhiteSkull then
		return SKULL_WHITE
	end
	return SKULL_NONE
end

--- Get skull duration based on skull type
-- @param skullType number The skull type
-- @return number Duration in seconds
function RetroPvP.getSkullDuration(skullType)
	if skullType == SKULL_BLACK then
		return RetroPvP.config.blackSkullDuration
	elseif skullType == SKULL_RED then
		return RetroPvP.config.redSkullDuration
	elseif skullType == SKULL_WHITE then
		return RetroPvP.config.whiteSkullDuration
	end
	return 0
end

--- Record an unjustified kill and update skull
-- @param player Player The player who made the kill
function RetroPvP.addUnjustifiedKill(player)
	local kills = player:getStorageValue(RetroPvP.STORAGE.UNJUST_KILLS)
	if kills < 0 then kills = 0 end
	kills = kills + 1
	player:setStorageValue(RetroPvP.STORAGE.UNJUST_KILLS, kills)

	local newSkull = RetroPvP.getSkullForKills(kills)
	local currentSkull = player:getSkull()

	if newSkull > currentSkull then
		player:setSkull(newSkull)
		local duration = RetroPvP.getSkullDuration(newSkull)
		player:setStorageValue(RetroPvP.STORAGE.SKULL_EXPIRE_TIME, os.time() + duration)

		local skullNames = {
			[SKULL_WHITE] = "white",
			[SKULL_RED] = "red",
			[SKULL_BLACK] = "black",
		}
		local skullName = skullNames[newSkull] or "unknown"
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
			"You have received a " .. skullName .. " skull for " .. kills .. " unjustified kills.")
	end
end

--- Check and update skull expiration
-- @param player Player The player to check
function RetroPvP.checkSkullExpiration(player)
	local expireTime = player:getStorageValue(RetroPvP.STORAGE.SKULL_EXPIRE_TIME)
	if expireTime > 0 and os.time() >= expireTime then
		player:setSkull(SKULL_NONE)
		player:setStorageValue(RetroPvP.STORAGE.SKULL_EXPIRE_TIME, -1)
		player:setStorageValue(RetroPvP.STORAGE.UNJUST_KILLS, 0)
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Your skull has expired.")
	end
end

-- ============================================================================
-- PvP Damage Reduction Formula
-- ============================================================================

--- Calculate PvP damage after reduction
-- Applies both flat reduction and level-based scaling
-- @param attacker Player The attacking player
-- @param target Player The target player
-- @param damage number The raw damage amount (positive value)
-- @param damageType string "physical" or "magic"
-- @return number The adjusted damage amount
function RetroPvP.calculatePvPDamage(attacker, target, damage, damageType)
	if not attacker or not target then
		return damage
	end

	-- Apply flat PvP reduction
	local reductionPercent
	if damageType == "physical" then
		reductionPercent = RetroPvP.config.pvpPhysicalReduction
	else
		reductionPercent = RetroPvP.config.pvpMagicReduction
	end

	local reducedDamage = damage * (1 - reductionPercent / 100)

	-- Apply level-based scaling
	if RetroPvP.config.levelScalingEnabled then
		local attackerLevel = attacker:getLevel()
		local targetLevel = target:getLevel()

		if attackerLevel > targetLevel then
			local levelDiff = attackerLevel - targetLevel
			local maxDiff = RetroPvP.config.levelScalingMaxDiff
			local minRatio = RetroPvP.config.levelScalingMinRatio

			-- Scale damage down when attacking lower-level players
			-- The bigger the level difference, the more reduction
			local scalingFactor = 1.0
			if levelDiff >= maxDiff then
				scalingFactor = minRatio
			else
				scalingFactor = 1.0 - ((1.0 - minRatio) * (levelDiff / maxDiff))
			end

			reducedDamage = reducedDamage * scalingFactor
		end
	end

	return math.max(0, math.floor(reducedDamage))
end

-- ============================================================================
-- Death Penalty Adjustments
-- ============================================================================

--- Get the death penalty multiplier based on death context
-- @param player Player The player who died
-- @param killerIsPlayer boolean Whether the killer was a player
-- @return number The penalty multiplier (0.0 - 1.0)
function RetroPvP.getDeathPenaltyMultiplier(player, killerIsPlayer)
	-- Check skull-based overrides first
	local skull = player:getSkull()
	local skullPenalty = RetroPvP.config.skullDeathPenalty[skull]
	if skullPenalty then
		return skullPenalty
	end

	-- Apply PvP vs PvE multiplier
	if killerIsPlayer then
		return RetroPvP.config.pvpDeathPenalty
	end

	return RetroPvP.config.pveDeathPenalty
end

-- ============================================================================
-- Protection Zone Restrictions
-- ============================================================================

--- Check if a player is protected from PvP
-- @param player Player The player to check
-- @return boolean True if the player is protected
function RetroPvP.isProtected(player)
	if player:getLevel() < RetroPvP.config.protectionLevel then
		return true
	end
	return false
end

--- Check if PvP combat is allowed between two players
-- @param attacker Player The attacking player
-- @param target Player The target player
-- @return boolean, string True if allowed, or false with reason message
function RetroPvP.canAttack(attacker, target)
	if not attacker or not target then
		return false, "Invalid target."
	end

	if attacker:getId() == target:getId() then
		return false, "You cannot attack yourself."
	end

	-- Protection level check
	if RetroPvP.isProtected(target) then
		return false, "This player is under protection level " .. RetroPvP.config.protectionLevel .. "."
	end

	if RetroPvP.isProtected(attacker) then
		return false, "You are under protection level " .. RetroPvP.config.protectionLevel .. "."
	end

	-- Protection zone check
	local targetTile = target:getTile()
	if targetTile and targetTile:hasFlag(TILESTATE_PROTECTIONZONE) then
		return false, "You cannot attack players in a protection zone."
	end

	local attackerTile = attacker:getTile()
	if attackerTile and attackerTile:hasFlag(TILESTATE_PROTECTIONZONE) then
		return false, "You cannot attack from a protection zone."
	end

	return true, nil
end

-- ============================================================================
-- Utility Functions
-- ============================================================================

--- Get PvP statistics for a player
-- @param player Player The player
-- @return table Stats table with kills, deaths, unjustKills, skull
function RetroPvP.getStats(player)
	local kills = player:getStorageValue(RetroPvP.STORAGE.PVP_KILL_COUNT)
	local deaths = player:getStorageValue(RetroPvP.STORAGE.PVP_DEATH_COUNT)
	local unjust = player:getStorageValue(RetroPvP.STORAGE.UNJUST_KILLS)

	return {
		kills = kills > 0 and kills or 0,
		deaths = deaths > 0 and deaths or 0,
		unjustKills = unjust > 0 and unjust or 0,
		skull = player:getSkull(),
	}
end

--- Increment PvP kill count
-- @param player Player The player who killed
function RetroPvP.addPvPKill(player)
	local kills = player:getStorageValue(RetroPvP.STORAGE.PVP_KILL_COUNT)
	if kills < 0 then kills = 0 end
	player:setStorageValue(RetroPvP.STORAGE.PVP_KILL_COUNT, kills + 1)
end

--- Increment PvP death count
-- @param player Player The player who died
function RetroPvP.addPvPDeath(player)
	local deaths = player:getStorageValue(RetroPvP.STORAGE.PVP_DEATH_COUNT)
	if deaths < 0 then deaths = 0 end
	player:setStorageValue(RetroPvP.STORAGE.PVP_DEATH_COUNT, deaths + 1)
	player:setStorageValue(RetroPvP.STORAGE.LAST_PVP_DEATH, os.time())
end

print(">> Retro PvP system loaded")
