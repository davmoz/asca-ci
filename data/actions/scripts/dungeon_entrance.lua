-- ============================================================================
-- Weekly Dungeon Entrance Action (Phase 5)
-- ============================================================================
-- Placed on actionid-tagged tiles near dungeon entrance markers.
-- ActionID mapping:  9001 = Dungeon 1, 9002 = Dungeon 2, ... 9005 = Dungeon 5
-- ============================================================================

local DUNGEON_ACTION_BASE = 9001

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local actionId = item:getActionId()
	local dungeonId = actionId - DUNGEON_ACTION_BASE + 1

	if dungeonId < 1 or dungeonId > 5 then
		return false
	end

	local dungeon = WeeklyDungeons.DUNGEONS[dungeonId]
	if not dungeon then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "This dungeon entrance is not configured.")
		return true
	end

	-- Must be party leader (or solo check handled inside canEnter)
	local party = player:getParty()
	if not party then
		player:sendTextMessage(MESSAGE_STATUS_SMALL,
			string.format("You need a party of at least %d to enter %s.",
				WeeklyDungeons.MIN_PARTY_SIZE, dungeon.name))
		return true
	end

	if party:getLeader():getGuid() ~= player:getGuid() then
		player:sendTextMessage(MESSAGE_STATUS_SMALL,
			"Only the party leader can activate the dungeon entrance.")
		return true
	end

	-- Check all members can enter
	local members = party:getMembers()
	table.insert(members, player)

	for _, member in ipairs(members) do
		local ok, msg = WeeklyDungeons.canEnter(member, dungeonId)
		if not ok then
			player:sendTextMessage(MESSAGE_STATUS_SMALL,
				string.format("%s cannot enter: %s", member:getName(), msg))
			return true
		end
	end

	-- All checks passed, enter the dungeon
	local ok, msg = WeeklyDungeons.enterDungeon(player, dungeonId)
	if not ok then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, msg)
	end

	return true
end
