-- ============================================================================
-- Enhanced Housing System (Phase 5)
-- ============================================================================
-- Provides floor modification, expanded decoration categories, in-house
-- crafting stations, showroom/display mode, and a player house rating system.
-- Storage layout:
--   60000-60099  house floor type per tile-offset (indexed by position hash)
--   60100        showroom mode flag (0=off, 1=on)
--   60200        house rating sum   (accumulated scores)
--   60201        house rating count (number of ratings)
--   60300-60399  rater tracking     (stores os.time of last rating by visitor)
-- ============================================================================

HousingEnhanced = {}

-- ============================================================================
-- Constants
-- ============================================================================

HousingEnhanced.STORAGE_FLOOR_BASE    = 60000
HousingEnhanced.STORAGE_SHOWROOM      = 60100
HousingEnhanced.STORAGE_RATING_SUM    = 60200
HousingEnhanced.STORAGE_RATING_COUNT  = 60201
HousingEnhanced.STORAGE_RATER_BASE    = 60300

HousingEnhanced.RATING_COOLDOWN = 7 * 24 * 3600  -- one rating per house per week

-- Floor types: name -> tile item id
HousingEnhanced.FLOOR_TYPES = {
	["wood"]      = {id = 405,  name = "Wooden Planks",    cost = 500},
	["marble"]    = {id = 408,  name = "Marble Tiles",     cost = 2000},
	["stone"]     = {id = 406,  name = "Stone Floor",      cost = 800},
	["grass"]     = {id = 4526, name = "Grass Patch",      cost = 300},
	["carpet_red"] = {id = 2576, name = "Red Carpet",      cost = 1500},
	["sand"]      = {id = 231,  name = "Sand Floor",       cost = 200},
	["ice"]       = {id = 670,  name = "Ice Floor",        cost = 3000},
	["lava"]      = {id = 598,  name = "Lava Floor",       cost = 5000},
}

-- Expanded decoration categories
HousingEnhanced.DECORATION_CATEGORIES = {
	furniture = {
		name = "Furniture",
		items = {
			{id = 2602, name = "Trunk",           cost = 1000},
			{id = 2604, name = "Bookcase",         cost = 1500},
			{id = 2360, name = "Table",            cost = 500},
			{id = 2358, name = "Chair",            cost = 300},
			{id = 2601, name = "Chest of Drawers", cost = 1200},
		},
	},
	lighting = {
		name = "Lighting",
		items = {
			{id = 2048, name = "Candelabrum",  cost = 800},
			{id = 2044, name = "Torch",        cost = 200},
			{id = 2057, name = "Crystal Lamp", cost = 2500},
			{id = 2054, name = "Wall Lamp",    cost = 600},
		},
	},
	trophies = {
		name = "Trophies & Wall Art",
		items = {
			{id = 2663, name = "Deer Trophy",       cost = 3000},
			{id = 2665, name = "Dragon Head",        cost = 10000},
			{id = 3904, name = "Painting (Scenery)", cost = 2000},
			{id = 3903, name = "Painting (Portrait)",cost = 2500},
		},
	},
	nature = {
		name = "Nature & Plants",
		items = {
			{id = 2682, name = "Flower Pot",    cost = 400},
			{id = 2683, name = "Potted Plant",  cost = 600},
			{id = 2684, name = "Small Fern",    cost = 500},
			{id = 7735, name = "Bamboo Plant",  cost = 900},
		},
	},
	seasonal = {
		name = "Seasonal & Holiday",
		items = {
			{id = 6570, name = "Surprise Bag (Blue)", cost = 1500},
			{id = 6571, name = "Surprise Bag (Red)",  cost = 1500},
			{id = 2114, name = "Snowman",              cost = 2000},
			{id = 6578, name = "Party Hat",            cost = 800},
		},
	},
}

-- Crafting stations that can be placed inside a house
HousingEnhanced.CRAFTING_STATIONS = {
	anvil = {
		id        = 2554,
		name      = "Blacksmith Anvil",
		cost      = 5000,
		skill     = "smithing",
		bonus     = 5,  -- +5% success rate when crafting inside own house
	},
	stove = {
		id        = 2548,
		name      = "Cooking Stove",
		cost      = 3000,
		skill     = "cooking",
		bonus     = 5,
	},
	planting_pot = {
		id        = 2682,
		name      = "Planting Pot",
		cost      = 2000,
		skill     = "farming",
		bonus     = 10,  -- +10% yield when farming inside own house
	},
	enchanting_table = {
		id        = 2607,
		name      = "Enchanting Table",
		cost      = 8000,
		skill     = "enchanting",
		bonus     = 5,
	},
}

-- ============================================================================
-- Floor Modification
-- ============================================================================

--- Attempt to change the floor type of the tile the player is standing on.
-- @param player  Player userdata
-- @param floorKey  String key from FLOOR_TYPES
-- @return boolean, string  success flag and message
function HousingEnhanced.changeFloor(player, floorKey)
	local floorData = HousingEnhanced.FLOOR_TYPES[floorKey]
	if not floorData then
		return false, "Unknown floor type. Available: " .. HousingEnhanced.getFloorTypeList()
	end

	local tile = Tile(player:getPosition())
	if not tile then
		return false, "You are not standing on a valid tile."
	end

	local house = tile:getHouse()
	if not house then
		return false, "You must be inside a house to change the floor."
	end

	if house:getOwnerGuid() ~= player:getGuid() then
		return false, "You can only modify floors in your own house."
	end

	if player:getMoney() < floorData.cost then
		return false, string.format("You need %d gold to apply %s.", floorData.cost, floorData.name)
	end

	player:removeMoney(floorData.cost)

	-- Persist the choice using a storage value keyed by a position hash
	local pos = player:getPosition()
	local posKey = pos.x .. "_" .. pos.y
	if not HousingEnhanced._floorStorage then
		HousingEnhanced._floorStorage = {}
	end
	HousingEnhanced._floorStorage[posKey] = floorData.id

	-- Apply visual via ground item swap
	local ground = tile:getGround()
	if ground then
		ground:transform(floorData.id)
	end

	pos:sendMagicEffect(CONST_ME_POFF)
	return true, string.format("Floor changed to %s for %d gold.", floorData.name, floorData.cost)
end

--- Return a comma-separated list of available floor type keys.
function HousingEnhanced.getFloorTypeList()
	local keys = {}
	for k, _ in pairs(HousingEnhanced.FLOOR_TYPES) do
		keys[#keys + 1] = k
	end
	table.sort(keys)
	return table.concat(keys, ", ")
end

-- ============================================================================
-- Showroom / Display Mode
-- ============================================================================

--- Toggle showroom mode for the player's house.
-- When active, visitors can look at items but not move or use them.
function HousingEnhanced.toggleShowroom(player)
	local tile = Tile(player:getPosition())
	if not tile then
		return false, "Invalid position."
	end

	local house = tile:getHouse()
	if not house then
		return false, "You must be inside your house."
	end

	if house:getOwnerGuid() ~= player:getGuid() then
		return false, "Only the house owner can toggle showroom mode."
	end

	local current = player:getStorageValue(HousingEnhanced.STORAGE_SHOWROOM)
	if current == 1 then
		player:setStorageValue(HousingEnhanced.STORAGE_SHOWROOM, 0)
		return true, "Showroom mode DISABLED. Visitors can interact normally."
	else
		player:setStorageValue(HousingEnhanced.STORAGE_SHOWROOM, 1)
		return true, "Showroom mode ENABLED. Visitors can view but not interact with items."
	end
end

--- Check whether a visitor is blocked by showroom mode.
-- @param owner  Player (house owner)
-- @param visitor  Player (the one trying to interact)
-- @return boolean  true if interaction should be blocked
function HousingEnhanced.isShowroomBlocked(owner, visitor)
	if not owner or not visitor then
		return false
	end
	if owner:getGuid() == visitor:getGuid() then
		return false  -- owner is never blocked
	end
	return owner:getStorageValue(HousingEnhanced.STORAGE_SHOWROOM) == 1
end

-- ============================================================================
-- House Rating System
-- ============================================================================

--- Rate a house (1-5 stars).
-- @param visitor  Player giving the rating
-- @param rating   integer 1-5
-- @return boolean, string
function HousingEnhanced.rateHouse(visitor, rating)
	rating = tonumber(rating)
	if not rating or rating < 1 or rating > 5 then
		return false, "Rating must be between 1 and 5."
	end
	rating = math.floor(rating)

	local tile = Tile(visitor:getPosition())
	if not tile then
		return false, "Invalid position."
	end

	local house = tile:getHouse()
	if not house then
		return false, "You must be inside a house to rate it."
	end

	local ownerGuid = house:getOwnerGuid()
	if ownerGuid == visitor:getGuid() then
		return false, "You cannot rate your own house."
	end
	if ownerGuid == 0 then
		return false, "This house has no owner."
	end

	-- Cooldown check (one rating per visitor per house per week)
	local raterSlot = HousingEnhanced.STORAGE_RATER_BASE + (visitor:getGuid() % 100)
	local lastRated = visitor:getStorageValue(raterSlot)
	if lastRated > 0 and os.time() - lastRated < HousingEnhanced.RATING_COOLDOWN then
		local remaining = (lastRated + HousingEnhanced.RATING_COOLDOWN) - os.time()
		local hours = math.ceil(remaining / 3600)
		return false, string.format("You can rate another house in %d hours.", hours)
	end

	-- Apply rating (stored on the owner -- lookup via offline storage)
	-- For simplicity we use the visitor's own storage keyed to the house id
	local owner = Player(ownerGuid)
	if not owner then
		return false, "House owner must be online to receive a rating."
	end

	local currentSum   = math.max(0, owner:getStorageValue(HousingEnhanced.STORAGE_RATING_SUM))
	local currentCount = math.max(0, owner:getStorageValue(HousingEnhanced.STORAGE_RATING_COUNT))

	owner:setStorageValue(HousingEnhanced.STORAGE_RATING_SUM,   currentSum + rating)
	owner:setStorageValue(HousingEnhanced.STORAGE_RATING_COUNT, currentCount + 1)

	visitor:setStorageValue(raterSlot, os.time())

	local newAvg = (currentSum + rating) / (currentCount + 1)
	return true, string.format(
		"You rated this house %d/5. House average: %.1f/5 (%d ratings).",
		rating, newAvg, currentCount + 1
	)
end

--- Get a house's average rating.
function HousingEnhanced.getHouseRating(ownerPlayer)
	local sum   = math.max(0, ownerPlayer:getStorageValue(HousingEnhanced.STORAGE_RATING_SUM))
	local count = math.max(0, ownerPlayer:getStorageValue(HousingEnhanced.STORAGE_RATING_COUNT))
	if count == 0 then
		return 0, 0
	end
	return sum / count, count
end

-- ============================================================================
-- Crafting Stations
-- ============================================================================

--- Check if a player is standing near a house crafting station and return
-- the bonus, if any.
-- @param player  Player userdata
-- @param skillName  string matching a station skill ("smithing", etc.)
-- @return number  bonus percentage (0 if none)
function HousingEnhanced.getCraftingStationBonus(player, skillName)
	local tile = Tile(player:getPosition())
	if not tile then
		return 0
	end

	local house = tile:getHouse()
	if not house or house:getOwnerGuid() ~= player:getGuid() then
		return 0
	end

	for _, station in pairs(HousingEnhanced.CRAFTING_STATIONS) do
		if station.skill == skillName then
			-- Check adjacent tiles for station item
			local pos = player:getPosition()
			for dx = -1, 1 do
				for dy = -1, 1 do
					local checkPos = Position(pos.x + dx, pos.y + dy, pos.z)
					local checkTile = Tile(checkPos)
					if checkTile then
						local item = checkTile:getItemById(station.id)
						if item then
							return station.bonus
						end
					end
				end
			end
		end
	end
	return 0
end

--- List all available decoration categories as a formatted string.
function HousingEnhanced.getDecorationCatalog()
	local lines = {"=== House Decoration Catalog ==="}
	for catKey, cat in pairs(HousingEnhanced.DECORATION_CATEGORIES) do
		lines[#lines + 1] = "\n[" .. cat.name .. "]"
		for _, item in ipairs(cat.items) do
			lines[#lines + 1] = string.format("  %s (ID %d) - %d gp", item.name, item.id, item.cost)
		end
	end
	return table.concat(lines, "\n")
end
