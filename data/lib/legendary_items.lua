-- Legendary Items System (Phase 3)
-- Unique items with fixed powerful effects, dropped by elite monster variants

LegendaryItems = {}

-- Storage key for elite monster flag
STORAGE_ELITE_MONSTER = 42500
STORAGE_LEGENDARY_CRIT = 42501
STORAGE_LEGENDARY_SPEED = 42502
STORAGE_LEGENDARY_MANA_SHIELD = 42503

-- ============================================================
-- Legendary Item Definitions (IDs 30700-30799)
-- ============================================================
-- Each entry: name, type, stats, effects, drop source, drop chance, requirements

LegendaryItems.items = {
	-- WEAPONS: Swords (30700-30709)
	[30700] = {
		name = "Blade of the Forgotten King",
		type = "sword",
		baseAttack = 52,
		baseDefense = 38,
		effects = {
			{type = "on_hit", id = "lifedrain", value = 5,
				description = "Drains 5% of damage dealt as HP"},
			{type = "on_equip", id = "speed_bonus", value = 15,
				description = "+15 movement speed"},
		},
		dropFrom = {"Elite Demon", "Elite Hellhound"},
		dropChance = 50, -- 0.05% (out of 100000)
		requiredLevel = 100,
		requiredVocation = {4, 8},
		lore = "Forged in the fires of a forgotten kingdom, this blade hungers for souls.",
	},
	[30701] = {
		name = "Shadowfang",
		type = "sword",
		baseAttack = 48,
		baseDefense = 32,
		effects = {
			{type = "on_hit", id = "poison_strike", value = 8,
				description = "8% chance to deal 100 earth damage"},
			{type = "passive", id = "critical_boost", value = 8,
				description = "+8% critical hit chance"},
		},
		dropFrom = {"Elite Serpent Spawn"},
		dropChance = 40,
		requiredLevel = 80,
		requiredVocation = {4, 8},
		lore = "The fangs of the shadow serpent, reforged into a deadly blade.",
	},
	[30702] = {
		name = "Dawnbreaker",
		type = "sword",
		baseAttack = 55,
		baseDefense = 30,
		effects = {
			{type = "on_hit", id = "holy_strike", value = 10,
				description = "10% chance to deal 150 holy damage"},
			{type = "passive", id = "berserk_boost", value = 10,
				description = "+10% damage when below 50% HP"},
		},
		dropFrom = {"Elite Undead Dragon"},
		dropChance = 30,
		requiredLevel = 130,
		requiredVocation = {4, 8},
		lore = "A blade blessed by the dawn, bane of all undead.",
	},

	-- WEAPONS: Axes (30710-30714)
	[30710] = {
		name = "Earthshatter",
		type = "axe",
		baseAttack = 54,
		baseDefense = 28,
		effects = {
			{type = "on_hit", id = "stun_strike", value = 5,
				description = "5% chance to stun target for 2 seconds"},
			{type = "passive", id = "strength_boost", value = 5,
				description = "+5 Strength"},
		},
		dropFrom = {"Elite Behemoth"},
		dropChance = 45,
		requiredLevel = 110,
		requiredVocation = {4, 8},
		lore = "This axe was carved from the bones of the earth itself.",
	},
	[30711] = {
		name = "Frostcleaver",
		type = "axe",
		baseAttack = 50,
		baseDefense = 34,
		effects = {
			{type = "on_hit", id = "ice_strike", value = 12,
				description = "12% chance to deal 80 ice damage and slow"},
			{type = "on_equip", id = "ice_resist", value = 10,
				description = "+10% ice resistance"},
		},
		dropFrom = {"Elite Frost Dragon"},
		dropChance = 35,
		requiredLevel = 120,
		requiredVocation = {4, 8},
		lore = "A frozen edge that never thaws, stolen from the lair of an ancient frost wyrm.",
	},

	-- WEAPONS: Clubs (30715-30719)
	[30715] = {
		name = "Thundermaul",
		type = "club",
		baseAttack = 53,
		baseDefense = 30,
		effects = {
			{type = "on_hit", id = "chain_lightning", value = 6,
				description = "6% chance to deal 120 energy damage to target and nearby enemies"},
			{type = "passive", id = "crushing_boost", value = 8,
				description = "+8% crushing blow chance"},
		},
		dropFrom = {"Elite Hydra"},
		dropChance = 40,
		requiredLevel = 100,
		requiredVocation = {4, 8},
		lore = "Lightning crackles along its surface, eager to be unleashed.",
	},
	[30716] = {
		name = "Bonecrusher",
		type = "club",
		baseAttack = 56,
		baseDefense = 25,
		effects = {
			{type = "on_hit", id = "armor_break", value = 15,
				description = "15% chance to reduce target armor by 20% for 5 seconds"},
			{type = "passive", id = "gauge_boost", value = 8,
				description = "+8% damage at full HP"},
		},
		dropFrom = {"Elite Giant Spider"},
		dropChance = 50,
		requiredLevel = 90,
		requiredVocation = {4, 8},
		lore = "Every strike echoes with the sound of shattering bone.",
	},

	-- WEAPONS: Distance (30720-30724)
	[30720] = {
		name = "Aetherbane Crossbow",
		type = "distance",
		baseAttack = 48,
		baseDefense = 0,
		effects = {
			{type = "on_hit", id = "mana_drain", value = 3,
				description = "3% chance to drain 50 mana from target"},
			{type = "passive", id = "critical_boost", value = 10,
				description = "+10% critical hit chance"},
		},
		dropFrom = {"Elite Dragon Lord"},
		dropChance = 30,
		requiredLevel = 150,
		requiredVocation = {3, 7},
		lore = "Bolts fired from this crossbow pierce not just flesh, but the arcane.",
	},
	[30721] = {
		name = "Windrunner Bow",
		type = "distance",
		baseAttack = 45,
		baseDefense = 0,
		effects = {
			{type = "on_equip", id = "speed_bonus", value = 25,
				description = "+25 movement speed"},
			{type = "passive", id = "dexterity_boost", value = 8,
				description = "+8 Dexterity"},
		},
		dropFrom = {"Elite Warlock"},
		dropChance = 35,
		requiredLevel = 120,
		requiredVocation = {3, 7},
		lore = "Crafted from the branches of the World Tree, light as the wind.",
	},

	-- WEAPONS: Wands (30725-30729)
	[30725] = {
		name = "Staff of the Void",
		type = "wand",
		baseAttack = 42,
		baseDefense = 15,
		effects = {
			{type = "on_hit", id = "void_burst", value = 8,
				description = "8% chance to deal 200 death damage"},
			{type = "passive", id = "intelligence_boost", value = 8,
				description = "+8 Intelligence"},
		},
		dropFrom = {"Elite Lich"},
		dropChance = 30,
		requiredLevel = 130,
		requiredVocation = {1, 2, 5, 6},
		lore = "Peers into the void between worlds and draws forth its power.",
	},
	[30726] = {
		name = "Phoenix Scepter",
		type = "wand",
		baseAttack = 38,
		baseDefense = 20,
		effects = {
			{type = "on_hit", id = "fire_burst", value = 10,
				description = "10% chance to deal 100 fire damage in area"},
			{type = "passive", id = "mana_regen", value = 5,
				description = "+5 mana regeneration per turn"},
		},
		dropFrom = {"Elite Dragon"},
		dropChance = 40,
		requiredLevel = 100,
		requiredVocation = {1, 2, 5, 6},
		lore = "Born from phoenix ashes, it burns eternally with arcane fire.",
	},

	-- ARMOR (30730-30739)
	[30730] = {
		name = "Dragonscale Cuirass",
		type = "armor",
		baseArmor = 18,
		effects = {
			{type = "on_equip", id = "fire_resist", value = 15,
				description = "+15% fire resistance"},
			{type = "on_equip", id = "hp_bonus", value = 150,
				description = "+150 max HP"},
		},
		dropFrom = {"Elite Dragon Lord"},
		dropChance = 25,
		requiredLevel = 120,
		requiredVocation = {4, 8},
		lore = "Forged from the scales of an ancient dragon lord.",
	},
	[30731] = {
		name = "Robes of the Archmage",
		type = "armor",
		baseArmor = 14,
		effects = {
			{type = "on_equip", id = "mana_bonus", value = 200,
				description = "+200 max mana"},
			{type = "passive", id = "spell_damage_boost", value = 8,
				description = "+8% spell damage"},
		},
		dropFrom = {"Elite Warlock"},
		dropChance = 30,
		requiredLevel = 100,
		requiredVocation = {1, 2, 5, 6},
		lore = "Woven from threads of pure mana by the last archmage.",
	},
	[30732] = {
		name = "Shadowveil Armor",
		type = "armor",
		baseArmor = 16,
		effects = {
			{type = "passive", id = "dodge_boost", value = 5,
				description = "+5% dodge chance"},
			{type = "on_equip", id = "speed_bonus", value = 10,
				description = "+10 movement speed"},
		},
		dropFrom = {"Elite Nightmare"},
		dropChance = 35,
		requiredLevel = 100,
		requiredVocation = {3, 4, 7, 8},
		lore = "Shadows cling to this armor, hiding its wearer from sight.",
	},

	-- SHIELDS (30740-30744)
	[30740] = {
		name = "Aegis of the Ancients",
		type = "shield",
		baseDefense = 42,
		effects = {
			{type = "on_equip", id = "all_resist", value = 5,
				description = "+5% all elemental resistance"},
			{type = "passive", id = "block_boost", value = 10,
				description = "+10% block chance"},
		},
		dropFrom = {"Elite Demon"},
		dropChance = 20,
		requiredLevel = 140,
		requiredVocation = {4, 8},
		lore = "Carried by the guardians of the ancient gates.",
	},
	[30741] = {
		name = "Bulwark of the Damned",
		type = "shield",
		baseDefense = 38,
		effects = {
			{type = "on_equip", id = "hp_bonus", value = 100,
				description = "+100 max HP"},
			{type = "passive", id = "reflect_damage", value = 5,
				description = "Reflects 5% of melee damage taken"},
		},
		dropFrom = {"Elite Hellhound"},
		dropChance = 40,
		requiredLevel = 100,
		requiredVocation = {4, 8},
		lore = "The screams of the damned echo from its surface.",
	},

	-- HELMETS (30745-30749)
	[30745] = {
		name = "Crown of the Lich King",
		type = "helmet",
		baseArmor = 10,
		effects = {
			{type = "on_equip", id = "mana_bonus", value = 150,
				description = "+150 max mana"},
			{type = "passive", id = "death_resist", value = 10,
				description = "+10% death resistance"},
		},
		dropFrom = {"Elite Lich"},
		dropChance = 25,
		requiredLevel = 120,
		requiredVocation = {1, 2, 5, 6},
		lore = "The phylactery of a lich king, reshaped into a crown of dark power.",
	},
	[30746] = {
		name = "Helm of the Berserker",
		type = "helmet",
		baseArmor = 12,
		effects = {
			{type = "passive", id = "berserk_boost", value = 15,
				description = "+15% damage when below 50% HP"},
			{type = "on_equip", id = "hp_bonus", value = 80,
				description = "+80 max HP"},
		},
		dropFrom = {"Elite Behemoth"},
		dropChance = 35,
		requiredLevel = 100,
		requiredVocation = {4, 8},
		lore = "Rage fuels the wearer, turning wounds into fury.",
	},

	-- BOOTS (30750-30754)
	[30750] = {
		name = "Boots of the Windwalker",
		type = "boots",
		baseArmor = 4,
		effects = {
			{type = "on_equip", id = "speed_bonus", value = 40,
				description = "+40 movement speed"},
			{type = "passive", id = "dodge_boost", value = 3,
				description = "+3% dodge chance"},
		},
		dropFrom = {"Elite Medusa"},
		dropChance = 30,
		requiredLevel = 100,
		requiredVocation = {1, 2, 3, 4, 5, 6, 7, 8},
		lore = "The wearer moves as swift as the wind itself.",
	},
	[30751] = {
		name = "Treads of the Juggernaut",
		type = "boots",
		baseArmor = 7,
		effects = {
			{type = "on_equip", id = "hp_bonus", value = 100,
				description = "+100 max HP"},
			{type = "passive", id = "knockback_immune", value = 1,
				description = "Immune to knockback effects"},
		},
		dropFrom = {"Elite Behemoth"},
		dropChance = 35,
		requiredLevel = 110,
		requiredVocation = {4, 8},
		lore = "Each step shakes the ground. Nothing can move the wearer.",
	},

	-- ACCESSORIES / RINGS (30755-30759)
	[30755] = {
		name = "Ring of the Phoenix",
		type = "ring",
		effects = {
			{type = "passive", id = "phoenix_revive", value = 1,
				description = "Once per hour: revive with 50% HP on death"},
			{type = "on_equip", id = "fire_resist", value = 8,
				description = "+8% fire resistance"},
		},
		dropFrom = {"Elite Dragon Lord"},
		dropChance = 15,
		requiredLevel = 150,
		requiredVocation = {1, 2, 3, 4, 5, 6, 7, 8},
		lore = "The eternal flame of the phoenix burns within this ring.",
	},
	[30756] = {
		name = "Band of the Vampire Lord",
		type = "ring",
		effects = {
			{type = "passive", id = "lifesteal_boost", value = 8,
				description = "+8% life leech on all attacks"},
			{type = "on_equip", id = "hp_bonus", value = 50,
				description = "+50 max HP"},
		},
		dropFrom = {"Elite Vampire Lord"},
		dropChance = 40,
		requiredLevel = 80,
		requiredVocation = {1, 2, 3, 4, 5, 6, 7, 8},
		lore = "Blood is the currency of power, and this ring is the bank.",
	},

	-- NECKLACES (30760-30764)
	[30760] = {
		name = "Amulet of the Arcane",
		type = "necklace",
		effects = {
			{type = "passive", id = "spell_damage_boost", value = 12,
				description = "+12% spell damage"},
			{type = "on_equip", id = "mana_bonus", value = 100,
				description = "+100 max mana"},
		},
		dropFrom = {"Elite Warlock"},
		dropChance = 25,
		requiredLevel = 130,
		requiredVocation = {1, 2, 5, 6},
		lore = "Channels raw arcane energy directly into the wearer's spells.",
	},
	[30761] = {
		name = "Talisman of Fortitude",
		type = "necklace",
		effects = {
			{type = "on_equip", id = "hp_bonus", value = 200,
				description = "+200 max HP"},
			{type = "passive", id = "damage_reduction", value = 3,
				description = "Reduces all incoming damage by 3%"},
		},
		dropFrom = {"Elite Demon"},
		dropChance = 20,
		requiredLevel = 150,
		requiredVocation = {1, 2, 3, 4, 5, 6, 7, 8},
		lore = "An ancient talisman that hardens the body and spirit.",
	},
}

-- ============================================================
-- Elite Monster System
-- ============================================================

LegendaryItems.elitePrefixes = {"Elite"}

LegendaryItems.eliteMultipliers = {
	health = 3,   -- 3x HP
	damage = 2,   -- 2x damage (applied via conditions in combat)
	experience = 2, -- 2x XP
}

LegendaryItems.eliteSpawnChance = 3  -- 3% chance a monster becomes elite

-- Build reverse lookup: monster name -> list of legendary item IDs
LegendaryItems.dropsByMonster = {}

function LegendaryItems.buildDropIndex()
	LegendaryItems.dropsByMonster = {}
	for itemId, data in pairs(LegendaryItems.items) do
		for _, monsterName in ipairs(data.dropFrom) do
			if not LegendaryItems.dropsByMonster[monsterName] then
				LegendaryItems.dropsByMonster[monsterName] = {}
			end
			table.insert(LegendaryItems.dropsByMonster[monsterName], {
				itemId = itemId,
				chance = data.dropChance,
			})
		end
	end
end

-- ============================================================
-- Elite Monster Creation
-- ============================================================

-- Transform a freshly spawned monster into an elite variant
-- Returns true if monster became elite
function LegendaryItems.tryMakeElite(monster)
	if not monster then return false end

	-- Check spawn chance
	if math.random(1, 100) > LegendaryItems.eliteSpawnChance then
		return false
	end

	local mType = monster:getType()
	if not mType then return false end

	-- Boost health
	local baseHP = mType:getMaxHealth()
	local newHP = baseHP * LegendaryItems.eliteMultipliers.health
	monster:setMaxHealth(newHP)
	monster:addHealth(newHP - baseHP)

	-- Visual indicator
	monster:setSkull(SKULL_RED)

	-- Mark as elite
	monster:setStorageValue(STORAGE_ELITE_MONSTER, 1)

	-- Broadcast to nearby players
	local pos = monster:getPosition()
	local spectators = Game.getSpectators(pos, false, true, 7, 7, 5, 5)
	for _, spectator in pairs(spectators) do
		spectator:sendTextMessage(MESSAGE_STATUS_WARNING,
			"An Elite " .. monster:getName() .. " has appeared!")
	end

	return true
end

-- Check if a monster is elite
function LegendaryItems.isElite(monster)
	return monster:getStorageValue(STORAGE_ELITE_MONSTER) == 1
end

-- ============================================================
-- Legendary Loot Rolling
-- ============================================================

-- Roll for a legendary drop from an elite monster
-- Returns item ID or nil
function LegendaryItems.rollLegendaryDrop(monster)
	if not LegendaryItems.isElite(monster) then
		return nil
	end

	local monsterName = "Elite " .. monster:getName()
	local drops = LegendaryItems.dropsByMonster[monsterName]
	if not drops then return nil end

	for _, drop in ipairs(drops) do
		-- dropChance is out of 100000 (e.g., 50 = 0.05%)
		if math.random(1, 100000) <= drop.chance then
			return drop.itemId
		end
	end

	return nil
end

-- Add a legendary item to a corpse
function LegendaryItems.addLegendaryToCorpse(corpse, itemId)
	local legendaryData = LegendaryItems.items[itemId]
	if not legendaryData then return nil end

	local item = corpse:addItem(itemId, 1)
	if not item then return nil end

	-- Set custom attributes to mark as legendary
	item:setCustomAttribute("legendary", 1)
	item:setCustomAttribute("legendary_id", itemId)

	-- Set the item name
	item:setAttribute(ITEM_ATTRIBUTE_NAME, legendaryData.name)

	-- Build description from effects
	local effectDescs = {}
	for _, effect in ipairs(legendaryData.effects) do
		table.insert(effectDescs, effect.description)
	end
	local desc = "[Legendary]\n" .. table.concat(effectDescs, "\n")
	if legendaryData.lore then
		desc = desc .. "\n\"" .. legendaryData.lore .. "\""
	end
	item:setSpecialDescription(desc)

	return item
end

-- ============================================================
-- Legendary Effect Processing
-- ============================================================

-- Process on-hit legendary effects during combat
function LegendaryItems.processOnHitEffects(player, target, damage)
	if not player or not target then return damage end

	-- Check weapon
	local weapon = player:getSlotItem(CONST_SLOT_LEFT) or player:getSlotItem(CONST_SLOT_RIGHT)
	if not weapon then return damage end

	local legendaryId = weapon:getCustomAttribute("legendary_id")
	if not legendaryId then return damage end

	local legendary = LegendaryItems.items[tonumber(legendaryId)]
	if not legendary then return damage end

	for _, effect in ipairs(legendary.effects) do
		if effect.type == "on_hit" then
			damage = LegendaryItems.applyOnHitEffect(player, target, damage, effect)
		end
	end

	return damage
end

-- Apply a single on-hit effect
function LegendaryItems.applyOnHitEffect(player, target, damage, effect)
	if effect.id == "lifedrain" then
		local healAmount = math.floor(math.abs(damage) * effect.value / 100)
		if healAmount > 0 then
			player:addHealth(healAmount)
		end
	elseif effect.id == "poison_strike" then
		if math.random(1, 100) <= effect.value then
			doTargetCombatHealth(player, target, COMBAT_EARTHDAMAGE, -100, -100, CONST_ME_SMALLPLANTS)
		end
	elseif effect.id == "holy_strike" then
		if math.random(1, 100) <= effect.value then
			doTargetCombatHealth(player, target, COMBAT_HOLYDAMAGE, -150, -150, CONST_ME_HOLYDAMAGE)
		end
	elseif effect.id == "stun_strike" then
		if math.random(1, 100) <= effect.value then
			local condition = Condition(CONDITION_PARALYZE)
			condition:setParameter(CONDITION_PARAM_TICKS, 2000)
			condition:setParameter(CONDITION_PARAM_SPEED, -100)
			target:addCondition(condition)
		end
	elseif effect.id == "ice_strike" then
		if math.random(1, 100) <= effect.value then
			doTargetCombatHealth(player, target, COMBAT_ICEDAMAGE, -80, -80, CONST_ME_ICEAREA)
			local condition = Condition(CONDITION_PARALYZE)
			condition:setParameter(CONDITION_PARAM_TICKS, 3000)
			condition:setParameter(CONDITION_PARAM_SPEED, -50)
			target:addCondition(condition)
		end
	elseif effect.id == "chain_lightning" then
		if math.random(1, 100) <= effect.value then
			doTargetCombatHealth(player, target, COMBAT_ENERGYDAMAGE, -120, -120, CONST_ME_ENERGYHIT)
		end
	elseif effect.id == "armor_break" then
		if math.random(1, 100) <= effect.value then
			local condition = Condition(CONDITION_ATTRIBUTES)
			condition:setParameter(CONDITION_PARAM_TICKS, 5000)
			condition:setParameter(CONDITION_PARAM_SKILL_SHIELDPERCENT, 80)
			target:addCondition(condition)
		end
	elseif effect.id == "mana_drain" then
		if math.random(1, 100) <= effect.value then
			local targetCreature = target
			if targetCreature then
				targetCreature:addMana(-50)
				player:addMana(50)
				target:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			end
		end
	elseif effect.id == "void_burst" then
		if math.random(1, 100) <= effect.value then
			doTargetCombatHealth(player, target, COMBAT_DEATHDAMAGE, -200, -200, CONST_ME_MORTAREA)
		end
	elseif effect.id == "fire_burst" then
		if math.random(1, 100) <= effect.value then
			doTargetCombatHealth(player, target, COMBAT_FIREDAMAGE, -100, -100, CONST_ME_FIREAREA)
		end
	end

	return damage
end

-- Apply on-equip legendary effects
function LegendaryItems.onEquip(player, item)
	local legendaryId = item:getCustomAttribute("legendary_id")
	if not legendaryId then return end

	local legendary = LegendaryItems.items[tonumber(legendaryId)]
	if not legendary then return end

	for _, effect in ipairs(legendary.effects) do
		if effect.type == "on_equip" or effect.type == "passive" then
			LegendaryItems.applyEquipEffect(player, effect, true)
		end
	end
end

-- Remove on-equip legendary effects
function LegendaryItems.onDeEquip(player, item)
	local legendaryId = item:getCustomAttribute("legendary_id")
	if not legendaryId then return end

	local legendary = LegendaryItems.items[tonumber(legendaryId)]
	if not legendary then return end

	for _, effect in ipairs(legendary.effects) do
		if effect.type == "on_equip" or effect.type == "passive" then
			LegendaryItems.applyEquipEffect(player, effect, false)
		end
	end
end

-- Apply or remove a single equip/passive effect
function LegendaryItems.applyEquipEffect(player, effect, equipping)
	if effect.id == "speed_bonus" then
		if equipping then
			local condition = Condition(CONDITION_SPEED)
			condition:setTicks(-1)
			condition:setParameter(CONDITION_PARAM_SPEED, effect.value)
			condition:setParameter(CONDITION_PARAM_SUBID, STORAGE_LEGENDARY_SPEED)
			player:addCondition(condition)
		else
			player:removeCondition(CONDITION_SPEED, CONDITIONID_DEFAULT, STORAGE_LEGENDARY_SPEED)
		end
	elseif effect.id == "hp_bonus" then
		if equipping then
			player:setMaxHealth(player:getMaxHealth() + effect.value)
			player:addHealth(effect.value)
		else
			player:setMaxHealth(math.max(1, player:getMaxHealth() - effect.value))
		end
	elseif effect.id == "mana_bonus" then
		if equipping then
			player:setMaxMana(player:getMaxMana() + effect.value)
			player:addMana(effect.value)
		else
			player:setMaxMana(math.max(0, player:getMaxMana() - effect.value))
		end
	elseif effect.id == "fire_resist" or effect.id == "ice_resist" or
	       effect.id == "all_resist" or effect.id == "death_resist" then
		-- Stored as custom attributes on player for combat system to read
		local key = "legendary_" .. effect.id
		if equipping then
			local current = player:getStorageValue(key) or 0
			player:setStorageValue(key, current + effect.value)
		else
			local current = player:getStorageValue(key) or 0
			player:setStorageValue(key, math.max(0, current - effect.value))
		end
	elseif effect.id == "critical_boost" then
		if equipping then
			player:setStorageValue(STORAGE_LEGENDARY_CRIT, effect.value)
		else
			player:setStorageValue(STORAGE_LEGENDARY_CRIT, 0)
		end
	end
end

-- ============================================================
-- Get passive bonus values for combat calculations
-- ============================================================

function LegendaryItems.getPassiveBonus(player, bonusId)
	local total = 0

	-- Check all equipment slots
	for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
		local item = player:getSlotItem(slot)
		if item then
			local legendaryId = item:getCustomAttribute("legendary_id")
			if legendaryId then
				local legendary = LegendaryItems.items[tonumber(legendaryId)]
				if legendary then
					for _, effect in ipairs(legendary.effects) do
						if effect.type == "passive" and effect.id == bonusId then
							total = total + effect.value
						end
					end
				end
			end
		end
	end

	return total
end

-- Get legendary item info for display
function LegendaryItems.getInfo(itemId)
	return LegendaryItems.items[itemId]
end

-- Check if an item is legendary
function LegendaryItems.isLegendary(item)
	local val = item:getCustomAttribute("legendary")
	return val and tonumber(val) == 1
end

-- Initialize the drop index
LegendaryItems.buildDropIndex()

print("[Phase 3] Legendary Items system loaded (" .. #(function()
	local count = 0
	for _ in pairs(LegendaryItems.items) do count = count + 1 end
	local t = {}
	for i = 1, count do t[i] = i end
	return t
end)() .. " items).")
