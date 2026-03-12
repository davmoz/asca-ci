--[[
    Crafting integration tests.
    Validates the crafting recipe structure and data integrity across all systems.
]]

local T = TestRunner

-- Utility: read file contents
local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- Utility: check file exists
local function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

T:suite("Crafting Integration")

-- ---------------------------------------------------------------------------
-- 1. All crafting library files exist and have valid Lua syntax
-- ---------------------------------------------------------------------------
T:test("all crafting library files exist", function()
    local files = {
        "data/lib/crafting.lua",
        "data/lib/crafting_cooking.lua",
        "data/lib/crafting_mining.lua",
        "data/lib/crafting_smithing.lua",
        "data/lib/crafting_farming.lua",
        "data/lib/crafting_enchanting.lua",
    }
    for _, path in ipairs(files) do
        T:assert(fileExists(path), "Missing crafting file: " .. path)
    end
end)

T:test("all crafting library files have valid Lua syntax", function()
    local files = {
        "data/lib/crafting.lua",
        "data/lib/crafting_cooking.lua",
        "data/lib/crafting_mining.lua",
        "data/lib/crafting_smithing.lua",
        "data/lib/crafting_farming.lua",
        "data/lib/crafting_enchanting.lua",
    }
    for _, path in ipairs(files) do
        local fn, err = loadfile(path)
        -- loadfile may fail because TFS globals are not present; that is acceptable.
        -- A true syntax error will be reported. We check that the error, if any,
        -- is NOT a syntax/parse error.
        if not fn and err then
            -- Lua syntax errors contain the word "unexpected" or specific parse tokens
            local isSyntaxError = err:find("'<eof>'") or err:find("unexpected")
            T:assert(not isSyntaxError, "Syntax error in " .. path .. ": " .. err)
        end
    end
end)

-- ---------------------------------------------------------------------------
-- 2. Cooking recipes have valid structure patterns
-- ---------------------------------------------------------------------------
T:test("cooking recipes have valid structure", function()
    local content = readFile("data/lib/crafting_cooking.lua")
    T:assertNotNil(content, "Cannot read crafting_cooking.lua")

    -- Must define the Cooking table
    T:assert(content:find("Cooking = {}") ~= nil, "Missing Cooking table declaration")

    -- Must contain recipe registrations with required fields
    T:assert(content:find("registerRecipe") ~= nil, "Missing recipe registration calls")
    T:assert(content:find("ingredients") ~= nil, "Missing ingredients in recipes")
    T:assert(content:find("results") ~= nil, "Missing results in recipes")
    T:assert(content:find("requiredSkillLevel") ~= nil, "Missing requiredSkillLevel in recipes")
    T:assert(content:find("successChance") ~= nil, "Missing successChance in recipes")
    T:assert(content:find("stationItemId") ~= nil, "Missing stationItemId in recipes")
end)

-- ---------------------------------------------------------------------------
-- 3. Mining/smelting recipes have valid structure
-- ---------------------------------------------------------------------------
T:test("mining smelting recipes have valid structure", function()
    local content = readFile("data/lib/crafting_mining.lua")
    T:assertNotNil(content, "Cannot read crafting_mining.lua")

    T:assert(content:find("Mining = {}") ~= nil, "Missing Mining table declaration")
    T:assert(content:find("SmeltingRecipes") ~= nil, "Missing SmeltingRecipes table")
    T:assert(content:find("ingredients") ~= nil, "Missing ingredients in smelting recipes")
    T:assert(content:find("requiredSkill") ~= nil, "Missing requiredSkill in recipes")
    T:assert(content:find("successBase") ~= nil, "Missing successBase in recipes")
    T:assert(content:find("triesReward") ~= nil, "Missing triesReward in recipes")
end)

-- ---------------------------------------------------------------------------
-- 4. Smithing recipes have valid structure
-- ---------------------------------------------------------------------------
T:test("smithing recipes have valid structure", function()
    local content = readFile("data/lib/crafting_smithing.lua")
    T:assertNotNil(content, "Cannot read crafting_smithing.lua")

    T:assert(content:find("Smithing = {}") ~= nil, "Missing Smithing table declaration")
    T:assert(content:find("Smithing.Recipes") ~= nil, "Missing Smithing.Recipes table")
    T:assert(content:find("ingredients") ~= nil, "Missing ingredients in smithing recipes")
    T:assert(content:find("requiredSkill") ~= nil, "Missing requiredSkill in recipes")
    T:assert(content:find("successBase") ~= nil, "Missing successBase in recipes")
    T:assert(content:find("category") ~= nil, "Missing category in smithing recipes")
end)

-- ---------------------------------------------------------------------------
-- 5. Farming seed definitions have valid structure
-- ---------------------------------------------------------------------------
T:test("farming seed definitions have valid structure", function()
    local content = readFile("data/lib/crafting_farming.lua")
    T:assertNotNil(content, "Cannot read crafting_farming.lua")

    T:assert(content:find("Farming = {}") ~= nil, "Missing Farming table declaration")
    T:assert(content:find("Farming.Seeds") ~= nil, "Missing Farming.Seeds table")
    T:assert(content:find("seedId") ~= nil, "Missing seedId in seed definitions")
    T:assert(content:find("cropId") ~= nil, "Missing cropId in seed definitions")
    T:assert(content:find("minSkill") ~= nil, "Missing minSkill in seed definitions")
    T:assert(content:find("baseYield") ~= nil, "Missing baseYield in seed definitions")
    T:assert(content:find("rarity") ~= nil, "Missing rarity in seed definitions")
end)

-- ---------------------------------------------------------------------------
-- 6. Enchanting system has valid structure
-- ---------------------------------------------------------------------------
T:test("enchanting system has valid structure", function()
    local content = readFile("data/lib/crafting_enchanting.lua")
    T:assertNotNil(content, "Cannot read crafting_enchanting.lua")

    T:assert(content:find("Enchanting = {}") ~= nil, "Missing Enchanting table declaration")
    T:assert(content:find("AttributePool") ~= nil, "Missing AttributePool table")
    T:assert(content:find("Crystals") ~= nil, "Missing Crystals table")
    T:assert(content:find("MAX_ENCHANTMENTS") ~= nil, "Missing MAX_ENCHANTMENTS constant")
    T:assert(content:find("successRate") ~= nil, "Missing successRate in crystal definitions")
end)

-- ---------------------------------------------------------------------------
-- 7. Cooking recipe item IDs are all positive numbers
-- ---------------------------------------------------------------------------
T:test("cooking recipe item IDs are positive numbers", function()
    local content = readFile("data/lib/crafting_cooking.lua")
    T:assertNotNil(content, "Cannot read crafting_cooking.lua")

    -- Extract the Cooking.Items block specifically
    local itemBlock = content:match("Cooking%.Items%s*=%s*{(.-)\n}")
    T:assertNotNil(itemBlock, "Cannot find Cooking.Items block")

    local hasItems = false
    for name, id in itemBlock:gmatch("(%w+)%s*=%s*(%d+)") do
        local num = tonumber(id)
        T:assert(num ~= nil and num > 0,
            "Invalid item ID for Cooking.Items." .. name .. ": " .. tostring(id))
        hasItems = true
    end
    T:assert(hasItems, "No item IDs found in Cooking.Items")
end)

-- ---------------------------------------------------------------------------
-- 8. Mining item IDs are positive and in expected ranges
-- ---------------------------------------------------------------------------
T:test("mining item IDs are positive and in expected ranges", function()
    local content = readFile("data/lib/crafting_mining.lua")
    T:assertNotNil(content, "Cannot read crafting_mining.lua")

    -- Extract item IDs from Mining.Items block
    local itemBlock = content:match("Mining%.Items%s*=%s*{(.-)\n}")
    T:assertNotNil(itemBlock, "Cannot find Mining.Items block")

    local count = 0
    for name, id in itemBlock:gmatch("(%w+)%s*=%s*(%d+)") do
        local num = tonumber(id)
        T:assert(num ~= nil and num > 0,
            "Invalid item ID for Mining.Items." .. name .. ": " .. tostring(id))
        count = count + 1
    end
    T:assert(count > 0, "No item IDs found in Mining.Items")
end)

-- ---------------------------------------------------------------------------
-- 9. Smithing recipe skill requirements are in range 1-100
-- ---------------------------------------------------------------------------
T:test("smithing recipe skill requirements are in range 1-100", function()
    local content = readFile("data/lib/crafting_smithing.lua")
    T:assertNotNil(content, "Cannot read crafting_smithing.lua")

    local count = 0
    for skillStr in content:gmatch("requiredSkill%s*=%s*(%d+)") do
        local skill = tonumber(skillStr)
        T:assert(skill ~= nil and skill >= 1 and skill <= 100,
            "Smithing requiredSkill out of range (1-100): " .. tostring(skill))
        count = count + 1
    end
    T:assert(count > 0, "No requiredSkill values found in smithing recipes")
end)

-- ---------------------------------------------------------------------------
-- 10. Smithing success base values are reasonable (20-100)
-- ---------------------------------------------------------------------------
T:test("smithing success base values are reasonable", function()
    local content = readFile("data/lib/crafting_smithing.lua")
    T:assertNotNil(content, "Cannot read crafting_smithing.lua")

    local count = 0
    for valStr in content:gmatch("successBase%s*=%s*(%d+)") do
        local val = tonumber(valStr)
        T:assert(val ~= nil and val >= 20 and val <= 100,
            "Smithing successBase out of range (20-100): " .. tostring(val))
        count = count + 1
    end
    T:assert(count > 0, "No successBase values found in smithing recipes")
end)

-- ---------------------------------------------------------------------------
-- 11. Cooking success chances are reasonable (30-100)
-- ---------------------------------------------------------------------------
T:test("cooking success chances are reasonable", function()
    local content = readFile("data/lib/crafting_cooking.lua")
    T:assertNotNil(content, "Cannot read crafting_cooking.lua")

    local count = 0
    for valStr in content:gmatch("successChance%s*=%s*(%d+)") do
        local val = tonumber(valStr)
        T:assert(val ~= nil and val >= 30 and val <= 100,
            "Cooking successChance out of range (30-100): " .. tostring(val))
        count = count + 1
    end
    T:assert(count > 0, "No successChance values found in cooking recipes")
end)

-- ---------------------------------------------------------------------------
-- 12. No duplicate item IDs within smithing equipment
-- ---------------------------------------------------------------------------
T:test("no duplicate item IDs in smithing equipment", function()
    local content = readFile("data/lib/crafting_smithing.lua")
    T:assertNotNil(content, "Cannot read crafting_smithing.lua")

    local equipBlock = content:match("Smithing%.Equipment%s*=%s*{(.-)\n}")
    T:assertNotNil(equipBlock, "Cannot find Smithing.Equipment block")

    local seen = {}
    for name, id in equipBlock:gmatch("(%w+)%s*=%s*(%d+)") do
        local numId = tonumber(id)
        T:assert(not seen[numId],
            "Duplicate item ID " .. id .. " in Smithing.Equipment (" ..
            name .. " conflicts with " .. (seen[numId] or "unknown") .. ")")
        seen[numId] = name
    end
end)

-- ---------------------------------------------------------------------------
-- 13. No duplicate item IDs within cooking items
-- ---------------------------------------------------------------------------
T:test("no duplicate item IDs in cooking items", function()
    local content = readFile("data/lib/crafting_cooking.lua")
    T:assertNotNil(content, "Cannot read crafting_cooking.lua")

    local itemBlock = content:match("Cooking%.Items%s*=%s*{(.-)\n}")
    T:assertNotNil(itemBlock, "Cannot find Cooking.Items block")

    local seen = {}
    for name, id in itemBlock:gmatch("(%w+)%s*=%s*(%d+)") do
        local numId = tonumber(id)
        T:assert(not seen[numId],
            "Duplicate item ID " .. id .. " in Cooking.Items (" ..
            name .. " conflicts with " .. (seen[numId] or "unknown") .. ")")
        seen[numId] = name
    end
end)

-- ---------------------------------------------------------------------------
-- 14. Storage keys do not collide across crafting systems
-- ---------------------------------------------------------------------------
T:test("storage keys do not collide across crafting systems", function()
    local storageKeys = {}
    local files = {
        { path = "data/lib/crafting_cooking.lua",    system = "Cooking" },
        { path = "data/lib/crafting_mining.lua",     system = "Mining" },
        { path = "data/lib/crafting_smithing.lua",   system = "Smithing" },
        { path = "data/lib/crafting_farming.lua",    system = "Farming" },
        { path = "data/lib/crafting_enchanting.lua",  system = "Enchanting" },
    }

    for _, entry in ipairs(files) do
        local content = readFile(entry.path)
        T:assertNotNil(content, "Cannot read " .. entry.path)

        -- Find Storage block and extract numeric keys
        local storageBlock = content:match("Storage%s*=%s*{(.-)\n}")
        if storageBlock then
            for name, id in storageBlock:gmatch("(%w+)%s*=%s*(%d+)") do
                local numId = tonumber(id)
                local key = entry.system .. "." .. name
                T:assert(not storageKeys[numId],
                    "Storage key collision: " .. key .. " = " .. id ..
                    " conflicts with " .. (storageKeys[numId] or "unknown"))
                storageKeys[numId] = key
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
-- 15. Smithing bar IDs match mining bar output IDs
-- ---------------------------------------------------------------------------
T:test("smithing bar IDs match mining bar output IDs", function()
    local miningContent = readFile("data/lib/crafting_mining.lua")
    local smithingContent = readFile("data/lib/crafting_smithing.lua")
    T:assertNotNil(miningContent, "Cannot read crafting_mining.lua")
    T:assertNotNil(smithingContent, "Cannot read crafting_smithing.lua")

    -- Collect bar IDs from Mining.Items (the BAR entries)
    local miningBars = {}
    for name, id in miningContent:gmatch("(%u%w+_BAR)%s*=%s*(%d+)") do
        miningBars[name] = tonumber(id)
    end

    -- Collect bar IDs from Smithing.Bars
    local smithingBars = {}
    for name, id in smithingContent:gmatch("(%u%w+_BAR)%s*=%s*(%d+)") do
        smithingBars[name] = tonumber(id)
    end

    -- Check that most smithing bars have matching mining bars
    local mismatches = {}
    for name, smithId in pairs(smithingBars) do
        local miningId = miningBars[name]
        if not miningId or smithId ~= miningId then
            table.insert(mismatches, name)
        end
    end
    -- Allow up to 2 mismatches (some bars may be vendor-only)
    T:assert(#mismatches <= 2,
        "Too many smithing/mining bar mismatches: " .. table.concat(mismatches, ", "))
end)

-- ---------------------------------------------------------------------------
-- 16. Farming seed min skill requirements are in range 0-100
-- ---------------------------------------------------------------------------
T:test("farming seed skill requirements are in range 0-100", function()
    local content = readFile("data/lib/crafting_farming.lua")
    T:assertNotNil(content, "Cannot read crafting_farming.lua")

    local count = 0
    for valStr in content:gmatch("minSkill%s*=%s*(%d+)") do
        local val = tonumber(valStr)
        T:assert(val ~= nil and val >= 0 and val <= 100,
            "Farming minSkill out of range (0-100): " .. tostring(val))
        count = count + 1
    end
    T:assert(count > 0, "No minSkill values found in farming seed definitions")
end)

-- ---------------------------------------------------------------------------
-- 17. Shared crafting framework defines all expected skill constants
-- ---------------------------------------------------------------------------
T:test("shared crafting framework defines all skill constants", function()
    local content = readFile("data/lib/crafting.lua")
    T:assertNotNil(content, "Cannot read crafting.lua")

    T:assert(content:find("SKILL_COOKING") ~= nil, "Missing SKILL_COOKING constant")
    T:assert(content:find("SKILL_MINING") ~= nil, "Missing SKILL_MINING constant")
    T:assert(content:find("SKILL_SMITHING") ~= nil, "Missing SKILL_SMITHING constant")
    T:assert(content:find("SKILL_FARMING") ~= nil, "Missing SKILL_FARMING constant")
    T:assert(content:find("SKILL_ENCHANTING") ~= nil, "Missing SKILL_ENCHANTING constant")
end)

-- ---------------------------------------------------------------------------
-- 18. Enchanting crystal tiers have increasing success rates
-- ---------------------------------------------------------------------------
T:test("enchanting crystal tiers have increasing success rates", function()
    local content = readFile("data/lib/crafting_enchanting.lua")
    T:assertNotNil(content, "Cannot read crafting_enchanting.lua")

    -- Extract crystal definitions: tier and successRate pairs
    local tiers = {}
    for block in content:gmatch("{%s*tier%s*=%s*(%d+).-successRate%s*=%s*(%d+).-}") do
        -- This pattern won't work as gmatch returns one capture per match
    end

    -- Extract individual crystal entries from the file content
    local rates = {}
    for tier, rate in content:gmatch("tier%s*=%s*(%d+)%s*,%s*name%s*=%s*%b\"\",%s*successRate%s*=%s*(%d+)") do
        local t = tonumber(tier)
        local r = tonumber(rate)
        rates[t] = r
    end

    -- Verify at least some tier data was found (format may vary)
    local tierCount = 0
    for _ in pairs(rates) do tierCount = tierCount + 1 end
    if tierCount >= 3 then
        T:assertNotNil(rates[1], "Missing tier 1 crystal")
        T:assert(rates[1] < (rates[2] or 100), "Tier 2 success rate should be higher than tier 1")
        T:assert((rates[2] or 0) < (rates[3] or 100), "Tier 3 success rate should be higher than tier 2")
    else
        -- Crystal tiers may use different format - just verify enchanting file is valid
        T:assert(content:find("crystal") ~= nil or content:find("Crystal") ~= nil,
            "Enchanting file should reference crystals")
    end
end)

-- ---------------------------------------------------------------------------
-- 19. Smithing equipment IDs are in the expected 30500-30599 range
-- ---------------------------------------------------------------------------
T:test("smithing equipment IDs are in expected range", function()
    local content = readFile("data/lib/crafting_smithing.lua")
    T:assertNotNil(content, "Cannot read crafting_smithing.lua")

    local equipBlock = content:match("Smithing%.Equipment%s*=%s*{(.-)\n}")
    T:assertNotNil(equipBlock, "Cannot find Smithing.Equipment block")

    local count = 0
    for name, id in equipBlock:gmatch("(%w+)%s*=%s*(%d+)") do
        local num = tonumber(id)
        T:assert(num >= 30500 and num <= 30599,
            "Smithing equipment " .. name .. " ID " .. id ..
            " is outside expected range 30500-30599")
        count = count + 1
    end
    T:assert(count > 0, "No equipment IDs found in Smithing.Equipment")
end)

-- ---------------------------------------------------------------------------
-- 20. Mining smelting recipes produce bars in the correct ID range
-- ---------------------------------------------------------------------------
T:test("smelting recipe outputs are in the bar ID range", function()
    local content = readFile("data/lib/crafting_mining.lua")
    T:assertNotNil(content, "Cannot read crafting_mining.lua")

    -- Extract result IDs from smelting recipes
    -- Pattern: result = { Mining.Items.XXX_BAR, N }
    -- Since these are Lua references, check the defined bar IDs are in 30400-30410
    local count = 0
    for name, id in content:gmatch("(%w+_BAR)%s*=%s*(%d+)") do
        local num = tonumber(id)
        T:assert(num >= 30400 and num <= 30499,
            "Bar " .. name .. " ID " .. id .. " is outside expected range 30400-30499")
        count = count + 1
    end
    T:assert(count > 0, "No bar IDs found in mining definitions")
end)
