-- ============================================================================
-- PvP Handler (Phase 1.3 + 5)
-- ============================================================================
-- Hooks into combat/kill/death events for PvP rule enforcement:
--   - Apply retro PvP rules (damage reduction, skull tracking)
--   - Track guild war kills
--   - Update PvP rankings
--   - Check and collect bounties
-- ============================================================================

--- onKill: triggered when a player kills another creature
-- Handles PvP kill tracking, bounties, guild war auto-accept, and skull logic
function onKill(player, target)
	if not target or not target:isPlayer() then
		-- Monster kill: award guild XP if applicable
		if GuildEnhanced and player:getGuild() then
			GuildEnhanced.onMemberActivity(player, "kill")
		end
		return true
	end

	local targetPlayer = target:getPlayer()
	if not targetPlayer then
		return true
	end

	-- ========================================================================
	-- 1. Retro PvP: Track unjustified kills and update skulls
	-- ========================================================================
	if RetroPvP then
		-- Check if this was an unjustified kill (target had no skull)
		local targetSkull = targetPlayer:getSkull()
		if targetSkull == SKULL_NONE then
			-- Check if they are in a guild war (war kills are justified)
			local isWarKill = false
			if player:getGuild() and targetPlayer:getGuild() then
				isWarKill = player:isInWar(targetPlayer)
			end

			-- Check if they are dueling (duel kills are justified)
			local isDuelKill = false
			if PvPSystems then
				isDuelKill = PvPSystems.areInDuel(player, targetPlayer)
			end

			if not isWarKill and not isDuelKill then
				RetroPvP.addUnjustifiedKill(player)
			end
		end

		-- Track PvP kill/death stats
		RetroPvP.addPvPKill(player)
		RetroPvP.addPvPDeath(targetPlayer)
	end

	-- ========================================================================
	-- 2. Guild War: Auto-accept and track war kills
	-- ========================================================================
	if GuildEnhanced then
		-- Check guild war auto-accept
		GuildEnhanced.checkWarAutoAccept(player, targetPlayer)

		-- Award guild XP for war kills
		if player:getGuild() and targetPlayer:getGuild() then
			if player:isInWar(targetPlayer) then
				GuildEnhanced.onMemberActivity(player, "war_kill")
			end
		end
	end

	-- ========================================================================
	-- 3. PvP Rankings: Update ELO and kill/death counts
	-- ========================================================================
	if PvPSystems then
		-- Check if this was a duel kill
		if PvPSystems.areInDuel(player, targetPlayer) then
			PvPSystems.endDuel(targetPlayer, player)
		else
			-- Regular PvP kill - update rankings
			PvPSystems.recordPvPKill(player, targetPlayer)
		end

		-- Collect bounties
		local bountyCollected = PvPSystems.collectBounties(player, targetPlayer)
		if bountyCollected > 0 then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
				"Total bounty collected: " .. bountyCollected .. " gold!")
		end
	end

	return true
end

--- onPrepareDeath: triggered before a player dies
-- Used to apply retro PvP death penalty adjustments
function onPrepareDeath(player, killer)
	-- Death penalty adjustments are handled by the RetroPvP system
	-- The actual penalty modification happens via the engine's getLostPercent
	-- but we track the death context here for reference
	if RetroPvP and killer and killer:isPlayer() then
		player:setStorageValue(RetroPvP.STORAGE.LAST_PVP_DEATH, os.time())
	end

	return true
end

--- onLogin: register PvP events and check skull expiration
function onLogin(player)
	-- Register kill tracking
	player:registerEvent("PvPKill")
	player:registerEvent("PvPDeath")

	-- Check skull expiration on login
	if RetroPvP then
		RetroPvP.checkSkullExpiration(player)
	end

	-- Clean up expired duel requests
	if PvPSystems then
		PvPSystems.cleanupExpiredDuels()
	end

	return true
end
