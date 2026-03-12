-- ============================================================================
-- Mining & Smelting System - Phase 2.4
-- ============================================================================
-- Uses player storage values to track mining skill since TFS 1.3
-- does not support custom skill types natively.
-- ============================================================================

Mining = {}

-- ---------------------------------------------------------------------------
-- Storage Keys
-- ---------------------------------------------------------------------------
Mining.Storage = {
	skillLevel     = 45100, -- current mining skill level (0-100)
	skillTries     = 45101, -- accumulated skill tries toward next level
	lastMineTime   = 45102, -- anti-spam cooldown timestamp
}

-- Skill tries needed per level (exponential curve, base 30, multiplier 1.1)
function Mining.getTriesForLevel(level)
	if level <= 0 then return 0 end
	return math.floor(30 * (1.1 ^ (level - 1)))
end

function Mining.getSkillLevel(player)
	return math.max(0, player:getStorageValue(Mining.Storage.skillLevel))
end

function Mining.getSkillTries(player)
	return math.max(0, player:getStorageValue(Mining.Storage.skillTries))
end

function Mining.addSkillTries(player, tries)
	local currentLevel = Mining.getSkillLevel(player)
	local currentTries = Mining.getSkillTries(player) + tries

	-- Level up loop
	while currentLevel < 100 do
		local needed = Mining.getTriesForLevel(currentLevel + 1)
		if currentTries >= needed then
			currentTries = currentTries - needed
			currentLevel = currentLevel + 1
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
				"You advanced to mining level " .. currentLevel .. ".")
			player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
		else
			break
		end
	end

	player:setStorageValue(Mining.Storage.skillLevel, currentLevel)
	player:setStorageValue(Mining.Storage.skillTries, currentTries)
end

-- ---------------------------------------------------------------------------
-- Item IDs (from Phase 2 allocation: 30300-30399)
-- ---------------------------------------------------------------------------
Mining.Items = {
	-- Ores (11 types)
	COPPER_ORE          = 30300,
	TIN_ORE             = 30301,
	IRON_ORE            = 30302,
	COAL                = 30303,
	SILVER_ORE          = 30304,
	GOLD_ORE            = 30305,
	MITHRIL_ORE         = 30306,
	PLATINUM_ORE        = 30307,
	ADAMANTITE_ORE      = 30308,
	ORICHALCUM_ORE      = 30309,
	PAINITE_CRYSTAL     = 30310, -- legendary, used for enchanting

	-- Pickaxes
	BASIC_PICKAXE       = 30320,
	STEEL_PICKAXE       = 30321,
	CRYSTAL_PICKAXE     = 30322,

	-- Gems (bonus finds)
	DIAMOND             = 2145,
	RUBY                = 2147,
	EMERALD             = 2149,
	SAPPHIRE            = 2146,

	-- Bars (smelting output, from Smithing range 30400+)
	COPPER_BAR          = 30400,
	TIN_BAR             = 30401,
	BRONZE_BAR          = 30402,
	IRON_BAR            = 30403,
	STEEL_BAR           = 30404,
	SILVER_BAR          = 30405,
	GOLD_BAR            = 30406,
	MITHRIL_BAR         = 30407,
	PLATINUM_BAR        = 30408,
	ADAMANTITE_BAR      = 30409,
	ORICHALCUM_BAR      = 30410,
}

-- ---------------------------------------------------------------------------
-- Ore Vein definitions (placed on map with specific action IDs)
-- ---------------------------------------------------------------------------
-- Map builders place items/tiles and assign these action IDs to create veins.
-- ActionID -> vein configuration
Mining.VEIN_ACTIONID_BASE = 9100

Mining.VeinTypes = {
	-- actionId          pool name       minSkill  depleteHits  respawnSec
	[9100] = { pool = "copper",      minSkill = 0,   depleteAfter = 5,  respawnTime = 300  },
	[9101] = { pool = "tin",         minSkill = 0,   depleteAfter = 5,  respawnTime = 300  },
	[9102] = { pool = "iron",        minSkill = 10,  depleteAfter = 4,  respawnTime = 600  },
	[9103] = { pool = "silver",      minSkill = 25,  depleteAfter = 3,  respawnTime = 900  },
	[9104] = { pool = "gold",        minSkill = 35,  depleteAfter = 3,  respawnTime = 900  },
	[9105] = { pool = "coal",        minSkill = 15,  depleteAfter = 5,  respawnTime = 300  },
	[9106] = { pool = "mithril",     minSkill = 50,  depleteAfter = 2,  respawnTime = 1200 },
	[9107] = { pool = "platinum",    minSkill = 60,  depleteAfter = 2,  respawnTime = 1200 },
	[9108] = { pool = "adamantite",  minSkill = 75,  depleteAfter = 2,  respawnTime = 1500 },
	[9109] = { pool = "orichalcum",  minSkill = 85,  depleteAfter = 1,  respawnTime = 1800 },
	[9110] = { pool = "painite",     minSkill = 90,  depleteAfter = 1,  respawnTime = 3600 },
	[9111] = { pool = "mixed_common",   minSkill = 0,   depleteAfter = 5,  respawnTime = 300  },
	[9112] = { pool = "mixed_uncommon", minSkill = 15,  depleteAfter = 3,  respawnTime = 900  },
	[9113] = { pool = "mixed_rare",     minSkill = 50,  depleteAfter = 2,  respawnTime = 1200 },
	[9114] = { pool = "mixed_all",      minSkill = 75,  depleteAfter = 2,  respawnTime = 1500 },
}

-- ---------------------------------------------------------------------------
-- Ore pools: define what each vein type can yield
-- Each entry: {itemId, weight, name, skillTries}
-- Higher weight = more common drop from that pool
-- ---------------------------------------------------------------------------
Mining.OrePools = {
	copper = {
		{ id = Mining.Items.COPPER_ORE, weight = 100, name = "copper ore", tries = 3 },
	},
	tin = {
		{ id = Mining.Items.TIN_ORE, weight = 100, name = "tin ore", tries = 3 },
	},
	iron = {
		{ id = Mining.Items.IRON_ORE, weight = 100, name = "iron ore", tries = 5 },
	},
	silver = {
		{ id = Mining.Items.SILVER_ORE, weight = 100, name = "silver ore", tries = 8 },
	},
	gold = {
		{ id = Mining.Items.GOLD_ORE, weight = 100, name = "gold ore", tries = 10 },
	},
	coal = {
		{ id = Mining.Items.COAL, weight = 100, name = "coal", tries = 4 },
	},
	mithril = {
		{ id = Mining.Items.MITHRIL_ORE, weight = 100, name = "mithril ore", tries = 15 },
	},
	platinum = {
		{ id = Mining.Items.PLATINUM_ORE, weight = 100, name = "platinum ore", tries = 15 },
	},
	adamantite = {
		{ id = Mining.Items.ADAMANTITE_ORE, weight = 100, name = "adamantite ore", tries = 25 },
	},
	orichalcum = {
		{ id = Mining.Items.ORICHALCUM_ORE, weight = 100, name = "orichalcum ore", tries = 30 },
	},
	painite = {
		{ id = Mining.Items.PAINITE_CRYSTAL, weight = 100, name = "painite crystal shard", tries = 50 },
	},
	-- Mixed pools for variety veins
	mixed_common = {
		{ id = Mining.Items.COPPER_ORE, weight = 40,  name = "copper ore", tries = 3 },
		{ id = Mining.Items.TIN_ORE,    weight = 40,  name = "tin ore",    tries = 3 },
		{ id = Mining.Items.IRON_ORE,   weight = 20,  name = "iron ore",   tries = 5 },
	},
	mixed_uncommon = {
		{ id = Mining.Items.IRON_ORE,   weight = 30,  name = "iron ore",   tries = 5 },
		{ id = Mining.Items.SILVER_ORE, weight = 25,  name = "silver ore", tries = 8 },
		{ id = Mining.Items.GOLD_ORE,   weight = 20,  name = "gold ore",   tries = 10 },
		{ id = Mining.Items.COAL,       weight = 25,  name = "coal",       tries = 4 },
	},
	mixed_rare = {
		{ id = Mining.Items.SILVER_ORE,    weight = 20, name = "silver ore",    tries = 8  },
		{ id = Mining.Items.GOLD_ORE,      weight = 20, name = "gold ore",      tries = 10 },
		{ id = Mining.Items.MITHRIL_ORE,   weight = 30, name = "mithril ore",   tries = 15 },
		{ id = Mining.Items.PLATINUM_ORE,  weight = 30, name = "platinum ore",  tries = 15 },
	},
	mixed_all = {
		{ id = Mining.Items.MITHRIL_ORE,    weight = 25, name = "mithril ore",      tries = 15 },
		{ id = Mining.Items.PLATINUM_ORE,   weight = 20, name = "platinum ore",     tries = 15 },
		{ id = Mining.Items.ADAMANTITE_ORE, weight = 20, name = "adamantite ore",   tries = 25 },
		{ id = Mining.Items.ORICHALCUM_ORE, weight = 15, name = "orichalcum ore",   tries = 30 },
		{ id = Mining.Items.PAINITE_CRYSTAL,weight = 5,  name = "painite crystal shard", tries = 50 },
		{ id = Mining.Items.GOLD_ORE,       weight = 15, name = "gold ore",         tries = 10 },
	},
}

-- ---------------------------------------------------------------------------
-- Pickaxe tiers: better pickaxe = higher success bonus and faster cooldown
-- ---------------------------------------------------------------------------
Mining.Pickaxes = {
	[Mining.Items.BASIC_PICKAXE]   = { name = "basic pickaxe",   bonus = 0,   cooldown = 3000 },
	[Mining.Items.STEEL_PICKAXE]   = { name = "steel pickaxe",   bonus = 10,  cooldown = 2500 },
	[Mining.Items.CRYSTAL_PICKAXE] = { name = "crystal pickaxe", bonus = 25,  cooldown = 2000 },
	[2553]                         = { name = "pick",            bonus = -5,  cooldown = 3500 }, -- vanilla pick as worst tier
}

-- ---------------------------------------------------------------------------
-- Gem bonus table (random chance on any successful mine)
-- ---------------------------------------------------------------------------
Mining.GemDrops = {
	{ id = Mining.Items.SAPPHIRE, chance = 0.5,  name = "a sapphire" },
	{ id = Mining.Items.RUBY,     chance = 0.4,  name = "a ruby" },
	{ id = Mining.Items.EMERALD,  chance = 0.3,  name = "an emerald" },
	{ id = Mining.Items.DIAMOND,  chance = 0.15, name = "a diamond" },
}

-- ---------------------------------------------------------------------------
-- Depleted vein tracking (global, keyed by position string)
-- ---------------------------------------------------------------------------
Mining.DepletedVeins = {}

function Mining.posKey(pos)
	return pos.x .. ":" .. pos.y .. ":" .. pos.z
end

-- ---------------------------------------------------------------------------
-- Weighted random selection from an ore pool
-- ---------------------------------------------------------------------------
function Mining.rollOre(poolName, miningLevel)
	local pool = Mining.OrePools[poolName]
	if not pool then return nil end

	local totalWeight = 0
	for _, entry in ipairs(pool) do
		totalWeight = totalWeight + entry.weight
	end

	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, entry in ipairs(pool) do
		cumulative = cumulative + entry.weight
		if roll <= cumulative then
			return entry
		end
	end
	return pool[#pool] -- fallback
end

-- ---------------------------------------------------------------------------
-- Calculate mining success chance
-- base 50% + 0.5% per mining level + pickaxe bonus, capped at 95%
-- ---------------------------------------------------------------------------
function Mining.getSuccessChance(miningLevel, pickaxeBonus)
	return math.min(95, 50 + (miningLevel * 0.5) + pickaxeBonus)
end

-- ---------------------------------------------------------------------------
-- Respawn a vein after depletion
-- ---------------------------------------------------------------------------
function Mining.respawnVein(posKey)
	Mining.DepletedVeins[posKey] = nil
end

-- ---------------------------------------------------------------------------
-- Smelting Recipes
-- ---------------------------------------------------------------------------
-- Each recipe: {name, ingredients={{id, count},...}, result={id, count},
--               requiredSkill, successBase, triesReward, requireCoal}
Mining.SmeltingRecipes = {
	{
		name = "Copper Bar",
		ingredients = { {Mining.Items.COPPER_ORE, 2} },
		result = { Mining.Items.COPPER_BAR, 1 },
		requiredSkill = 0,
		successBase = 80,
		triesReward = 3,
		requireCoal = false,
	},
	{
		name = "Tin Bar",
		ingredients = { {Mining.Items.TIN_ORE, 2} },
		result = { Mining.Items.TIN_BAR, 1 },
		requiredSkill = 0,
		successBase = 80,
		triesReward = 3,
		requireCoal = false,
	},
	{
		name = "Bronze Bar",
		ingredients = { {Mining.Items.COPPER_ORE, 1}, {Mining.Items.TIN_ORE, 1} },
		result = { Mining.Items.BRONZE_BAR, 1 },
		requiredSkill = 5,
		successBase = 75,
		triesReward = 5,
		requireCoal = false,
	},
	{
		name = "Iron Bar",
		ingredients = { {Mining.Items.IRON_ORE, 2} },
		result = { Mining.Items.IRON_BAR, 1 },
		requiredSkill = 10,
		successBase = 70,
		triesReward = 6,
		requireCoal = true, -- 1 coal
	},
	{
		name = "Steel Bar",
		ingredients = { {Mining.Items.IRON_ORE, 1}, {Mining.Items.COAL, 2} },
		result = { Mining.Items.STEEL_BAR, 1 },
		requiredSkill = 20,
		successBase = 65,
		triesReward = 10,
		requireCoal = false, -- coal already in ingredients
	},
	{
		name = "Silver Bar",
		ingredients = { {Mining.Items.SILVER_ORE, 2} },
		result = { Mining.Items.SILVER_BAR, 1 },
		requiredSkill = 25,
		successBase = 65,
		triesReward = 10,
		requireCoal = true,
	},
	{
		name = "Gold Bar",
		ingredients = { {Mining.Items.GOLD_ORE, 2} },
		result = { Mining.Items.GOLD_BAR, 1 },
		requiredSkill = 30,
		successBase = 60,
		triesReward = 12,
		requireCoal = true,
	},
	{
		name = "Mithril Bar",
		ingredients = { {Mining.Items.MITHRIL_ORE, 3} },
		result = { Mining.Items.MITHRIL_BAR, 1 },
		requiredSkill = 50,
		successBase = 50,
		triesReward = 20,
		requireCoal = true,
	},
	{
		name = "Platinum Bar",
		ingredients = { {Mining.Items.PLATINUM_ORE, 3} },
		result = { Mining.Items.PLATINUM_BAR, 1 },
		requiredSkill = 55,
		successBase = 50,
		triesReward = 20,
		requireCoal = true,
	},
	{
		name = "Adamantite Bar",
		ingredients = { {Mining.Items.ADAMANTITE_ORE, 4} },
		result = { Mining.Items.ADAMANTITE_BAR, 1 },
		requiredSkill = 75,
		successBase = 40,
		triesReward = 35,
		requireCoal = true,
	},
	{
		name = "Orichalcum Bar",
		ingredients = { {Mining.Items.ORICHALCUM_ORE, 4} },
		result = { Mining.Items.ORICHALCUM_BAR, 1 },
		requiredSkill = 80,
		successBase = 35,
		triesReward = 40,
		requireCoal = true,
	},
}

-- ---------------------------------------------------------------------------
-- Furnace item IDs that can be used for smelting (existing TFS furnace IDs)
-- ---------------------------------------------------------------------------
Mining.FurnaceIds = {
	1786, 1787, 1788, 1789,  -- standard furnaces
	1790, 1791, 1792, 1793,  -- oven variants
	30420,                    -- custom crafting furnace from Phase 2
}

function Mining.isFurnace(itemId)
	for _, id in ipairs(Mining.FurnaceIds) do
		if id == itemId then return true end
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Find matching smelting recipe given ingredients the player has
-- ---------------------------------------------------------------------------
function Mining.findSmeltingRecipe(player, miningLevel)
	local matches = {}
	for _, recipe in ipairs(Mining.SmeltingRecipes) do
		if miningLevel >= recipe.requiredSkill then
			local hasAll = true
			for _, ing in ipairs(recipe.ingredients) do
				if player:getItemCount(ing[1]) < ing[2] then
					hasAll = false
					break
				end
			end
			-- Check coal requirement (1 coal extra if requireCoal)
			if hasAll and recipe.requireCoal then
				if player:getItemCount(Mining.Items.COAL) < 1 then
					hasAll = false
				end
			end
			if hasAll then
				table.insert(matches, recipe)
			end
		end
	end
	return matches
end

-- Smelting success chance: successBase + 0.5 per level above required, cap 95%
function Mining.getSmeltingChance(recipe, miningLevel)
	local bonus = math.max(0, miningLevel - recipe.requiredSkill) * 0.5
	return math.min(95, recipe.successBase + bonus)
end
