-- ============================================================================
-- Prey System Talkaction (Issue #218)
-- ============================================================================
-- !prey              - show current prey slots and bonuses
-- !prey set 1 Dragon - set slot 1 to Dragon
-- !prey reroll 1     - reroll slot 1
-- ============================================================================

function onSay(player, words, param, channel)
	if not PreySystem then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Prey system is not available.")
		return false
	end

	-- Parse arguments
	local args = {}
	for word in param:gmatch("%S+") do
		table.insert(args, word)
	end

	local subcommand = args[1] and args[1]:lower() or ""

	-- !prey set <slot> <creature>
	if subcommand == "set" then
		local slotNum = tonumber(args[2])
		if not slotNum or slotNum < 1 or slotNum > PreySystem.MAX_SLOTS then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"Usage: !prey set <slot 1-" .. PreySystem.MAX_SLOTS .. "> <creature name>")
			return false
		end

		-- Remaining args form the creature name
		if not args[3] then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"Usage: !prey set " .. slotNum .. " <creature name>")
			return false
		end

		local creatureName = table.concat(args, " ", 3)
		local success, msg = PreySystem.selectPrey(player, slotNum - 1, creatureName)
		if not success then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Prey] " .. msg)
		end
		return false
	end

	-- !prey reroll <slot>
	if subcommand == "reroll" then
		local slotNum = tonumber(args[2])
		if not slotNum or slotNum < 1 or slotNum > PreySystem.MAX_SLOTS then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"Usage: !prey reroll <slot 1-" .. PreySystem.MAX_SLOTS .. ">")
			return false
		end

		local success, msg = PreySystem.rerollPrey(player, slotNum - 1)
		if not success then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Prey] " .. msg)
		end
		return false
	end

	-- Default: show all prey slots
	local summary = PreySystem.getSummary(player)

	local msg = "=== Prey Slots ===\n"

	for _, info in ipairs(summary) do
		local slotDisplay = info.slot + 1
		if info.active and info.creature then
			local hours = math.floor(info.remaining / 3600)
			local mins = math.floor((info.remaining % 3600) / 60)
			msg = msg .. "Slot " .. slotDisplay .. ": " .. info.creature .. "\n"
			msg = msg .. "  Bonus: " .. info.bonusName .. " +" .. info.bonusValue .. "%"
			msg = msg .. " (Tier " .. info.bonusTier .. ")\n"
			msg = msg .. "  Time: " .. hours .. "h " .. mins .. "m remaining\n"
		elseif info.creature then
			msg = msg .. "Slot " .. slotDisplay .. ": " .. info.creature .. " (EXPIRED)\n"
		else
			msg = msg .. "Slot " .. slotDisplay .. ": Empty\n"
		end
		local cost = PreySystem.REROLL_COSTS[slotDisplay] or 10000
		msg = msg .. "  Reroll cost: " .. cost .. " gold | Rerolls used: " .. (info.rerolls or 0) .. "\n"
	end

	msg = msg .. "\nCommands:\n"
	msg = msg .. "  !prey set <slot> <creature> - select a prey creature\n"
	msg = msg .. "  !prey reroll <slot> - reroll for a random creature"
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end
