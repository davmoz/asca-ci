-- ============================================================================
-- Enchanting System - Phase 2.6
-- ============================================================================
-- Use Painite Crystals on equipment to add random enchantment attributes.
-- Crystal tier determines attribute quality and success rate.
-- Max 3 enchantments per item. Crystals are always consumed.
-- Legendary items cannot be enchanted.
-- ============================================================================

Enchanting = {}

-- ---------------------------------------------------------------------------
-- Item IDs (from Phase 2 allocation: 30600-30699)
-- ---------------------------------------------------------------------------
Enchanting.Items = {
	SMALL_PAINITE_CRYSTAL  = 30600,
	MEDIUM_PAINITE_CRYSTAL = 30601,
	LARGE_PAINITE_CRYSTAL  = 30602,
	ENCHANTING_ALTAR       = 30610,
}

-- ---------------------------------------------------------------------------
-- Crystal Tier Definitions
-- ---------------------------------------------------------------------------
-- tier: numeric tier (1-3)
-- successRate: % chance the enchantment succeeds
-- minValue / maxValue: multiplier ranges applied to attribute base values
Enchanting.Crystals = {
	[30600] = { tier = 1, name = "Small Painite Shard",  successRate = 70 },
	[30601] = { tier = 2, name = "Medium Painite Shard", successRate = 85 },
	[30602] = { tier = 3, name = "Large Painite Shard",  successRate = 95 },
}

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
Enchanting.MAX_ENCHANTMENTS = 3
Enchanting.CUSTOM_ATTR_PREFIX = "enchant_"
Enchanting.CUSTOM_ATTR_COUNT  = "enchant_count"

-- Cooldown between enchant attempts (milliseconds)
Enchanting.COOLDOWN_MS = 3000
Enchanting.STORAGE_COOLDOWN = 45200

-- ---------------------------------------------------------------------------
-- Attribute Pool
-- ---------------------------------------------------------------------------
-- Each attribute entry:
--   id          - internal key (stored as enchant_<id>)
--   name        - display name shown to the player
--   min / max   - base value range (scaled by tier)
--   weight      - relative drop weight (higher = more common)
--   appliesTo   - table of slot types the attribute can appear on
--   vocations   - nil means all vocations; otherwise table of base voc IDs

-- Slot type helpers
local SLOT_WEAPON  = "weapon"
local SLOT_SHIELD  = "shield"
local SLOT_ARMOR   = "armor"
local SLOT_HELMET  = "helmet"
local SLOT_LEGS    = "legs"
local SLOT_BOOTS   = "boots"
local SLOT_RING    = "ring"
local SLOT_AMULET  = "amulet"

-- All body equipment
local ALL_EQUIPMENT = {SLOT_WEAPON, SLOT_SHIELD, SLOT_ARMOR, SLOT_HELMET, SLOT_LEGS, SLOT_BOOTS, SLOT_RING, SLOT_AMULET}
local ALL_ARMOR     = {SLOT_SHIELD, SLOT_ARMOR, SLOT_HELMET, SLOT_LEGS, SLOT_BOOTS}
local BODY_ARMOR    = {SLOT_ARMOR, SLOT_HELMET, SLOT_LEGS}

Enchanting.AttributePool = {
	-- Offensive attributes (weapons)
	{ id = "attack",        name = "Attack",        min = 1, max = 3,  weight = 25, appliesTo = {SLOT_WEAPON} },
	{ id = "defense",       name = "Defense",       min = 1, max = 3,  weight = 25, appliesTo = {SLOT_SHIELD, SLOT_ARMOR, SLOT_HELMET} },
	{ id = "critical",      name = "Critical Hit",  min = 1, max = 5,  weight = 15, appliesTo = {SLOT_WEAPON} },
	{ id = "berserk",       name = "Berserk",       min = 1, max = 5,  weight = 8,  appliesTo = {SLOT_WEAPON} },
	{ id = "gauge",         name = "Gauge",         min = 1, max = 5,  weight = 8,  appliesTo = {SLOT_WEAPON} },
	{ id = "crushing_blow", name = "Crushing Blow", min = 1, max = 5,  weight = 6,  appliesTo = {SLOT_WEAPON} },
	{ id = "dazing_blow",   name = "Dazing Blow",   min = 1, max = 5,  weight = 6,  appliesTo = {SLOT_WEAPON} },

	-- Defensive / utility attributes
	{ id = "lean",          name = "Speed",         min = 5, max = 15, weight = 12, appliesTo = {SLOT_BOOTS} },
	{ id = "fortitude",     name = "HP",            min = 10, max = 50, weight = 15, appliesTo = BODY_ARMOR },
	{ id = "wisdom",        name = "Mana",          min = 10, max = 50, weight = 15, appliesTo = BODY_ARMOR },

	-- Vocation-specific attributes
	{ id = "intelligence",  name = "Intelligence",  min = 1, max = 5,  weight = 10, appliesTo = ALL_EQUIPMENT, vocations = {1, 5} },  -- Sorcerer
	{ id = "dexterity",     name = "Dexterity",     min = 1, max = 5,  weight = 10, appliesTo = ALL_EQUIPMENT, vocations = {3, 7} },  -- Paladin
	{ id = "strength",      name = "Strength",      min = 1, max = 5,  weight = 10, appliesTo = ALL_EQUIPMENT, vocations = {4, 8} },  -- Knight
	{ id = "wisdom_voc",    name = "Wisdom",        min = 1, max = 5,  weight = 10, appliesTo = ALL_EQUIPMENT, vocations = {2, 6} },  -- Druid
}

-- ---------------------------------------------------------------------------
-- Legendary item IDs that cannot be enchanted (Phase 3 range 30700+)
-- ---------------------------------------------------------------------------
Enchanting.LegendaryRange = { min = 30700, max = 30799 }

function Enchanting.isLegendary(itemId)
	return itemId >= Enchanting.LegendaryRange.min and itemId <= Enchanting.LegendaryRange.max
end

-- ---------------------------------------------------------------------------
-- Determine the "slot type" of an item for attribute filtering
-- ---------------------------------------------------------------------------
function Enchanting.getItemSlotType(item)
	local itemType = ItemType(item:getId())
	if not itemType then
		return nil
	end

	-- Check weapon type first
	local weaponType = itemType:getWeaponType()
	if weaponType == WEAPON_SWORD or weaponType == WEAPON_AXE or
	   weaponType == WEAPON_CLUB or weaponType == WEAPON_DISTANCE or
	   weaponType == WEAPON_WAND then
		return SLOT_WEAPON
	end
	if weaponType == WEAPON_SHIELD then
		return SLOT_SHIELD
	end

	-- Check slot position for armor types
	local slotPos = itemType:getSlotPosition()
	if slotPos then
		-- Check body slot flags (TFS bit flags)
		if bit.band(slotPos, SLOTP_HEAD) ~= 0 then
			return SLOT_HELMET
		end
		if bit.band(slotPos, SLOTP_ARMOR) ~= 0 then
			return SLOT_ARMOR
		end
		if bit.band(slotPos, SLOTP_LEGS) ~= 0 then
			return SLOT_LEGS
		end
		if bit.band(slotPos, SLOTP_FEET) ~= 0 then
			return SLOT_BOOTS
		end
		if bit.band(slotPos, SLOTP_RING) ~= 0 then
			return SLOT_RING
		end
		if bit.band(slotPos, SLOTP_NECKLACE) ~= 0 then
			return SLOT_AMULET
		end
	end

	-- Fallback: if it has armor value, treat as armor
	if itemType:getArmor() > 0 then
		return SLOT_ARMOR
	end
	if itemType:getDefense() > 0 then
		return SLOT_SHIELD
	end

	return nil
end

-- ---------------------------------------------------------------------------
-- Check whether a specific item is valid equipment that can be enchanted
-- ---------------------------------------------------------------------------
function Enchanting.canEnchant(item)
	if not item then
		return false, "Invalid item."
	end

	local itemId = item:getId()

	-- Legendary items cannot be enchanted
	if Enchanting.isLegendary(itemId) then
		return false, "Legendary items cannot be enchanted."
	end

	-- Must be equipment (has a slot type)
	local slotType = Enchanting.getItemSlotType(item)
	if not slotType then
		return false, "This item cannot be enchanted."
	end

	-- Check max enchantments
	local count = Enchanting.getEnchantmentCount(item)
	if count >= Enchanting.MAX_ENCHANTMENTS then
		return false, "This item already has the maximum number of enchantments (" .. Enchanting.MAX_ENCHANTMENTS .. ")."
	end

	return true, slotType
end

-- ---------------------------------------------------------------------------
-- Get the current number of enchantments on an item
-- ---------------------------------------------------------------------------
function Enchanting.getEnchantmentCount(item)
	local count = item:getCustomAttribute(Enchanting.CUSTOM_ATTR_COUNT)
	if not count or count < 0 then
		return 0
	end
	return count
end

-- ---------------------------------------------------------------------------
-- Build the eligible attribute pool for a given slot type and vocation
-- ---------------------------------------------------------------------------
function Enchanting.buildAttributePool(slotType, vocId, item)
	local pool = {}
	local existingAttrs = Enchanting.getExistingAttributes(item)

	for _, attr in ipairs(Enchanting.AttributePool) do
		-- Check slot compatibility
		local slotMatch = false
		for _, s in ipairs(attr.appliesTo) do
			if s == slotType then
				slotMatch = true
				break
			end
		end

		if slotMatch then
			-- Check vocation restriction
			local vocMatch = true
			if attr.vocations then
				vocMatch = false
				for _, v in ipairs(attr.vocations) do
					if v == vocId then
						vocMatch = true
						break
					end
				end
			end

			-- Skip attributes already on the item (no duplicate enchants)
			local alreadyHas = existingAttrs[attr.id] ~= nil

			if vocMatch and not alreadyHas then
				table.insert(pool, attr)
			end
		end
	end

	return pool
end

-- ---------------------------------------------------------------------------
-- Get existing enchantment attribute IDs on an item
-- ---------------------------------------------------------------------------
function Enchanting.getExistingAttributes(item)
	local existing = {}
	for _, attr in ipairs(Enchanting.AttributePool) do
		local key = Enchanting.CUSTOM_ATTR_PREFIX .. attr.id
		local val = item:getCustomAttribute(key)
		if val and val > 0 then
			existing[attr.id] = val
		end
	end
	return existing
end

-- ---------------------------------------------------------------------------
-- Weighted random selection from an attribute pool
-- ---------------------------------------------------------------------------
function Enchanting.weightedRandom(pool)
	if #pool == 0 then
		return nil
	end

	local totalWeight = 0
	for _, attr in ipairs(pool) do
		totalWeight = totalWeight + attr.weight
	end

	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, attr in ipairs(pool) do
		cumulative = cumulative + attr.weight
		if roll <= cumulative then
			return attr
		end
	end

	return pool[#pool]
end

-- ---------------------------------------------------------------------------
-- Roll the attribute value based on crystal tier
-- Higher tier = better rolls (biased toward the upper range)
-- ---------------------------------------------------------------------------
function Enchanting.rollValue(attr, tier)
	local min = attr.min
	local max = attr.max

	if tier == 1 then
		-- Tier 1: lower third of range
		max = min + math.max(1, math.floor((max - min) * 0.4))
	elseif tier == 2 then
		-- Tier 2: middle range
		local range = max - min
		min = min + math.floor(range * 0.2)
		max = min + math.max(1, math.floor(range * 0.7))
	end
	-- Tier 3: full range (min to max)

	return math.random(min, max)
end

-- ---------------------------------------------------------------------------
-- Build / update the enchantment description on the item
-- ---------------------------------------------------------------------------
function Enchanting.updateDescription(item)
	local parts = {}
	for _, attr in ipairs(Enchanting.AttributePool) do
		local key = Enchanting.CUSTOM_ATTR_PREFIX .. attr.id
		local val = item:getCustomAttribute(key)
		if val and val > 0 then
			-- Format based on attribute type
			local suffix = ""
			if attr.id == "critical" or attr.id == "berserk" or attr.id == "gauge" or
			   attr.id == "crushing_blow" or attr.id == "dazing_blow" then
				suffix = "%"
			end
			table.insert(parts, attr.name .. " +" .. val .. suffix)
		end
	end

	if #parts > 0 then
		-- Preserve any existing non-enchantment description
		local baseDesc = ""
		local currentDesc = item:getSpecialDescription()
		if currentDesc and currentDesc ~= "" then
			-- Strip old enchantment block if present
			baseDesc = currentDesc:gsub("%[Enchanted:.-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
			if baseDesc ~= "" then
				baseDesc = baseDesc .. "\n"
			end
		end
		local enchantDesc = "[Enchanted: " .. table.concat(parts, ", ") .. "]"
		item:setSpecialDescription(baseDesc .. enchantDesc)
	end
end

-- ---------------------------------------------------------------------------
-- Core enchanting function
-- ---------------------------------------------------------------------------
-- @param player   Player userdata
-- @param crystal  Item userdata (the Painite crystal being used)
-- @param target   Item userdata (the equipment being enchanted)
-- @return boolean success
function Enchanting.enchant(player, crystal, target)
	-- Validate crystal
	local crystalData = Enchanting.Crystals[crystal:getId()]
	if not crystalData then
		player:sendCancelMessage("This is not a valid enchanting crystal.")
		return false
	end

	-- Cooldown check
	if not Crafting.checkCooldown(player, Enchanting.STORAGE_COOLDOWN, Enchanting.COOLDOWN_MS) then
		return false
	end

	-- Can the target be enchanted?
	local canDo, slotTypeOrMsg = Enchanting.canEnchant(target)
	if not canDo then
		player:sendCancelMessage(slotTypeOrMsg)
		return false
	end
	local slotType = slotTypeOrMsg

	-- Build eligible attribute pool
	local vocId = player:getVocation():getBaseId()
	local pool = Enchanting.buildAttributePool(slotType, vocId, target)

	if #pool == 0 then
		player:sendCancelMessage("No enchantments are available for this item.")
		return false
	end

	-- Set cooldown
	Crafting.setCooldown(player, Enchanting.STORAGE_COOLDOWN)

	-- Always consume the crystal
	crystal:remove(1)

	-- Roll for success
	local tier = crystalData.tier
	if math.random(1, 100) > crystalData.successRate then
		-- Failure
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:sendTextMessage(MESSAGE_STATUS_SMALL,
			"The " .. crystalData.name .. " shatters. The enchantment failed.")
		-- Award some enchanting XP on failure
		Crafting.addSkillTries(player, Crafting.SKILL_ENCHANTING, 2)
		return false
	end

	-- Success: pick a random attribute
	local attr = Enchanting.weightedRandom(pool)
	if not attr then
		player:sendCancelMessage("Something went wrong with the enchantment.")
		return false
	end

	local value = Enchanting.rollValue(attr, tier)

	-- Apply the enchantment as a custom attribute
	local key = Enchanting.CUSTOM_ATTR_PREFIX .. attr.id
	target:setCustomAttribute(key, value)

	-- Increment enchantment count
	local newCount = Enchanting.getEnchantmentCount(target) + 1
	target:setCustomAttribute(Enchanting.CUSTOM_ATTR_COUNT, newCount)

	-- Update item description
	Enchanting.updateDescription(target)

	-- Visual + message
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	local suffix = ""
	if attr.id == "critical" or attr.id == "berserk" or attr.id == "gauge" or
	   attr.id == "crushing_blow" or attr.id == "dazing_blow" then
		suffix = "%"
	end
	player:sendTextMessage(MESSAGE_INFO_DESCR,
		"Enchantment successful! " .. attr.name .. " +" .. value .. suffix ..
		" (" .. newCount .. "/" .. Enchanting.MAX_ENCHANTMENTS .. " enchantments)")

	-- Award enchanting XP
	local xpReward = 5 + (tier * 5)
	Crafting.addSkillTries(player, Crafting.SKILL_ENCHANTING, xpReward)

	return true
end
