--[[
    Monster validation tests.
    Validates data/monster/monsters.xml index and individual monster XML files.
]]

local T = TestRunner

T:suite("Monsters")

-- Test: monsters.xml index exists
T:test("monsters.xml index exists", function()
    local f = io.open("data/monster/monsters.xml", "r")
    T:assertNotNil(f, "data/monster/monsters.xml not found")
    f:close()
end)

-- Test: monsters.xml has valid root element
T:test("monsters.xml has valid structure", function()
    local f = io.open("data/monster/monsters.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()
    T:assert(content:find("<monsters>") ~= nil, "Missing <monsters> root element")
    T:assert(content:find("</monsters>") ~= nil, "Missing </monsters> closing tag")
end)

-- Test: count monster entries in index
T:test("monsters.xml has expected number of entries", function()
    local f = io.open("data/monster/monsters.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local count = 0
    for _ in content:gmatch('<monster%s') do
        count = count + 1
    end
    T:assert(count >= 600, string.format("Expected at least 600 monsters, found %d", count))
end)

-- Test: all monster entries have name and file attributes
T:test("all monster index entries have name and file", function()
    local f = io.open("data/monster/monsters.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local malformed = {}
    for entry in content:gmatch('<monster%s(.-)/>') do
        if not entry:find('name="') then
            table.insert(malformed, "missing name")
        end
        if not entry:find('file="') then
            table.insert(malformed, "missing file")
        end
    end
    T:assert(#malformed == 0,
        "Malformed monster entries: " .. table.concat(malformed, ", "))
end)

-- Test: all referenced monster XML files exist
T:test("all referenced monster files exist", function()
    local f = io.open("data/monster/monsters.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local missingFiles = {}
    for file in content:gmatch('file="([^"]+)"') do
        local path = "data/monster/" .. file
        local mf = io.open(path, "r")
        if mf then
            mf:close()
        else
            table.insert(missingFiles, file)
        end
    end
    T:assert(#missingFiles == 0,
        "Missing monster files (" .. #missingFiles .. "): " .. table.concat(missingFiles, ", "))
end)

-- Test: monster XML files have required elements
T:test("monster files have required XML structure", function()
    local handle = io.popen('find data/monster/monsters -name "*.xml" -type f 2>/dev/null | head -50')
    local badFiles = {}
    if handle then
        for path in handle:lines() do
            local f = io.open(path, "r")
            if f then
                local content = f:read("*a")
                f:close()
                if not content:find("<monster%s") then
                    table.insert(badFiles, path .. ": missing <monster> element")
                end
                if not content:find("<health%s") then
                    table.insert(badFiles, path .. ": missing <health> element")
                end
                if not content:find("<look%s") then
                    table.insert(badFiles, path .. ": missing <look> element")
                end
            end
        end
        handle:close()
    end
    T:assert(#badFiles == 0,
        "Monster files with structural issues:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: monster names are non-empty
T:test("all monsters have non-empty names", function()
    local handle = io.popen('find data/monster/monsters -name "*.xml" -type f 2>/dev/null | head -50')
    local badNames = {}
    if handle then
        for path in handle:lines() do
            local f = io.open(path, "r")
            if f then
                local content = f:read("*a")
                f:close()
                local name = content:match('name="([^"]*)"')
                if not name or name == "" then
                    table.insert(badNames, path)
                end
            end
        end
        handle:close()
    end
    T:assert(#badNames == 0,
        "Monsters with empty names: " .. table.concat(badNames, ", "))
end)

-- Test: monster health values are positive
T:test("monster health values are positive", function()
    local handle = io.popen('find data/monster/monsters -name "*.xml" -type f 2>/dev/null | head -50')
    local badHealth = {}
    if handle then
        for path in handle:lines() do
            local f = io.open(path, "r")
            if f then
                local content = f:read("*a")
                f:close()
                local maxHp = content:match('<health[^>]*max="(%d+)"')
                if maxHp then
                    local hp = tonumber(maxHp)
                    if not hp or hp <= 0 then
                        table.insert(badHealth, path)
                    end
                end
            end
        end
        handle:close()
    end
    T:assert(#badHealth == 0,
        "Monsters with invalid health: " .. table.concat(badHealth, ", "))
end)

-- Test: monster experience values are non-negative
T:test("monster experience values are non-negative", function()
    local handle = io.popen('find data/monster/monsters -name "*.xml" -type f 2>/dev/null | head -50')
    local badExp = {}
    if handle then
        for path in handle:lines() do
            local f = io.open(path, "r")
            if f then
                local content = f:read("*a")
                f:close()
                local exp = content:match('experience="(%-?%d+)"')
                if exp then
                    local expNum = tonumber(exp)
                    if expNum and expNum < 0 then
                        table.insert(badExp, path .. " (exp=" .. exp .. ")")
                    end
                end
            end
        end
        handle:close()
    end
    T:assert(#badExp == 0,
        "Monsters with negative experience: " .. table.concat(badExp, ", "))
end)
