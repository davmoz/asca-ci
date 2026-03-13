--[[
    NPC validation tests.
    Validates NPC XML definitions and script files.
]]

local T = TestRunner

T:suite("NPCs")

-- Test: NPC directory exists
T:test("NPC directory exists", function()
    local handle = io.popen('ls data/npc/ 2>/dev/null | head -1')
    local result = handle:read("*a")
    handle:close()
    T:assert(result ~= "", "data/npc/ directory is empty or missing")
end)

-- Test: NPC XML files exist
T:test("NPC XML files are present", function()
    local handle = io.popen('find data/npc -maxdepth 1 -name "*.xml" -type f 2>/dev/null')
    local count = 0
    if handle then
        for _ in handle:lines() do count = count + 1 end
        handle:close()
    end
    T:assert(count > 0, string.format("Expected NPC XML files, found %d", count))
end)

-- Test: NPC XML files have valid structure
T:test("NPC XML files have valid structure", function()
    local handle = io.popen('find data/npc -maxdepth 1 -name "*.xml" -type f 2>/dev/null')
    local badFiles = {}
    if handle then
        for path in handle:lines() do
            local f = io.open(path, "r")
            if f then
                local content = f:read("*a")
                f:close()
                if not content:find("<npc%s") then
                    table.insert(badFiles, path .. ": missing <npc> element")
                end
                if not content:find('name="') then
                    table.insert(badFiles, path .. ": missing name attribute")
                end
            end
        end
        handle:close()
    end
    T:assert(#badFiles == 0,
        "NPC files with structural issues:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: NPC script files have valid Lua syntax
T:test("NPC scripts have valid Lua syntax", function()
    local handle = io.popen('find data/npc/scripts -name "*.lua" -type f 2>/dev/null')
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
        "Lua syntax errors in NPC scripts:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: NPC lib files have valid Lua syntax
T:test("NPC lib files have valid Lua syntax", function()
    local handle = io.popen('find data/npc/lib -name "*.lua" -type f 2>/dev/null')
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
        "Lua syntax errors in NPC lib:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: NPC XML files reference existing scripts
T:test("NPC XML files reference existing scripts", function()
    local handle = io.popen('find data/npc -maxdepth 1 -name "*.xml" -type f 2>/dev/null')
    local missingScripts = {}
    if handle then
        for path in handle:lines() do
            local f = io.open(path, "r")
            if f then
                local content = f:read("*a")
                f:close()
                local script = content:match('script="([^"]+)"')
                if script then
                    local scriptPath = "data/npc/scripts/" .. script
                    local sf = io.open(scriptPath, "r")
                    if sf then
                        sf:close()
                    else
                        table.insert(missingScripts, script .. " (from " .. path .. ")")
                    end
                end
            end
        end
        handle:close()
    end
    T:assert(#missingScripts == 0,
        "Missing NPC scripts: " .. table.concat(missingScripts, ", "))
end)
