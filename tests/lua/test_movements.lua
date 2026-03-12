--[[
    Movement script validation tests.
    Validates data/movements/ structure and script syntax.
]]

local T = TestRunner

T:suite("Movements")

-- Test: movements.xml exists
T:test("movements.xml exists", function()
    local f = io.open("data/movements/movements.xml", "r")
    T:assertNotNil(f, "data/movements/movements.xml not found")
    f:close()
end)

-- Test: movements.xml has valid root element
T:test("movements.xml has valid structure", function()
    local f = io.open("data/movements/movements.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()
    T:assert(content:find("<movements>") ~= nil, "Missing <movements> root element")
    T:assert(content:find("</movements>") ~= nil, "Missing </movements> closing tag")
end)

-- Test: movement entries exist
T:test("movement entries exist", function()
    local f = io.open("data/movements/movements.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local count = 0
    for _ in content:gmatch('<movevent%s') do
        count = count + 1
    end
    T:assert(count > 0, "No movevent entries found")
end)

-- Test: movement events have valid event types
T:test("movement events have valid event types", function()
    local f = io.open("data/movements/movements.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local validEvents = {
        StepIn=true, StepOut=true, Equip=true, DeEquip=true,
        AddItem=true, RemoveItem=true,
    }
    local invalidEvents = {}
    for event in content:gmatch('event="([^"]+)"') do
        if not validEvents[event] then
            table.insert(invalidEvents, event)
        end
    end
    T:assert(#invalidEvents == 0,
        "Invalid movement event types: " .. table.concat(invalidEvents, ", "))
end)

-- Test: referenced movement scripts exist
T:test("referenced movement scripts exist", function()
    local f = io.open("data/movements/movements.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local missingScripts = {}
    for script in content:gmatch('script="([^"]+)"') do
        local path = "data/movements/scripts/" .. script
        local sf = io.open(path, "r")
        if sf then
            sf:close()
        else
            table.insert(missingScripts, script)
        end
    end
    T:assert(#missingScripts == 0,
        "Missing movement scripts: " .. table.concat(missingScripts, ", "))
end)

-- Test: movement scripts have valid Lua syntax
T:test("movement scripts have valid Lua syntax", function()
    local handle = io.popen('find data/movements/scripts -name "*.lua" -type f 2>/dev/null')
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
        "Lua syntax errors in movement scripts:\n  " .. table.concat(badFiles, "\n  "))
end)
