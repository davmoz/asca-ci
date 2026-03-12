--[[
    Lib loading validation tests.
    Verifies all dofile() references in lib.lua point to existing files.
]]

local T = TestRunner

T:suite("Lib Loading")

-- Test: all dofile() references in lib.lua point to existing files
T:test("all lib.lua dofile references exist", function()
    local f = io.open("data/lib/lib.lua", "r")
    T:assertNotNil(f, "data/lib/lib.lua not found")
    local content = f:read("*a")
    f:close()

    local missing = {}
    for path in content:gmatch("dofile%('([^']+)'%)") do
        local df = io.open(path, "r")
        if df then
            df:close()
        else
            table.insert(missing, path)
        end
    end
    T:assert(#missing == 0,
        "Missing files referenced in lib.lua dofile():\n  " .. table.concat(missing, "\n  "))
end)

-- Test: all dofile() referenced files have valid Lua syntax
T:test("all lib.lua dofile files have valid syntax", function()
    local f = io.open("data/lib/lib.lua", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local badFiles = {}
    for path in content:gmatch("dofile%('([^']+)'%)") do
        local exists = io.open(path, "r")
        if exists then
            exists:close()
            local fn, err = loadfile(path)
            if not fn then
                table.insert(badFiles, path .. ": " .. tostring(err))
            end
        end
    end
    T:assert(#badFiles == 0,
        "Syntax errors in lib files:\n  " .. table.concat(badFiles, "\n  "))
end)

-- Test: creaturescript XML references existing scripts
T:test("creaturescript XML references existing scripts", function()
    local f = io.open("data/creaturescripts/creaturescripts.xml", "r")
    if not f then T:assert(true) return end
    local content = f:read("*a")
    f:close()

    local missing = {}
    for script in content:gmatch('script="([^"]+)"') do
        local path = "data/creaturescripts/scripts/" .. script
        local sf = io.open(path, "r")
        if sf then
            sf:close()
        else
            table.insert(missing, script)
        end
    end
    T:assert(#missing == 0,
        "Missing creaturescripts: " .. table.concat(missing, ", "))
end)

-- Test: creaturescript Lua files have valid syntax
T:test("creaturescript files have valid Lua syntax", function()
    local handle = io.popen('find data/creaturescripts/scripts -name "*.lua" -type f 2>/dev/null')
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

-- Test: globalevents XML references existing scripts
T:test("globalevent XML references existing scripts", function()
    local f = io.open("data/globalevents/globalevents.xml", "r")
    if not f then T:assert(true) return end
    local content = f:read("*a")
    f:close()

    -- Remove XML comments before checking references
    content = content:gsub("<!%-%-.-%-%->", "")

    local missing = {}
    local seen = {}
    for script in content:gmatch('script="([^"]+)"') do
        if not seen[script] then
            seen[script] = true
            local path = "data/globalevents/scripts/" .. script
            local sf = io.open(path, "r")
            if sf then
                sf:close()
            else
                table.insert(missing, script)
            end
        end
    end
    T:assert(#missing == 0,
        "Missing globalevent scripts: " .. table.concat(missing, ", "))
end)

-- Test: raids XML files have valid structure
T:test("raid XML files have valid structure", function()
    local f = io.open("data/raids/raids.xml", "r")
    if not f then T:assert(true) return end
    local content = f:read("*a")
    f:close()

    T:assert(content:find("<raids>") ~= nil, "Missing <raids> root element")

    -- Check referenced raid files exist
    local missing = {}
    for raidFile in content:gmatch('file="([^"]+)"') do
        local path = "data/raids/" .. raidFile
        local rf = io.open(path, "r")
        if rf then
            rf:close()
        else
            table.insert(missing, raidFile)
        end
    end
    T:assert(#missing == 0,
        "Missing raid files: " .. table.concat(missing, ", "))
end)
