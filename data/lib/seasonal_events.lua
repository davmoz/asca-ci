-- Seasonal Events System (Phase 4.6 + 5.5)
-- Manages seasonal/holiday events with special modifiers, monsters, and rewards

SeasonalEvents = SeasonalEvents or {}

-- ============================================================================
-- Event Definitions
-- ============================================================================

SeasonalEvents.EVENTS = {
	-- Christmas Event: Dec 15 - Jan 5
	CHRISTMAS = {
		name = "Christmas Celebration",
		startMonth = 12, startDay = 15,
		endMonth = 1, endDay = 5,
		crossesNewYear = true,
		broadcastStart = "The Christmas Celebration has begun! Snow blankets the land and festive cheer fills the air!",
		broadcastEnd = "The Christmas Celebration has ended. The snow melts away as the new year begins.",
		modifiers = {
			expBonus = 1.15,         -- 15% XP bonus
			lootBonus = 1.10,        -- 10% loot bonus
			spawnRateMultiplier = 1.0
		},
		specialMonsters = {
			{ name = "Yeti", spawnChance = 0.05 },
			{ name = "Ice Golem", spawnChance = 0.08 },
			{ name = "Crystal Spider", spawnChance = 0.06 }
		},
		decorItems = {
			-- Item IDs for snow/christmas decorations
			{ itemId = 2114, name = "christmas tree" },
			{ itemId = 6570, name = "snowball" },
			{ itemId = 2078, name = "present box" }
		},
		giftNPC = {
			enabled = true,
			name = "Santa Claus",
			greeting = "Ho ho ho! Merry Christmas, {player}! Have you been good this year?",
			dailyGiftChance = 0.75,
			possibleGifts = {
				{ itemId = 2152, count = 10, name = "platinum coin" },
				{ itemId = 6570, count = 50, name = "snowball" },
				{ itemId = 2078, count = 1, name = "present box" },
				{ itemId = 2160, count = 1, name = "crystal coin" }
			}
		}
	},

	-- Halloween Event: Oct 20 - Nov 5
	HALLOWEEN = {
		name = "Halloween Horror",
		startMonth = 10, startDay = 20,
		endMonth = 11, endDay = 5,
		crossesNewYear = false,
		broadcastStart = "Halloween Horror has begun! The dead walk among the living and darkness covers the land!",
		broadcastEnd = "Halloween Horror has ended. The restless spirits return to their graves... for now.",
		modifiers = {
			expBonus = 1.10,         -- 10% XP bonus
			lootBonus = 1.20,        -- 20% loot bonus (more loot from undead)
			spawnRateMultiplier = 1.15  -- 15% faster undead respawns
		},
		specialMonsters = {
			{ name = "Vampire", spawnChance = 0.10 },
			{ name = "Ghost", spawnChance = 0.12 },
			{ name = "Necromancer", spawnChance = 0.06 },
			{ name = "Skeleton", spawnChance = 0.15 },
			{ name = "Ghoul", spawnChance = 0.10 }
		},
		decorItems = {
			{ itemId = 2096, name = "pumpkinhead" },
			{ itemId = 2114, name = "dead tree" }
		},
		hauntedAreas = {
			{ name = "Town Cemetery", centerX = 90, centerY = 140, centerZ = 7, radius = 15 },
			{ name = "Dark Cathedral", centerX = 125, centerY = 145, centerZ = 7, radius = 10 }
		}
	},

	-- Easter Event: Configurable dates (default late March/early April)
	EASTER = {
		name = "Easter Egg Hunt",
		startMonth = 3, startDay = 25,
		endMonth = 4, endDay = 10,
		crossesNewYear = false,
		broadcastStart = "The Easter Egg Hunt has begun! Colorful eggs are hidden throughout the land!",
		broadcastEnd = "The Easter Egg Hunt has ended. Until next year, egg hunters!",
		modifiers = {
			expBonus = 1.10,
			lootBonus = 1.05,
			spawnRateMultiplier = 1.0
		},
		specialMonsters = {
			{ name = "Rabbit", spawnChance = 0.20 }
		},
		eggHunt = {
			enabled = true,
			maxEggsPerDay = 10,
			eggItemId = 2222,
			eggColors = { "red", "blue", "green", "gold", "purple" },
			goldenEggChance = 0.05,
			rewards = {
				{ eggsNeeded = 5, itemId = 2152, count = 5, name = "platinum coin" },
				{ eggsNeeded = 15, itemId = 2160, count = 1, name = "crystal coin" },
				{ eggsNeeded = 30, itemId = 2152, count = 25, name = "platinum coin" }
			}
		}
	},

	-- Anniversary Event: Configurable (server launch date)
	ANNIVERSARY = {
		name = "Server Anniversary",
		-- Set these to your server launch month/day
		startMonth = 6, startDay = 1,
		endMonth = 6, endDay = 7,
		crossesNewYear = false,
		broadcastStart = "Happy Anniversary! Celebrate the founding of our server with special bonuses!",
		broadcastEnd = "The Anniversary celebration has ended. Thank you for being part of our community!",
		modifiers = {
			expBonus = 1.25,         -- 25% XP bonus
			lootBonus = 1.15,        -- 15% loot bonus
			spawnRateMultiplier = 1.0
		},
		specialQuests = {
			enabled = true,
			questName = "Anniversary Treasure Hunt",
			description = "Find 5 anniversary tokens scattered across the world",
			tokenItemId = 2229,
			tokensNeeded = 5,
			rewardItemId = 2160,
			rewardCount = 5
		}
	},

	-- Royal Outfit Prestige Event: Annual top XP earners
	ROYAL_PRESTIGE = {
		name = "Royal Prestige Awards",
		startMonth = 1, startDay = 10,
		endMonth = 1, endDay = 17,
		crossesNewYear = false,
		broadcastStart = "The Royal Prestige Awards have begun! The top adventurers shall receive the Royal Outfit!",
		broadcastEnd = "The Royal Prestige Awards ceremony has concluded. Congratulations to all recipients!",
		modifiers = {
			expBonus = 1.05,
			lootBonus = 1.0,
			spawnRateMultiplier = 1.0
		},
		prestige = {
			enabled = true,
			topPlayersCount = 10,     -- Top 10 XP earners
			royalOutfitMale = 325,
			royalOutfitFemale = 324,
			announcementMessage = "The following players have earned the Royal Outfit for their outstanding achievements: ",
			trackingPeriod = "yearly"  -- Track XP gains over the past year
		}
	}
}

-- ============================================================================
-- Storage Keys
-- ============================================================================

SeasonalEvents.STORAGE = {
	ACTIVE_EVENT_PREFIX = 63000,   -- Base storage for active event tracking
	GIFT_COOLDOWN = 63100,         -- Daily gift cooldown per player
	EGG_COUNT = 63101,             -- Easter egg count per player
	EGG_DAILY_COUNT = 63102,       -- Daily egg pickup count
	ANNIVERSARY_TOKENS = 63103,    -- Anniversary token count
	PRESTIGE_XP_TRACKING = 63104   -- XP tracking for prestige
}

-- ============================================================================
-- Core Functions
-- ============================================================================

--- Check if a date falls within an event period
-- @param event table: event definition
-- @param month number: current month
-- @param day number: current day
-- @return boolean: true if date is within event period
function SeasonalEvents.isDateInRange(event, month, day)
	if event.crossesNewYear then
		-- Event spans across Dec -> Jan (e.g., Christmas)
		if month == event.startMonth and day >= event.startDay then
			return true
		elseif month == event.endMonth and day <= event.endDay then
			return true
		elseif month > event.startMonth or month < event.endMonth then
			return true
		end
		return false
	else
		-- Normal date range within same year
		if month > event.startMonth or (month == event.startMonth and day >= event.startDay) then
			if month < event.endMonth or (month == event.endMonth and day <= event.endDay) then
				return true
			end
		end
		return false
	end
end

--- Check if a specific event is currently active
-- @param eventKey string: key from SeasonalEvents.EVENTS (e.g., "CHRISTMAS")
-- @return boolean: true if event is active
function SeasonalEvents.isEventActive(eventKey)
	local event = SeasonalEvents.EVENTS[eventKey]
	if not event then
		return false
	end

	-- Check if the event has been force-stopped by an admin
	if SeasonalEvents._forcedStops and SeasonalEvents._forcedStops[eventKey] then
		return false
	end

	-- Check if the event has been force-started by an admin
	if SeasonalEvents._forcedEvents and SeasonalEvents._forcedEvents[eventKey] then
		return true
	end

	local now = os.date("*t")
	return SeasonalEvents.isDateInRange(event, now.month, now.day)
end

--- Get all currently active events (cached for 60 seconds)
-- @return table: list of {key, event} pairs for active events
SeasonalEvents._activeEventsCache = nil
SeasonalEvents._activeEventsCacheTime = 0

function SeasonalEvents.getActiveEvents()
	local now = os.time()
	if SeasonalEvents._activeEventsCache and (now - SeasonalEvents._activeEventsCacheTime) < 60 then
		return SeasonalEvents._activeEventsCache
	end

	local activeEvents = {}
	for key, event in pairs(SeasonalEvents.EVENTS) do
		if SeasonalEvents.isEventActive(key) then
			table.insert(activeEvents, { key = key, event = event })
		end
	end

	SeasonalEvents._activeEventsCache = activeEvents
	SeasonalEvents._activeEventsCacheTime = now
	return activeEvents
end

--- Get the combined XP bonus from all active events
-- @return number: combined XP multiplier (e.g., 1.25 for 25% bonus)
function SeasonalEvents.getExpBonus()
	local totalBonus = 1.0
	local activeEvents = SeasonalEvents.getActiveEvents()
	for _, entry in ipairs(activeEvents) do
		if entry.event.modifiers and entry.event.modifiers.expBonus then
			-- Stack bonuses additively: 1.10 + 1.15 = 1.25 (not 1.265)
			totalBonus = totalBonus + (entry.event.modifiers.expBonus - 1.0)
		end
	end
	return totalBonus
end

--- Get the combined loot bonus from all active events
-- @return number: combined loot multiplier
function SeasonalEvents.getLootBonus()
	local totalBonus = 1.0
	local activeEvents = SeasonalEvents.getActiveEvents()
	for _, entry in ipairs(activeEvents) do
		if entry.event.modifiers and entry.event.modifiers.lootBonus then
			totalBonus = totalBonus + (entry.event.modifiers.lootBonus - 1.0)
		end
	end
	return totalBonus
end

--- Get the combined spawn rate multiplier from all active events
-- @return number: combined spawn rate multiplier
function SeasonalEvents.getSpawnRateMultiplier()
	local totalMultiplier = 1.0
	local activeEvents = SeasonalEvents.getActiveEvents()
	for _, entry in ipairs(activeEvents) do
		if entry.event.modifiers and entry.event.modifiers.spawnRateMultiplier then
			totalMultiplier = totalMultiplier + (entry.event.modifiers.spawnRateMultiplier - 1.0)
		end
	end
	return totalMultiplier
end

--- Get all special monsters from active events
-- @return table: list of {name, spawnChance} for special event monsters
function SeasonalEvents.getSpecialMonsters()
	local monsters = {}
	local activeEvents = SeasonalEvents.getActiveEvents()
	for _, entry in ipairs(activeEvents) do
		if entry.event.specialMonsters then
			for _, monster in ipairs(entry.event.specialMonsters) do
				table.insert(monsters, monster)
			end
		end
	end
	return monsters
end

--- Apply event modifiers to a player's experience gain
-- @param baseExp number: base experience points
-- @return number: modified experience points
function SeasonalEvents.applyExpModifier(baseExp)
	return math.floor(baseExp * SeasonalEvents.getExpBonus())
end

--- Check if a player can receive a daily gift (Christmas)
-- @param player userdata: player object
-- @return boolean: true if player can receive gift today
function SeasonalEvents.canReceiveDailyGift(player)
	if not SeasonalEvents.isEventActive("CHRISTMAS") then
		return false
	end

	local lastGift = player:getStorageValue(SeasonalEvents.STORAGE.GIFT_COOLDOWN)
	local today = os.date("%Y%m%d")
	if tostring(lastGift) == today then
		return false
	end
	return true
end

--- Grant a daily gift to a player
-- @param player userdata: player object
-- @return table|nil: gift info {itemId, count, name} or nil if not eligible
function SeasonalEvents.grantDailyGift(player)
	if not SeasonalEvents.canReceiveDailyGift(player) then
		return nil
	end

	local christmas = SeasonalEvents.EVENTS.CHRISTMAS
	if math.random() > christmas.giftNPC.dailyGiftChance then
		return nil
	end

	local gifts = christmas.giftNPC.possibleGifts
	local gift = gifts[math.random(#gifts)]

	player:addItem(gift.itemId, gift.count)
	player:setStorageValue(SeasonalEvents.STORAGE.GIFT_COOLDOWN, tonumber(os.date("%Y%m%d")))

	return gift
end

--- Check if a position is within a haunted area (Halloween)
-- @param pos table: position {x, y, z}
-- @return boolean: true if position is in a haunted area
function SeasonalEvents.isInHauntedArea(pos)
	if not SeasonalEvents.isEventActive("HALLOWEEN") then
		return false
	end

	local halloween = SeasonalEvents.EVENTS.HALLOWEEN
	if not halloween.hauntedAreas then
		return false
	end

	for _, area in ipairs(halloween.hauntedAreas) do
		if pos.z == area.centerZ then
			local dx = math.abs(pos.x - area.centerX)
			local dy = math.abs(pos.y - area.centerY)
			if dx <= area.radius and dy <= area.radius then
				return true
			end
		end
	end
	return false
end

--- Get a formatted status string for all events
-- @return string: human-readable event status
function SeasonalEvents.getStatusString()
	local activeEvents = SeasonalEvents.getActiveEvents()
	if #activeEvents == 0 then
		return "No seasonal events are currently active."
	end

	local lines = { "Active Seasonal Events:" }
	for _, entry in ipairs(activeEvents) do
		local event = entry.event
		local modStr = ""
		if event.modifiers.expBonus > 1.0 then
			modStr = modStr .. string.format(" +%d%% XP", (event.modifiers.expBonus - 1.0) * 100)
		end
		if event.modifiers.lootBonus > 1.0 then
			modStr = modStr .. string.format(" +%d%% Loot", (event.modifiers.lootBonus - 1.0) * 100)
		end
		table.insert(lines, string.format("  - %s (%s/%d - %s/%d)%s",
			event.name,
			tostring(event.startMonth), event.startDay,
			tostring(event.endMonth), event.endDay,
			modStr))
	end
	return table.concat(lines, "\n")
end

--- Get event configuration for Easter egg dates (allows runtime override)
-- @param startMonth number: override start month
-- @param startDay number: override start day
-- @param endMonth number: override end month
-- @param endDay number: override end day
function SeasonalEvents.setEasterDates(startMonth, startDay, endMonth, endDay)
	local easter = SeasonalEvents.EVENTS.EASTER
	if easter then
		easter.startMonth = startMonth or easter.startMonth
		easter.startDay = startDay or easter.startDay
		easter.endMonth = endMonth or easter.endMonth
		easter.endDay = endDay or easter.endDay
	end
end

--- Set the server anniversary dates
-- @param startMonth number: launch month
-- @param startDay number: launch day
function SeasonalEvents.setAnniversaryDate(startMonth, startDay)
	local anniversary = SeasonalEvents.EVENTS.ANNIVERSARY
	if anniversary then
		anniversary.startMonth = startMonth or anniversary.startMonth
		anniversary.startDay = startDay or anniversary.startDay
		anniversary.endMonth = startMonth or anniversary.endMonth
		anniversary.endDay = (startDay or anniversary.startDay) + 6
	end
end

print(">> Seasonal Events system loaded")
