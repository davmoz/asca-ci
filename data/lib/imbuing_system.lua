-- ============================================================================
-- Imbuing System
-- ============================================================================
-- Players can imbue equipment with temporary stat bonuses using materials.
-- Imbues last 20 hours of active use (72000 seconds) and are tracked via
-- player storage values. Equipment slots: helmet, armor, weapon, shield.
--
-- Storage keys: 64200-64299 (registered in storage_keys.lua)
-- ============================================================================

ImbuingSystem = {}

-- ---------------------------------------------------------------------------
-- Storage Keys (range: 64200-64299)
-- ---------------------------------------------------------------------------
-- Layout per slot (4 slots x 4 keys = 16 keys):
--   base + 0..3   = helmet  (type, tier, startTime, elapsed)
--   base + 4..7   = armor
--   base + 8..11  = weapon
--   base + 12..15 = shield
ImbuingSystem.Storage = {
	BASE = 64200,
}

-- Offsets within each slot block of 4 keys
local OFFSET_TYPE      = 0  -- imbue type ID (0 = none)
local OFFSET_TIER      = 1  -- tier (1/2/3)
local OFFSET_START     = 2  -- os.time() when imbue was applied
local OFFSET_ELAPSED   = 3  -- accumulated active seconds so far

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
ImbuingSystem.DURATION = 72000  -- 20 hours in seconds

-- ---------------------------------------------------------------------------
-- Slot Definitions
-- ---------------------------------------------------------------------------
ImbuingSystem.SLOT_HELMET = 1
ImbuingSystem.SLOT_ARMOR  = 2
ImbuingSystem.SLOT_WEAPON = 3
ImbuingSystem.SLOT_SHIELD = 4

ImbuingSystem.Slots = {
	[ImbuingSystem.SLOT_HELMET] = { name = "helmet", offset = 0  },
	[ImbuingSystem.SLOT_ARMOR]  = { name = "armor",  offset = 4  },
	[ImbuingSystem.SLOT_WEAPON] = { name = "weapon", offset = 8  },
	[ImbuingSystem.SLOT_SHIELD] = { name = "shield", offset = 12 },
}

-- Reverse lookup: name -> slot id
ImbuingSystem.SlotByName = {}
for id, def in pairs(ImbuingSystem.Slots) do
	ImbuingSystem.SlotByName[def.name] = id
end

-- ---------------------------------------------------------------------------
-- Imbue Type Definitions (12 types)
-- ---------------------------------------------------------------------------
-- Each type has 3 tiers: Basic (1), Intricate (2), Powerful (3)
-- values = { tier1, tier2, tier3 }
-- For Strike, bonusValues holds the flat bonus per tier.

ImbuingSystem.IMBUE_VAMPIRISM    = 1
ImbuingSystem.IMBUE_VOID         = 2
ImbuingSystem.IMBUE_STRIKE       = 3
ImbuingSystem.IMBUE_EPIPHANY     = 4
ImbuingSystem.IMBUE_SWIFTNESS    = 5
ImbuingSystem.IMBUE_BASH         = 6
ImbuingSystem.IMBUE_CHOP         = 7
ImbuingSystem.IMBUE_SLASH        = 8
ImbuingSystem.IMBUE_PRECISION    = 9
ImbuingSystem.IMBUE_BLOCKADE     = 10
ImbuingSystem.IMBUE_FEATHERWEIGHT = 11
ImbuingSystem.IMBUE_VIBRANCY     = 12

ImbuingSystem.Types = {
	[1]  = {
		name = "Vampirism", desc = "Life Leech",
		values = { 5, 10, 15 }, unit = "%",
		allowedSlots = { ImbuingSystem.SLOT_WEAPON },
	},
	[2]  = {
		name = "Void", desc = "Mana Leech",
		values = { 3, 5, 8 }, unit = "%",
		allowedSlots = { ImbuingSystem.SLOT_WEAPON },
	},
	[3]  = {
		name = "Strike", desc = "Critical Hit",
		values = { 5, 10, 15 }, unit = "%",
		bonusValues = { 10, 25, 50 },
		allowedSlots = { ImbuingSystem.SLOT_WEAPON },
	},
	[4]  = {
		name = "Epiphany", desc = "Magic Level",
		values = { 1, 2, 3 }, unit = "",
		allowedSlots = { ImbuingSystem.SLOT_HELMET },
	},
	[5]  = {
		name = "Swiftness", desc = "Speed",
		values = { 15, 25, 40 }, unit = "",
		allowedSlots = { ImbuingSystem.SLOT_ARMOR },
	},
	[6]  = {
		name = "Bash", desc = "Club Skill",
		values = { 1, 2, 3 }, unit = "",
		allowedSlots = { ImbuingSystem.SLOT_WEAPON },
	},
	[7]  = {
		name = "Chop", desc = "Axe Skill",
		values = { 1, 2, 3 }, unit = "",
		allowedSlots = { ImbuingSystem.SLOT_WEAPON },
	},
	[8]  = {
		name = "Slash", desc = "Sword Skill",
		values = { 1, 2, 3 }, unit = "",
		allowedSlots = { ImbuingSystem.SLOT_WEAPON },
	},
	[9]  = {
		name = "Precision", desc = "Distance Skill",
		values = { 1, 2, 3 }, unit = "",
		allowedSlots = { ImbuingSystem.SLOT_WEAPON },
	},
	[10] = {
		name = "Blockade", desc = "Shield Skill",
		values = { 1, 2, 3 }, unit = "",
		allowedSlots = { ImbuingSystem.SLOT_SHIELD },
	},
	[11] = {
		name = "Featherweight", desc = "Capacity",
		values = { 100, 250, 500 }, unit = "",
		allowedSlots = { ImbuingSystem.SLOT_ARMOR },
	},
	[12] = {
		name = "Vibrancy", desc = "Paralysis Protection",
		values = { 15, 25, 50 }, unit = "%",
		allowedSlots = { ImbuingSystem.SLOT_ARMOR },
	},
}

-- ---------------------------------------------------------------------------
-- Tier Names
-- ---------------------------------------------------------------------------
ImbuingSystem.TIER_BASIC     = 1
ImbuingSystem.TIER_INTRICATE = 2
ImbuingSystem.TIER_POWERFUL  = 3

ImbuingSystem.TierNames = {
	[1] = "Basic",
	[2] = "Intricate",
	[3] = "Powerful",
}

-- ---------------------------------------------------------------------------
-- Material Costs
-- ---------------------------------------------------------------------------
-- Uses existing items + ore IDs from crafting_mining.lua.
-- Each entry: { {itemId, count}, ... }
-- Gold cost per tier is also defined (consumed from player balance).

ImbuingSystem.GoldCost = {
	[1] = 15000,   -- Basic
	[2] = 55000,   -- Intricate
	[3] = 150000,  -- Powerful
}

-- Material tables indexed by [imbuType][tier]
-- References Mining.Items for ores/bars and standard TFS item IDs for
-- creature products.
ImbuingSystem.Materials = {
	-- Vampirism: vampire teeth (5765), blood herb (2798), ores
	[1] = {
		[1] = { {5765, 5},  {Mining.Items.IRON_ORE, 5} },
		[2] = { {5765, 15}, {Mining.Items.SILVER_ORE, 10}, {2798, 5} },
		[3] = { {5765, 25}, {Mining.Items.GOLD_ORE, 15},   {2798, 15} },
	},
	-- Void: rope belt (11492), blank rune (2260), ores
	[2] = {
		[1] = { {2260, 10}, {Mining.Items.IRON_ORE, 5} },
		[2] = { {2260, 25}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.COAL, 10} },
		[3] = { {2260, 50}, {Mining.Items.MITHRIL_ORE, 10}, {Mining.Items.COAL, 20} },
	},
	-- Strike: protective charm (2195), ores
	[3] = {
		[1] = { {2195, 5},  {Mining.Items.IRON_ORE, 5} },
		[2] = { {2195, 15}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.STEEL_BAR, 5} },
		[3] = { {2195, 25}, {Mining.Items.GOLD_ORE, 15},   {Mining.Items.MITHRIL_BAR, 5} },
	},
	-- Epiphany: elvish talisman (2198), ores
	[4] = {
		[1] = { {2198, 5},  {Mining.Items.COPPER_ORE, 10} },
		[2] = { {2198, 15}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.IRON_BAR, 5} },
		[3] = { {2198, 25}, {Mining.Items.MITHRIL_ORE, 15}, {Mining.Items.GOLD_BAR, 5} },
	},
	-- Swiftness: damselfly wing (5894), ores
	[5] = {
		[1] = { {5894, 10}, {Mining.Items.COPPER_ORE, 10} },
		[2] = { {5894, 25}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.IRON_BAR, 5} },
		[3] = { {5894, 50}, {Mining.Items.MITHRIL_ORE, 15}, {Mining.Items.SILVER_BAR, 10} },
	},
	-- Bash: cyclops toe (2230), ores
	[6] = {
		[1] = { {2230, 5},  {Mining.Items.IRON_ORE, 5} },
		[2] = { {2230, 15}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.IRON_BAR, 5} },
		[3] = { {2230, 25}, {Mining.Items.GOLD_ORE, 15},   {Mining.Items.STEEL_BAR, 10} },
	},
	-- Chop: orc tooth (2232), ores
	[7] = {
		[1] = { {2232, 5},  {Mining.Items.IRON_ORE, 5} },
		[2] = { {2232, 15}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.IRON_BAR, 5} },
		[3] = { {2232, 25}, {Mining.Items.GOLD_ORE, 15},   {Mining.Items.STEEL_BAR, 10} },
	},
	-- Slash: lion's mane (2215), ores
	[8] = {
		[1] = { {2215, 5},  {Mining.Items.IRON_ORE, 5} },
		[2] = { {2215, 15}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.IRON_BAR, 5} },
		[3] = { {2215, 25}, {Mining.Items.GOLD_ORE, 15},   {Mining.Items.STEEL_BAR, 10} },
	},
	-- Precision: elven hoof (2224), ores
	[9] = {
		[1] = { {2224, 5},  {Mining.Items.IRON_ORE, 5} },
		[2] = { {2224, 15}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.IRON_BAR, 5} },
		[3] = { {2224, 25}, {Mining.Items.GOLD_ORE, 15},   {Mining.Items.MITHRIL_BAR, 5} },
	},
	-- Blockade: piece of scarab shield (2159), ores
	[10] = {
		[1] = { {2159, 5},  {Mining.Items.IRON_ORE, 5} },
		[2] = { {2159, 15}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.STEEL_BAR, 5} },
		[3] = { {2159, 25}, {Mining.Items.MITHRIL_ORE, 15}, {Mining.Items.PLATINUM_BAR, 5} },
	},
	-- Featherweight: fairy wings (2186), ores
	[11] = {
		[1] = { {2186, 10}, {Mining.Items.COPPER_ORE, 10} },
		[2] = { {2186, 25}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.IRON_BAR, 5} },
		[3] = { {2186, 50}, {Mining.Items.MITHRIL_ORE, 15}, {Mining.Items.SILVER_BAR, 10} },
	},
	-- Vibrancy: spider silk (2212), ores
	[12] = {
		[1] = { {2212, 10}, {Mining.Items.COPPER_ORE, 10} },
		[2] = { {2212, 25}, {Mining.Items.SILVER_ORE, 10}, {Mining.Items.IRON_BAR, 5} },
		[3] = { {2212, 50}, {Mining.Items.GOLD_ORE, 15},   {Mining.Items.MITHRIL_BAR, 5} },
	},
}

-- ---------------------------------------------------------------------------
-- Helper: get storage key for a given slot and offset
-- ---------------------------------------------------------------------------
local function getStorageKey(slot, offset)
	local slotDef = ImbuingSystem.Slots[slot]
	if not slotDef then return nil end
	return ImbuingSystem.Storage.BASE + slotDef.offset + offset
end

-- ---------------------------------------------------------------------------
-- Helper: determine equipment slot from an item
-- ---------------------------------------------------------------------------
function ImbuingSystem.getSlotFromItem(item)
	if not item then return nil end
	local itemType = ItemType(item:getId())
	if not itemType then return nil end

	-- Check weapon type first
	local weaponType = itemType:getWeaponType()
	if weaponType == WEAPON_SWORD or weaponType == WEAPON_AXE or
	   weaponType == WEAPON_CLUB or weaponType == WEAPON_DISTANCE or
	   weaponType == WEAPON_WAND then
		return ImbuingSystem.SLOT_WEAPON
	end
	if weaponType == WEAPON_SHIELD then
		return ImbuingSystem.SLOT_SHIELD
	end

	-- Check slot position for armor types
	local slotPos = itemType:getSlotPosition()
	if slotPos then
		if bit.band(slotPos, SLOTP_HEAD) ~= 0 then
			return ImbuingSystem.SLOT_HELMET
		end
		if bit.band(slotPos, SLOTP_ARMOR) ~= 0 then
			return ImbuingSystem.SLOT_ARMOR
		end
	end

	-- Fallback by defense/armor values
	if itemType:getArmor() > 0 then
		return ImbuingSystem.SLOT_ARMOR
	end
	if itemType:getDefense() > 0 then
		return ImbuingSystem.SLOT_SHIELD
	end

	return nil
end

-- ---------------------------------------------------------------------------
-- Check whether a given imbue type is allowed on a particular slot
-- ---------------------------------------------------------------------------
function ImbuingSystem.isAllowedOnSlot(imbuType, slot)
	local typeDef = ImbuingSystem.Types[imbuType]
	if not typeDef then return false end
	for _, s in ipairs(typeDef.allowedSlots) do
		if s == slot then return true end
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Get material cost for an imbue type and tier
-- ---------------------------------------------------------------------------
-- @return table of {itemId, count} pairs, or nil on invalid input
function ImbuingSystem.getMaterialCost(imbuType, tier)
	if not ImbuingSystem.Materials[imbuType] then return nil end
	if not ImbuingSystem.Materials[imbuType][tier] then return nil end
	return ImbuingSystem.Materials[imbuType][tier]
end

-- ---------------------------------------------------------------------------
-- Check if a player has all required materials for an imbue
-- ---------------------------------------------------------------------------
function ImbuingSystem.hasMaterials(player, imbuType, tier)
	local mats = ImbuingSystem.getMaterialCost(imbuType, tier)
	if not mats then return false end

	for _, mat in ipairs(mats) do
		if player:getItemCount(mat[1]) < mat[2] then
			return false
		end
	end

	-- Check gold cost
	local goldCost = ImbuingSystem.GoldCost[tier] or 0
	if player:getMoney() < goldCost then
		return false
	end

	return true
end

-- ---------------------------------------------------------------------------
-- Consume materials and gold from the player
-- ---------------------------------------------------------------------------
local function consumeMaterials(player, imbuType, tier)
	local mats = ImbuingSystem.getMaterialCost(imbuType, tier)
	if not mats then return false end

	for _, mat in ipairs(mats) do
		player:removeItem(mat[1], mat[2])
	end

	local goldCost = ImbuingSystem.GoldCost[tier] or 0
	if goldCost > 0 then
		player:removeMoney(goldCost)
	end

	return true
end

-- ---------------------------------------------------------------------------
-- Get the current imbue on a slot
-- ---------------------------------------------------------------------------
-- @return imbuType, tier, elapsed, remaining  (or nil if no imbue)
function ImbuingSystem.getImbue(player, slot)
	local keyType = getStorageKey(slot, OFFSET_TYPE)
	if not keyType then return nil end

	local imbuType = player:getStorageValue(keyType)
	if not imbuType or imbuType <= 0 then
		return nil
	end

	local tier    = math.max(1, player:getStorageValue(getStorageKey(slot, OFFSET_TIER)))
	local elapsed = math.max(0, player:getStorageValue(getStorageKey(slot, OFFSET_ELAPSED)))

	local remaining = ImbuingSystem.DURATION - elapsed
	if remaining <= 0 then
		remaining = 0
	end

	return imbuType, tier, elapsed, remaining
end

-- ---------------------------------------------------------------------------
-- Check if an imbue on a given slot is still active (has time remaining)
-- ---------------------------------------------------------------------------
function ImbuingSystem.isActive(player, slot)
	local imbuType, tier, elapsed, remaining = ImbuingSystem.getImbue(player, slot)
	if not imbuType then return false end
	return remaining > 0
end

-- ---------------------------------------------------------------------------
-- Get the stat value for the current imbue on a slot
-- ---------------------------------------------------------------------------
function ImbuingSystem.getStatValue(player, slot)
	local imbuType, tier, elapsed, remaining = ImbuingSystem.getImbue(player, slot)
	if not imbuType or remaining <= 0 then return nil, nil end

	local typeDef = ImbuingSystem.Types[imbuType]
	if not typeDef then return nil, nil end

	return typeDef.values[tier], typeDef
end

-- ---------------------------------------------------------------------------
-- Imbue an equipment item
-- ---------------------------------------------------------------------------
-- @param player    Player userdata
-- @param itemUid   UID of the item to imbue
-- @param imbuType  Imbue type constant (1-12)
-- @param tier      Tier constant (1-3)
-- @return boolean success
function ImbuingSystem.imbue(player, itemUid, imbuType, tier)
	-- Validate imbue type
	local typeDef = ImbuingSystem.Types[imbuType]
	if not typeDef then
		player:sendCancelMessage("Invalid imbue type.")
		return false
	end

	-- Validate tier
	if tier < 1 or tier > 3 then
		player:sendCancelMessage("Invalid imbue tier.")
		return false
	end

	-- Resolve item
	local item = Item(itemUid)
	if not item then
		player:sendCancelMessage("Item not found.")
		return false
	end

	-- Determine equipment slot
	local slot = ImbuingSystem.getSlotFromItem(item)
	if not slot then
		player:sendCancelMessage("This item cannot be imbued.")
		return false
	end

	-- Check if this imbue type is allowed on this slot
	if not ImbuingSystem.isAllowedOnSlot(imbuType, slot) then
		local slotName = ImbuingSystem.Slots[slot] and ImbuingSystem.Slots[slot].name or "unknown"
		player:sendCancelMessage(typeDef.name .. " cannot be applied to " .. slotName .. " equipment.")
		return false
	end

	-- Check for existing active imbue on this slot
	if ImbuingSystem.isActive(player, slot) then
		player:sendCancelMessage("This equipment slot already has an active imbue. Remove it first.")
		return false
	end

	-- Check materials
	if not ImbuingSystem.hasMaterials(player, imbuType, tier) then
		player:sendCancelMessage("You do not have the required materials or gold.")
		return false
	end

	-- Consume materials
	if not consumeMaterials(player, imbuType, tier) then
		player:sendCancelMessage("Failed to consume materials.")
		return false
	end

	-- Apply the imbue to storage
	player:setStorageValue(getStorageKey(slot, OFFSET_TYPE), imbuType)
	player:setStorageValue(getStorageKey(slot, OFFSET_TIER), tier)
	player:setStorageValue(getStorageKey(slot, OFFSET_START), os.time())
	player:setStorageValue(getStorageKey(slot, OFFSET_ELAPSED), 0)

	-- Visual feedback
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)

	local tierName = ImbuingSystem.TierNames[tier] or "Unknown"
	local value = typeDef.values[tier]
	local bonus = ""
	if typeDef.bonusValues then
		bonus = ", +" .. typeDef.bonusValues[tier] .. " bonus damage"
	end

	player:sendTextMessage(MESSAGE_INFO_DESCR,
		"Imbue applied: " .. tierName .. " " .. typeDef.name ..
		" (" .. typeDef.desc .. " +" .. value .. typeDef.unit .. bonus .. ")." ..
		" Duration: 20 hours of active use.")

	return true
end

-- ---------------------------------------------------------------------------
-- Remove an imbue from a slot
-- ---------------------------------------------------------------------------
-- @param player    Player userdata
-- @param itemUid   UID of the item to remove imbue from
-- @return boolean success
function ImbuingSystem.removeImbue(player, itemUid)
	-- Resolve item
	local item = Item(itemUid)
	if not item then
		player:sendCancelMessage("Item not found.")
		return false
	end

	local slot = ImbuingSystem.getSlotFromItem(item)
	if not slot then
		player:sendCancelMessage("This item cannot hold imbues.")
		return false
	end

	local imbuType = ImbuingSystem.getImbue(player, slot)
	if not imbuType then
		player:sendCancelMessage("This slot has no imbue to remove.")
		return false
	end

	-- Clear all storage keys for this slot
	player:setStorageValue(getStorageKey(slot, OFFSET_TYPE), -1)
	player:setStorageValue(getStorageKey(slot, OFFSET_TIER), -1)
	player:setStorageValue(getStorageKey(slot, OFFSET_START), -1)
	player:setStorageValue(getStorageKey(slot, OFFSET_ELAPSED), -1)

	player:getPosition():sendMagicEffect(CONST_ME_POFF)
	player:sendTextMessage(MESSAGE_INFO_DESCR, "The imbue has been removed.")

	return true
end

-- ---------------------------------------------------------------------------
-- Tick elapsed time for active imbues (call periodically, e.g. every 60s)
-- ---------------------------------------------------------------------------
-- @param player    Player userdata
-- @param seconds   Number of seconds to add to elapsed counters
function ImbuingSystem.tick(player, seconds)
	for slotId, _ in pairs(ImbuingSystem.Slots) do
		local imbuType, tier, elapsed, remaining = ImbuingSystem.getImbue(player, slotId)
		if imbuType and remaining > 0 then
			local newElapsed = elapsed + seconds
			player:setStorageValue(getStorageKey(slotId, OFFSET_ELAPSED), newElapsed)

			-- Check if imbue has just expired
			if newElapsed >= ImbuingSystem.DURATION then
				local typeDef = ImbuingSystem.Types[imbuType]
				local typeName = typeDef and typeDef.name or "Unknown"
				local slotName = ImbuingSystem.Slots[slotId] and ImbuingSystem.Slots[slotId].name or "unknown"
				player:sendTextMessage(MESSAGE_STATUS_WARNING,
					"Your " .. typeName .. " imbue on your " .. slotName .. " has expired.")
				player:getPosition():sendMagicEffect(CONST_ME_POFF)
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- Get a formatted summary of all active imbues for a player
-- ---------------------------------------------------------------------------
function ImbuingSystem.getSummary(player)
	local lines = {}
	for slotId, slotDef in pairs(ImbuingSystem.Slots) do
		local imbuType, tier, elapsed, remaining = ImbuingSystem.getImbue(player, slotId)
		if imbuType then
			local typeDef = ImbuingSystem.Types[imbuType]
			local tierName = ImbuingSystem.TierNames[tier] or "?"
			local typeName = typeDef and typeDef.name or "Unknown"
			local hours = math.floor(remaining / 3600)
			local mins  = math.floor((remaining % 3600) / 60)
			local status = remaining > 0 and (hours .. "h " .. mins .. "m remaining") or "EXPIRED"
			table.insert(lines,
				slotDef.name:sub(1, 1):upper() .. slotDef.name:sub(2) .. ": " ..
				tierName .. " " .. typeName .. " - " .. status)
		end
	end

	if #lines == 0 then
		return "You have no active imbues."
	end
	return "Active Imbues:\n" .. table.concat(lines, "\n")
end

print(">> Imbuing system loaded")
