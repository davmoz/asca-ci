-- Item Rank System (Phase 3)
-- Equipment can be upgraded from rank 0 to rank 5
-- Higher ranks increase base stats and grant property bonuses (STR/DEX/INT)

ItemRanks = {}

-- ============================================================
-- Rank Configuration
-- ============================================================

ItemRanks.MAX_RANK = 5

-- Rank effects: modifier = multiplier on base attack/defense/armor
-- propertyBonus = STR/DEX/INT points granted
ItemRanks.ranks = {
	[0] = {modifier = 1.00, propertyBonus = 0, prefix = ""},
	[1] = {modifier = 1.05, propertyBonus = 1, prefix = "[+1] "},
	[2] = {modifier = 1.10, propertyBonus = 2, prefix = "[+2] "},
	[3] = {modifier = 1.15, propertyBonus = 3, prefix = "[+3] "},
	[4] = {modifier = 1.20, propertyBonus = 5, prefix = "[+4] "},
	[5] = {modifier = 1.25, propertyBonus = 8, prefix = "[+5] "},
}

-- Upgrade costs: gold, material item ID, material count, success chance %
ItemRanks.upgradeCosts = {
	[1] = {gold = 10000,   material = {30404, 2}, chance = 90},   -- Steel bars
	[2] = {gold = 50000,   material = {30407, 2}, chance = 75},   -- Mithril bars
	[3] = {gold = 200000,  material = {30408, 3}, chance = 60},   -- Adamantite bars
	[4] = {gold = 500000,  material = {30409, 2}, chance = 40},   -- Starmetal bars
	[5] = {gold = 1000000, material = {30410, 3}, chance = 25},   -- Dragon Scale bars
}

-- ============================================================
-- Properties System (STR / DEX / INT)
-- ============================================================

-- Property effects per point:
-- STR +1 = +0.5% melee damage, +2 max carry capacity
-- DEX +1 = +0.3% dodge chance, +1 movement speed, +0.3% ranged damage
-- INT +1 = +0.5% spell damage, +5 max mana

ItemRanks.PROPERTY_STRENGTH     = "strength"
ItemRanks.PROPERTY_DEXTERITY    = "dexterity"
ItemRanks.PROPERTY_INTELLIGENCE = "intelligence"

-- Determine which property an item grants based on weapon type
function ItemRanks.getItemProperty(item)
	local it = ItemType(item:getId())
	if not it then return nil end

	local weaponType = it:getWeaponType()

	-- Melee weapons grant Strength
	if weaponType == WEAPON_SWORD or weaponType == WEAPON_AXE or weaponType == WEAPON_CLUB then
		return ItemRanks.PROPERTY_STRENGTH
	end

	-- Ranged weapons grant Dexterity
	if weaponType == WEAPON_DISTANCE then
		return ItemRanks.PROPERTY_DEXTERITY
	end

	-- Wands grant Intelligence
	if weaponType == WEAPON_WAND then
		return ItemRanks.PROPERTY_INTELLIGENCE
	end

	-- Shields grant Strength
	if weaponType == WEAPON_SHIELD then
		return ItemRanks.PROPERTY_STRENGTH
	end

	-- Armor pieces: check slot
	local slotPos = it:getSlotPosition()
	if bit.band(slotPos, SLOTP_HEAD) ~= 0 then
		return ItemRanks.PROPERTY_INTELLIGENCE
	end
	if bit.band(slotPos, SLOTP_ARMOR) ~= 0 then
		return ItemRanks.PROPERTY_STRENGTH
	end
	if bit.band(slotPos, SLOTP_LEGS) ~= 0 then
		return ItemRanks.PROPERTY_STRENGTH
	end
	if bit.band(slotPos, SLOTP_FEET) ~= 0 then
		return ItemRanks.PROPERTY_DEXTERITY
	end

	return nil
end

-- ============================================================
-- Get / Set Rank
-- ============================================================

function ItemRanks.getRank(item)
	local rank = item:getCustomAttribute("item_rank")
	if rank then
		return tonumber(rank) or 0
	end
	return 0
end

function ItemRanks.setRank(item, rank)
	rank = math.max(0, math.min(ItemRanks.MAX_RANK, rank))
	item:setCustomAttribute("item_rank", rank)
	ItemRanks.applyRankBonus(item, rank)
	ItemRanks.updateItemName(item, rank)
end

-- ============================================================
-- Calculate Property Bonuses
-- ============================================================

function ItemRanks.getRankPropertyBonus(rank)
	local rankData = ItemRanks.ranks[rank]
	if rankData then
		return rankData.propertyBonus
	end
	return 0
end

-- Get total STR/DEX/INT from all equipped items for a player
function ItemRanks.getPlayerProperties(player)
	local str, dex, int = 0, 0, 0

	for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
		local item = player:getSlotItem(slot)
		if item then
			local rank = ItemRanks.getRank(item)
			local propBonus = ItemRanks.getRankPropertyBonus(rank)
			local property = ItemRanks.getItemProperty(item)

			if property == ItemRanks.PROPERTY_STRENGTH then
				str = str + propBonus
			elseif property == ItemRanks.PROPERTY_DEXTERITY then
				dex = dex + propBonus
			elseif property == ItemRanks.PROPERTY_INTELLIGENCE then
				int = int + propBonus
			end

			-- Also read random attribute properties if present
			if ItemAttributes then
				str = str + (ItemAttributes.readAttribute(item, "strength") or 0)
				dex = dex + (ItemAttributes.readAttribute(item, "dexterity") or 0)
				int = int + (ItemAttributes.readAttribute(item, "intelligence") or 0)
			end
		end
	end

	-- Vocation passive bonuses
	local voc = player:getVocation()
	if voc then
		local vocId = voc:getBaseId()
		local level = player:getLevel()
		if vocId == 4 then      -- Knight
			str = str + math.floor(level / 10)
		elseif vocId == 3 then  -- Paladin
			dex = dex + math.floor(level / 10)
		elseif vocId == 1 then  -- Sorcerer
			int = int + math.floor(level / 10)
		elseif vocId == 2 then  -- Druid
			int = int + math.floor(level / 15)
			str = str + math.floor(level / 30)
		end
	end

	return str, dex, int
end

-- ============================================================
-- Apply Rank Stat Bonuses
-- ============================================================

function ItemRanks.applyRankBonus(item, rank)
	local baseType = ItemType(item:getId())
	if not baseType then return end

	local rankData = ItemRanks.ranks[rank]
	if not rankData then return end

	local modifier = rankData.modifier

	-- Scale attack
	local baseAttack = baseType:getAttack()
	if baseAttack > 0 then
		item:setAttribute(ITEM_ATTRIBUTE_ATTACK, math.floor(baseAttack * modifier))
	end

	-- Scale defense
	local baseDefense = baseType:getDefense()
	if baseDefense > 0 then
		item:setAttribute(ITEM_ATTRIBUTE_DEFENSE, math.floor(baseDefense * modifier))
	end

	-- Scale armor
	local baseArmor = baseType:getArmor()
	if baseArmor > 0 then
		item:setAttribute(ITEM_ATTRIBUTE_ARMOR, math.floor(baseArmor * modifier))
	end
end

-- ============================================================
-- Update Item Name with Rank Prefix
-- ============================================================

function ItemRanks.updateItemName(item, rank)
	local baseName = ItemType(item:getId()):getName()
	if rank > 0 then
		local prefix = ItemRanks.ranks[rank].prefix
		item:setAttribute(ITEM_ATTRIBUTE_NAME, prefix .. baseName)
	else
		item:removeAttribute(ITEM_ATTRIBUTE_NAME)
	end
end

-- ============================================================
-- Rank Upgrade Mechanic
-- ============================================================

-- Attempt to upgrade an item's rank
-- Returns true on success, false on failure
function ItemRanks.upgradeItem(player, item)
	if not player or not item then
		return false
	end

	local currentRank = ItemRanks.getRank(item)
	if currentRank >= ItemRanks.MAX_RANK then
		player:sendCancelMessage("This item is already at maximum rank.")
		return false
	end

	-- Check if item is equipment
	local it = ItemType(item:getId())
	if not it then
		player:sendCancelMessage("This item cannot be upgraded.")
		return false
	end

	local weaponType = it:getWeaponType()
	local isEquipment = (weaponType ~= WEAPON_NONE and weaponType ~= WEAPON_AMMO)
		or it:getArmor() > 0
		or it:getDefense() > 0
	if not isEquipment then
		player:sendCancelMessage("This item cannot be upgraded.")
		return false
	end

	local nextRank = currentRank + 1
	local cost = ItemRanks.upgradeCosts[nextRank]
	if not cost then
		player:sendCancelMessage("Upgrade data not found.")
		return false
	end

	-- Check gold
	if player:getMoney() < cost.gold then
		player:sendCancelMessage("You need " .. cost.gold .. " gold to upgrade this item.")
		return false
	end

	-- Check materials
	local materialId = cost.material[1]
	local materialCount = cost.material[2]
	if player:getItemCount(materialId) < materialCount then
		local materialName = ItemType(materialId):getName() or "materials"
		player:sendCancelMessage("You need " .. materialCount .. "x " .. materialName .. " to upgrade this item.")
		return false
	end

	-- Consume resources
	player:removeMoney(cost.gold)
	player:removeItem(materialId, materialCount)

	-- Roll for success
	if math.random(1, 100) <= cost.chance then
		-- Success
		ItemRanks.setRank(item, nextRank)

		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"Upgrade successful! Item is now rank " .. nextRank .. ".")
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		return true
	else
		-- Failure: item loses one rank (minimum 0)
		if currentRank > 0 then
			ItemRanks.setRank(item, currentRank - 1)
			player:sendTextMessage(MESSAGE_INFO_DESCR,
				"Upgrade failed! Item rank decreased to " .. (currentRank - 1) .. ".")
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR,
				"Upgrade failed! The item was not damaged.")
		end
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end
end

-- ============================================================
-- Get Rank Description
-- ============================================================

function ItemRanks.getDescription(item)
	local rank = ItemRanks.getRank(item)
	if rank == 0 then return nil end

	local rankData = ItemRanks.ranks[rank]
	local property = ItemRanks.getItemProperty(item)
	local propName = ""
	if property == ItemRanks.PROPERTY_STRENGTH then propName = "Strength"
	elseif property == ItemRanks.PROPERTY_DEXTERITY then propName = "Dexterity"
	elseif property == ItemRanks.PROPERTY_INTELLIGENCE then propName = "Intelligence"
	end

	local desc = "Rank " .. rank .. "/" .. ItemRanks.MAX_RANK
	if propName ~= "" and rankData.propertyBonus > 0 then
		desc = desc .. " (+" .. rankData.propertyBonus .. " " .. propName .. ")"
	end

	return desc
end

print("[Phase 3] Item Ranks system loaded.")
