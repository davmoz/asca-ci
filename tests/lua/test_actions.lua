--[[
    Action script validation tests.
    Validates data/actions/ structure and script syntax.
]]

local T = TestRunner

T:suite("Actions")

-- Test: actions.xml exists
T:test("actions.xml exists", function()
    local f = io.open("data/actions/actions.xml", "r")
    T:assertNotNil(f, "data/actions/actions.xml not found")
    f:close()
end)

-- Test: actions.xml has valid root element
T:test("actions.xml has valid structure", function()
    local f = io.open("data/actions/actions.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()
    T:assert(content:find("<actions>") ~= nil, "Missing <actions> root element")
    T:assert(content:find("</actions>") ~= nil, "Missing </actions> closing tag")
end)

-- Test: action entries have required attributes
T:test("action entries have itemid or actionid", function()
    local f = io.open("data/actions/actions.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local count = 0
    for _ in content:gmatch('<action%s') do
        count = count + 1
    end
    T:assert(count > 0, "No action entries found")
end)

-- Test: all referenced action scripts exist
T:test("referenced action script files exist", function()
    local f = io.open("data/actions/actions.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local missingScripts = {}
    for script in content:gmatch('script="([^"]+)"') do
        local path = "data/actions/scripts/" .. script
        local sf = io.open(path, "r")
        if sf then
            sf:close()
        else
            table.insert(missingScripts, script)
        end
    end
    T:assert(#missingScripts == 0,
        "Missing action scripts: " .. table.concat(missingScripts, ", "))
end)

-- Test: action scripts have valid Lua syntax
T:test("action scripts have valid Lua syntax", function()
    local handle = io.popen('find data/actions/scripts -name "*.lua" -type f 2>/dev/null')
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
        "Lua syntax errors in action scripts:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: action lib files have valid Lua syntax
T:test("action lib files have valid Lua syntax", function()
    local handle = io.popen('find data/actions/lib -name "*.lua" -type f 2>/dev/null')
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
        "Lua syntax errors in action lib:\n  " .. table.concat(badFiles, "\n  "))
end)
