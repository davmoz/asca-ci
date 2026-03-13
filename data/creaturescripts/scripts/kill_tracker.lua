-- ============================================================================
-- Kill Tracker (Phase 4)
-- ============================================================================
-- Registered as a creature-death event. On monster kill:
--   1. Update bestiary kill count
--   2. Check task progress and auto-complete if threshold met
--   3. Check achievement conditions
-- ============================================================================

-- Global kill counter storage (total kills across all monsters)
local STORAGE_TOTAL_KILLS = 52500

function onKill(player, target)
	if not target or not target:isMonster() then
		return true
	end

	local monsterName = target:getName()
	if not monsterName or monsterName == "" then
		return true
	end

	-- ========================================================================
	-- 1. Update Bestiary
	-- ========================================================================
	if Bestiary then
		Bestiary.addKill(player, monsterName)
	end

	-- ========================================================================
	-- 2. Update Task Progress
	-- ========================================================================
	if TaskSystem then
		local results = TaskSystem.onKill(player, monsterName)
		for _, result in ipairs(results) do
			if result.completed then
				-- Auto-complete the task and award rewards
				TaskSystem.completeTask(player, result.task.id)

				-- Check task achievements after completion
				if AchievementSystem then
					AchievementSystem.checkTaskAchievements(player)
				end
			end
		end
	end

	-- ========================================================================
	-- 3. Update Total Kill Counter and Check Achievements
	-- ========================================================================
	if AchievementSystem then
		-- Track total kills
		local totalKills = player:getStorageValue(STORAGE_TOTAL_KILLS)
		if totalKills < 0 then totalKills = 0 end
		totalKills = totalKills + 1
		player:setStorageValue(STORAGE_TOTAL_KILLS, totalKills)

		-- First Blood
		if totalKills >= 1 then
			AchievementSystem.awardAchievement(player, 1)
		end
		-- Hundred Kills
		if totalKills >= 100 then
			AchievementSystem.awardAchievement(player, 2)
		end
		-- Thousand Kills
		if totalKills >= 1000 then
			AchievementSystem.awardAchievement(player, 3)
		end
		-- Ten Thousand Kills
		if totalKills >= 10000 then
			AchievementSystem.awardAchievement(player, 4)
		end

		-- Check creature-specific combat achievements
		local bestiaryKills = 0
		if Bestiary then
			bestiaryKills = Bestiary.getKillCount(player, monsterName)
		end
		AchievementSystem.checkCombatAchievements(player, monsterName, bestiaryKills)

		-- Check bestiary achievements
		AchievementSystem.checkBestiaryAchievements(player)
	end

	return true
end
