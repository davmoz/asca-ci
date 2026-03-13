-- Item Random Attributes System (Phase 3)
-- Generates random attribute bonuses on equipment dropped by monsters

ItemAttributes = {}

-- ============================================================
-- Attribute Pools by Equipment Category
-- ============================================================
-- weight = relative probability of being selected

ItemAttributes.pool = {
	weapons = {
		{id = "attack", name = "Attack", min = 1, max = 5, weight = 30, suffix = ""},
		{id = "defense", name = "Defense", min = 1, max = 5, weight = 15, suffix = ""},
		{id = "critical", name = "Critical Hit", min = 1, max = 8, weight = 20, suffix = "%"},
		{id = "berserk", name = "Berserk", min = 1, max = 5, weight = 10, suffix = "%"},
		{id = "gauge", name = "Gauge", min = 1, max = 5, weight = 10, suffix = "%"},
		{id = "crushing", name = "Crushing Blow", min = 1, max = 5, weight = 8, suffix = "%"},
		{id = "dazing", name = "Dazing Blow", min = 1, max = 3, weight = 7, suffix = "%"},
		{id = "lifesteal", name = "Life Leech", min = 1, max = 5, weight = 10, suffix = "%"},
		{id = "manasteal", name = "Mana Leech", min = 1, max = 5, weight = 8, suffix = "%"},
	},
	armor = {
		{id = "defense", name = "Defense", min = 1, max = 5, weight = 25, suffix = ""},
		{id = "armor", name = "Armor", min = 1, max = 5, weight = 25, suffix = ""},
		{id = "fortitude", name = "HP", min = 10, max = 100, weight = 20, suffix = ""},
		{id = "wisdom", name = "Mana", min = 10, max = 100, weight = 15, suffix = ""},
		{id = "resist_fire", name = "Fire Resist", min = 1, max = 5, weight = 5, suffix = "%"},
		{id = "resist_ice", name = "Ice Resist", min = 1, max = 5, weight = 5, suffix = "%"},
		{id = "resist_energy", name = "Energy Resist", min = 1, max = 5, weight = 5, suffix = "%"},
		{id = "resist_earth", name = "Earth Resist", min = 1, max = 5, weight = 5, suffix = "%"},
	},
	shields = {
		{id = "defense", name = "Defense", min = 1, max = 5, weight = 40, suffix = ""},
		{id = "armor", name = "Armor", min = 1, max = 3, weight = 25, suffix = ""},
		{id = "fortitude", name = "HP", min = 10, max = 50, weight = 20, suffix = ""},
		{id = "resist_fire", name = "Fire Resist", min = 1, max = 5, weight = 5, suffix = "%"},
		{id = "resist_ice", name = "Ice Resist", min = 1, max = 5, weight = 5, suffix = "%"},
		{id = "resist_energy", name = "Energy Resist", min = 1, max = 5, weight = 5, suffix = "%"},
		{id = "resist_earth", name = "Earth Resist", min = 1, max = 5, weight = 5, suffix = "%"},
	},
	helmets = {
		{id = "armor", name = "Armor", min = 1, max = 3, weight = 30, suffix = ""},
		{id = "fortitude", name = "HP", min = 10, max = 60, weight = 25, suffix = ""},
		{id = "wisdom", name = "Mana", min = 10, max = 60, weight = 25, suffix = ""},
		{id = "resist_fire", name = "Fire Resist", min = 1, max = 3, weight = 5, suffix = "%"},
		{id = "resist_ice", name = "Ice Resist", min = 1, max = 3, weight = 5, suffix = "%"},
		{id = "resist_energy", name = "Energy Resist", min = 1, max = 3, weight = 5, suffix = "%"},
		{id = "resist_earth", name = "Earth Resist", min = 1, max = 3, weight = 5, suffix = "%"},
	},
	boots = {
		{id = "lean", name = "Speed", min = 5, max = 20, weight = 40, suffix = ""},
		{id = "armor", name = "Armor", min = 1, max = 2, weight = 25, suffix = ""},
		{id = "fortitude", name = "HP", min = 10, max = 40, weight = 15, suffix = ""},
		{id = "resist_fire", name = "Fire Resist", min = 1, max = 3, weight = 10, suffix = "%"},
		{id = "resist_ice", name = "Ice Resist", min = 1, max = 3, weight = 10, suffix = "%"},
	},
}

-- ============================================================
-- Rarity Tiers
-- ============================================================
-- Common:   1 attribute, normal value range
-- Uncommon: 2 attributes, normal value range
-- Rare:     3 attributes, normal value range
-- Epic:     3 attributes, values scaled toward upper range

ItemAttributes.RARITY_COMMON   = 1
ItemAttributes.RARITY_UNCOMMON = 2
ItemAttributes.RARITY_RARE     = 3
ItemAttributes.RARITY_EPIC     = 4

ItemAttributes.rarityNames = {
	[1] = "Common",
	[2] = "Uncommon",
	[3] = "Rare",
	[4] = "Epic",
}

ItemAttributes.rarityColors = {
	[1] = "",           -- no prefix
	[2] = "uncommon ",  -- green-tier
	[3] = "rare ",      -- blue-tier
	[4] = "epic ",      -- purple-tier
}

-- ============================================================
-- Determine rarity from monster difficulty
-- ============================================================
-- monsterLevel: approximate creature level (maxHealth / 10)
-- Returns rarity tier constant
function ItemAttributes.rollRarity(monsterLevel)
	local roll = math.random(1, 1000)

	if monsterLevel >= 200 then
		if roll <= 50 then return ItemAttributes.RARITY_EPIC end      -- 5%
		if roll <= 200 then return ItemAttributes.RARITY_RARE end     -- 15%
		if roll <= 500 then return ItemAttributes.RARITY_UNCOMMON end -- 30%
		if roll <= 800 then return ItemAttributes.RARITY_COMMON end   -- 30%
		return 0                                                       -- 20% nothing
	elseif monsterLevel >= 100 then
		if roll <= 20 then return ItemAttributes.RARITY_EPIC end      -- 2%
		if roll <= 100 then return ItemAttributes.RARITY_RARE end     -- 8%
		if roll <= 350 then return ItemAttributes.RARITY_UNCOMMON end -- 25%
		if roll <= 700 then return ItemAttributes.RARITY_COMMON end   -- 35%
		return 0                                                       -- 30% nothing
	elseif monsterLevel >= 50 then
		if roll <= 5 then return ItemAttributes.RARITY_EPIC end       -- 0.5%
		if roll <= 30 then return ItemAttributes.RARITY_RARE end      -- 2.5%
		if roll <= 150 then return ItemAttributes.RARITY_UNCOMMON end -- 12%
		if roll <= 500 then return ItemAttributes.RARITY_COMMON end   -- 35%
		return 0                                                       -- 50% nothing
	else
		if roll <= 10 then return ItemAttributes.RARITY_RARE end      -- 1%
		if roll <= 60 then return ItemAttributes.RARITY_UNCOMMON end  -- 5%
		if roll <= 250 then return ItemAttributes.RARITY_COMMON end   -- 19%
		return 0                                                       -- 75% nothing
	end
end

-- ============================================================
-- Get attribute count from rarity
-- ============================================================
function ItemAttributes.getAttributeCount(rarity)
	if rarity == ItemAttributes.RARITY_COMMON then return 1 end
	if rarity == ItemAttributes.RARITY_UNCOMMON then return 2 end
	if rarity == ItemAttributes.RARITY_RARE then return 3 end
	if rarity == ItemAttributes.RARITY_EPIC then return 3 end
	return 0
end

-- ============================================================
-- Determine pool category for an item
-- ============================================================
function ItemAttributes.getPoolForItem(item)
	local it = ItemType(item:getId())
	if not it then return nil end

	local weaponType = it:getWeaponType()

	-- Weapons (swords, axes, clubs, distance, wands)
	if weaponType == WEAPON_SWORD or weaponType == WEAPON_AXE or
	   weaponType == WEAPON_CLUB or weaponType == WEAPON_DISTANCE or
	   weaponType == WEAPON_WAND then
		return ItemAttributes.pool.weapons
	end

	-- Shields
	if weaponType == WEAPON_SHIELD then
		return ItemAttributes.pool.shields
	end

	-- Determine slot-based category from slot position
	local slotPos = it:getSlotPosition()

	-- Check for boots (feet slot)
	if bit.band(slotPos, SLOTP_FEET) ~= 0 then
		return ItemAttributes.pool.boots
	end

	-- Check for helmets (head slot)
	if bit.band(slotPos, SLOTP_HEAD) ~= 0 then
		return ItemAttributes.pool.helmets
	end

	-- Check for armor (armor slot) or legs
	if bit.band(slotPos, SLOTP_ARMOR) ~= 0 or bit.band(slotPos, SLOTP_LEGS) ~= 0 then
		return ItemAttributes.pool.armor
	end

	-- Fallback: if item has armor stat, treat as armor
	if it:getArmor() > 0 then
		return ItemAttributes.pool.armor
	end

	return nil
end

-- ============================================================
-- Weighted random selection from a pool
-- ============================================================
-- pool: table of attribute definitions
-- usedIds: table of already-selected attribute IDs (strings)
-- Returns an attribute definition or nil
function ItemAttributes.weightedRandom(pool, usedIds)
	local totalWeight = 0
	local available = {}

	for _, attr in ipairs(pool) do
		local skip = false
		for _, usedId in ipairs(usedIds) do
			if attr.id == usedId then
				skip = true
				break
			end
		end
		if not skip then
			table.insert(available, attr)
			totalWeight = totalWeight + attr.weight
		end
	end

	if totalWeight == 0 or #available == 0 then
		return nil
	end

	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, attr in ipairs(available) do
		cumulative = cumulative + attr.weight
		if roll <= cumulative then
			return attr
		end
	end

	return available[#available]
end

-- ============================================================
-- Roll an attribute value, optionally scaled for epic rarity
-- ============================================================
function ItemAttributes.rollValue(attr, rarity, monsterLevel)
	local value

	if rarity == ItemAttributes.RARITY_EPIC then
		-- Epic: roll twice and take the higher value
		local roll1 = math.random(attr.min, attr.max)
		local roll2 = math.random(attr.min, attr.max)
		value = math.max(roll1, roll2)
	else
		value = math.random(attr.min, attr.max)
	end

	-- Scale by monster level: up to 2x at level 200+
	local scaleFactor = math.min(2.0, 1.0 + (monsterLevel / 200))
	value = math.floor(value * scaleFactor)
	value = math.max(attr.min, math.min(attr.max * 2, value))

	return value
end

-- ============================================================
-- Generate random attributes for an item
-- ============================================================
-- item: Item userdata
-- monsterLevel: approximate level of the monster
-- Returns true if attributes were added, false otherwise
function ItemAttributes.generateAttributes(item, monsterLevel)
	local pool = ItemAttributes.getPoolForItem(item)
	if not pool then return false end

	local rarity = ItemAttributes.rollRarity(monsterLevel)
	if rarity == 0 then return false end

	local count = ItemAttributes.getAttributeCount(rarity)
	if count == 0 then return false end

	local usedIds = {}
	local descriptions = {}

	for i = 1, count do
		local attr = ItemAttributes.weightedRandom(pool, usedIds)
		if attr then
			local value = ItemAttributes.rollValue(attr, rarity, monsterLevel)

			-- Store as custom attribute with rattr_ prefix
			item:setCustomAttribute("rattr_" .. attr.id, value)
			table.insert(usedIds, attr.id)
			table.insert(descriptions, attr.name .. " +" .. value .. attr.suffix)
		end
	end

	-- Store rarity on the item
	item:setCustomAttribute("rattr_rarity", rarity)

	-- Update item description with attribute list
	if #descriptions > 0 then
		local rarityTag = ItemAttributes.rarityNames[rarity] or ""
		local desc = "[" .. rarityTag .. ": " .. table.concat(descriptions, ", ") .. "]"
		item:setSpecialDescription(desc)
	end

	return true
end

-- ============================================================
-- Format attribute text for display
-- ============================================================
-- item: Item userdata
-- Returns formatted string of all random attributes, or nil
function ItemAttributes.formatDescription(item)
	local rarity = ItemAttributes.readAttribute(item, "rarity")
	if not rarity or rarity == 0 then return nil end

	local lines = {}
	local rarityName = ItemAttributes.rarityNames[rarity] or "Unknown"
	table.insert(lines, "[" .. rarityName .. "]")

	-- Scan all known attribute IDs
	local allIds = {
		"attack", "defense", "armor", "critical", "critdmg",
		"berserk", "gauge", "crushing", "dazing",
		"lean", "fortitude", "wisdom",
		"lifesteal", "manasteal",
		"resist_fire", "resist_ice", "resist_energy", "resist_earth",
		"strength", "dexterity", "intelligence",
	}

	for _, id in ipairs(allIds) do
		local value = ItemAttributes.readAttribute(item, id)
		if value and value > 0 then
			local name = ItemAttributes.getAttributeName(id)
			local suffix = ItemAttributes.getAttributeSuffix(id)
			table.insert(lines, "  " .. name .. " +" .. value .. suffix)
		end
	end

	return table.concat(lines, "\n")
end

-- ============================================================
-- Read / Write helpers
-- ============================================================

function ItemAttributes.readAttribute(item, attrId)
	local val = item:getCustomAttribute("rattr_" .. attrId)
	if val then
		return tonumber(val) or 0
	end
	return nil
end

function ItemAttributes.writeAttribute(item, attrId, value)
	item:setCustomAttribute("rattr_" .. attrId, value)
end

function ItemAttributes.removeAttribute(item, attrId)
	item:removeCustomAttribute("rattr_" .. attrId)
end

-- ============================================================
-- Attribute name and suffix lookup
-- ============================================================

ItemAttributes.nameMap = {
	attack = "Attack",
	defense = "Defense",
	armor = "Armor",
	critical = "Critical Hit",
	critdmg = "Critical Damage",
	berserk = "Berserk",
	gauge = "Gauge",
	crushing = "Crushing Blow",
	dazing = "Dazing Blow",
	lean = "Speed",
	fortitude = "HP",
	wisdom = "Mana",
	lifesteal = "Life Leech",
	manasteal = "Mana Leech",
	resist_fire = "Fire Resist",
	resist_ice = "Ice Resist",
	resist_energy = "Energy Resist",
	resist_earth = "Earth Resist",
	strength = "Strength",
	dexterity = "Dexterity",
	intelligence = "Intelligence",
}

ItemAttributes.suffixMap = {
	attack = "",
	defense = "",
	armor = "",
	critical = "%",
	critdmg = "%",
	berserk = "%",
	gauge = "%",
	crushing = "%",
	dazing = "%",
	lean = "",
	fortitude = "",
	wisdom = "",
	lifesteal = "%",
	manasteal = "%",
	resist_fire = "%",
	resist_ice = "%",
	resist_energy = "%",
	resist_earth = "%",
	strength = "",
	dexterity = "",
	intelligence = "",
}

function ItemAttributes.getAttributeName(id)
	return ItemAttributes.nameMap[id] or id
end

function ItemAttributes.getAttributeSuffix(id)
	return ItemAttributes.suffixMap[id] or ""
end

-- ============================================================
-- Combat Hook Helpers
-- ============================================================
-- These are called from loot_attributes.lua creature script
-- or from event callbacks.

-- Get total bonus from all equipped items for a given attribute
function ItemAttributes.getEquippedBonus(player, attrId)
	local total = 0
	for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
		local item = player:getSlotItem(slot)
		if item then
			local val = ItemAttributes.readAttribute(item, attrId)
			if val then
				total = total + val
			end
		end
	end
	return total
end

-- Check if an on-hit effect triggers (percentage chance)
function ItemAttributes.rollChance(percentChance)
	return math.random(1, 100) <= percentChance
end

-- Apply combat-relevant attribute effects for an attacker
-- Returns a table of active bonuses
function ItemAttributes.getCombatBonuses(player)
	local bonuses = {
		attackFlat = 0,
		defenseFlat = 0,
		armorFlat = 0,
		critChance = 0,
		berserk = 0,
		gauge = 0,
		crushingChance = 0,
		dazingChance = 0,
		speedBonus = 0,
		hpBonus = 0,
		manaBonus = 0,
		lifeLeech = 0,
		manaLeech = 0,
	}

	for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
		local item = player:getSlotItem(slot)
		if item then
			local rarity = ItemAttributes.readAttribute(item, "rarity")
			if rarity and rarity > 0 then
				bonuses.attackFlat = bonuses.attackFlat + (ItemAttributes.readAttribute(item, "attack") or 0)
				bonuses.defenseFlat = bonuses.defenseFlat + (ItemAttributes.readAttribute(item, "defense") or 0)
				bonuses.armorFlat = bonuses.armorFlat + (ItemAttributes.readAttribute(item, "armor") or 0)
				bonuses.critChance = bonuses.critChance + (ItemAttributes.readAttribute(item, "critical") or 0)
				bonuses.berserk = bonuses.berserk + (ItemAttributes.readAttribute(item, "berserk") or 0)
				bonuses.gauge = bonuses.gauge + (ItemAttributes.readAttribute(item, "gauge") or 0)
				bonuses.crushingChance = bonuses.crushingChance + (ItemAttributes.readAttribute(item, "crushing") or 0)
				bonuses.dazingChance = bonuses.dazingChance + (ItemAttributes.readAttribute(item, "dazing") or 0)
				bonuses.speedBonus = bonuses.speedBonus + (ItemAttributes.readAttribute(item, "lean") or 0)
				bonuses.hpBonus = bonuses.hpBonus + (ItemAttributes.readAttribute(item, "fortitude") or 0)
				bonuses.manaBonus = bonuses.manaBonus + (ItemAttributes.readAttribute(item, "wisdom") or 0)
				bonuses.lifeLeech = bonuses.lifeLeech + (ItemAttributes.readAttribute(item, "lifesteal") or 0)
				bonuses.manaLeech = bonuses.manaLeech + (ItemAttributes.readAttribute(item, "manasteal") or 0)
			end
		end
	end

	return bonuses
end

-- Hook: called when a monster drops loot to process all equipment in corpse
function ItemAttributes.onLootDrop(monster, corpse)
	if not corpse or not monster then return end

	local mType = monster:getType()
	if not mType then return end

	local monsterLevel = math.max(1, math.floor(mType:getMaxHealth() / 10))

	-- Check if monster is elite (boosted attribute chances)
	local isElite = monster:getStorageValue(42500) == 1
	if isElite then
		monsterLevel = monsterLevel * 2
	end

	local items = corpse:getItems()
	if not items then return end

	for _, item in pairs(items) do
		local it = ItemType(item:getId())
		if it then
			local weaponType = it:getWeaponType()
			local isEquipment = (weaponType ~= WEAPON_NONE and weaponType ~= WEAPON_AMMO)
				or it:getArmor() > 0
				or it:getDefense() > 0
			if isEquipment then
				ItemAttributes.generateAttributes(item, monsterLevel)
			end
		end
	end
end

print("[Phase 3] Item Attributes system loaded.")
