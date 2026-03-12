-- ============================================================================
-- Imbuing System Talkaction (Issue #219)
-- ============================================================================
-- !imbue                      - show current imbuements
-- !imbue list                 - show available imbue types
-- !imbue apply <type> <tier>  - apply an imbue (by name and tier)
-- ============================================================================

function onSay(player, words, param, channel)
	if not ImbuingSystem then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Imbuing system is not available.")
		return false
	end

	-- Parse arguments
	local args = {}
	for word in param:gmatch("%S+") do
		table.insert(args, word)
	end

	local subcommand = args[1] and args[1]:lower() or ""

	-- !imbue list
	if subcommand == "list" then
		local msg = "=== Available Imbue Types ===\n"

		for typeId, typeDef in pairs(ImbuingSystem.Types) do
			local slotNames = {}
			for _, slotId in ipairs(typeDef.allowedSlots) do
				local slotDef = ImbuingSystem.Slots[slotId]
				if slotDef then
					table.insert(slotNames, slotDef.name)
				end
			end

			msg = msg .. "[" .. typeId .. "] " .. typeDef.name .. " (" .. typeDef.desc .. ")\n"
			msg = msg .. "  Slots: " .. table.concat(slotNames, ", ") .. "\n"
			msg = msg .. "  Tiers: "

			local tierParts = {}
			for tier = 1, 3 do
				local tierName = ImbuingSystem.TierNames[tier]
				local value = typeDef.values[tier]
				local bonus = ""
				if typeDef.bonusValues then
					bonus = " +" .. typeDef.bonusValues[tier] .. " dmg"
				end
				local goldCost = ImbuingSystem.GoldCost[tier] or 0
				table.insert(tierParts,
					tierName .. " +" .. value .. typeDef.unit .. bonus ..
					" (" .. goldCost .. "gp)")
			end
			msg = msg .. table.concat(tierParts, ", ") .. "\n"
		end

		msg = msg .. "\nUsage: !imbue apply <type name> <tier 1-3>"
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- !imbue apply <type> <tier>
	if subcommand == "apply" then
		if not args[2] then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"Usage: !imbue apply <type name> <tier 1-3>\nUse !imbue list to see available types.")
			return false
		end

		-- Find tier (last numeric argument)
		local tier = tonumber(args[#args])
		local typeName
		if tier and tier >= 1 and tier <= 3 then
			-- Type name is everything between "apply" and the tier number
			typeName = table.concat(args, " ", 2, #args - 1)
		else
			-- No tier specified, default to 1
			tier = 1
			typeName = table.concat(args, " ", 2)
		end

		typeName = typeName:lower()

		-- Find the imbue type by name
		local imbuType = nil
		for typeId, typeDef in pairs(ImbuingSystem.Types) do
			if typeDef.name:lower() == typeName then
				imbuType = typeId
				break
			end
		end

		if not imbuType then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"[Imbue] Unknown imbue type: " .. typeName .. ". Use !imbue list to see available types.")
			return false
		end

		-- Check what equipment slot this imbue goes on
		local typeDef = ImbuingSystem.Types[imbuType]
		local targetSlot = typeDef.allowedSlots[1]
		local slotDef = ImbuingSystem.Slots[targetSlot]

		-- Check if player has materials
		if not ImbuingSystem.hasMaterials(player, imbuType, tier) then
			local mats = ImbuingSystem.getMaterialCost(imbuType, tier)
			local goldCost = ImbuingSystem.GoldCost[tier] or 0
			local msg = "[Imbue] Missing materials for " ..
				ImbuingSystem.TierNames[tier] .. " " .. typeDef.name .. ".\n"
			msg = msg .. "Required: " .. goldCost .. " gold"
			if mats then
				for _, mat in ipairs(mats) do
					local itemType = ItemType(mat[1])
					local itemName = itemType and itemType:getName() or ("item#" .. mat[1])
					msg = msg .. ", " .. itemName .. " x" .. mat[2]
				end
			end
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
			return false
		end

		-- Check for existing active imbue on this slot
		if ImbuingSystem.isActive(player, targetSlot) then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				"[Imbue] Your " .. slotDef.name .. " slot already has an active imbue.")
			return false
		end

		-- Apply directly to the slot (without requiring item UID)
		local goldCost = ImbuingSystem.GoldCost[tier] or 0
		player:setStorageValue(ImbuingSystem.Storage.BASE + slotDef.offset + 0, imbuType)
		player:setStorageValue(ImbuingSystem.Storage.BASE + slotDef.offset + 1, tier)
		player:setStorageValue(ImbuingSystem.Storage.BASE + slotDef.offset + 2, os.time())
		player:setStorageValue(ImbuingSystem.Storage.BASE + slotDef.offset + 3, 0)

		-- Consume materials
		local mats = ImbuingSystem.getMaterialCost(imbuType, tier)
		if mats then
			for _, mat in ipairs(mats) do
				player:removeItem(mat[1], mat[2])
			end
		end
		if goldCost > 0 then
			player:removeMoney(goldCost)
		end

		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)

		local value = typeDef.values[tier]
		local bonus = ""
		if typeDef.bonusValues then
			bonus = ", +" .. typeDef.bonusValues[tier] .. " bonus damage"
		end

		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
			"[Imbue] Applied " .. ImbuingSystem.TierNames[tier] .. " " .. typeDef.name ..
			" (" .. typeDef.desc .. " +" .. value .. typeDef.unit .. bonus .. ")" ..
			" to " .. slotDef.name .. " slot. Duration: 20 hours of active use.")
		return false
	end

	-- Default: show current imbuements
	local msg = "=== Current Imbuements ===\n"
	msg = msg .. ImbuingSystem.getSummary(player) .. "\n"
	msg = msg .. "\nCommands:\n"
	msg = msg .. "  !imbue list - view available imbue types\n"
	msg = msg .. "  !imbue apply <type> <tier> - apply an imbue"
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end
