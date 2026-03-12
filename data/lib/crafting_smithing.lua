-- ============================================================================
-- Smithing System Library - Phase 2.5
-- ============================================================================
-- Defines smithing skill progression, equipment recipes, and quality system.
-- Uses the shared Crafting framework (crafting.lua) with SKILL_SMITHING.
-- Bars are produced by the smelting system (crafting_mining.lua) and
-- consumed here at an anvil to forge weapons and armor.
-- ============================================================================

Smithing = {}

-- ---------------------------------------------------------------------------
-- Storage Keys (smithing-specific, avoids collision with Mining 45100-45103)
-- ---------------------------------------------------------------------------
Smithing.Storage = {
	skillLevel     = 45200, -- current smithing skill level (0-100)
	skillTries     = 45201, -- accumulated tries toward next level
	lastSmithTime  = 45202, -- cooldown timestamp
}

-- Skill tries needed per level (same exponential curve as Mining)
function Smithing.getTriesForLevel(level)
	if level <= 0 then return 0 end
	return math.floor(30 * (1.1 ^ (level - 1)))
end

function Smithing.getSkillLevel(player)
	return math.max(0, player:getStorageValue(Smithing.Storage.skillLevel))
end

function Smithing.getSkillTries(player)
	return math.max(0, player:getStorageValue(Smithing.Storage.skillTries))
end

function Smithing.addSkillTries(player, tries)
	local currentLevel = Smithing.getSkillLevel(player)
	local currentTries = Smithing.getSkillTries(player) + tries

	while currentLevel < 100 do
		local needed = Smithing.getTriesForLevel(currentLevel + 1)
		if currentTries >= needed then
			currentTries = currentTries - needed
			currentLevel = currentLevel + 1
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
				"You advanced to smithing level " .. currentLevel .. ".")
			player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
		else
			break
		end
	end

	player:setStorageValue(Smithing.Storage.skillLevel, currentLevel)
	player:setStorageValue(Smithing.Storage.skillTries, currentTries)
end

-- ---------------------------------------------------------------------------
-- Item IDs - Bars (from Mining.Items, repeated here for readability)
-- ---------------------------------------------------------------------------
Smithing.Bars = {
	COPPER_BAR      = 30400,
	TIN_BAR         = 30401,
	BRONZE_BAR      = 30402,
	IRON_BAR        = 30403,
	STEEL_BAR       = 30404,
	SILVER_BAR      = 30405,
	GOLD_BAR        = 30406,
	MITHRIL_BAR     = 30407,
	PLATINUM_BAR    = 30408,
	ADAMANTITE_BAR  = 30409,
	ORICHALCUM_BAR  = 30410,
}

-- ---------------------------------------------------------------------------
-- Item IDs - Crafted Equipment (30500-30599 range per Phase 2 allocation)
-- ---------------------------------------------------------------------------
Smithing.Equipment = {
	-- Tier 1: Bronze (Copper + Tin -> Bronze Bar)
	BRONZE_SWORD        = 30500,
	BRONZE_AXE          = 30501,
	BRONZE_MACE         = 30502,
	BRONZE_HELMET       = 30503,
	BRONZE_ARMOR        = 30504,
	BRONZE_LEGS         = 30505,
	BRONZE_SHIELD       = 30506,
	BRONZE_BOOTS        = 30507,

	-- Tier 2: Steel (Iron + Coal -> Steel Bar)
	STEEL_SWORD         = 30508,
	STEEL_AXE           = 30509,
	STEEL_MACE          = 30510,
	STEEL_HELMET        = 30511,
	STEEL_ARMOR         = 30512,
	STEEL_LEGS          = 30513,
	STEEL_SHIELD        = 30514,
	STEEL_CROSSBOW      = 30515,

	-- Tier 3: Silver
	SILVER_SWORD        = 30516,
	SILVER_MACE         = 30517,
	SILVER_HELMET       = 30518,
	SILVER_ARMOR        = 30519,
	SILVER_SHIELD       = 30520,

	-- Tier 4: Gold
	GOLD_AXE            = 30521,
	GOLD_MACE           = 30522,
	GOLD_HELMET         = 30523,
	GOLD_ARMOR          = 30524,
	GOLD_SHIELD         = 30525,

	-- Tier 5: Mithril
	MITHRIL_SWORD       = 30526,
	MITHRIL_AXE         = 30527,
	MITHRIL_BOW         = 30528,
	MITHRIL_HELMET      = 30529,
	MITHRIL_ARMOR       = 30530,
	MITHRIL_LEGS        = 30531,
	MITHRIL_SHIELD      = 30532,
	MITHRIL_BOOTS       = 30533,

	-- Tier 6: Platinum
	PLATINUM_SWORD      = 30534,
	PLATINUM_AXE        = 30535,
	PLATINUM_CROSSBOW   = 30536,
	PLATINUM_HELMET     = 30537,
	PLATINUM_ARMOR      = 30538,
	PLATINUM_LEGS       = 30539,
	PLATINUM_SHIELD     = 30540,

	-- Tier 7: Adamantite
	ADAMANTITE_SWORD    = 30541,
	ADAMANTITE_AXE      = 30542,
	ADAMANTITE_BOW      = 30543,
	ADAMANTITE_ARMOR    = 30544,
	ADAMANTITE_SHIELD   = 30545,
	ADAMANTITE_BOOTS    = 30546,

	-- Tier 8: Orichalcum
	ORICHALCUM_SWORD    = 30547,
	ORICHALCUM_AXE      = 30548,
	ORICHALCUM_BOW      = 30549,
	ORICHALCUM_ARMOR    = 30550,
	ORICHALCUM_SHIELD   = 30551,
	ORICHALCUM_HELMET   = 30552,
}

-- ---------------------------------------------------------------------------
-- Tools
-- ---------------------------------------------------------------------------
Smithing.Tools = {
	BLACKSMITH_HAMMER = 30422,
	MASTER_HAMMER     = 30423,
}

-- ---------------------------------------------------------------------------
-- Station IDs (anvil variants that can be used for smithing)
-- ---------------------------------------------------------------------------
Smithing.AnvilIds = {
	2555, 2556,    -- standard TFS anvils
	30421,         -- custom crafting anvil from Phase 2
}

function Smithing.isAnvil(itemId)
	for _, id in ipairs(Smithing.AnvilIds) do
		if id == itemId then return true end
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Hammer tiers: better hammer = higher success bonus
-- ---------------------------------------------------------------------------
Smithing.Hammers = {
	[Smithing.Tools.BLACKSMITH_HAMMER] = { name = "blacksmith hammer", bonus = 0  },
	[Smithing.Tools.MASTER_HAMMER]     = { name = "master hammer",     bonus = 10 },
}

-- ---------------------------------------------------------------------------
-- Quality System
-- ---------------------------------------------------------------------------
-- Quality tiers based on skill level relative to recipe requirement.
-- Higher skill above the recipe threshold = better chance at higher quality.
-- Quality affects the item's description and can be read by combat scripts.
-- ---------------------------------------------------------------------------
Smithing.Quality = {
	BASIC      = 1,
	FINE       = 2,
	SUPERIOR   = 3,
	MASTERWORK = 4,
}

Smithing.QualityNames = {
	[1] = "Basic",
	[2] = "Fine",
	[3] = "Superior",
	[4] = "Masterwork",
}

Smithing.QualityColors = {
	[1] = "",                -- no prefix
	[2] = "fine ",           -- "fine Steel Sword"
	[3] = "superior ",       -- "superior Steel Sword"
	[4] = "masterwork ",     -- "masterwork Steel Sword"
}

--- Determine quality tier based on skill level above recipe requirement.
-- @param smithingLevel  number  player's current smithing level
-- @param requiredLevel  number  recipe's minimum smithing level
-- @param hammerBonus    number  bonus from hammer tier (adds to effective level)
-- @return number  quality tier (1-4)
function Smithing.rollQuality(smithingLevel, requiredLevel, hammerBonus)
	local effectiveLevel = smithingLevel + (hammerBonus or 0)
	local surplus = math.max(0, effectiveLevel - requiredLevel)

	-- Masterwork: 20+ levels above, 15% chance (capped at 30%)
	-- Superior:   10+ levels above, 25% chance (capped at 50%)
	-- Fine:       5+ levels above, 40% chance (capped at 70%)
	-- Basic:      default

	local roll = math.random(1, 100)

	if surplus >= 20 then
		local masterChance = math.min(30, 15 + (surplus - 20))
		if roll <= masterChance then
			return Smithing.Quality.MASTERWORK
		end
	end

	if surplus >= 10 then
		local superiorChance = math.min(50, 25 + (surplus - 10))
		if roll <= superiorChance then
			return Smithing.Quality.SUPERIOR
		end
	end

	if surplus >= 5 then
		local fineChance = math.min(70, 40 + (surplus - 5) * 2)
		if roll <= fineChance then
			return Smithing.Quality.FINE
		end
	end

	return Smithing.Quality.BASIC
end

-- ---------------------------------------------------------------------------
-- Success chance calculation
-- base successChance + 0.5% per level above required + hammer bonus, cap 95%
-- ---------------------------------------------------------------------------
function Smithing.getSuccessChance(recipe, smithingLevel, hammerBonus)
	local bonus = math.max(0, smithingLevel - recipe.requiredSkill) * 0.5
	return math.min(95, recipe.successBase + bonus + (hammerBonus or 0))
end

-- ---------------------------------------------------------------------------
-- Smithing Recipes
-- ---------------------------------------------------------------------------
-- Each recipe: {name, ingredients={{id, count},...}, result=itemId,
--               requiredSkill, successBase, triesReward, category}
--
-- Categories: "sword", "axe", "club", "bow", "crossbow",
--             "helmet", "armor", "legs", "boots", "shield"
-- ---------------------------------------------------------------------------
Smithing.Recipes = {
	-- ===== TIER 1: Bronze (req skill 1-10) =====
	{
		name = "Bronze Sword",
		ingredients = { {Smithing.Bars.BRONZE_BAR, 3} },
		result = Smithing.Equipment.BRONZE_SWORD,
		requiredSkill = 1,
		successBase = 80,
		triesReward = 5,
		category = "sword",
	},
	{
		name = "Bronze Axe",
		ingredients = { {Smithing.Bars.BRONZE_BAR, 3} },
		result = Smithing.Equipment.BRONZE_AXE,
		requiredSkill = 1,
		successBase = 80,
		triesReward = 5,
		category = "axe",
	},
	{
		name = "Bronze Mace",
		ingredients = { {Smithing.Bars.BRONZE_BAR, 3} },
		result = Smithing.Equipment.BRONZE_MACE,
		requiredSkill = 1,
		successBase = 80,
		triesReward = 5,
		category = "club",
	},
	{
		name = "Bronze Helmet",
		ingredients = { {Smithing.Bars.BRONZE_BAR, 2} },
		result = Smithing.Equipment.BRONZE_HELMET,
		requiredSkill = 3,
		successBase = 80,
		triesReward = 4,
		category = "helmet",
	},
	{
		name = "Bronze Armor",
		ingredients = { {Smithing.Bars.BRONZE_BAR, 5} },
		result = Smithing.Equipment.BRONZE_ARMOR,
		requiredSkill = 5,
		successBase = 75,
		triesReward = 6,
		category = "armor",
	},
	{
		name = "Bronze Legs",
		ingredients = { {Smithing.Bars.BRONZE_BAR, 4} },
		result = Smithing.Equipment.BRONZE_LEGS,
		requiredSkill = 5,
		successBase = 75,
		triesReward = 5,
		category = "legs",
	},
	{
		name = "Bronze Shield",
		ingredients = { {Smithing.Bars.BRONZE_BAR, 3} },
		result = Smithing.Equipment.BRONZE_SHIELD,
		requiredSkill = 3,
		successBase = 80,
		triesReward = 5,
		category = "shield",
	},
	{
		name = "Bronze Boots",
		ingredients = { {Smithing.Bars.BRONZE_BAR, 2} },
		result = Smithing.Equipment.BRONZE_BOOTS,
		requiredSkill = 2,
		successBase = 85,
		triesReward = 3,
		category = "boots",
	},

	-- ===== TIER 2: Steel (req skill 15-25) =====
	{
		name = "Steel Sword",
		ingredients = { {Smithing.Bars.STEEL_BAR, 4} },
		result = Smithing.Equipment.STEEL_SWORD,
		requiredSkill = 15,
		successBase = 70,
		triesReward = 10,
		category = "sword",
	},
	{
		name = "Steel Axe",
		ingredients = { {Smithing.Bars.STEEL_BAR, 4} },
		result = Smithing.Equipment.STEEL_AXE,
		requiredSkill = 15,
		successBase = 70,
		triesReward = 10,
		category = "axe",
	},
	{
		name = "Steel Mace",
		ingredients = { {Smithing.Bars.STEEL_BAR, 4} },
		result = Smithing.Equipment.STEEL_MACE,
		requiredSkill = 15,
		successBase = 70,
		triesReward = 10,
		category = "club",
	},
	{
		name = "Steel Helmet",
		ingredients = { {Smithing.Bars.STEEL_BAR, 3} },
		result = Smithing.Equipment.STEEL_HELMET,
		requiredSkill = 18,
		successBase = 70,
		triesReward = 8,
		category = "helmet",
	},
	{
		name = "Steel Armor",
		ingredients = { {Smithing.Bars.STEEL_BAR, 6} },
		result = Smithing.Equipment.STEEL_ARMOR,
		requiredSkill = 22,
		successBase = 65,
		triesReward = 12,
		category = "armor",
	},
	{
		name = "Steel Legs",
		ingredients = { {Smithing.Bars.STEEL_BAR, 5} },
		result = Smithing.Equipment.STEEL_LEGS,
		requiredSkill = 20,
		successBase = 65,
		triesReward = 10,
		category = "legs",
	},
	{
		name = "Steel Shield",
		ingredients = { {Smithing.Bars.STEEL_BAR, 4} },
		result = Smithing.Equipment.STEEL_SHIELD,
		requiredSkill = 18,
		successBase = 70,
		triesReward = 10,
		category = "shield",
	},
	{
		name = "Steel Crossbow",
		ingredients = { {Smithing.Bars.STEEL_BAR, 3}, {Smithing.Bars.IRON_BAR, 2} },
		result = Smithing.Equipment.STEEL_CROSSBOW,
		requiredSkill = 20,
		successBase = 65,
		triesReward = 12,
		category = "crossbow",
	},

	-- ===== TIER 3: Silver (req skill 25-35) =====
	{
		name = "Silver Sword",
		ingredients = { {Smithing.Bars.SILVER_BAR, 4}, {Smithing.Bars.STEEL_BAR, 1} },
		result = Smithing.Equipment.SILVER_SWORD,
		requiredSkill = 25,
		successBase = 65,
		triesReward = 15,
		category = "sword",
	},
	{
		name = "Silver Mace",
		ingredients = { {Smithing.Bars.SILVER_BAR, 4}, {Smithing.Bars.STEEL_BAR, 1} },
		result = Smithing.Equipment.SILVER_MACE,
		requiredSkill = 25,
		successBase = 65,
		triesReward = 15,
		category = "club",
	},
	{
		name = "Silver Helmet",
		ingredients = { {Smithing.Bars.SILVER_BAR, 3} },
		result = Smithing.Equipment.SILVER_HELMET,
		requiredSkill = 28,
		successBase = 65,
		triesReward = 12,
		category = "helmet",
	},
	{
		name = "Silver Armor",
		ingredients = { {Smithing.Bars.SILVER_BAR, 6}, {Smithing.Bars.STEEL_BAR, 2} },
		result = Smithing.Equipment.SILVER_ARMOR,
		requiredSkill = 32,
		successBase = 60,
		triesReward = 18,
		category = "armor",
	},
	{
		name = "Silver Shield",
		ingredients = { {Smithing.Bars.SILVER_BAR, 4} },
		result = Smithing.Equipment.SILVER_SHIELD,
		requiredSkill = 28,
		successBase = 65,
		triesReward = 15,
		category = "shield",
	},

	-- ===== TIER 4: Gold (req skill 35-45) =====
	{
		name = "Gold Axe",
		ingredients = { {Smithing.Bars.GOLD_BAR, 5}, {Smithing.Bars.STEEL_BAR, 2} },
		result = Smithing.Equipment.GOLD_AXE,
		requiredSkill = 35,
		successBase = 60,
		triesReward = 20,
		category = "axe",
	},
	{
		name = "Gold Mace",
		ingredients = { {Smithing.Bars.GOLD_BAR, 5}, {Smithing.Bars.STEEL_BAR, 2} },
		result = Smithing.Equipment.GOLD_MACE,
		requiredSkill = 35,
		successBase = 60,
		triesReward = 20,
		category = "club",
	},
	{
		name = "Gold Helmet",
		ingredients = { {Smithing.Bars.GOLD_BAR, 4} },
		result = Smithing.Equipment.GOLD_HELMET,
		requiredSkill = 38,
		successBase = 60,
		triesReward = 16,
		category = "helmet",
	},
	{
		name = "Gold Armor",
		ingredients = { {Smithing.Bars.GOLD_BAR, 7}, {Smithing.Bars.STEEL_BAR, 3} },
		result = Smithing.Equipment.GOLD_ARMOR,
		requiredSkill = 42,
		successBase = 55,
		triesReward = 25,
		category = "armor",
	},
	{
		name = "Gold Shield",
		ingredients = { {Smithing.Bars.GOLD_BAR, 5} },
		result = Smithing.Equipment.GOLD_SHIELD,
		requiredSkill = 38,
		successBase = 60,
		triesReward = 20,
		category = "shield",
	},

	-- ===== TIER 5: Mithril (req skill 50-60) =====
	{
		name = "Mithril Sword",
		ingredients = { {Smithing.Bars.MITHRIL_BAR, 5}, {Smithing.Bars.STEEL_BAR, 2} },
		result = Smithing.Equipment.MITHRIL_SWORD,
		requiredSkill = 50,
		successBase = 55,
		triesReward = 30,
		category = "sword",
	},
	{
		name = "Mithril Axe",
		ingredients = { {Smithing.Bars.MITHRIL_BAR, 5}, {Smithing.Bars.STEEL_BAR, 2} },
		result = Smithing.Equipment.MITHRIL_AXE,
		requiredSkill = 50,
		successBase = 55,
		triesReward = 30,
		category = "axe",
	},
	{
		name = "Mithril Bow",
		ingredients = { {Smithing.Bars.MITHRIL_BAR, 4}, {Smithing.Bars.IRON_BAR, 2} },
		result = Smithing.Equipment.MITHRIL_BOW,
		requiredSkill = 52,
		successBase = 55,
		triesReward = 28,
		category = "bow",
	},
	{
		name = "Mithril Helmet",
		ingredients = { {Smithing.Bars.MITHRIL_BAR, 4} },
		result = Smithing.Equipment.MITHRIL_HELMET,
		requiredSkill = 53,
		successBase = 55,
		triesReward = 25,
		category = "helmet",
	},
	{
		name = "Mithril Armor",
		ingredients = { {Smithing.Bars.MITHRIL_BAR, 8}, {Smithing.Bars.STEEL_BAR, 3} },
		result = Smithing.Equipment.MITHRIL_ARMOR,
		requiredSkill = 58,
		successBase = 45,
		triesReward = 40,
		category = "armor",
	},
	{
		name = "Mithril Legs",
		ingredients = { {Smithing.Bars.MITHRIL_BAR, 6}, {Smithing.Bars.STEEL_BAR, 2} },
		result = Smithing.Equipment.MITHRIL_LEGS,
		requiredSkill = 55,
		successBase = 50,
		triesReward = 35,
		category = "legs",
	},
	{
		name = "Mithril Shield",
		ingredients = { {Smithing.Bars.MITHRIL_BAR, 5} },
		result = Smithing.Equipment.MITHRIL_SHIELD,
		requiredSkill = 53,
		successBase = 55,
		triesReward = 30,
		category = "shield",
	},
	{
		name = "Mithril Boots",
		ingredients = { {Smithing.Bars.MITHRIL_BAR, 3} },
		result = Smithing.Equipment.MITHRIL_BOOTS,
		requiredSkill = 50,
		successBase = 60,
		triesReward = 22,
		category = "boots",
	},

	-- ===== TIER 6: Platinum (req skill 60-70) =====
	{
		name = "Platinum Sword",
		ingredients = { {Smithing.Bars.PLATINUM_BAR, 5}, {Smithing.Bars.MITHRIL_BAR, 2} },
		result = Smithing.Equipment.PLATINUM_SWORD,
		requiredSkill = 60,
		successBase = 50,
		triesReward = 40,
		category = "sword",
	},
	{
		name = "Platinum Axe",
		ingredients = { {Smithing.Bars.PLATINUM_BAR, 5}, {Smithing.Bars.MITHRIL_BAR, 2} },
		result = Smithing.Equipment.PLATINUM_AXE,
		requiredSkill = 60,
		successBase = 50,
		triesReward = 40,
		category = "axe",
	},
	{
		name = "Platinum Crossbow",
		ingredients = { {Smithing.Bars.PLATINUM_BAR, 4}, {Smithing.Bars.MITHRIL_BAR, 2} },
		result = Smithing.Equipment.PLATINUM_CROSSBOW,
		requiredSkill = 62,
		successBase = 50,
		triesReward = 38,
		category = "crossbow",
	},
	{
		name = "Platinum Helmet",
		ingredients = { {Smithing.Bars.PLATINUM_BAR, 4}, {Smithing.Bars.MITHRIL_BAR, 1} },
		result = Smithing.Equipment.PLATINUM_HELMET,
		requiredSkill = 63,
		successBase = 50,
		triesReward = 35,
		category = "helmet",
	},
	{
		name = "Platinum Armor",
		ingredients = { {Smithing.Bars.PLATINUM_BAR, 8}, {Smithing.Bars.MITHRIL_BAR, 3} },
		result = Smithing.Equipment.PLATINUM_ARMOR,
		requiredSkill = 68,
		successBase = 40,
		triesReward = 50,
		category = "armor",
	},
	{
		name = "Platinum Legs",
		ingredients = { {Smithing.Bars.PLATINUM_BAR, 6}, {Smithing.Bars.MITHRIL_BAR, 2} },
		result = Smithing.Equipment.PLATINUM_LEGS,
		requiredSkill = 65,
		successBase = 45,
		triesReward = 45,
		category = "legs",
	},
	{
		name = "Platinum Shield",
		ingredients = { {Smithing.Bars.PLATINUM_BAR, 5}, {Smithing.Bars.MITHRIL_BAR, 1} },
		result = Smithing.Equipment.PLATINUM_SHIELD,
		requiredSkill = 63,
		successBase = 50,
		triesReward = 40,
		category = "shield",
	},

	-- ===== TIER 7: Adamantite (req skill 75-85) =====
	{
		name = "Adamantite Sword",
		ingredients = { {Smithing.Bars.ADAMANTITE_BAR, 6}, {Smithing.Bars.MITHRIL_BAR, 3} },
		result = Smithing.Equipment.ADAMANTITE_SWORD,
		requiredSkill = 75,
		successBase = 40,
		triesReward = 60,
		category = "sword",
	},
	{
		name = "Adamantite Axe",
		ingredients = { {Smithing.Bars.ADAMANTITE_BAR, 6}, {Smithing.Bars.MITHRIL_BAR, 3} },
		result = Smithing.Equipment.ADAMANTITE_AXE,
		requiredSkill = 75,
		successBase = 40,
		triesReward = 60,
		category = "axe",
	},
	{
		name = "Adamantite Bow",
		ingredients = { {Smithing.Bars.ADAMANTITE_BAR, 5}, {Smithing.Bars.PLATINUM_BAR, 2} },
		result = Smithing.Equipment.ADAMANTITE_BOW,
		requiredSkill = 78,
		successBase = 40,
		triesReward = 55,
		category = "bow",
	},
	{
		name = "Adamantite Armor",
		ingredients = { {Smithing.Bars.ADAMANTITE_BAR, 10}, {Smithing.Bars.MITHRIL_BAR, 4} },
		result = Smithing.Equipment.ADAMANTITE_ARMOR,
		requiredSkill = 82,
		successBase = 35,
		triesReward = 80,
		category = "armor",
	},
	{
		name = "Adamantite Shield",
		ingredients = { {Smithing.Bars.ADAMANTITE_BAR, 6}, {Smithing.Bars.PLATINUM_BAR, 2} },
		result = Smithing.Equipment.ADAMANTITE_SHIELD,
		requiredSkill = 78,
		successBase = 40,
		triesReward = 60,
		category = "shield",
	},
	{
		name = "Adamantite Boots",
		ingredients = { {Smithing.Bars.ADAMANTITE_BAR, 4}, {Smithing.Bars.MITHRIL_BAR, 1} },
		result = Smithing.Equipment.ADAMANTITE_BOOTS,
		requiredSkill = 75,
		successBase = 45,
		triesReward = 45,
		category = "boots",
	},

	-- ===== TIER 8: Orichalcum (req skill 85-95) =====
	{
		name = "Orichalcum Sword",
		ingredients = { {Smithing.Bars.ORICHALCUM_BAR, 7}, {Smithing.Bars.ADAMANTITE_BAR, 3} },
		result = Smithing.Equipment.ORICHALCUM_SWORD,
		requiredSkill = 85,
		successBase = 35,
		triesReward = 80,
		category = "sword",
	},
	{
		name = "Orichalcum Axe",
		ingredients = { {Smithing.Bars.ORICHALCUM_BAR, 7}, {Smithing.Bars.ADAMANTITE_BAR, 3} },
		result = Smithing.Equipment.ORICHALCUM_AXE,
		requiredSkill = 85,
		successBase = 35,
		triesReward = 80,
		category = "axe",
	},
	{
		name = "Orichalcum Bow",
		ingredients = { {Smithing.Bars.ORICHALCUM_BAR, 6}, {Smithing.Bars.ADAMANTITE_BAR, 2} },
		result = Smithing.Equipment.ORICHALCUM_BOW,
		requiredSkill = 88,
		successBase = 35,
		triesReward = 75,
		category = "bow",
	},
	{
		name = "Orichalcum Armor",
		ingredients = { {Smithing.Bars.ORICHALCUM_BAR, 12}, {Smithing.Bars.ADAMANTITE_BAR, 5} },
		result = Smithing.Equipment.ORICHALCUM_ARMOR,
		requiredSkill = 92,
		successBase = 25,
		triesReward = 120,
		category = "armor",
	},
	{
		name = "Orichalcum Shield",
		ingredients = { {Smithing.Bars.ORICHALCUM_BAR, 7}, {Smithing.Bars.ADAMANTITE_BAR, 2} },
		result = Smithing.Equipment.ORICHALCUM_SHIELD,
		requiredSkill = 88,
		successBase = 35,
		triesReward = 80,
		category = "shield",
	},
	{
		name = "Orichalcum Helmet",
		ingredients = { {Smithing.Bars.ORICHALCUM_BAR, 5}, {Smithing.Bars.ADAMANTITE_BAR, 2} },
		result = Smithing.Equipment.ORICHALCUM_HELMET,
		requiredSkill = 90,
		successBase = 30,
		triesReward = 70,
		category = "helmet",
	},
}

-- ---------------------------------------------------------------------------
-- Recipe lookup helpers
-- ---------------------------------------------------------------------------

--- Build a lookup table keyed by bar item ID for fast recipe matching.
-- Each bar ID maps to a list of recipes that use it as an ingredient.
Smithing.RecipesByBar = {}

function Smithing.buildRecipeIndex()
	Smithing.RecipesByBar = {}
	for _, recipe in ipairs(Smithing.Recipes) do
		for _, ing in ipairs(recipe.ingredients) do
			local barId = ing[1]
			if not Smithing.RecipesByBar[barId] then
				Smithing.RecipesByBar[barId] = {}
			end
			table.insert(Smithing.RecipesByBar[barId], recipe)
		end
	end
end

-- Build the index on load
Smithing.buildRecipeIndex()

--- Find all recipes the player can craft right now (has materials + skill).
-- If barId is provided, only check recipes using that bar type.
function Smithing.findAvailableRecipes(player, smithingLevel, barId)
	local candidates
	if barId and Smithing.RecipesByBar[barId] then
		candidates = Smithing.RecipesByBar[barId]
	else
		candidates = Smithing.Recipes
	end

	local matches = {}
	for _, recipe in ipairs(candidates) do
		if smithingLevel >= recipe.requiredSkill then
			local hasAll = true
			for _, ing in ipairs(recipe.ingredients) do
				if player:getItemCount(ing[1]) < ing[2] then
					hasAll = false
					break
				end
			end
			if hasAll then
				table.insert(matches, recipe)
			end
		end
	end
	return matches
end

--- Find the single best (highest skill requirement) recipe the player can
-- craft with a given bar type.
function Smithing.findBestRecipe(player, smithingLevel, barId)
	local available = Smithing.findAvailableRecipes(player, smithingLevel, barId)
	if #available == 0 then return nil end

	-- Sort by required skill descending so the hardest craftable recipe wins
	table.sort(available, function(a, b)
		return a.requiredSkill > b.requiredSkill
	end)
	return available[1]
end

--- Check if an item ID is a bar used in any smithing recipe.
function Smithing.isBar(itemId)
	return Smithing.RecipesByBar[itemId] ~= nil
end
