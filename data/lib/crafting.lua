-- Shared Crafting Framework Library
-- Used by all crafting systems: Cooking, Fishing, Mining, Smithing, Farming, Enchanting
-- Phase 2 implementation per docs/phase2-crafting-overview.md

Crafting = {}

-- Storage key base for crafting skill levels (using player storage values)
-- Cooking: 40001, Mining: 40002, Smithing: 40003, Farming: 40004, Enchanting: 40005
Crafting.STORAGE_SKILL_BASE = 40000
Crafting.SKILL_COOKING   = 1
Crafting.SKILL_MINING    = 2
Crafting.SKILL_SMITHING  = 3
Crafting.SKILL_FARMING   = 4
Crafting.SKILL_ENCHANTING = 5

-- Storage key for crafting XP (tracks tries toward next level)
Crafting.STORAGE_XP_BASE = 40100

-- Storage key for active food buff tracking
Crafting.STORAGE_FOOD_BUFF = 40200

-- Skill names for display
Crafting.SKILL_NAMES = {
	[1] = "Cooking",
	[2] = "Mining",
	[3] = "Smithing",
	[4] = "Farming",
	[5] = "Enchanting",
}

-- Recipe registries (populated by each system)
Crafting.recipes = {
	cooking = {},
	fishing = {},
	mining = {},
	smithing = {},
	farming = {},
	enchanting = {},
}

-- Progression curve: tries needed per level
-- Uses base=30, multiplier=1.1 as specified in phase2 doc
Crafting.SKILL_BASE = 30
Crafting.SKILL_MULTIPLIER = 1.1

-- ============================================================================
-- Skill Management
-- ============================================================================

function Crafting.getSkillLevel(player, skillId)
	local key = Crafting.STORAGE_SKILL_BASE + skillId
	local level = player:getStorageValue(key)
	if level < 1 then
		return 1
	end
	return level
end

function Crafting.setSkillLevel(player, skillId, level)
	local key = Crafting.STORAGE_SKILL_BASE + skillId
	player:setStorageValue(key, level)
end

function Crafting.getSkillTries(player, skillId)
	local key = Crafting.STORAGE_XP_BASE + skillId
	local tries = player:getStorageValue(key)
	if tries < 0 then
		return 0
	end
	return tries
end

function Crafting.setSkillTries(player, skillId, tries)
	local key = Crafting.STORAGE_XP_BASE + skillId
	player:setStorageValue(key, tries)
end

function Crafting.getTriesForLevel(level)
	if level <= 1 then
		return 0
	end
	return math.floor(Crafting.SKILL_BASE * math.pow(Crafting.SKILL_MULTIPLIER, level - 1))
end

function Crafting.getSkillName(skillId)
	return Crafting.SKILL_NAMES[skillId] or "Unknown"
end

-- Add skill tries and handle level-ups
function Crafting.addSkillTries(player, skillId, tries)
	local currentLevel = Crafting.getSkillLevel(player, skillId)
	local currentTries = Crafting.getSkillTries(player, skillId) + tries
	local neededTries = Crafting.getTriesForLevel(currentLevel + 1)

	while currentTries >= neededTries and currentLevel < 100 do
		currentTries = currentTries - neededTries
		currentLevel = currentLevel + 1
		neededTries = Crafting.getTriesForLevel(currentLevel + 1)

		local skillName = Crafting.getSkillName(skillId)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
			"You advanced to " .. skillName .. " level " .. currentLevel .. ".")
		player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
	end

	Crafting.setSkillLevel(player, skillId, currentLevel)
	Crafting.setSkillTries(player, skillId, currentTries)
end

-- ============================================================================
-- Recipe Registration
-- ============================================================================

function Crafting.registerRecipe(system, recipe)
	if not Crafting.recipes[system] then
		Crafting.recipes[system] = {}
	end

	-- Apply defaults for optional fields
	recipe.system = system
	recipe.tools = recipe.tools or {}
	recipe.requiredVocation = recipe.requiredVocation or {}
	recipe.failSkillTries = recipe.failSkillTries or math.floor((recipe.skillTries or 1) / 3)
	recipe.successChance = recipe.successChance or 80
	recipe.skillBonusPerLevel = recipe.skillBonusPerLevel or 2
	recipe.maxSuccessChance = recipe.maxSuccessChance or 100
	recipe.craftTime = recipe.craftTime or 1000

	table.insert(Crafting.recipes[system], recipe)
	return recipe
end

-- ============================================================================
-- Ingredient Validation
-- ============================================================================

function Crafting.hasIngredients(player, recipe)
	for _, ingredient in ipairs(recipe.ingredients) do
		if player:getItemCount(ingredient[1]) < ingredient[2] then
			return false
		end
	end
	return true
end

function Crafting.hasTools(player, recipe)
	for _, tool in ipairs(recipe.tools) do
		if player:getItemCount(tool[1]) < 1 then
			return false
		end
	end
	return true
end

function Crafting.checkVocation(player, recipe)
	if #recipe.requiredVocation == 0 then
		return true
	end
	local vocId = player:getVocation():getBaseId()
	for _, v in ipairs(recipe.requiredVocation) do
		if v == vocId then
			return true
		end
	end
	return false
end

-- ============================================================================
-- Skill Check
-- ============================================================================

function Crafting.meetsSkillRequirement(player, recipe)
	local level = Crafting.getSkillLevel(player, recipe.craftingSkill)
	return level >= recipe.requiredSkillLevel
end

-- ============================================================================
-- Success/Failure Calculation
-- ============================================================================

function Crafting.calculateSuccessChance(player, recipe)
	local skillLevel = Crafting.getSkillLevel(player, recipe.craftingSkill)
	local bonusLevels = math.max(0, skillLevel - recipe.requiredSkillLevel)
	local chance = recipe.successChance + (bonusLevels * recipe.skillBonusPerLevel)
	return math.min(recipe.maxSuccessChance, math.max(0, chance))
end

function Crafting.rollSuccess(player, recipe)
	local chance = Crafting.calculateSuccessChance(player, recipe)
	return math.random(1, 100) <= chance
end

-- ============================================================================
-- Core Crafting Attempt
-- ============================================================================

function Crafting.attempt(player, recipe)
	-- 1. Check skill level
	if not Crafting.meetsSkillRequirement(player, recipe) then
		local skillName = Crafting.getSkillName(recipe.craftingSkill)
		player:sendCancelMessage("You need " .. skillName ..
			" level " .. recipe.requiredSkillLevel .. " to craft " .. recipe.name .. ".")
		return false, "skill"
	end

	-- 2. Check vocation
	if not Crafting.checkVocation(player, recipe) then
		player:sendCancelMessage("Your vocation cannot craft this.")
		return false, "vocation"
	end

	-- 3. Check ingredients
	if not Crafting.hasIngredients(player, recipe) then
		player:sendCancelMessage("You don't have enough ingredients to make " .. recipe.name .. ".")
		return false, "ingredients"
	end

	-- 4. Check tools
	if not Crafting.hasTools(player, recipe) then
		player:sendCancelMessage("You need the right tools to craft this.")
		return false, "tools"
	end

	-- 5. Consume ingredients
	for _, ingredient in ipairs(recipe.ingredients) do
		player:removeItem(ingredient[1], ingredient[2])
	end

	-- 6. Consume tools if applicable
	for _, tool in ipairs(recipe.tools) do
		if tool.consumeOnUse then
			player:removeItem(tool[1], 1)
		end
	end

	-- 7. Roll for success
	if Crafting.rollSuccess(player, recipe) then
		-- Success: give results
		for _, result in ipairs(recipe.results) do
			local chance = result[3] or 100
			if math.random(1, 100) <= chance then
				player:addItem(result[1], result[2])
			end
		end
		Crafting.addSkillTries(player, recipe.craftingSkill, recipe.skillTries)
		return true, "success"
	else
		-- Failure: partial XP
		Crafting.addSkillTries(player, recipe.craftingSkill, recipe.failSkillTries)
		return false, "failed"
	end
end

-- ============================================================================
-- Recipe Lookup Utilities
-- ============================================================================

function Crafting.findRecipeByName(system, name)
	for _, recipe in ipairs(Crafting.recipes[system] or {}) do
		if recipe.name:lower() == name:lower() then
			return recipe
		end
	end
	return nil
end

function Crafting.findRecipeById(system, id)
	for _, recipe in ipairs(Crafting.recipes[system] or {}) do
		if recipe.id == id then
			return recipe
		end
	end
	return nil
end

function Crafting.findRecipeByResult(system, itemId)
	for _, recipe in ipairs(Crafting.recipes[system] or {}) do
		for _, result in ipairs(recipe.results) do
			if result[1] == itemId then
				return recipe
			end
		end
	end
	return nil
end

function Crafting.getAvailableRecipes(player, system)
	local available = {}
	for _, recipe in ipairs(Crafting.recipes[system] or {}) do
		local level = Crafting.getSkillLevel(player, recipe.craftingSkill)
		if level >= recipe.requiredSkillLevel then
			table.insert(available, recipe)
		end
	end
	return available
end

-- Get all recipes that can be made at a specific station
function Crafting.getRecipesForStation(system, stationItemId)
	local recipes = {}
	for _, recipe in ipairs(Crafting.recipes[system] or {}) do
		if recipe.stationItemId == stationItemId then
			table.insert(recipes, recipe)
		end
	end
	return recipes
end

-- Format a recipe's ingredient list for display
function Crafting.formatIngredients(recipe)
	local parts = {}
	for _, ingredient in ipairs(recipe.ingredients) do
		local itemType = ItemType(ingredient[1])
		local name = itemType and itemType:getName() or ("item #" .. ingredient[1])
		if ingredient[2] > 1 then
			name = ingredient[2] .. "x " .. name
		end
		table.insert(parts, name)
	end
	return table.concat(parts, ", ")
end
