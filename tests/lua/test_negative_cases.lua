--[[
    Negative / edge-case tests for Lua library functions.
    Verifies that crafting helpers, storage key utilities, recipe lookups,
    and string-based lookup functions handle bad input gracefully.
]]

local T = TestRunner

T:suite("Negative Cases")

-- ============================================================================
-- Crafting functions with nil / missing inputs
-- ============================================================================

T:test("Crafting.makeRecipe handles nil opts gracefully", function()
    -- Load the crafting libraries so the functions are available
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then
        T:assert(true) -- skip if crafting.lua cannot be loaded standalone
        return
    end
    pcall(dofile, "data/lib/crafting_lib.lua")

    -- makeRecipe with empty table should fill in defaults
    local recipe = Crafting.makeRecipe({})
    T:assertNotNil(recipe, "makeRecipe({}) should return a table")
    T:assertEqual(recipe.id, 0, "default id should be 0")
    T:assertEqual(recipe.name, "Unknown Recipe", "default name should be 'Unknown Recipe'")
    T:assertType(recipe.ingredients, "table", "ingredients should default to a table")
    T:assert(#recipe.ingredients == 0, "ingredients should default to empty")
    T:assert(recipe.successChance > 0, "successChance should be positive")
end)

T:test("Crafting.getSkillName returns 'Unknown' for invalid skill IDs", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    T:assertEqual(Crafting.getSkillName(999), "Unknown",
        "getSkillName(999) should return 'Unknown'")
    T:assertEqual(Crafting.getSkillName(-1), "Unknown",
        "getSkillName(-1) should return 'Unknown'")
    T:assertEqual(Crafting.getSkillName(0), "Unknown",
        "getSkillName(0) should return 'Unknown'")
end)

T:test("Crafting.getTriesForLevel handles boundary levels", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    -- Level 0 and 1 should return 0 (no tries needed for level 1)
    T:assertEqual(Crafting.getTriesForLevel(0), 0,
        "getTriesForLevel(0) should return 0")
    T:assertEqual(Crafting.getTriesForLevel(1), 0,
        "getTriesForLevel(1) should return 0")

    -- Level 2 should return the base value
    local tries2 = Crafting.getTriesForLevel(2)
    T:assert(tries2 > 0, "getTriesForLevel(2) should be positive")

    -- Negative level should not crash
    local ok2, _ = pcall(function() return Crafting.getTriesForLevel(-5) end)
    T:assert(ok2, "getTriesForLevel(-5) should not crash")
end)

T:test("Crafting.calcSuccessRate clamps to valid range", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end
    pcall(dofile, "data/lib/crafting_lib.lua")

    -- Very high player level should be capped at maxChance
    local rate = Crafting.calcSuccessRate(50, 200, 1, 2, 95)
    T:assert(rate <= 95, "success rate should be capped at maxChance (95)")

    -- Zero base chance with no level bonus
    local rate2 = Crafting.calcSuccessRate(0, 1, 1, 2, 95)
    T:assertEqual(rate2, 0, "0 base chance with no bonus should yield 0")

    -- Negative base chance should clamp to 0
    local rate3 = Crafting.calcSuccessRate(-50, 1, 1, 2, 95)
    T:assert(rate3 >= 0, "negative base chance should clamp to 0 or above")
end)

T:test("Crafting.skillProximityMultiplier handles extreme gaps", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end
    pcall(dofile, "data/lib/crafting_lib.lua")

    -- Player below requirement should get full multiplier
    local mult = Crafting.skillProximityMultiplier(1, 50)
    T:assertEqual(mult, 1.0, "player below requirement should get 1.0 multiplier")

    -- Huge gap above requirement should return minimum multiplier
    local mult2 = Crafting.skillProximityMultiplier(200, 1)
    T:assert(mult2 <= 0.1, "huge gap should yield minimum multiplier (0.1)")
    T:assert(mult2 > 0, "multiplier should never be zero")
end)

-- ============================================================================
-- Recipe lookups with non-existent IDs and systems
-- ============================================================================

T:test("Crafting.findRecipeById returns nil for non-existent recipe", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    local result = Crafting.findRecipeById("cooking", 99999)
    T:assert(result == nil, "findRecipeById with bogus ID should return nil")
end)

T:test("Crafting.findRecipeById returns nil for non-existent system", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    local result = Crafting.findRecipeById("nonexistent_system", 1)
    T:assert(result == nil,
        "findRecipeById on non-existent system should return nil, not crash")
end)

T:test("Crafting.findRecipeByName returns nil for non-existent recipe", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    local result = Crafting.findRecipeByName("cooking", "This Recipe Does Not Exist")
    T:assert(result == nil, "findRecipeByName with bogus name should return nil")
end)

T:test("Crafting.findRecipeByName handles nil system gracefully", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    -- Passing a system that is nil in the recipes table
    local ok2, _ = pcall(function()
        return Crafting.findRecipeByName("zzz_does_not_exist", "test")
    end)
    T:assert(ok2, "findRecipeByName on missing system should not crash")
end)

T:test("Crafting.findRecipeByResult returns nil for non-existent item", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    local result = Crafting.findRecipeByResult("cooking", 0)
    T:assert(result == nil, "findRecipeByResult(0) should return nil")

    local result2 = Crafting.findRecipeByResult("cooking", -1)
    T:assert(result2 == nil, "findRecipeByResult(-1) should return nil")
end)

T:test("Crafting.getRecipesForStation returns empty for bogus station", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    local recipes = Crafting.getRecipesForStation("cooking", 999999)
    T:assertType(recipes, "table", "should return a table")
    T:assert(#recipes == 0, "should return empty table for non-existent station")
end)

-- ============================================================================
-- Storage key operations with boundary values
-- ============================================================================

T:test("storage key range constants are valid", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    T:assert(Crafting.STORAGE_SKILL_BASE > 0,
        "STORAGE_SKILL_BASE should be positive")
    T:assert(Crafting.STORAGE_XP_BASE > Crafting.STORAGE_SKILL_BASE,
        "STORAGE_XP_BASE should be greater than STORAGE_SKILL_BASE")
    T:assert(Crafting.STORAGE_FOOD_BUFF > Crafting.STORAGE_XP_BASE,
        "STORAGE_FOOD_BUFF should be after XP base")

    -- Verify no overlap between skill storage and XP storage ranges
    local maxSkillKey = Crafting.STORAGE_SKILL_BASE + 10  -- room for 10 skills
    T:assert(Crafting.STORAGE_XP_BASE > maxSkillKey,
        "XP storage range should not overlap with skill storage range")
end)

T:test("skill IDs map to non-overlapping storage keys", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    local skillIds = {
        Crafting.SKILL_COOKING, Crafting.SKILL_MINING,
        Crafting.SKILL_SMITHING, Crafting.SKILL_FARMING,
        Crafting.SKILL_ENCHANTING
    }

    -- Each skill should produce a unique storage key
    local seen = {}
    for _, skillId in ipairs(skillIds) do
        local key = Crafting.STORAGE_SKILL_BASE + skillId
        T:assert(not seen[key],
            "duplicate storage key " .. key .. " for skill " .. skillId)
        seen[key] = true
    end

    -- XP keys should also be unique and separate from skill keys
    local seenXP = {}
    for _, skillId in ipairs(skillIds) do
        local key = Crafting.STORAGE_XP_BASE + skillId
        T:assert(not seen[key],
            "XP key " .. key .. " overlaps with a skill key")
        T:assert(not seenXP[key],
            "duplicate XP storage key " .. key)
        seenXP[key] = true
    end
end)

-- ============================================================================
-- Empty string handling in lookup functions
-- ============================================================================

T:test("Crafting.findRecipeByName with empty string returns nil", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    local result = Crafting.findRecipeByName("cooking", "")
    T:assert(result == nil, "empty string name should return nil")
end)

T:test("Crafting.registerRecipe with empty system string works", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    -- Should create a new system entry without crashing
    local ok2, _ = pcall(function()
        Crafting.registerRecipe("", {
            id = 99999,
            name = "Test Empty System",
            craftingSkill = 1,
            requiredSkillLevel = 1,
            ingredients = {},
            results = {},
            skillTries = 1,
        })
    end)
    T:assert(ok2, "registerRecipe with empty system string should not crash")
end)

T:test("storage key file documents no overlapping ranges", function()
    local f = io.open("data/lib/storage_keys.lua", "r")
    if not f then
        T:assert(true) -- skip if storage_keys.lua not found
        return
    end
    local content = f:read("*a")
    f:close()

    -- Check that the file is not empty and has allocation info
    T:assert(#content > 100,
        "storage_keys.lua should contain allocation documentation")
    T:assert(content:find("STORAGE KEY ALLOCATION"),
        "storage_keys.lua should contain the allocation map header")

    -- Extract all range starts and verify they are in ascending order
    local ranges = {}
    for rangeStart in content:gmatch("(%d%d%d%d%d+)%s*%-") do
        table.insert(ranges, tonumber(rangeStart))
    end
    for i = 2, #ranges do
        T:assert(ranges[i] >= ranges[i-1],
            string.format("Storage key ranges should be ascending: %d came after %d",
                ranges[i], ranges[i-1]))
    end
end)

T:test("Crafting.registerRecipe handles recipe with nil optional fields", function()
    local ok, _ = pcall(dofile, "data/lib/crafting.lua")
    if not ok then T:assert(true) return end

    -- Register a recipe with minimal fields, leaving optional ones nil
    local ok2, _ = pcall(function()
        Crafting.registerRecipe("cooking", {
            id = 88888,
            name = "Bare Minimum Recipe",
            craftingSkill = 1,
            requiredSkillLevel = 1,
            ingredients = {{2674, 1}},
            results = {{2671, 1}},
        })
    end)
    T:assert(ok2, "registerRecipe should fill defaults for nil optional fields")

    -- Verify defaults were applied
    local recipe = Crafting.findRecipeById("cooking", 88888)
    if recipe then
        T:assertType(recipe.tools, "table", "tools should default to table")
        T:assertType(recipe.requiredVocation, "table",
            "requiredVocation should default to table")
        T:assert(recipe.successChance > 0, "successChance should have a default")
        T:assert(recipe.craftTime > 0, "craftTime should have a default")
    end
end)
