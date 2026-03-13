--[[
    Spell validation tests.
    Validates data/spells/spells.xml structure and spell script files.
]]

local T = TestRunner

T:suite("Spells")

-- Test: spells.xml exists
T:test("spells.xml exists", function()
    local f = io.open("data/spells/spells.xml", "r")
    T:assertNotNil(f, "data/spells/spells.xml not found")
    f:close()
end)

-- Test: spells.xml is valid XML (basic structure check)
T:test("spells.xml has valid root element", function()
    local f = io.open("data/spells/spells.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()
    T:assert(content:find("<spells>") ~= nil, "Missing <spells> root element")
    T:assert(content:find("</spells>") ~= nil, "Missing </spells> closing tag")
end)

-- Test: all instant spells have required attributes
T:test("instant spells have required attributes", function()
    local f = io.open("data/spells/spells.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local count = 0
    local missing = {}
    -- Match the attribute portion of <instant ...> or <instant .../>
    -- Use a non-greedy match up to the first > to get only the tag attributes
    for spell in content:gmatch('<instant%s(.-)[/]?>') do
        count = count + 1
        if not spell:find('name="') then table.insert(missing, "name in: " .. spell:sub(1, 40)) end
        if not spell:find('words="') then table.insert(missing, "words in: " .. spell:sub(1, 40)) end
    end

    T:assert(count > 0, "No instant spells found")
    T:assert(#missing == 0, "Spells missing required attributes: " .. table.concat(missing, ", "))
end)

-- Test: spell scripts directory exists
T:test("spell scripts directory exists", function()
    local handle = io.popen('ls data/spells/scripts/ 2>/dev/null | head -1')
    local result = handle:read("*a")
    handle:close()
    T:assert(result ~= "", "data/spells/scripts/ directory is empty or missing")
end)

-- Test: all referenced spell scripts exist
T:test("referenced spell script files exist", function()
    local f = io.open("data/spells/spells.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local missingScripts = {}
    for script in content:gmatch('script="([^"]+)"') do
        local path = "data/spells/scripts/" .. script
        local sf = io.open(path, "r")
        if sf then
            sf:close()
        else
            table.insert(missingScripts, script)
        end
    end

    T:assert(#missingScripts == 0,
        "Missing spell scripts: " .. table.concat(missingScripts, ", "))
end)

-- Test: spell script files have valid Lua syntax
T:test("spell scripts have valid Lua syntax", function()
    local handle = io.popen('find data/spells/scripts -name "*.lua" -type f 2>/dev/null')
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
        "Lua syntax errors in spell scripts:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: spell groups are valid
T:test("spell groups are valid values", function()
    local f = io.open("data/spells/spells.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local validGroups = {attack=true, healing=true, support=true, special=true}
    local invalidGroups = {}
    for group in content:gmatch('group="([^"]+)"') do
        if not validGroups[group] then
            table.insert(invalidGroups, group)
        end
    end
    T:assert(#invalidGroups == 0,
        "Invalid spell groups found: " .. table.concat(invalidGroups, ", "))
end)

-- Test: spell cooldowns are positive
T:test("spell cooldowns are positive numbers", function()
    local f = io.open("data/spells/spells.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local badCooldowns = {}
    for cooldown in content:gmatch('cooldown="([^"]+)"') do
        local num = tonumber(cooldown)
        if not num or num <= 0 then
            table.insert(badCooldowns, cooldown)
        end
    end
    T:assert(#badCooldowns == 0,
        "Invalid cooldown values: " .. table.concat(badCooldowns, ", "))
end)
