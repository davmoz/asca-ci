-- ============================================================================
-- Party, Dungeon, and Housing Commands (Phase 5)
-- ============================================================================
-- !party find            - show party finder listings
-- !party register [lvl] [purpose] - register in party finder
-- !dungeon               - show weekly dungeon status
-- !house floor [type]    - change house floor
-- !house rate [1-5]      - rate a house you are visiting
-- !house showroom        - toggle showroom mode
-- ============================================================================

function onSay(player, words, param)
	if words == "!party" then
		return handlePartyCommand(player, param)
	elseif words == "!dungeon" then
		return handleDungeonCommand(player, param)
	elseif words == "!house" then
		return handleHouseCommand(player, param)
	end
	return false
end

-- ============================================================================
-- !party
-- ============================================================================
function handlePartyCommand(player, param)
	local args = param:split(" ")
	local subCmd = args[1] and args[1]:lower() or ""

	if subCmd == "find" then
		player:sendTextMessage(MESSAGE_INFO_DESCR, PartyEnhanced.getFinderListings())
		return false

	elseif subCmd == "register" then
		local minLvl = tonumber(args[2])
		local purpose = args[3] or "general"
		local maxLvl = minLvl and (minLvl + 40) or nil

		local ok, msg = PartyEnhanced.registerFinder(player, minLvl, maxLvl, purpose)
		player:sendTextMessage(ok and MESSAGE_INFO_DESCR or MESSAGE_STATUS_SMALL, msg)
		return false

	elseif subCmd == "quests" then
		player:sendTextMessage(MESSAGE_INFO_DESCR, PartyEnhanced.getQuestList())
		return false

	elseif subCmd == "buffs" then
		local lines = {"=== Party Buffs ==="}
		for key, buff in pairs(PartyEnhanced.BUFFS) do
			lines[#lines + 1] = string.format("- %s (%s)", buff.name, key)
		end
		player:sendTextMessage(MESSAGE_INFO_DESCR, table.concat(lines, "\n"))
		return false

	else
		local help = {
			"=== Party Commands ===",
			"!party find               - Browse party finder listings",
			"!party register [lvl] [purpose] - Register (purposes: hunting, questing, dungeon, boss, general)",
			"!party quests             - View party quests",
			"!party buffs              - View party buff info",
		}
		player:sendTextMessage(MESSAGE_INFO_DESCR, table.concat(help, "\n"))
		return false
	end
end

-- ============================================================================
-- !dungeon
-- ============================================================================
function handleDungeonCommand(player, param)
	player:sendTextMessage(MESSAGE_INFO_DESCR, WeeklyDungeons.getDungeonList(player))
	return false
end

-- ============================================================================
-- !house
-- ============================================================================
function handleHouseCommand(player, param)
	local args = param:split(" ")
	local subCmd = args[1] and args[1]:lower() or ""

	if subCmd == "floor" then
		local floorType = args[2] and args[2]:lower() or nil
		if not floorType then
			player:sendTextMessage(MESSAGE_INFO_DESCR,
				"Usage: !house floor [type]\nAvailable types: " .. HousingEnhanced.getFloorTypeList())
			return false
		end
		local ok, msg = HousingEnhanced.changeFloor(player, floorType)
		player:sendTextMessage(ok and MESSAGE_INFO_DESCR or MESSAGE_STATUS_SMALL, msg)
		return false

	elseif subCmd == "rate" then
		local rating = tonumber(args[2])
		if not rating then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "Usage: !house rate [1-5]")
			return false
		end
		local ok, msg = HousingEnhanced.rateHouse(player, rating)
		player:sendTextMessage(ok and MESSAGE_INFO_DESCR or MESSAGE_STATUS_SMALL, msg)
		return false

	elseif subCmd == "showroom" then
		local ok, msg = HousingEnhanced.toggleShowroom(player)
		player:sendTextMessage(ok and MESSAGE_INFO_DESCR or MESSAGE_STATUS_SMALL, msg)
		return false

	elseif subCmd == "decorations" then
		player:sendTextMessage(MESSAGE_INFO_DESCR, HousingEnhanced.getDecorationCatalog())
		return false

	else
		local help = {
			"=== Housing Commands ===",
			"!house floor [type]       - Change floor tile (in your house)",
			"!house rate [1-5]         - Rate a house you are visiting",
			"!house showroom           - Toggle showroom mode (owner only)",
			"!house decorations        - View decoration catalog",
		}
		player:sendTextMessage(MESSAGE_INFO_DESCR, table.concat(help, "\n"))
		return false
	end
end
