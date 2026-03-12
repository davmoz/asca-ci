-- ============================================================================
-- Daily Login Rewards System
-- ============================================================================
-- Provides escalating daily login rewards on a 7-day cycle.
-- Players who log in on consecutive days receive increasingly valuable
-- rewards. Missing a day resets the streak back to day 1.
-- Storage layout:
--   64000  login streak (current consecutive day, 1-7)
--   64001  last claim timestamp (os.time())
--   64002  last claim year (os.date year)
--   64003  last claim yday (os.date year-day)
--   64004  bonus XP flag (1 = active, timestamp of expiry)
-- ============================================================================

DailyRewards = {}

-- ============================================================================
-- Constants
-- ============================================================================

DailyRewards.STORAGE_STREAK     = 64000
DailyRewards.STORAGE_LAST_CLAIM = 64001
DailyRewards.STORAGE_LAST_YEAR  = 64002
DailyRewards.STORAGE_LAST_YDAY  = 64003
DailyRewards.STORAGE_BONUS_XP   = 64004

DailyRewards.CYCLE_LENGTH = 7

-- ============================================================================
-- Reward Definitions (7-day cycle)
-- ============================================================================
-- Each entry: {day, gold, items = {{id, count}, ...}, description}

DailyRewards.rewards = {
	[1] = {
		gold = 500,
		items = {},
		description = "500 gold",
	},
	[2] = {
		gold = 1000,
		items = {{id = 7618, count = 5}},  -- small health potion
		description = "1000 gold + 5 small health potions",
	},
	[3] = {
		gold = 2000,
		items = {{id = 7620, count = 5}},  -- small mana potion
		description = "2000 gold + 5 small mana potions",
	},
	[4] = {
		gold = 3000,
		items = {{id = 7588, count = 2}},  -- strong health potion
		description = "3000 gold + 2 strong health potions",
	},
	[5] = {
		gold = 5000,
		items = {{id = 7590, count = 2}},  -- strong mana potion
		description = "5000 gold + 2 strong mana potions",
	},
	[6] = {
		gold = 7500,
		items = {{id = 1988, count = 1, fillWith = {  -- backpack with mixed supplies
			{id = 7618, count = 5},   -- small health potion
			{id = 7620, count = 5},   -- small mana potion
			{id = 7588, count = 2},   -- strong health potion
			{id = 7590, count = 2},   -- strong mana potion
		}}},
		description = "7500 gold + 1 backpack with mixed supplies",
	},
	[7] = {
		gold = 15000,
		items = {},
		bonusXP = true,  -- 2x XP for 1 hour
		description = "15000 gold + bonus XP scroll (2x XP for 1 hour)",
	},
}

-- ============================================================================
-- Storage Helpers
-- ============================================================================

function DailyRewards.getStreak(player)
	local v = player:getStorageValue(DailyRewards.STORAGE_STREAK)
	if v < 1 then return 0 end
	return v
end

function DailyRewards.setStreak(player, streak)
	player:setStorageValue(DailyRewards.STORAGE_STREAK, streak)
end

function DailyRewards.getLastClaim(player)
	local year = player:getStorageValue(DailyRewards.STORAGE_LAST_YEAR)
	local yday = player:getStorageValue(DailyRewards.STORAGE_LAST_YDAY)
	if year < 0 or yday < 0 then
		return nil
	end
	return {year = year, yday = yday}
end

function DailyRewards.setLastClaim(player)
	local now = os.date("*t")
	player:setStorageValue(DailyRewards.STORAGE_LAST_CLAIM, os.time())
	player:setStorageValue(DailyRewards.STORAGE_LAST_YEAR, now.year)
	player:setStorageValue(DailyRewards.STORAGE_LAST_YDAY, now.yday)
end

-- ============================================================================
-- Day Comparison Helpers
-- ============================================================================

--- Calculate the difference in days between a saved date and today.
-- Returns the number of days elapsed (0 = same day, 1 = next day, etc.)
function DailyRewards.daysSinceLastClaim(player)
	local last = DailyRewards.getLastClaim(player)
	if not last then
		return -1  -- never claimed
	end

	local now = os.date("*t")

	if now.year == last.year then
		return now.yday - last.yday
	end

	-- Handle year boundary: count remaining days in last.year + days in now.year
	-- Determine if last.year was a leap year
	local function isLeapYear(y)
		return (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0)
	end

	local daysInLastYear = isLeapYear(last.year) and 366 or 365
	local daysRemaining = daysInLastYear - last.yday
	local totalDays = daysRemaining + now.yday

	-- If more than one year apart, it is definitely more than 1 day
	if now.year - last.year > 1 then
		return totalDays + 365 * (now.year - last.year - 1)
	end

	return totalDays
end

-- ============================================================================
-- Core Functions
-- ============================================================================

--- Called when a player logs in. Checks streak status and notifies player.
function DailyRewards.onLogin(player)
	local daysSince = DailyRewards.daysSinceLastClaim(player)
	local streak = DailyRewards.getStreak(player)

	if daysSince == -1 then
		-- First time login, no previous claim
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			"[Daily Reward] Welcome! Type !daily to claim your first daily reward.")
		return true
	end

	if daysSince == 0 then
		-- Already claimed today
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			"[Daily Reward] You have already claimed today's reward. Come back tomorrow!")
		return true
	end

	if daysSince == 1 then
		-- Consecutive day, streak continues
		local nextDay = (streak % DailyRewards.CYCLE_LENGTH) + 1
		local reward = DailyRewards.rewards[nextDay]
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			"[Daily Reward] Day " .. nextDay .. " streak! Type !daily to claim: " .. reward.description)
	elseif daysSince > 1 then
		-- Missed a day, streak resets
		if streak > 0 then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"[Daily Reward] You missed a day! Your streak has been reset. Type !daily to claim your Day 1 reward.")
		else
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"[Daily Reward] Type !daily to claim your daily reward.")
		end
	end

	return true
end

--- Claim the daily reward. Returns true on success, or false and an error message.
function DailyRewards.claimReward(player)
	local daysSince = DailyRewards.daysSinceLastClaim(player)
	local streak = DailyRewards.getStreak(player)

	-- Check if already claimed today
	if daysSince == 0 then
		return false, "You have already claimed your daily reward today. Come back tomorrow!"
	end

	-- Determine new streak
	local newStreak
	if daysSince == 1 then
		-- Consecutive day
		newStreak = (streak % DailyRewards.CYCLE_LENGTH) + 1
	else
		-- First claim ever (daysSince == -1) or missed a day (daysSince > 1)
		newStreak = 1
	end

	local reward = DailyRewards.rewards[newStreak]
	if not reward then
		return false, "Reward configuration error."
	end

	-- Award gold
	if reward.gold > 0 then
		player:addMoney(reward.gold)
	end

	-- Award items
	for _, item in ipairs(reward.items) do
		if item.fillWith then
			-- Create a backpack and fill it with supplies
			local backpack = player:addItem(item.id, item.count)
			if backpack then
				for _, supply in ipairs(item.fillWith) do
					backpack:addItem(supply.id, supply.count)
				end
			end
		else
			player:addItem(item.id, item.count)
		end
	end

	-- Award bonus XP if applicable (day 7)
	if reward.bonusXP then
		local expiryTime = os.time() + 3600  -- 1 hour from now
		player:setStorageValue(DailyRewards.STORAGE_BONUS_XP, expiryTime)
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
			"[Daily Reward] Bonus XP activated! You gain 2x experience for the next hour.")
	end

	-- Update streak and claim timestamp
	DailyRewards.setStreak(player, newStreak)
	DailyRewards.setLastClaim(player)

	-- Send reward message
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
		"[Daily Reward] Day " .. newStreak .. "/" .. DailyRewards.CYCLE_LENGTH ..
		" claimed: " .. reward.description .. "!")

	if newStreak == DailyRewards.CYCLE_LENGTH then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
			"[Daily Reward] Congratulations! You completed the full 7-day cycle! " ..
			"The cycle will reset tomorrow.")
	end

	player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)

	return true
end

--- Check if a player currently has the 2x XP bonus active.
-- Returns true if active, false otherwise.
function DailyRewards.hasBonusXP(player)
	local expiry = player:getStorageValue(DailyRewards.STORAGE_BONUS_XP)
	if expiry < 1 then
		return false
	end
	if os.time() >= expiry then
		-- Bonus has expired, clear the storage
		player:setStorageValue(DailyRewards.STORAGE_BONUS_XP, -1)
		return false
	end
	return true
end

--- Get remaining bonus XP time in seconds. Returns 0 if not active.
function DailyRewards.getBonusXPRemaining(player)
	local expiry = player:getStorageValue(DailyRewards.STORAGE_BONUS_XP)
	if expiry < 1 then
		return 0
	end
	local remaining = expiry - os.time()
	if remaining <= 0 then
		player:setStorageValue(DailyRewards.STORAGE_BONUS_XP, -1)
		return 0
	end
	return remaining
end

-- ============================================================================
-- Display Function (Issue #217)
-- ============================================================================
-- Shows streak, today's reward tier, and time until next daily reward on login.

function DailyRewards.displayLoginInfo(player)
	local daysSince = DailyRewards.daysSinceLastClaim(player)
	local streak = DailyRewards.getStreak(player)

	local msg = "=== Daily Rewards ===\n"

	-- Show current streak
	msg = msg .. "Current streak: " .. streak .. "/" .. DailyRewards.CYCLE_LENGTH .. " days\n"

	-- Determine today's reward tier
	if daysSince == 0 then
		-- Already claimed today
		local reward = DailyRewards.rewards[streak]
		msg = msg .. "Today's reward (CLAIMED): Day " .. streak .. " - " .. reward.description .. "\n"

		-- Show time until next daily reward (next midnight)
		local now = os.date("*t")
		local secondsUntilMidnight = (24 - now.hour - 1) * 3600 + (60 - now.min - 1) * 60 + (60 - now.sec)
		local hoursLeft = math.floor(secondsUntilMidnight / 3600)
		local minsLeft = math.floor((secondsUntilMidnight % 3600) / 60)
		msg = msg .. "Next reward available in: " .. hoursLeft .. "h " .. minsLeft .. "m\n"

		-- Preview next day reward
		local nextDay = (streak % DailyRewards.CYCLE_LENGTH) + 1
		local nextReward = DailyRewards.rewards[nextDay]
		if nextReward then
			msg = msg .. "Tomorrow (Day " .. nextDay .. "): " .. nextReward.description .. "\n"
		end
	elseif daysSince == 1 then
		-- Consecutive day, can claim
		local nextDay = (streak % DailyRewards.CYCLE_LENGTH) + 1
		local reward = DailyRewards.rewards[nextDay]
		msg = msg .. "Today's reward (AVAILABLE): Day " .. nextDay .. " - " .. reward.description .. "\n"
		msg = msg .. "Type !daily to claim your reward!\n"
	elseif daysSince == -1 then
		-- Never claimed
		local reward = DailyRewards.rewards[1]
		msg = msg .. "Today's reward (AVAILABLE): Day 1 - " .. reward.description .. "\n"
		msg = msg .. "Type !daily to claim your first reward!\n"
	else
		-- Streak broken
		local reward = DailyRewards.rewards[1]
		msg = msg .. "Streak broken! Your streak has been reset.\n"
		msg = msg .. "Today's reward (AVAILABLE): Day 1 - " .. reward.description .. "\n"
		msg = msg .. "Type !daily to claim your reward and start a new streak!\n"
	end

	-- Show bonus XP status if active
	if DailyRewards.hasBonusXP(player) then
		local remaining = DailyRewards.getBonusXPRemaining(player)
		local mins = math.floor(remaining / 60)
		msg = msg .. "\n2x XP Bonus ACTIVE: " .. mins .. " minutes remaining"
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
end

print(">> Daily rewards system loaded")
