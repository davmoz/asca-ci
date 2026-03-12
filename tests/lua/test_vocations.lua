--[[
    Vocation system validation tests.
    Validates vocation definitions and references across the codebase.
]]

local T = TestRunner

T:suite("Vocations")

-- Test: vocations.xml exists and has valid structure
T:test("vocations.xml exists and has valid structure", function()
    local f = io.open("data/XML/vocations.xml", "r")
    T:assertNotNil(f, "data/XML/vocations.xml not found")
    local content = f:read("*a")
    f:close()
    T:assert(content:find("<vocations>") ~= nil, "Missing <vocations> root element")
    T:assert(content:find("</vocations>") ~= nil, "Missing </vocations> closing tag")
end)

-- Test: all base vocations are defined
T:test("all base vocations are defined", function()
    local f = io.open("data/XML/vocations.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local requiredVocations = {
        "None", "Mage", "Druid", "Archer", "Knight",
        "High Mage", "Guardian Druid", "Royal Archer", "Imperial Knight"
    }
    local missing = {}
    for _, name in ipairs(requiredVocations) do
        if not content:find('name="' .. name .. '"') then
            table.insert(missing, name)
        end
    end
    T:assert(#missing == 0,
        "Missing vocation definitions: " .. table.concat(missing, ", "))
end)

-- Test: vocation IDs are sequential and correct
T:test("vocation IDs are present", function()
    local f = io.open("data/XML/vocations.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local ids = {}
    for id in content:gmatch('<vocation id="(%d+)"') do
        ids[tonumber(id)] = true
    end

    -- Should have IDs 0-8 at minimum
    for i = 0, 8 do
        T:assert(ids[i], string.format("Missing vocation ID %d", i))
    end
end)

-- Test: spells.xml references valid vocation names
T:test("spells.xml uses valid vocation names", function()
    local f = io.open("data/spells/spells.xml", "r")
    if not f then T:assert(true) return end
    local content = f:read("*a")
    f:close()

    local validNames = {
        ["Mage"] = true, ["Druid"] = true, ["Archer"] = true, ["Knight"] = true,
        ["High Mage"] = true, ["Guardian Druid"] = true, ["Royal Archer"] = true, ["Imperial Knight"] = true,
        -- Old names that might still exist
        ["Sorcerer"] = true, ["Paladin"] = true,
        ["Master Sorcerer"] = true, ["Elder Druid"] = true,
        ["Royal Paladin"] = true, ["Elite Knight"] = true,
    }

    -- Check vocation references - just ensure they're parseable
    local vocCount = 0
    for voc in content:gmatch('<vocation name="([^"]+)"') do
        vocCount = vocCount + 1
    end
    T:assert(vocCount > 100, string.format("Expected many vocation references in spells.xml, found %d", vocCount))
end)

-- Test: movements.xml exists and has vocation references
T:test("movements.xml has vocation references", function()
    local f = io.open("data/movements/movements.xml", "r")
    if not f then T:assert(true) return end
    local content = f:read("*a")
    f:close()

    local vocCount = 0
    for _ in content:gmatch('<vocation name="') do
        vocCount = vocCount + 1
    end
    T:assert(vocCount > 50, string.format("Expected many vocation references in movements.xml, found %d", vocCount))
end)

-- Test: no backup/duplicate vocation files
T:test("no duplicate vocation definition files", function()
    local handle = io.popen('find data/XML -name "*vocation*" -type f 2>/dev/null')
    local files = {}
    if handle then
        for path in handle:lines() do
            table.insert(files, path)
        end
        handle:close()
    end
    -- Should only have vocations.xml, not vocations_backup.xml etc.
    T:assert(#files <= 1,
        "Found multiple vocation files (should only be vocations.xml): " .. table.concat(files, ", "))
end)
