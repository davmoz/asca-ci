--[[
    Talkaction script validation tests.
    Validates data/talkactions/ structure and script syntax.
]]

local T = TestRunner

T:suite("Talkactions")

-- Test: talkactions.xml exists
T:test("talkactions.xml exists", function()
    local f = io.open("data/talkactions/talkactions.xml", "r")
    T:assertNotNil(f, "data/talkactions/talkactions.xml not found")
    f:close()
end)

-- Test: talkactions.xml has valid root element
T:test("talkactions.xml has valid structure", function()
    local f = io.open("data/talkactions/talkactions.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()
    T:assert(content:find("<talkactions>") ~= nil, "Missing <talkactions> root element")
    T:assert(content:find("</talkactions>") ~= nil, "Missing </talkactions> closing tag")
end)

-- Test: talkaction entries have words attribute
T:test("talkaction entries have words attribute", function()
    local f = io.open("data/talkactions/talkactions.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local count = 0
    local noWords = 0
    for entry in content:gmatch('<talkaction%s(.-)/>') do
        count = count + 1
        if not entry:find('words="') then
            noWords = noWords + 1
        end
    end
    T:assert(count > 0, "No talkaction entries found")
    T:assert(noWords == 0, string.format("%d talkaction entries missing words attribute", noWords))
end)

-- Test: referenced talkaction scripts exist
T:test("referenced talkaction scripts exist", function()
    local f = io.open("data/talkactions/talkactions.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local missingScripts = {}
    for script in content:gmatch('script="([^"]+)"') do
        local path = "data/talkactions/scripts/" .. script
        local sf = io.open(path, "r")
        if sf then
            sf:close()
        else
            table.insert(missingScripts, script)
        end
    end
    T:assert(#missingScripts == 0,
        "Missing talkaction scripts: " .. table.concat(missingScripts, ", "))
end)

-- Test: talkaction scripts have valid Lua syntax
T:test("talkaction scripts have valid Lua syntax", function()
    local handle = io.popen('find data/talkactions/scripts -name "*.lua" -type f 2>/dev/null')
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
        "Lua syntax errors in talkaction scripts:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: talkaction words are unique
T:test("talkaction words are unique", function()
    local f = io.open("data/talkactions/talkactions.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local seen = {}
    local duplicates = {}
    for words in content:gmatch('words="([^"]+)"') do
        if seen[words] then
            table.insert(duplicates, words)
        end
        seen[words] = true
    end
    T:assert(#duplicates == 0,
        "Duplicate talkaction words: " .. table.concat(duplicates, ", "))
end)
