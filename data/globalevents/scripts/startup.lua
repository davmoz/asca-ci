-- Server Startup Event
-- Runs once when the server starts up

function onStartup()
	-- Log startup
	print(">> ASCA Server startup event executed")

	-- Initialize crafting recipe registries
	if Crafting and Crafting.recipes then
		local totalRecipes = 0
		for system, recipes in pairs(Crafting.recipes) do
			totalRecipes = totalRecipes + #recipes
		end
		print(">> Crafting systems loaded: " .. totalRecipes .. " total recipes")
	end

	-- Initialize task system
	if TaskSystem and TaskSystem.tasks then
		print(">> Task system loaded: " .. #TaskSystem.tasks .. " tasks")
	end

	-- Initialize bestiary
	if Bestiary and Bestiary.creatures then
		print(">> Bestiary loaded: " .. #Bestiary.creatures .. " creatures")
	end

	-- Initialize achievement system
	if AchievementSystem and AchievementSystem.achievements then
		print(">> Achievement system loaded: " .. #AchievementSystem.achievements .. " achievements")
	end

	return true
end
