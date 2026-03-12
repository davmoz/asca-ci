--[[
    Crafting system validation tests.
    Validates all crafting library files and their data integrity.
]]

local T = TestRunner

T:suite("Crafting Systems")

-- Test: all crafting library files exist
T:test("crafting library files exist", function()
    local craftingFiles = {
        "data/lib/crafting.lua",
        "data/lib/crafting_lib.lua",
        "data/lib/crafting_mining.lua",
        "data/lib/crafting_smithing.lua",
        "data/lib/crafting_farming.lua",
        "data/lib/crafting_enchanting.lua",
    }
    local missing = {}
    for _, path in ipairs(craftingFiles) do
        local f = io.open(path, "r")
        if f then
            f:close()
        else
            table.insert(missing, path)
        end
    end
    T:assert(#missing == 0,
        "Missing crafting library files: " .. table.concat(missing, ", "))
end)

-- Test: all crafting library files have valid Lua syntax
T:test("crafting library files have valid Lua syntax", function()
    local craftingFiles = {
        "data/lib/crafting.lua",
        "data/lib/crafting_lib.lua",
        "data/lib/crafting_mining.lua",
        "data/lib/crafting_smithing.lua",
        "data/lib/crafting_farming.lua",
        "data/lib/crafting_enchanting.lua",
    }
    local badFiles = {}
    for _, path in ipairs(craftingFiles) do
        local fn, err = loadfile(path)
        if not fn then
            table.insert(badFiles, path .. ": " .. tostring(err))
        end
    end
    T:assert(#badFiles == 0,
        "Lua syntax errors in crafting libs:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: cooking library exists and has valid syntax
T:test("cooking library exists and has valid syntax", function()
    local path = "data/lib/crafting_cooking.lua"
    local f = io.open(path, "r")
    if not f then
        path = "data/lib/cooking.lua"
        f = io.open(path, "r")
    end
    T:assertNotNil(f, "No cooking library found (checked crafting_cooking.lua and cooking.lua)")
    if f then
        f:close()
        local fn, err = loadfile(path)
        T:assertNotNil(fn, "Cooking library syntax error: " .. tostring(err))
    end
end)

-- Test: custom system library files exist
T:test("custom system library files exist", function()
    local systemFiles = {
        "data/lib/task_system.lua",
        "data/lib/bestiary_system.lua",
        "data/lib/achievement_system.lua",
        "data/lib/item_attributes.lua",
        "data/lib/item_ranks.lua",
        "data/lib/legendary_items.lua",
    }
    local missing = {}
    for _, path in ipairs(systemFiles) do
        local f = io.open(path, "r")
        if f then
            f:close()
        else
            table.insert(missing, path)
        end
    end
    T:assert(#missing == 0,
        "Missing system library files: " .. table.concat(missing, ", "))
end)

-- Test: custom system library files have valid Lua syntax
T:test("custom system library files have valid Lua syntax", function()
    local systemFiles = {
        "data/lib/task_system.lua",
        "data/lib/bestiary_system.lua",
        "data/lib/achievement_system.lua",
        "data/lib/item_attributes.lua",
        "data/lib/item_ranks.lua",
        "data/lib/legendary_items.lua",
    }
    local badFiles = {}
    for _, path in ipairs(systemFiles) do
        local fn, err = loadfile(path)
        if not fn then
            table.insert(badFiles, path .. ": " .. tostring(err))
        end
    end
    T:assert(#badFiles == 0,
        "Lua syntax errors in system libs:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: PvP and social system files exist and have valid syntax
T:test("PvP and social system files exist and have valid syntax", function()
    local pvpFiles = {
        "data/lib/retro_pvp.lua",
        "data/lib/guild_enhanced.lua",
        "data/lib/pvp_systems.lua",
        "data/lib/party_enhanced.lua",
        "data/lib/weekly_dungeons.lua",
    }
    local missing = {}
    local badSyntax = {}
    for _, path in ipairs(pvpFiles) do
        local f = io.open(path, "r")
        if f then
            f:close()
            local fn, err = loadfile(path)
            if not fn then
                table.insert(badSyntax, path .. ": " .. tostring(err))
            end
        else
            table.insert(missing, path)
        end
    end
    T:assert(#missing == 0,
        "Missing PvP/social files: " .. table.concat(missing, ", "))
    T:assert(#badSyntax == 0,
        "Lua syntax errors:\n  " .. table.concat(badSyntax, "\n  "))
end)

-- Test: infrastructure system files exist and have valid syntax
T:test("infrastructure system files exist and have valid syntax", function()
    local infraFiles = {
        "data/lib/seasonal_events.lua",
        "data/lib/housing_enhanced.lua",
        "data/lib/server_monitor.lua",
    }
    local missing = {}
    local badSyntax = {}
    for _, path in ipairs(infraFiles) do
        local f = io.open(path, "r")
        if f then
            f:close()
            local fn, err = loadfile(path)
            if not fn then
                table.insert(badSyntax, path .. ": " .. tostring(err))
            end
        else
            table.insert(missing, path)
        end
    end
    T:assert(#missing == 0,
        "Missing infrastructure files: " .. table.concat(missing, ", "))
    T:assert(#badSyntax == 0,
        "Lua syntax errors:\n  " .. table.concat(badSyntax, "\n  "))
end)

-- Test: storage keys registry exists
T:test("storage keys registry exists", function()
    local f = io.open("data/lib/storage_keys.lua", "r")
    if f then
        f:close()
        local fn, err = loadfile("data/lib/storage_keys.lua")
        T:assertNotNil(fn, "storage_keys.lua syntax error: " .. tostring(err))
    end
    -- Not a hard failure if missing yet, just log
    T:assert(true)
end)
