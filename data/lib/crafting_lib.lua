-- ============================================================================
-- Shared Crafting Library (crafting_lib.lua) - Phase 2
-- ============================================================================
-- Convenience wrappers and helpers used across all crafting action scripts.
-- This supplements the core Crafting table defined in crafting.lua with
-- higher-level utilities that individual systems (fishing, cooking, mining,
-- smithing, farming, enchanting) can call without duplicating logic.
-- ============================================================================

if not Crafting then
	Crafting = {}
end

-- ============================================================================
-- Recipe Registration Helpers
-- ============================================================================

--- Register a batch of recipes for a given crafting system.
-- @param system  string  e.g. "cooking", "mining", "smithing"
-- @param recipes table   array of recipe tables
function Crafting.registerRecipes(system, recipes)
	for _, recipe in ipairs(recipes) do
		Crafting.registerRecipe(system, recipe)
	end
end

--- Quick recipe builder with sensible defaults.
-- Returns a recipe table that can be passed to registerRecipe.
-- @param opts table with keys: id, name, craftingSkill, requiredSkillLevel,
--   ingredients, results, skillTries, successChance, stationItemId, etc.
function Crafting.makeRecipe(opts)
	return {
		id                = opts.id or 0,
		name              = opts.name or "Unknown Recipe",
		craftingSkill     = opts.craftingSkill or Crafting.SKILL_COOKING,
		requiredSkillLevel = opts.requiredSkillLevel or 1,
		ingredients       = opts.ingredients or {},
		tools             = opts.tools or {},
		results           = opts.results or {},
		requiredVocation  = opts.requiredVocation or {},
		skillTries        = opts.skillTries or 5,
		failSkillTries    = opts.failSkillTries or math.floor((opts.skillTries or 5) / 3),
		successChance     = opts.successChance or 80,
		skillBonusPerLevel = opts.skillBonusPerLevel or 2,
		maxSuccessChance  = opts.maxSuccessChance or 100,
		craftTime         = opts.craftTime or 1000,
		stationItemId     = opts.stationItemId or 0,
	}
end

-- ============================================================================
-- Skill Check Helpers
-- ============================================================================

--- Check whether a player meets the skill requirement for a recipe and send
-- an appropriate cancel message if not.
-- @return boolean  true if the player meets the requirement
function Crafting.requireSkill(player, craftingSkill, requiredLevel)
	local level = Crafting.getSkillLevel(player, craftingSkill)
	if level < requiredLevel then
		local skillName = Crafting.getSkillName(craftingSkill)
		player:sendCancelMessage(
			"You need " .. skillName .. " level " .. requiredLevel ..
			" to do this. Your current level is " .. level .. ".")
		return false
	end
	return true
end

--- Return the player's current level for a crafting skill, clamped to [1, 100].
function Crafting.clampedSkillLevel(player, craftingSkill)
	return math.max(1, math.min(100, Crafting.getSkillLevel(player, craftingSkill)))
end

--- Check multiple prerequisites at once (skill, ingredients, tools, vocation).
-- @return boolean, string  success flag and reason on failure
function Crafting.checkAllPrerequisites(player, recipe)
	if not Crafting.meetsSkillRequirement(player, recipe) then
		return false, "skill"
	end
	if not Crafting.checkVocation(player, recipe) then
		return false, "vocation"
	end
	if not Crafting.hasIngredients(player, recipe) then
		return false, "ingredients"
	end
	if not Crafting.hasTools(player, recipe) then
		return false, "tools"
	end
	return true, "ok"
end

-- ============================================================================
-- Success Rate Calculation Helpers
-- ============================================================================

--- Calculate a generic success rate given base chance, player skill, and
-- the required skill level. Each level above the requirement adds bonusPerLevel
-- percentage points, capped at maxChance.
-- @param baseChance     number  base success % (e.g. 50)
-- @param playerLevel    number  player's current skill level
-- @param requiredLevel  number  recipe's minimum skill level
-- @param bonusPerLevel  number  extra % per level above required (default 2)
-- @param maxChance      number  hard cap (default 95)
-- @return number  final success chance (0-100)
function Crafting.calcSuccessRate(baseChance, playerLevel, requiredLevel, bonusPerLevel, maxChance)
	bonusPerLevel = bonusPerLevel or 2
	maxChance = maxChance or 95
	local bonus = math.max(0, playerLevel - requiredLevel) * bonusPerLevel
	return math.min(maxChance, math.max(0, baseChance + bonus))
end

--- Perform a success/fail roll against a calculated chance.
-- @return boolean
function Crafting.rollChance(chance)
	return math.random(1, 100) <= chance
end

-- ============================================================================
-- XP / Skill Reward Helpers
-- ============================================================================

--- Award crafting XP and handle level-ups, with an optional multiplier.
-- @param player        userdata
-- @param craftingSkill number   skill id (e.g. Crafting.SKILL_COOKING)
-- @param baseTries     number   base tries to award
-- @param multiplier    number   optional multiplier (default 1.0)
function Crafting.rewardXP(player, craftingSkill, baseTries, multiplier)
	multiplier = multiplier or 1.0
	local tries = math.floor(baseTries * multiplier)
	if tries > 0 then
		Crafting.addSkillTries(player, craftingSkill, tries)
	end
end

--- Award a reduced amount of XP on failure (typically 1/3 of success XP).
function Crafting.rewardFailXP(player, craftingSkill, successTries)
	local failTries = math.max(1, math.floor(successTries / 3))
	Crafting.addSkillTries(player, craftingSkill, failTries)
end

--- Calculate an XP multiplier based on how close the recipe is to the
-- player's skill level. Recipes near the player's level give full XP;
-- recipes far below give diminished returns.
-- @return number  multiplier between 0.1 and 1.0
function Crafting.skillProximityMultiplier(playerLevel, requiredLevel)
	local gap = playerLevel - requiredLevel
	if gap <= 0 then
		return 1.0
	elseif gap <= 10 then
		return 1.0
	elseif gap <= 20 then
		return 0.75
	elseif gap <= 40 then
		return 0.5
	elseif gap <= 60 then
		return 0.25
	end
	return 0.1
end

-- ============================================================================
-- Cooldown Helpers
-- ============================================================================

--- Check whether a player is on cooldown for a crafting action.
-- @param player      userdata
-- @param storageKey  number   storage key used to track the cooldown
-- @param cooldownMs  number   cooldown duration in milliseconds
-- @return boolean  true if the player can act (cooldown expired)
function Crafting.checkCooldown(player, storageKey, cooldownMs)
	local lastTime = player:getStorageValue(storageKey)
	if lastTime > 0 then
		local elapsed = (os.mtime() - lastTime)
		if elapsed < cooldownMs then
			local remaining = math.ceil((cooldownMs - elapsed) / 1000)
			player:sendCancelMessage("You must wait " .. remaining .. " seconds before doing that again.")
			return false
		end
	end
	return true
end

--- Set the cooldown timestamp for a crafting action.
function Crafting.setCooldown(player, storageKey)
	player:setStorageValue(storageKey, os.mtime())
end

-- ============================================================================
-- Display / Formatting Helpers
-- ============================================================================

--- Format a skill progress string like "Mining: 45 (1234/5678 tries)"
function Crafting.formatSkillProgress(player, craftingSkill)
	local level = Crafting.getSkillLevel(player, craftingSkill)
	local tries = Crafting.getSkillTries(player, craftingSkill)
	local needed = Crafting.getTriesForLevel(level + 1)
	local name = Crafting.getSkillName(craftingSkill)
	return name .. ": " .. level .. " (" .. tries .. "/" .. needed .. " tries)"
end

--- Send the player a summary of all their crafting skill levels.
function Crafting.sendSkillSummary(player)
	local lines = {"--- Crafting Skills ---"}
	for skillId, skillName in pairs(Crafting.SKILL_NAMES) do
		table.insert(lines, Crafting.formatSkillProgress(player, skillId))
	end
	player:sendTextMessage(MESSAGE_INFO_DESCR, table.concat(lines, "\n"))
end
