-- ============================================================================
-- Farming System Library - Phase 2.2
-- ============================================================================
-- Defines seed types, crop definitions, growth stages, yield calculations,
-- and seasonal/location modifiers for the farming crafting system.
-- Uses player storage values to track farming skill (Crafting.SKILL_FARMING).
-- ============================================================================

Farming = {}

-- ---------------------------------------------------------------------------
-- Storage Keys
-- ---------------------------------------------------------------------------
Farming.Storage = {
	skillLevel   = 45200, -- current farming skill level (0-100)
	skillTries   = 45201, -- accumulated skill tries toward next level
	lastFarmTime = 45202, -- anti-spam cooldown timestamp
}

-- Skill tries needed per level (exponential curve, base 30, multiplier 1.1)
function Farming.getTriesForLevel(level)
	if level <= 0 then return 0 end
	return math.floor(30 * (1.1 ^ (level - 1)))
end

function Farming.getSkillLevel(player)
	return math.max(0, player:getStorageValue(Farming.Storage.skillLevel))
end

function Farming.getSkillTries(player)
	return math.max(0, player:getStorageValue(Farming.Storage.skillTries))
end

function Farming.addSkillTries(player, tries)
	local currentLevel = Farming.getSkillLevel(player)
	local currentTries = Farming.getSkillTries(player) + tries

	-- Level up loop
	while currentLevel < 100 do
		local needed = Farming.getTriesForLevel(currentLevel + 1)
		if currentTries >= needed then
			currentTries = currentTries - needed
			currentLevel = currentLevel + 1
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
				"You advanced to farming level " .. currentLevel .. ".")
			player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
		else
			break
		end
	end

	player:setStorageValue(Farming.Storage.skillLevel, currentLevel)
	player:setStorageValue(Farming.Storage.skillTries, currentTries)
end

-- ---------------------------------------------------------------------------
-- Item IDs (from Phase 2 allocation: 30100-30199)
-- ---------------------------------------------------------------------------
Farming.Items = {
	-- Seeds (30100-30119)
	WHEAT_SEEDS      = 30100,
	CORN_SEEDS       = 30101,
	POTATO_SEEDS     = 30102,
	CARROT_SEEDS     = 30103,
	TOMATO_SEEDS     = 30104,
	ONION_SEEDS      = 30105,
	GARLIC_SEEDS     = 30106,
	LETTUCE_SEEDS    = 30107,
	PUMPKIN_SEEDS    = 30108,
	BASIL_SEEDS      = 30109,
	THYME_SEEDS      = 30110,
	ROSEMARY_SEEDS   = 30111,
	BERRY_SEEDS      = 30112,
	GRAPE_SEEDS      = 30113,
	HERB_SEEDS       = 30114,  -- generic herb seeds (yields Fresh Herbs)
	MANDRAKE_SEEDS   = 30115,
	STARFLOWER_SEEDS = 30116,

	-- Harvested Crops (30140-30169)
	WHEAT_BUNDLE     = 30140,
	CORN             = 30141,
	POTATO           = 30142,
	CARROT           = 30143,
	TOMATO           = 30144,
	ONION            = 30145,
	GARLIC           = 30146,
	LETTUCE          = 30147,
	PUMPKIN          = 30148,
	BASIL            = 30149,
	THYME            = 30150,
	ROSEMARY         = 30151,
	MIXED_BERRIES    = 30152,
	GRAPES           = 30153,
	FRESH_HERBS      = 30154,
	MANDRAKE_ROOT    = 30155,
	STARFLOWER       = 30156,

	-- Tools
	WATERING_CAN     = 30120,
	GARDEN_HOE       = 30121,

	-- Stations / Plots
	PLANTING_POT     = 30130,  -- house item
	FARM_PLOT_EMPTY  = 30131,  -- public farm plot (empty)
	FARM_PLOT_PLANTED = 30132, -- plot with seeds
	FARM_PLOT_SPROUT  = 30133, -- plot with sprout
	FARM_PLOT_GROWING = 30134, -- plot with growing plant
	FARM_PLOT_READY   = 30135, -- plot with harvestable crop

	-- Water containers that can water crops
	WATER_FLASK      = 30256,  -- from cooking supplies
}

-- ---------------------------------------------------------------------------
-- Growth Stages
-- ---------------------------------------------------------------------------
Farming.STAGE_EMPTY     = 0
Farming.STAGE_PLANTED   = 1
Farming.STAGE_SPROUTING = 2
Farming.STAGE_GROWING   = 3
Farming.STAGE_READY     = 4

Farming.STAGE_NAMES = {
	[0] = "empty",
	[1] = "planted",
	[2] = "sprouting",
	[3] = "growing",
	[4] = "ready to harvest",
}

-- ---------------------------------------------------------------------------
-- Rarity tiers and growth timers (in seconds)
-- ---------------------------------------------------------------------------
Farming.RARITY_COMMON   = 1
Farming.RARITY_UNCOMMON = 2
Farming.RARITY_RARE     = 3

Farming.GROWTH_TIMES = {
	[1] = 30 * 60,   -- common: 30 minutes per stage
	[2] = 60 * 60,   -- uncommon: 60 minutes per stage
	[3] = 120 * 60,  -- rare: 120 minutes per stage
}

Farming.RARITY_NAMES = {
	[1] = "common",
	[2] = "uncommon",
	[3] = "rare",
}

-- ---------------------------------------------------------------------------
-- Seed Definitions (17 crops total)
-- ---------------------------------------------------------------------------
-- Each seed defines: seedId, cropId, name, rarity, minSkill, baseYield,
-- skillTries awarded on harvest.
Farming.Seeds = {
	-- ===== Common Crops (Rarity 1, 30 min per stage) =====
	[Farming.Items.WHEAT_SEEDS] = {
		name        = "Wheat",
		seedId      = Farming.Items.WHEAT_SEEDS,
		cropId      = Farming.Items.WHEAT_BUNDLE,
		rarity      = Farming.RARITY_COMMON,
		minSkill    = 0,
		baseYield   = 3,
		skillTries  = 3,
	},
	[Farming.Items.CORN_SEEDS] = {
		name        = "Corn",
		seedId      = Farming.Items.CORN_SEEDS,
		cropId      = Farming.Items.CORN,
		rarity      = Farming.RARITY_COMMON,
		minSkill    = 0,
		baseYield   = 2,
		skillTries  = 3,
	},
	[Farming.Items.POTATO_SEEDS] = {
		name        = "Potato",
		seedId      = Farming.Items.POTATO_SEEDS,
		cropId      = Farming.Items.POTATO,
		rarity      = Farming.RARITY_COMMON,
		minSkill    = 0,
		baseYield   = 3,
		skillTries  = 3,
	},
	[Farming.Items.CARROT_SEEDS] = {
		name        = "Carrot",
		seedId      = Farming.Items.CARROT_SEEDS,
		cropId      = Farming.Items.CARROT,
		rarity      = Farming.RARITY_COMMON,
		minSkill    = 5,
		baseYield   = 3,
		skillTries  = 4,
	},
	[Farming.Items.TOMATO_SEEDS] = {
		name        = "Tomato",
		seedId      = Farming.Items.TOMATO_SEEDS,
		cropId      = Farming.Items.TOMATO,
		rarity      = Farming.RARITY_COMMON,
		minSkill    = 5,
		baseYield   = 2,
		skillTries  = 4,
	},
	[Farming.Items.ONION_SEEDS] = {
		name        = "Onion",
		seedId      = Farming.Items.ONION_SEEDS,
		cropId      = Farming.Items.ONION,
		rarity      = Farming.RARITY_COMMON,
		minSkill    = 8,
		baseYield   = 3,
		skillTries  = 4,
	},
	[Farming.Items.GARLIC_SEEDS] = {
		name        = "Garlic",
		seedId      = Farming.Items.GARLIC_SEEDS,
		cropId      = Farming.Items.GARLIC,
		rarity      = Farming.RARITY_COMMON,
		minSkill    = 10,
		baseYield   = 2,
		skillTries  = 5,
	},
	[Farming.Items.LETTUCE_SEEDS] = {
		name        = "Lettuce",
		seedId      = Farming.Items.LETTUCE_SEEDS,
		cropId      = Farming.Items.LETTUCE,
		rarity      = Farming.RARITY_COMMON,
		minSkill    = 5,
		baseYield   = 2,
		skillTries  = 4,
	},

	-- ===== Uncommon Crops (Rarity 2, 60 min per stage) =====
	[Farming.Items.PUMPKIN_SEEDS] = {
		name        = "Pumpkin",
		seedId      = Farming.Items.PUMPKIN_SEEDS,
		cropId      = Farming.Items.PUMPKIN,
		rarity      = Farming.RARITY_UNCOMMON,
		minSkill    = 15,
		baseYield   = 1,
		skillTries  = 8,
	},
	[Farming.Items.BASIL_SEEDS] = {
		name        = "Basil",
		seedId      = Farming.Items.BASIL_SEEDS,
		cropId      = Farming.Items.BASIL,
		rarity      = Farming.RARITY_UNCOMMON,
		minSkill    = 20,
		baseYield   = 2,
		skillTries  = 10,
	},
	[Farming.Items.THYME_SEEDS] = {
		name        = "Thyme",
		seedId      = Farming.Items.THYME_SEEDS,
		cropId      = Farming.Items.THYME,
		rarity      = Farming.RARITY_UNCOMMON,
		minSkill    = 25,
		baseYield   = 2,
		skillTries  = 10,
	},
	[Farming.Items.ROSEMARY_SEEDS] = {
		name        = "Rosemary",
		seedId      = Farming.Items.ROSEMARY_SEEDS,
		cropId      = Farming.Items.ROSEMARY,
		rarity      = Farming.RARITY_UNCOMMON,
		minSkill    = 25,
		baseYield   = 2,
		skillTries  = 10,
	},
	[Farming.Items.BERRY_SEEDS] = {
		name        = "Mixed Berries",
		seedId      = Farming.Items.BERRY_SEEDS,
		cropId      = Farming.Items.MIXED_BERRIES,
		rarity      = Farming.RARITY_UNCOMMON,
		minSkill    = 15,
		baseYield   = 3,
		skillTries  = 8,
	},
	[Farming.Items.GRAPE_SEEDS] = {
		name        = "Grapes",
		seedId      = Farming.Items.GRAPE_SEEDS,
		cropId      = Farming.Items.GRAPES,
		rarity      = Farming.RARITY_UNCOMMON,
		minSkill    = 20,
		baseYield   = 2,
		skillTries  = 10,
	},
	[Farming.Items.HERB_SEEDS] = {
		name        = "Fresh Herbs",
		seedId      = Farming.Items.HERB_SEEDS,
		cropId      = Farming.Items.FRESH_HERBS,
		rarity      = Farming.RARITY_UNCOMMON,
		minSkill    = 15,
		baseYield   = 2,
		skillTries  = 8,
	},

	-- ===== Rare Crops (Rarity 3, 120 min per stage) =====
	[Farming.Items.MANDRAKE_SEEDS] = {
		name        = "Mandrake Root",
		seedId      = Farming.Items.MANDRAKE_SEEDS,
		cropId      = Farming.Items.MANDRAKE_ROOT,
		rarity      = Farming.RARITY_RARE,
		minSkill    = 50,
		baseYield   = 1,
		skillTries  = 25,
	},
	[Farming.Items.STARFLOWER_SEEDS] = {
		name        = "Starflower",
		seedId      = Farming.Items.STARFLOWER_SEEDS,
		cropId      = Farming.Items.STARFLOWER,
		rarity      = Farming.RARITY_RARE,
		minSkill    = 60,
		baseYield   = 1,
		skillTries  = 35,
	},
}

-- Build a quick lookup: is this item ID a seed?
Farming.SeedIds = {}
for seedId, _ in pairs(Farming.Seeds) do
	Farming.SeedIds[seedId] = true
end

function Farming.isSeed(itemId)
	return Farming.SeedIds[itemId] == true
end

-- ---------------------------------------------------------------------------
-- Plot / Pot identification
-- ---------------------------------------------------------------------------
-- Action IDs used on map tiles to mark them as farm plots
Farming.PLOT_ACTIONID = 9200   -- map builders assign this to usable farm plots

-- Items that act as plantable surfaces
Farming.PlantableItems = {
	[Farming.Items.PLANTING_POT]     = true,
	[Farming.Items.FARM_PLOT_EMPTY]  = true,
}

-- Items that represent growth stages (for visual transforms)
Farming.StageItems = {
	[Farming.STAGE_PLANTED]   = Farming.Items.FARM_PLOT_PLANTED,
	[Farming.STAGE_SPROUTING] = Farming.Items.FARM_PLOT_SPROUT,
	[Farming.STAGE_GROWING]   = Farming.Items.FARM_PLOT_GROWING,
	[Farming.STAGE_READY]     = Farming.Items.FARM_PLOT_READY,
}

function Farming.isPlantable(item)
	local itemId = item:getId()
	if Farming.PlantableItems[itemId] then
		return true
	end
	-- Also allow map tiles with the farm plot action ID
	if item:getActionId() == Farming.PLOT_ACTIONID then
		return true
	end
	return false
end

function Farming.isPlotOccupied(item)
	local stage = item:getCustomAttribute("farm_stage") or 0
	return stage > 0
end

-- ---------------------------------------------------------------------------
-- Water containers that can water crops
-- ---------------------------------------------------------------------------
Farming.WaterContainers = {
	[Farming.Items.WATERING_CAN] = true,
	[Farming.Items.WATER_FLASK]  = true,
	[2005] = true,  -- vial of water (fluid container with water subtype)
	[2006] = true,  -- water container variant
	[2007] = true,  -- water container variant
	[2008] = true,  -- water container variant
	[2009] = true,  -- water container variant
}

function Farming.isWaterContainer(itemId)
	return Farming.WaterContainers[itemId] == true
end

-- ---------------------------------------------------------------------------
-- Growth Time Calculation
-- ---------------------------------------------------------------------------
-- Returns the time in seconds for one growth stage transition.
-- @param seed      table   seed definition
-- @param watered   boolean whether the crop has been watered
-- @return number   seconds until next stage
function Farming.getGrowthTime(seed, watered)
	local baseTime = Farming.GROWTH_TIMES[seed.rarity] or Farming.GROWTH_TIMES[1]
	if watered then
		-- Watered crops grow 25% faster
		baseTime = math.floor(baseTime * 0.75)
	end
	return baseTime
end

-- ---------------------------------------------------------------------------
-- Yield Calculation
-- ---------------------------------------------------------------------------
-- Calculates the number of crops yielded on harvest.
-- @param seed        table   seed definition
-- @param farmLevel   number  player's farming skill level
-- @param watered     boolean whether the crop was watered
-- @return number     final yield count
function Farming.calculateYield(seed, farmLevel, watered)
	local yield = seed.baseYield

	-- Watered bonus: +50% yield (rounded up)
	if watered then
		yield = math.ceil(yield * 1.5)
	end

	-- Skill bonus: +1 yield per 20 skill levels above minimum
	local bonusLevels = math.max(0, farmLevel - seed.minSkill)
	local skillBonus = math.floor(bonusLevels / 20)
	yield = yield + skillBonus

	-- Cap yield at baseYield * 3
	yield = math.min(yield, seed.baseYield * 3)

	return math.max(1, yield)
end

-- ---------------------------------------------------------------------------
-- Season Modifiers
-- ---------------------------------------------------------------------------
-- Optional seasonal effects. Seasons are determined by real-world month
-- or can be overridden by server config.
Farming.Seasons = {
	SPRING = 1,
	SUMMER = 2,
	AUTUMN = 3,
	WINTER = 4,
}

-- Map real months to seasons
Farming.MonthToSeason = {
	[1]  = Farming.Seasons.WINTER,
	[2]  = Farming.Seasons.WINTER,
	[3]  = Farming.Seasons.SPRING,
	[4]  = Farming.Seasons.SPRING,
	[5]  = Farming.Seasons.SPRING,
	[6]  = Farming.Seasons.SUMMER,
	[7]  = Farming.Seasons.SUMMER,
	[8]  = Farming.Seasons.SUMMER,
	[9]  = Farming.Seasons.AUTUMN,
	[10] = Farming.Seasons.AUTUMN,
	[11] = Farming.Seasons.AUTUMN,
	[12] = Farming.Seasons.WINTER,
}

function Farming.getCurrentSeason()
	local month = tonumber(os.date("%m"))
	return Farming.MonthToSeason[month] or Farming.Seasons.SPRING
end

-- Season yield multipliers: crops grow best in certain seasons
Farming.SeasonMultipliers = {
	[Farming.Seasons.SPRING] = 1.25,  -- +25% yield in spring
	[Farming.Seasons.SUMMER] = 1.0,   -- normal in summer
	[Farming.Seasons.AUTUMN] = 1.10,  -- +10% yield in autumn (harvest season)
	[Farming.Seasons.WINTER] = 0.75,  -- -25% yield in winter
}

-- Season growth speed multipliers (affects time between stages)
Farming.SeasonGrowthSpeed = {
	[Farming.Seasons.SPRING] = 0.85,  -- 15% faster growth in spring
	[Farming.Seasons.SUMMER] = 1.0,   -- normal in summer
	[Farming.Seasons.AUTUMN] = 1.10,  -- 10% slower in autumn
	[Farming.Seasons.WINTER] = 1.50,  -- 50% slower in winter
}

-- Apply season modifier to yield
function Farming.applySeasonYield(baseYield)
	local season = Farming.getCurrentSeason()
	local mult = Farming.SeasonMultipliers[season] or 1.0
	return math.max(1, math.floor(baseYield * mult))
end

-- Apply season modifier to growth time
function Farming.applySeasonGrowthTime(baseTime)
	local season = Farming.getCurrentSeason()
	local mult = Farming.SeasonGrowthSpeed[season] or 1.0
	return math.floor(baseTime * mult)
end

-- ---------------------------------------------------------------------------
-- Location Modifiers
-- ---------------------------------------------------------------------------
-- Farm plots can have special action ID sub-ranges for bonus locations.
-- ActionID 9201 = fertile soil (+25% yield)
-- ActionID 9202 = greenhouse (+50% growth speed)
-- ActionID 9203 = magical garden (+25% yield, +25% growth speed, rare seed bonus)

Farming.LOCATION_FERTILE    = 9201
Farming.LOCATION_GREENHOUSE = 9202
Farming.LOCATION_MAGICAL    = 9203

Farming.LocationBonuses = {
	[Farming.LOCATION_FERTILE] = {
		name = "Fertile Soil",
		yieldMultiplier = 1.25,
		growthMultiplier = 1.0,
	},
	[Farming.LOCATION_GREENHOUSE] = {
		name = "Greenhouse",
		yieldMultiplier = 1.0,
		growthMultiplier = 0.5,  -- 50% faster
	},
	[Farming.LOCATION_MAGICAL] = {
		name = "Magical Garden",
		yieldMultiplier = 1.25,
		growthMultiplier = 0.75, -- 25% faster
	},
}

function Farming.getLocationBonus(actionId)
	return Farming.LocationBonuses[actionId]
end

-- ---------------------------------------------------------------------------
-- Growth Stage Advancement (called by addEvent timer)
-- ---------------------------------------------------------------------------
-- Advances a crop at a given position to its next growth stage.
-- Uses item custom attributes to track crop state.

function Farming.advanceGrowth(posTable)
	local pos = Position(posTable.x, posTable.y, posTable.z)
	local tile = Tile(pos)
	if not tile then return end

	-- Find the plot item at this position
	local plotItem = nil
	for _, item in ipairs(tile:getItems() or {}) do
		local stage = item:getCustomAttribute("farm_stage")
		if stage and stage > 0 and stage < Farming.STAGE_READY then
			plotItem = item
			break
		end
	end

	if not plotItem then return end

	local currentStage = plotItem:getCustomAttribute("farm_stage") or 0
	if currentStage >= Farming.STAGE_READY then return end

	local newStage = currentStage + 1
	plotItem:setCustomAttribute("farm_stage", newStage)
	plotItem:setCustomAttribute("farm_stage_time", os.time())

	-- Transform the item to the appropriate visual stage
	local stageItemId = Farming.StageItems[newStage]
	if stageItemId then
		plotItem:transform(stageItemId)
	end

	-- If not yet ready, schedule the next growth stage
	if newStage < Farming.STAGE_READY then
		local seedId = plotItem:getCustomAttribute("farm_seed_id")
		local seed = Farming.Seeds[seedId]
		if seed then
			local watered = (plotItem:getCustomAttribute("farm_watered") or 0) == 1
			local growthTime = Farming.getGrowthTime(seed, watered)
			growthTime = Farming.applySeasonGrowthTime(growthTime)

			-- Apply location modifier
			local locActionId = plotItem:getCustomAttribute("farm_location_aid") or 0
			local locBonus = Farming.getLocationBonus(locActionId)
			if locBonus then
				growthTime = math.floor(growthTime * locBonus.growthMultiplier)
			end

			addEvent(Farming.advanceGrowth, growthTime * 1000, {x = pos.x, y = pos.y, z = pos.z})
		end
	else
		-- Crop is ready: send notification effect
		pos:sendMagicEffect(CONST_ME_MAGIC_GREEN)
	end
end

-- ---------------------------------------------------------------------------
-- Active Plots Tracking (global, keyed by position string)
-- ---------------------------------------------------------------------------
Farming.ActivePlots = {}

function Farming.posKey(pos)
	return pos.x .. ":" .. pos.y .. ":" .. pos.z
end

-- ---------------------------------------------------------------------------
-- Planting Success Chance
-- ---------------------------------------------------------------------------
-- Base 70% + 0.5% per farming level, capped at 98%
function Farming.getPlantingChance(farmLevel, seedRarity)
	local base = 70
	if seedRarity == Farming.RARITY_UNCOMMON then
		base = 60
	elseif seedRarity == Farming.RARITY_RARE then
		base = 45
	end
	return math.min(98, base + (farmLevel * 0.5))
end

-- ---------------------------------------------------------------------------
-- Harvest Success Chance
-- ---------------------------------------------------------------------------
-- Always succeeds if the crop reached STAGE_READY, but farming level
-- influences bonus yield.
function Farming.getHarvestBonusChance(farmLevel, minSkill)
	local bonus = math.max(0, farmLevel - minSkill)
	return math.min(50, bonus * 1.0)  -- up to 50% chance for bonus harvest
end
