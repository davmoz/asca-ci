--[[
    Shared library validation tests.
    Validates data/lib/ Lua library files.
]]

local T = TestRunner

T:suite("Lib")

-- Test: lib.lua exists
T:test("lib.lua entry point exists", function()
    local f = io.open("data/lib/lib.lua", "r")
    T:assertNotNil(f, "data/lib/lib.lua not found")
    f:close()
end)

-- Test: lib.lua has valid syntax
T:test("lib.lua has valid Lua syntax", function()
    local fn, err = loadfile("data/lib/lib.lua")
    T:assertNotNil(fn, "lib.lua syntax error: " .. tostring(err))
end)

-- Test: core library files exist
T:test("core library files exist", function()
    local coreFiles = {
        "data/lib/core/core.lua",
        "data/lib/core/position.lua",
        "data/lib/core/player.lua",
        "data/lib/core/creature.lua",
        "data/lib/core/item.lua",
        "data/lib/core/game.lua",
        "data/lib/core/container.lua",
        "data/lib/core/combat.lua",
        "data/lib/core/vocation.lua",
        "data/lib/core/tile.lua",
    }
    local missing = {}
    for _, path in ipairs(coreFiles) do
        local f = io.open(path, "r")
        if f then
            f:close()
        else
            table.insert(missing, path)
        end
    end
    T:assert(#missing == 0,
        "Missing core library files: " .. table.concat(missing, ", "))
end)

-- Test: core library files have valid Lua syntax
T:test("core library files have valid Lua syntax", function()
    local handle = io.popen('find data/lib/core -name "*.lua" -type f 2>/dev/null')
    local badFiles = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(badFiles, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end
    T:assert(#badFiles == 0,
        "Lua syntax errors in core lib:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: compat library exists and has valid syntax
T:test("compat library has valid Lua syntax", function()
    local handle = io.popen('find data/lib/compat -name "*.lua" -type f 2>/dev/null')
    local badFiles = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(badFiles, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end
    T:assert(#badFiles == 0,
        "Lua syntax errors in compat lib:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: debugging library files have valid syntax
T:test("debugging library files have valid Lua syntax", function()
    local handle = io.popen('find data/lib/debugging -name "*.lua" -type f 2>/dev/null')
    local badFiles = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(badFiles, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end
    T:assert(#badFiles == 0,
        "Lua syntax errors in debugging lib:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: global.lua exists and has valid syntax
T:test("global.lua exists and has valid syntax", function()
    local f = io.open("data/global.lua", "r")
    T:assertNotNil(f, "data/global.lua not found")
    if f then f:close() end

    local fn, err = loadfile("data/global.lua")
    T:assertNotNil(fn, "global.lua syntax error: " .. tostring(err))
end)

-- Test: migration files have valid Lua syntax
T:test("migration files have valid Lua syntax", function()
    local handle = io.popen('find data/migrations -name "*.lua" -type f 2>/dev/null')
    local badFiles = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(badFiles, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end
    T:assert(#badFiles == 0,
        "Lua syntax errors in migrations:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: expected number of migration files
T:test("expected number of migration files", function()
    local handle = io.popen('find data/migrations -name "*.lua" -type f 2>/dev/null')
    local count = 0
    if handle then
        for _ in handle:lines() do count = count + 1 end
        handle:close()
    end
    T:assert(count >= 20, string.format("Expected at least 20 migration files, found %d", count))
end)

-- Test: all creaturescript files have valid Lua syntax
T:test("creaturescript files have valid Lua syntax", function()
    local handle = io.popen('find data/creaturescripts -name "*.lua" -type f 2>/dev/null')
    local badFiles = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(badFiles, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end
    T:assert(#badFiles == 0,
        "Lua syntax errors in creaturescripts:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: all globalevents files have valid Lua syntax
T:test("globalevent files have valid Lua syntax", function()
    local handle = io.popen('find data/globalevents -name "*.lua" -type f 2>/dev/null')
    local badFiles = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(badFiles, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end
    T:assert(#badFiles == 0,
        "Lua syntax errors in globalevents:\n  " .. table.concat(badFiles, "\n  "))
end)
