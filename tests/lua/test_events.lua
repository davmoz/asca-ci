--[[
    Event system completeness tests.
    Validates that event registrations in XML match actual script files,
    and that login.lua event registrations match creaturescripts.xml entries.
]]

local T = TestRunner

T:suite("Event System Completeness")

-- Helper: read file content
local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- Helper: check file existence
local function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- ============================================================
-- Creaturescripts
-- ============================================================

-- Test: all creaturescript scripts referenced in XML exist
T:test("all creaturescript scripts exist", function()
    local content = readFile("data/creaturescripts/creaturescripts.xml")
    T:assertNotNil(content, "Cannot read creaturescripts.xml")

    local missing = {}
    local checked = {}
    for script in content:gmatch('script="([^"]+)"') do
        if not checked[script] then
            checked[script] = true
            local path = "data/creaturescripts/scripts/" .. script
            if not fileExists(path) then
                table.insert(missing, script)
            end
        end
    end

    T:assert(#missing == 0,
        "Missing creaturescript files: " .. table.concat(missing, ", "))
end)

-- Test: creaturescript scripts have valid Lua syntax
T:test("creaturescript scripts have valid Lua syntax", function()
    local handle = io.popen('find data/creaturescripts/scripts -name "*.lua" -type f 2>/dev/null')
    local bad = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(bad, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end

    T:assert(#bad == 0,
        "Creaturescript syntax errors:\n  " .. table.concat(bad, "\n  "))
end)

-- Test: events registered in login.lua have matching entries in creaturescripts.xml
T:test("login.lua registerEvent calls match creaturescripts.xml names", function()
    local loginContent = readFile("data/creaturescripts/scripts/login.lua")
    T:assertNotNil(loginContent, "Cannot read login.lua")

    local xmlContent = readFile("data/creaturescripts/creaturescripts.xml")
    T:assertNotNil(xmlContent, "Cannot read creaturescripts.xml")

    -- Collect all event names defined in XML
    local xmlEvents = {}
    for name in xmlContent:gmatch('name="([^"]+)"') do
        xmlEvents[name] = true
    end

    -- C++ engine built-in events that are registered but not defined in XML
    local builtinEvents = {
        PlayerDeath = true,
        DropLoot = true,
    }

    -- Collect all registerEvent calls in login.lua
    local unregistered = {}
    for eventName in loginContent:gmatch('registerEvent%("([^"]+)"%)') do
        if not xmlEvents[eventName] and not builtinEvents[eventName] then
            table.insert(unregistered, eventName)
        end
    end

    T:assert(#unregistered == 0,
        "Events registered in login.lua but not defined in creaturescripts.xml: " ..
        table.concat(unregistered, ", "))
end)

-- ============================================================
-- Globalevents
-- ============================================================

-- Test: all globalevent scripts referenced in XML exist
T:test("all globalevent scripts exist", function()
    local content = readFile("data/globalevents/globalevents.xml")
    T:assertNotNil(content, "Cannot read globalevents.xml")

    -- Strip XML comments to avoid matching commented-out entries
    local stripped = content:gsub("<!%-%-.-%-%->" , "")

    local missing = {}
    local checked = {}
    for script in stripped:gmatch('script="([^"]+)"') do
        if not checked[script] then
            checked[script] = true
            local path = "data/globalevents/scripts/" .. script
            if not fileExists(path) then
                table.insert(missing, script)
            end
        end
    end

    T:assert(#missing == 0,
        "Missing globalevent scripts: " .. table.concat(missing, ", "))
end)

-- Test: globalevent scripts have valid Lua syntax
T:test("globalevent scripts have valid Lua syntax", function()
    local handle = io.popen('find data/globalevents/scripts -name "*.lua" -type f 2>/dev/null')
    local bad = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(bad, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end

    T:assert(#bad == 0,
        "Globalevent syntax errors:\n  " .. table.concat(bad, "\n  "))
end)

-- ============================================================
-- Actions
-- ============================================================

-- Test: all action scripts referenced in actions.xml exist
T:test("all action scripts exist", function()
    local content = readFile("data/actions/actions.xml")
    T:assertNotNil(content, "Cannot read actions.xml")

    local missing = {}
    local checked = {}
    for script in content:gmatch('script="([^"]+)"') do
        if not checked[script] then
            checked[script] = true
            local path = "data/actions/scripts/" .. script
            if not fileExists(path) then
                table.insert(missing, script)
            end
        end
    end

    T:assert(#missing == 0,
        "Missing action scripts: " .. table.concat(missing, ", "))
end)

-- Test: action scripts have valid Lua syntax
T:test("action scripts have valid Lua syntax", function()
    local handle = io.popen('find data/actions/scripts -name "*.lua" -type f 2>/dev/null')
    local bad = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(bad, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end

    T:assert(#bad == 0,
        "Action script syntax errors:\n  " .. table.concat(bad, "\n  "))
end)

-- ============================================================
-- Movements
-- ============================================================

-- Test: all movement scripts referenced in movements.xml exist
T:test("all movement scripts exist", function()
    local content = readFile("data/movements/movements.xml")
    T:assertNotNil(content, "Cannot read movements.xml")

    local missing = {}
    local checked = {}
    for script in content:gmatch('script="([^"]+)"') do
        if not checked[script] then
            checked[script] = true
            local path = "data/movements/scripts/" .. script
            if not fileExists(path) then
                table.insert(missing, script)
            end
        end
    end

    T:assert(#missing == 0,
        "Missing movement scripts: " .. table.concat(missing, ", "))
end)

-- Test: movement scripts have valid Lua syntax
T:test("movement scripts have valid Lua syntax", function()
    local handle = io.popen('find data/movements/scripts -name "*.lua" -type f 2>/dev/null')
    local bad = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(bad, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end

    T:assert(#bad == 0,
        "Movement script syntax errors:\n  " .. table.concat(bad, "\n  "))
end)

-- ============================================================
-- Talkactions
-- ============================================================

-- Test: all talkaction scripts referenced in talkactions.xml exist
T:test("all talkaction scripts exist", function()
    local content = readFile("data/talkactions/talkactions.xml")
    T:assertNotNil(content, "Cannot read talkactions.xml")

    -- Strip XML comments
    content = content:gsub("<!%-%-.-%%-%->", "")

    local missing = {}
    local checked = {}
    for script in content:gmatch('script="([^"]+)"') do
        if not checked[script] then
            checked[script] = true
            local path = "data/talkactions/scripts/" .. script
            if not fileExists(path) then
                table.insert(missing, script)
            end
        end
    end

    T:assert(#missing == 0,
        "Missing talkaction scripts: " .. table.concat(missing, ", "))
end)

-- Test: talkaction scripts have valid Lua syntax
T:test("talkaction scripts have valid Lua syntax", function()
    local handle = io.popen('find data/talkactions/scripts -name "*.lua" -type f 2>/dev/null')
    local bad = {}
    if handle then
        for path in handle:lines() do
            local fn, err = loadfile(path)
            if not fn then
                table.insert(bad, path .. ": " .. tostring(err))
            end
        end
        handle:close()
    end

    T:assert(#bad == 0,
        "Talkaction script syntax errors:\n  " .. table.concat(bad, "\n  "))
end)

-- ============================================================
-- Cross-system consistency
-- ============================================================

-- Test: no orphan scripts in creaturescripts/scripts/ (exist on disk but not in XML)
T:test("no orphan creaturescript files (on disk but not in XML)", function()
    local xmlContent = readFile("data/creaturescripts/creaturescripts.xml")
    T:assertNotNil(xmlContent)

    -- Collect scripts referenced in XML
    local referenced = {}
    for script in xmlContent:gmatch('script="([^"]+)"') do
        referenced[script] = true
    end

    -- List actual files
    local handle = io.popen('find data/creaturescripts/scripts -maxdepth 1 -name "*.lua" -type f 2>/dev/null')
    local orphans = {}
    if handle then
        for path in handle:lines() do
            local filename = path:match("([^/]+)$")
            if filename and not referenced[filename] then
                table.insert(orphans, filename)
            end
        end
        handle:close()
    end

    -- Orphans are a warning, not necessarily an error, but worth flagging
    T:assert(#orphans == 0,
        "Creaturescript files on disk but not in XML (possibly orphaned): " ..
        table.concat(orphans, ", "))
end)

-- Test: no orphan globalevent scripts
T:test("no orphan globalevent files (on disk but not in XML)", function()
    local xmlContent = readFile("data/globalevents/globalevents.xml")
    T:assertNotNil(xmlContent)

    local referenced = {}
    for script in xmlContent:gmatch('script="([^"]+)"') do
        referenced[script] = true
    end

    local handle = io.popen('find data/globalevents/scripts -maxdepth 1 -name "*.lua" -type f 2>/dev/null')
    local orphans = {}
    if handle then
        for path in handle:lines() do
            local filename = path:match("([^/]+)$")
            if filename and not referenced[filename] then
                table.insert(orphans, filename)
            end
        end
        handle:close()
    end

    T:assert(#orphans == 0,
        "Globalevent files on disk but not in XML (possibly orphaned): " ..
        table.concat(orphans, ", "))
end)
