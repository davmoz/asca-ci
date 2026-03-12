-- ============================================================================
-- Achievement System (Phase 4)
-- ============================================================================
-- Extends the existing achievements table in data/lib/core/achievements.lua
-- with 100+ new achievements across Combat, Exploration, Crafting, Social,
-- and Quest categories.
--
-- Also provides a title system: players earn titles and can display them.
--
-- Storage layout:
--   55000        selected title index
--   55001-55200  achievement unlock flags (1 = unlocked) for custom achievements
--   55201        total custom achievement points
--   300000+      base game achievements (existing system)
-- ============================================================================

AchievementSystem = {}

-- ============================================================================
-- Constants
-- ============================================================================

AchievementSystem.STORAGE_TITLE       = 55000
AchievementSystem.STORAGE_ACH_BASE    = 55001
AchievementSystem.STORAGE_ACH_POINTS  = 55201

-- Categories
AchievementSystem.CAT_COMBAT      = "Combat"
AchievementSystem.CAT_EXPLORATION = "Exploration"
AchievementSystem.CAT_CRAFTING    = "Crafting"
AchievementSystem.CAT_SOCIAL      = "Social"
AchievementSystem.CAT_QUESTS      = "Quests"
AchievementSystem.CAT_BESTIARY    = "Bestiary"
AchievementSystem.CAT_TASKS       = "Tasks"
AchievementSystem.CAT_GENERAL     = "General"

-- ============================================================================
-- Title Definitions
-- ============================================================================

AchievementSystem.titles = {
	[1]  = {name = "Novice Hunter",        requirement = "Complete 5 tasks"},
	[2]  = {name = "Seasoned Hunter",      requirement = "Complete 15 tasks"},
	[3]  = {name = "Master Hunter",        requirement = "Complete 30 tasks"},
	[4]  = {name = "Grand Master Hunter",  requirement = "Complete 50 tasks"},
	[5]  = {name = "Beast Scholar",        requirement = "Unlock 10 bestiary entries"},
	[6]  = {name = "Beast Expert",         requirement = "Unlock 30 bestiary entries"},
	[7]  = {name = "Beast Master",         requirement = "Complete 20 bestiary entries"},
	[8]  = {name = "Dragon Slayer",        requirement = "Kill 500 dragons"},
	[9]  = {name = "Demon Bane",           requirement = "Kill 500 demons"},
	[10] = {name = "The Relentless",       requirement = "Earn 100 task points"},
	[11] = {name = "Artisan",              requirement = "Reach skill level 50 in any craft"},
	[12] = {name = "Centurion",            requirement = "Reach level 100"},
	[13] = {name = "Warlord",              requirement = "Reach level 200"},
	[14] = {name = "Legend",               requirement = "Reach level 300"},
	[15] = {name = "Completionist",        requirement = "Earn 500 achievement points"},
}

-- ============================================================================
-- Achievement Definitions (100+ custom achievements)
-- ============================================================================
-- Fields: id, name, description, category, points, titleReward (optional),
--         itemReward (optional: {id, count})

AchievementSystem.customAchievements = {
	-- ========================================================================
	-- COMBAT (1-25)
	-- ========================================================================
	{id = 1,  name = "First Blood",           category = "Combat",      points = 1,  description = "Kill your first monster."},
	{id = 2,  name = "Hundred Kills",          category = "Combat",      points = 2,  description = "Kill 100 monsters."},
	{id = 3,  name = "Thousand Kills",         category = "Combat",      points = 3,  description = "Kill 1,000 monsters."},
	{id = 4,  name = "Ten Thousand Kills",     category = "Combat",      points = 5,  description = "Kill 10,000 monsters."},
	{id = 5,  name = "Rat Catcher",            category = "Combat",      points = 1,  description = "Kill 100 rats."},
	{id = 6,  name = "Spider Stomper",         category = "Combat",      points = 1,  description = "Kill 100 spiders."},
	{id = 7,  name = "Orc Slayer",             category = "Combat",      points = 2,  description = "Kill 200 orcs."},
	{id = 8,  name = "Undead Purifier",        category = "Combat",      points = 2,  description = "Kill 200 skeletons."},
	{id = 9,  name = "Dragon Hunter",          category = "Combat",      points = 3,  description = "Kill 100 dragons."},
	{id = 10, name = "Dragon Lord Vanquisher", category = "Combat",      points = 4,  description = "Kill 100 dragon lords."},
	{id = 11, name = "Demonologist",           category = "Combat",      points = 5,  description = "Kill 100 demons."},
	{id = 12, name = "Grim Determination",     category = "Combat",      points = 5,  description = "Kill 100 grim reapers."},
	{id = 13, name = "Hydra Slayer",           category = "Combat",      points = 3,  description = "Kill 100 hydras."},
	{id = 14, name = "Warlock Breaker",        category = "Combat",      points = 4,  description = "Kill 100 warlocks."},
	{id = 15, name = "Behemoth Toppler",       category = "Combat",      points = 4,  description = "Kill 100 behemoths."},
	{id = 16, name = "Nightmare Ender",        category = "Combat",      points = 3,  description = "Kill 100 nightmares."},
	{id = 17, name = "Hellhound Tamer",        category = "Combat",      points = 4,  description = "Kill 100 hellhounds."},
	{id = 18, name = "Juggernaut Breaker",     category = "Combat",      points = 5,  description = "Kill 50 juggernauts."},
	{id = 19, name = "Boss Killer",            category = "Combat",      points = 5,  description = "Kill 10 different bosses."},
	{id = 20, name = "Survivor",               category = "Combat",      points = 2,  description = "Reach level 50 without dying."},
	{id = 21, name = "Fury Fighter",           category = "Combat",      points = 4,  description = "Kill 100 furies."},
	{id = 22, name = "Medusa Gazer",           category = "Combat",      points = 3,  description = "Kill 100 medusas."},
	{id = 23, name = "Wyrm Rider",             category = "Combat",      points = 3,  description = "Kill 100 wyrms."},
	{id = 24, name = "Giant Spider Squisher",  category = "Combat",      points = 3,  description = "Kill 200 giant spiders."},
	{id = 25, name = "Vampire Hunter",         category = "Combat",      points = 3,  description = "Kill 200 vampires."},

	-- ========================================================================
	-- EXPLORATION (26-45)
	-- ========================================================================
	{id = 26, name = "World Traveler",         category = "Exploration",  points = 2,  description = "Visit 10 different cities."},
	{id = 27, name = "Deep Diver",             category = "Exploration",  points = 3,  description = "Explore the deepest caves."},
	{id = 28, name = "Mountain Climber",       category = "Exploration",  points = 2,  description = "Reach the highest peaks."},
	{id = 29, name = "Desert Walker",          category = "Exploration",  points = 2,  description = "Cross the great desert."},
	{id = 30, name = "Ice Explorer",           category = "Exploration",  points = 2,  description = "Explore the frozen north."},
	{id = 31, name = "Jungle Survivor",        category = "Exploration",  points = 2,  description = "Survive the deep jungle."},
	{id = 32, name = "Tomb Raider",            category = "Exploration",  points = 3,  description = "Explore the ancient tombs."},
	{id = 33, name = "Dungeon Delver",         category = "Exploration",  points = 3,  description = "Explore 20 different dungeons."},
	{id = 34, name = "Island Hopper",          category = "Exploration",  points = 2,  description = "Visit 5 different islands."},
	{id = 35, name = "Cartographer",           category = "Exploration",  points = 4,  description = "Discover all major map areas."},
	{id = 36, name = "Secret Finder",          category = "Exploration",  points = 3,  description = "Find 10 hidden areas."},
	{id = 37, name = "Cave Explorer",          category = "Exploration",  points = 2,  description = "Explore 15 different caves."},
	{id = 38, name = "Lighthouse Keeper",      category = "Exploration",  points = 1,  description = "Visit all lighthouses."},
	{id = 39, name = "Bridge Builder",         category = "Exploration",  points = 2,  description = "Cross 10 different bridges."},
	{id = 40, name = "Seaside Stroller",       category = "Exploration",  points = 1,  description = "Walk along every coastline."},
	{id = 41, name = "Underworld Explorer",    category = "Exploration",  points = 4,  description = "Reach the deepest level of the underworld."},
	{id = 42, name = "High Ground",            category = "Exploration",  points = 2,  description = "Stand atop the tallest tower."},
	{id = 43, name = "Swamp Walker",           category = "Exploration",  points = 2,  description = "Traverse the poisonous swamps."},
	{id = 44, name = "Graveyard Shift",        category = "Exploration",  points = 2,  description = "Visit every graveyard at night."},
	{id = 45, name = "Portal Hopper",          category = "Exploration",  points = 3,  description = "Use 10 different teleportation portals."},

	-- ========================================================================
	-- CRAFTING (46-65)
	-- ========================================================================
	{id = 46, name = "Apprentice Cook",        category = "Crafting",     points = 1,  description = "Cook your first meal."},
	{id = 47, name = "Master Chef",            category = "Crafting",     points = 3,  description = "Cook 50 different recipes."},
	{id = 48, name = "Ore Miner",              category = "Crafting",     points = 1,  description = "Mine your first ore."},
	{id = 49, name = "Deep Miner",             category = "Crafting",     points = 3,  description = "Mine 500 ores total."},
	{id = 50, name = "Apprentice Smith",       category = "Crafting",     points = 1,  description = "Forge your first item."},
	{id = 51, name = "Master Smith",           category = "Crafting",     points = 4,  description = "Forge 100 items."},
	{id = 52, name = "Enchantment Novice",     category = "Crafting",     points = 1,  description = "Enchant your first item."},
	{id = 53, name = "Enchantment Master",     category = "Crafting",     points = 4,  description = "Enchant 50 items."},
	{id = 54, name = "Green Thumb",            category = "Crafting",     points = 1,  description = "Harvest your first crop."},
	{id = 55, name = "Farmer Extraordinaire",  category = "Crafting",     points = 3,  description = "Harvest 200 crops."},
	{id = 56, name = "Jack of All Trades",     category = "Crafting",     points = 5,  description = "Reach skill level 10 in all crafting skills."},
	{id = 57, name = "Renaissance Crafter",    category = "Crafting",     points = 5,  description = "Reach skill level 25 in all crafting skills."},
	{id = 58, name = "Potion Brewer",          category = "Crafting",     points = 2,  description = "Brew 50 potions."},
	{id = 59, name = "Legendary Forger",       category = "Crafting",     points = 5,  description = "Forge a legendary quality item."},
	{id = 60, name = "Iron Worker",            category = "Crafting",     points = 2,  description = "Smelt 100 iron bars."},
	{id = 61, name = "Gold Digger",            category = "Crafting",     points = 3,  description = "Mine 50 gold ores."},
	{id = 62, name = "Diamond Hands",          category = "Crafting",     points = 4,  description = "Mine 10 diamonds."},
	{id = 63, name = "Master Enchanter",       category = "Crafting",     points = 5,  description = "Reach enchanting skill level 50."},
	{id = 64, name = "Master Farmer",          category = "Crafting",     points = 4,  description = "Reach farming skill level 50."},
	{id = 65, name = "Master Miner",           category = "Crafting",     points = 4,  description = "Reach mining skill level 50."},

	-- ========================================================================
	-- SOCIAL (66-80)
	-- ========================================================================
	{id = 66, name = "Friendly",               category = "Social",       points = 1,  description = "Add 5 players to your VIP list."},
	{id = 67, name = "Social Butterfly",       category = "Social",       points = 2,  description = "Add 20 players to your VIP list."},
	{id = 68, name = "Guild Member",           category = "Social",       points = 2,  description = "Join a guild."},
	{id = 69, name = "Guild Leader",           category = "Social",       points = 3,  description = "Become a guild leader."},
	{id = 70, name = "Trader",                 category = "Social",       points = 1,  description = "Complete your first trade."},
	{id = 71, name = "Merchant Prince",        category = "Social",       points = 3,  description = "Complete 100 trades."},
	{id = 72, name = "Homeowner",              category = "Social",       points = 2,  description = "Buy a house."},
	{id = 73, name = "Party Animal",           category = "Social",       points = 2,  description = "Be in a party of 5 or more."},
	{id = 74, name = "Wedding Bells",          category = "Social",       points = 2,  description = "Attend a wedding ceremony."},
	{id = 75, name = "Veteran",                category = "Social",       points = 3,  description = "Play for 100 hours total."},
	{id = 76, name = "Dedicated Player",       category = "Social",       points = 4,  description = "Play for 500 hours total."},
	{id = 77, name = "Mentor",                 category = "Social",       points = 3,  description = "Help 10 new players."},
	{id = 78, name = "Philanthropist",         category = "Social",       points = 3,  description = "Donate 100,000 gold to other players."},
	{id = 79, name = "Famous",                 category = "Social",       points = 2,  description = "Receive 50 player commendations."},
	{id = 80, name = "Loyal Subject",          category = "Social",       points = 2,  description = "Log in for 30 consecutive days."},

	-- ========================================================================
	-- QUESTS (81-95)
	-- ========================================================================
	{id = 81, name = "Quest Rookie",           category = "Quests",       points = 1,  description = "Complete your first quest."},
	{id = 82, name = "Quest Veteran",          category = "Quests",       points = 3,  description = "Complete 25 quests."},
	{id = 83, name = "Quest Master",           category = "Quests",       points = 5,  description = "Complete 50 quests."},
	{id = 84, name = "Annihilator Champion",   category = "Quests",       points = 5,  description = "Complete the Annihilator quest."},
	{id = 85, name = "Demon Oak Slayer",       category = "Quests",       points = 5,  description = "Complete the Demon Oak quest."},
	{id = 86, name = "Inquisitor",             category = "Quests",       points = 4,  description = "Complete the Inquisition quest."},
	{id = 87, name = "Wrath of the Emperor",   category = "Quests",       points = 5,  description = "Complete the Wrath of the Emperor quest."},
	{id = 88, name = "Children of the Revolution", category = "Quests",   points = 4,  description = "Complete the Children of the Revolution quest."},
	{id = 89, name = "Realm Unifier",          category = "Quests",       points = 4,  description = "Complete the Realm Unification quest."},
	{id = 90, name = "Treasure Seeker",        category = "Quests",       points = 2,  description = "Open 50 treasure chests."},
	{id = 91, name = "Key Collector",          category = "Quests",       points = 3,  description = "Collect 20 different keys."},
	{id = 92, name = "Lore Keeper",            category = "Quests",       points = 3,  description = "Read 50 books and scrolls."},
	{id = 93, name = "NPC Whisperer",          category = "Quests",       points = 2,  description = "Talk to 100 different NPCs."},
	{id = 94, name = "Djinn Friend",           category = "Quests",       points = 3,  description = "Complete both djinn quest lines."},
	{id = 95, name = "Postman",                category = "Quests",       points = 2,  description = "Complete the postman quest."},

	-- ========================================================================
	-- BESTIARY & TASKS (96-115)
	-- ========================================================================
	{id = 96,  name = "Bestiary Beginner",      category = "Bestiary",    points = 1,  description = "Unlock your first bestiary entry."},
	{id = 97,  name = "Bestiary Scholar",        category = "Bestiary",    points = 2,  description = "Unlock 10 bestiary entries to Basic tier."},
	{id = 98,  name = "Bestiary Expert",         category = "Bestiary",    points = 3,  description = "Unlock 10 bestiary entries to Detailed tier."},
	{id = 99,  name = "Bestiary Master",         category = "Bestiary",    points = 5,  description = "Unlock 10 bestiary entries to Complete tier."},
	{id = 100, name = "Charm Collector",         category = "Bestiary",    points = 3,  description = "Earn 50 charm points."},
	{id = 101, name = "Charm Hoarder",           category = "Bestiary",    points = 5,  description = "Earn 200 charm points."},
	{id = 102, name = "Task Beginner",           category = "Tasks",       points = 1,  description = "Complete your first task."},
	{id = 103, name = "Task Worker",             category = "Tasks",       points = 2,  description = "Complete 5 tasks."},
	{id = 104, name = "Task Veteran",            category = "Tasks",       points = 3,  description = "Complete 15 tasks."},
	{id = 105, name = "Task Master",             category = "Tasks",       points = 5,  description = "Complete 30 tasks."},
	{id = 106, name = "Task Legend",             category = "Tasks",       points = 8,  description = "Complete all 55 tasks.", titleReward = 4},
	{id = 107, name = "Point Collector",         category = "Tasks",       points = 2,  description = "Earn 25 task points."},
	{id = 108, name = "Point Hoarder",           category = "Tasks",       points = 4,  description = "Earn 100 task points.", titleReward = 10},
	{id = 109, name = "Boss Hunter",             category = "Tasks",       points = 5,  description = "Complete all boss tasks."},
	{id = 110, name = "Gathering Expert",        category = "Tasks",       points = 3,  description = "Complete all gathering tasks."},

	-- ========================================================================
	-- GENERAL / MILESTONES (111-125)
	-- ========================================================================
	{id = 111, name = "Level 10",                category = "General",     points = 1,  description = "Reach level 10."},
	{id = 112, name = "Level 25",                category = "General",     points = 1,  description = "Reach level 25."},
	{id = 113, name = "Level 50",                category = "General",     points = 2,  description = "Reach level 50."},
	{id = 114, name = "Level 100",               category = "General",     points = 3,  description = "Reach level 100.", titleReward = 12},
	{id = 115, name = "Level 150",               category = "General",     points = 4,  description = "Reach level 150."},
	{id = 116, name = "Level 200",               category = "General",     points = 5,  description = "Reach level 200.", titleReward = 13},
	{id = 117, name = "Level 300",               category = "General",     points = 8,  description = "Reach level 300.", titleReward = 14},
	{id = 118, name = "Millionaire",             category = "General",     points = 3,  description = "Have 1,000,000 gold in your bank."},
	{id = 119, name = "Rich and Famous",         category = "General",     points = 5,  description = "Have 10,000,000 gold in your bank."},
	{id = 120, name = "Premium Warrior",         category = "General",     points = 2,  description = "Be a premium player for 30 days."},
	{id = 121, name = "Death Defier",            category = "General",     points = 3,  description = "Die and return 10 times."},
	{id = 122, name = "Promoted",                category = "General",     points = 2,  description = "Get your first promotion."},
	{id = 123, name = "Addon Collector",         category = "General",     points = 3,  description = "Unlock 10 outfit addons."},
	{id = 124, name = "Mount Rider",             category = "General",     points = 2,  description = "Unlock your first mount."},
	{id = 125, name = "Achievement Hunter",      category = "General",     points = 5,  description = "Earn 100 achievement points.", titleReward = 15},
}

-- Build lookup tables
AchievementSystem.achievementsById = {}
for _, ach in ipairs(AchievementSystem.customAchievements) do
	AchievementSystem.achievementsById[ach.id] = ach
end

AchievementSystem.achievementsByName = {}
for _, ach in ipairs(AchievementSystem.customAchievements) do
	AchievementSystem.achievementsByName[ach.name:lower()] = ach
end

-- ============================================================================
-- Core Functions
-- ============================================================================

--- Check if a player has unlocked a custom achievement.
function AchievementSystem.hasAchievement(player, achId)
	local v = player:getStorageValue(AchievementSystem.STORAGE_ACH_BASE + achId)
	return v == 1
end

--- Award an achievement to a player. Returns true if newly awarded.
function AchievementSystem.awardAchievement(player, achId)
	if AchievementSystem.hasAchievement(player, achId) then
		return false
	end

	local ach = AchievementSystem.achievementsById[achId]
	if not ach then
		return false
	end

	player:setStorageValue(AchievementSystem.STORAGE_ACH_BASE + achId, 1)

	-- Add points
	local currentPoints = AchievementSystem.getAchievementPoints(player)
	player:setStorageValue(AchievementSystem.STORAGE_ACH_POINTS, currentPoints + ach.points)

	-- Award title if applicable
	if ach.titleReward then
		-- Title is auto-available once the achievement is unlocked
	end

	-- Award item if applicable
	if ach.itemReward then
		player:addItem(ach.itemReward.id, ach.itemReward.count)
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
		"[Achievement] Unlocked: " .. ach.name .. "! (+" .. ach.points .. " points) - " .. ach.description)

	return true
end

--- Get the total custom achievement points for a player.
function AchievementSystem.getAchievementPoints(player)
	local v = player:getStorageValue(AchievementSystem.STORAGE_ACH_POINTS)
	if v < 0 then return 0 end
	return v
end

--- Get all achievements in a category.
function AchievementSystem.getByCategory(category)
	local result = {}
	for _, ach in ipairs(AchievementSystem.customAchievements) do
		if ach.category == category then
			table.insert(result, ach)
		end
	end
	return result
end

--- Get all unlocked achievements for a player.
function AchievementSystem.getUnlocked(player)
	local result = {}
	for _, ach in ipairs(AchievementSystem.customAchievements) do
		if AchievementSystem.hasAchievement(player, ach.id) then
			table.insert(result, ach)
		end
	end
	return result
end

--- Get progress: count of unlocked vs total.
function AchievementSystem.getProgress(player)
	local total = #AchievementSystem.customAchievements
	local unlocked = 0
	for _, ach in ipairs(AchievementSystem.customAchievements) do
		if AchievementSystem.hasAchievement(player, ach.id) then
			unlocked = unlocked + 1
		end
	end
	return unlocked, total
end

-- ============================================================================
-- Title Functions
-- ============================================================================

--- Get the player's currently selected title.
function AchievementSystem.getSelectedTitle(player)
	local v = player:getStorageValue(AchievementSystem.STORAGE_TITLE)
	if v < 1 then return nil end
	return AchievementSystem.titles[v]
end

--- Get the player's selected title name (or nil).
function AchievementSystem.getSelectedTitleName(player)
	local title = AchievementSystem.getSelectedTitle(player)
	if title then return title.name end
	return nil
end

--- Set the player's displayed title. Pass 0 or nil to clear.
function AchievementSystem.setTitle(player, titleIndex)
	if not titleIndex or titleIndex < 1 then
		player:setStorageValue(AchievementSystem.STORAGE_TITLE, 0)
		return true
	end
	if not AchievementSystem.titles[titleIndex] then
		return false
	end
	player:setStorageValue(AchievementSystem.STORAGE_TITLE, titleIndex)
	return true
end

--- Get all titles a player has earned (based on achievements with titleReward).
function AchievementSystem.getEarnedTitles(player)
	local earned = {}
	for _, ach in ipairs(AchievementSystem.customAchievements) do
		if ach.titleReward and AchievementSystem.hasAchievement(player, ach.id) then
			local title = AchievementSystem.titles[ach.titleReward]
			if title then
				table.insert(earned, {index = ach.titleReward, name = title.name})
			end
		end
	end
	return earned
end

-- ============================================================================
-- Achievement Checking Helpers
-- ============================================================================
-- These are called from kill_tracker and other scripts to check conditions.

--- Check kill-count-based combat achievements.
function AchievementSystem.checkCombatAchievements(player, monsterName, totalKills)
	local key = monsterName:lower()

	-- Total monster kills (across all types) - uses a global kill counter
	-- Individual checks:
	local killChecks = {
		{monster = "rat",            count = 100, achId = 5},
		{monster = "spider",         count = 100, achId = 6},
		{monster = "orc",            count = 200, achId = 7},
		{monster = "skeleton",       count = 200, achId = 8},
		{monster = "dragon",         count = 100, achId = 9},
		{monster = "dragon lord",    count = 100, achId = 10},
		{monster = "demon",          count = 100, achId = 11},
		{monster = "grim reaper",    count = 100, achId = 12},
		{monster = "hydra",          count = 100, achId = 13},
		{monster = "warlock",        count = 100, achId = 14},
		{monster = "behemoth",       count = 100, achId = 15},
		{monster = "nightmare",      count = 100, achId = 16},
		{monster = "hellhound",      count = 100, achId = 17},
		{monster = "juggernaut",     count = 50,  achId = 18},
		{monster = "fury",           count = 100, achId = 21},
		{monster = "medusa",         count = 100, achId = 22},
		{monster = "wyrm",           count = 100, achId = 23},
		{monster = "giant spider",   count = 200, achId = 24},
		{monster = "vampire",        count = 200, achId = 25},
	}

	for _, check in ipairs(killChecks) do
		if key == check.monster and totalKills >= check.count then
			AchievementSystem.awardAchievement(player, check.achId)
		end
	end
end

--- Check bestiary-related achievements.
function AchievementSystem.checkBestiaryAchievements(player)
	if not Bestiary then return end

	local summary = Bestiary.getProgressSummary(player)

	-- First entry
	if summary.basic >= 1 then
		AchievementSystem.awardAchievement(player, 96)
	end
	-- 10 basic
	if summary.basic >= 10 then
		AchievementSystem.awardAchievement(player, 97)
	end
	-- 10 detailed
	if summary.detailed >= 10 then
		AchievementSystem.awardAchievement(player, 98)
	end
	-- 10 complete
	if summary.complete >= 10 then
		AchievementSystem.awardAchievement(player, 99)
	end

	-- Charm point achievements
	local charms = Bestiary.getCharmPoints(player)
	if charms >= 50 then
		AchievementSystem.awardAchievement(player, 100)
	end
	if charms >= 200 then
		AchievementSystem.awardAchievement(player, 101)
	end
end

--- Check task-related achievements.
function AchievementSystem.checkTaskAchievements(player)
	if not TaskSystem then return end

	-- Count completed tasks
	local completed = 0
	local bossCompleted = 0
	local gatheringCompleted = 0
	for _, task in ipairs(TaskSystem.tasks) do
		if TaskSystem.getTaskState(player, task.id) == TaskSystem.STATE_COMPLETED then
			completed = completed + 1
			if task.category == "boss" then bossCompleted = bossCompleted + 1 end
			if task.category == "gathering" then gatheringCompleted = gatheringCompleted + 1 end
		end
	end

	if completed >= 1  then AchievementSystem.awardAchievement(player, 102) end
	if completed >= 5  then AchievementSystem.awardAchievement(player, 103) end
	if completed >= 15 then AchievementSystem.awardAchievement(player, 104) end
	if completed >= 30 then AchievementSystem.awardAchievement(player, 105) end
	if completed >= 55 then AchievementSystem.awardAchievement(player, 106) end

	-- Task points
	local points = TaskSystem.getTaskPoints(player)
	if points >= 25  then AchievementSystem.awardAchievement(player, 107) end
	if points >= 100 then AchievementSystem.awardAchievement(player, 108) end

	-- Boss tasks (5 boss tasks total)
	if bossCompleted >= 5 then AchievementSystem.awardAchievement(player, 109) end

	-- Gathering tasks (5 gathering tasks total)
	if gatheringCompleted >= 5 then AchievementSystem.awardAchievement(player, 110) end
end

--- Check level-based achievements.
function AchievementSystem.checkLevelAchievements(player)
	local level = player:getLevel()
	if level >= 10  then AchievementSystem.awardAchievement(player, 111) end
	if level >= 25  then AchievementSystem.awardAchievement(player, 112) end
	if level >= 50  then AchievementSystem.awardAchievement(player, 113) end
	if level >= 100 then AchievementSystem.awardAchievement(player, 114) end
	if level >= 150 then AchievementSystem.awardAchievement(player, 115) end
	if level >= 200 then AchievementSystem.awardAchievement(player, 116) end
	if level >= 300 then AchievementSystem.awardAchievement(player, 117) end
end
