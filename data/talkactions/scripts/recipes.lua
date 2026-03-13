-- ============================================================================
-- Recipe List Talkaction (Issue #216)
-- ============================================================================
-- !recipes          - show available crafting categories
-- !recipes cooking  - show cooking recipes
-- !recipes smithing - show smithing recipes
-- ============================================================================

function onSay(player, words, param, channel)
	if not Crafting or not Crafting.recipes then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Crafting system is not available.")
		return false
	end

	-- Parse param
	local category = param and param:lower():match("^%s*(%S+)") or ""

	-- No category: show available categories
	if category == "" then
		local msg = "=== Crafting Recipes ===\n"
		msg = msg .. "Available categories:\n"

		for system, recipes in pairs(Crafting.recipes) do
			local count = #recipes
			if count > 0 then
				msg = msg .. "  " .. system:sub(1, 1):upper() .. system:sub(2) .. " (" .. count .. " recipes)\n"
			end
		end

		msg = msg .. "\nUsage: !recipes <category>\n"
		msg = msg .. "Example: !recipes cooking"
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
		return false
	end

	-- Look up the category
	local recipes = Crafting.recipes[category]
	if not recipes or #recipes == 0 then
		-- Try to find a partial match
		for system, recs in pairs(Crafting.recipes) do
			if system:sub(1, #category) == category and #recs > 0 then
				recipes = recs
				category = system
				break
			end
		end
	end

	if not recipes or #recipes == 0 then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			"[Recipes] Unknown category: " .. param .. ". Use !recipes to see available categories.")
		return false
	end

	-- Display recipes for this category
	local displayName = category:sub(1, 1):upper() .. category:sub(2)
	local skillId = nil
	for id, name in pairs(Crafting.SKILL_NAMES) do
		if name:lower() == category then
			skillId = id
			break
		end
	end

	local playerLevel = 1
	if skillId then
		playerLevel = Crafting.getSkillLevel(player, skillId)
	end

	local msg = "=== " .. displayName .. " Recipes ===\n"
	if skillId then
		msg = msg .. "Your " .. displayName .. " level: " .. playerLevel .. "\n\n"
	end

	for _, recipe in ipairs(recipes) do
		local levelReq = recipe.requiredSkillLevel or 1
		local canCraft = playerLevel >= levelReq
		local status = canCraft and "[+]" or "[-]"

		msg = msg .. status .. " " .. (recipe.name or "Unknown")
		msg = msg .. " (Lvl " .. levelReq .. ")"

		-- Show ingredients
		if recipe.ingredients and #recipe.ingredients > 0 then
			local parts = {}
			for _, ing in ipairs(recipe.ingredients) do
				local itemType = ItemType(ing[1])
				local itemName = itemType and itemType:getName() or ("item#" .. ing[1])
				table.insert(parts, itemName .. " x" .. ing[2])
			end
			msg = msg .. " - " .. table.concat(parts, ", ")
		end

		msg = msg .. "\n"
	end

	msg = msg .. "\n[+] = available, [-] = level too low"
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
	return false
end
