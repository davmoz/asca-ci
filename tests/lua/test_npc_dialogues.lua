--[[
    NPC dialogue and script integrity tests.
    Validates NPC XML files reference valid scripts and scripts have correct structure.
]]

local T = TestRunner

T:suite("NPC Dialogues & Script Integrity")

-- Helper: read file content
local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- Helper: list files via find
local function listFiles(dir, pattern)
    local files = {}
    local cmd = string.format('find "%s" -name "%s" -type f 2>/dev/null', dir, pattern)
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            table.insert(files, line)
        end
        handle:close()
    end
    return files
end

-- Test: every NPC XML file references a Lua script that exists
T:test("all NPC XML script references resolve to existing files", function()
    local xmlFiles = listFiles("data/npc", "*.xml")
    local missing = {}

    for _, xmlPath in ipairs(xmlFiles) do
        -- Skip sub-directories like lib/
        if xmlPath:match("^data/npc/[^/]+%.xml$") then
            local content = readFile(xmlPath)
            if content then
                local script = content:match('script="([^"]+)"')
                if script then
                    local scriptPath = "data/npc/scripts/" .. script
                    local sf = io.open(scriptPath, "r")
                    if sf then
                        sf:close()
                    else
                        table.insert(missing, script .. " (from " .. xmlPath .. ")")
                    end
                end
            end
        end
    end

    T:assert(#missing == 0,
        "NPC XML files reference missing scripts: " .. table.concat(missing, ", "))
end)

-- Test: all NPC Lua scripts have valid syntax
T:test("all NPC Lua scripts pass syntax check", function()
    local scripts = listFiles("data/npc/scripts", "*.lua")
    local bad = {}

    for _, path in ipairs(scripts) do
        local fn, err = loadfile(path)
        if not fn then
            table.insert(bad, path .. ": " .. tostring(err))
        end
    end

    T:assert(#bad == 0,
        "NPC scripts with syntax errors:\n  " .. table.concat(bad, "\n  "))
end)

-- Test: NPC scripts define required callback functions
T:test("NPC scripts define required callbacks (onCreatureAppear, onCreatureSay, onThink)", function()
    local scripts = listFiles("data/npc/scripts", "*.lua")
    local incomplete = {}

    local requiredCallbacks = {
        "onCreatureAppear",
        "onCreatureSay",
        "onThink",
    }

    for _, path in ipairs(scripts) do
        local content = readFile(path)
        if content then
            local missingCbs = {}
            for _, cb in ipairs(requiredCallbacks) do
                -- Look for function definition or assignment
                if not content:find("function%s+" .. cb) and not content:find(cb .. "%s*=") then
                    table.insert(missingCbs, cb)
                end
            end
            if #missingCbs > 0 then
                local shortPath = path:match("scripts/(.+)$") or path
                table.insert(incomplete, shortPath .. " missing: " .. table.concat(missingCbs, ", "))
            end
        end
    end

    T:assert(#incomplete == 0,
        "NPC scripts missing required callbacks:\n  " .. table.concat(incomplete, "\n  "))
end)

-- Test: NPC scripts that define onCreatureDisappear also define onCreatureAppear
T:test("NPC scripts with onCreatureDisappear also have onCreatureAppear", function()
    local scripts = listFiles("data/npc/scripts", "*.lua")
    local mismatched = {}

    for _, path in ipairs(scripts) do
        local content = readFile(path)
        if content then
            local hasDisappear = content:find("onCreatureDisappear") ~= nil
            local hasAppear = content:find("onCreatureAppear") ~= nil
            if hasDisappear and not hasAppear then
                local shortPath = path:match("scripts/(.+)$") or path
                table.insert(mismatched, shortPath)
            end
        end
    end

    T:assert(#mismatched == 0,
        "NPC scripts with onCreatureDisappear but no onCreatureAppear: " .. table.concat(mismatched, ", "))
end)

-- Test: NPC XML files without a script attribute (orphan NPCs)
T:test("all NPC XML files specify a script", function()
    local xmlFiles = listFiles("data/npc", "*.xml")
    local noScript = {}

    for _, xmlPath in ipairs(xmlFiles) do
        if xmlPath:match("^data/npc/[^/]+%.xml$") then
            local content = readFile(xmlPath)
            if content and content:find("<npc%s") then
                if not content:find('script="') then
                    table.insert(noScript, xmlPath)
                end
            end
        end
    end

    T:assert(#noScript == 0,
        "NPC XML files without a script attribute: " .. table.concat(noScript, ", "))
end)

-- Test: NPC trade items - scripts using shopModule:addBuyableItem reference valid item IDs (positive integers)
T:test("NPC shop item IDs are valid positive integers", function()
    local scripts = listFiles("data/npc/scripts", "*.lua")
    local bad = {}

    for _, path in ipairs(scripts) do
        local content = readFile(path)
        if content then
            -- Match addBuyableItem calls and extract the item ID (second argument)
            for call in content:gmatch("addBuyableItem%((.-)%)") do
                local itemId = call:match(",%s*(%d+)")
                if itemId then
                    local id = tonumber(itemId)
                    if not id or id <= 0 or id > 50000 then
                        local shortPath = path:match("scripts/(.+)$") or path
                        table.insert(bad, string.format("%s: itemId=%s", shortPath, tostring(itemId)))
                    end
                end
            end
            for call in content:gmatch("addSellableItem%((.-)%)") do
                local itemId = call:match(",%s*(%d+)")
                if itemId then
                    local id = tonumber(itemId)
                    if not id or id <= 0 or id > 50000 then
                        local shortPath = path:match("scripts/(.+)$") or path
                        table.insert(bad, string.format("%s: itemId=%s", shortPath, tostring(itemId)))
                    end
                end
            end
        end
    end

    T:assert(#bad == 0,
        "NPC shop entries with suspicious item IDs:\n  " .. table.concat(bad, "\n  "))
end)

-- Test: no NPC XML files have empty name attribute
T:test("all NPC XML files have non-empty name attribute", function()
    local xmlFiles = listFiles("data/npc", "*.xml")
    local empty = {}

    for _, xmlPath in ipairs(xmlFiles) do
        if xmlPath:match("^data/npc/[^/]+%.xml$") then
            local content = readFile(xmlPath)
            if content then
                local name = content:match('name="([^"]*)"')
                if name == nil or name == "" then
                    table.insert(empty, xmlPath)
                end
            end
        end
    end

    T:assert(#empty == 0,
        "NPC XML files with empty or missing name: " .. table.concat(empty, ", "))
end)
