--[[
    Spell formula and configuration validation tests.
    Validates spell data integrity in data/spells/spells.xml.
]]

local T = TestRunner

T:suite("Spell Formulas & Configuration")

-- Helper: read spells.xml content once
local function readSpellsXml()
    local f = io.open("data/spells/spells.xml", "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- Test: all script= references in spells.xml point to files that exist
T:test("all spell script files exist on disk", function()
    local content = readSpellsXml()
    T:assertNotNil(content, "Cannot read spells.xml")

    local missing = {}
    local checked = {}
    for script in content:gmatch('script="([^"]+)"') do
        if not checked[script] then
            checked[script] = true
            local path = "data/spells/scripts/" .. script
            local sf = io.open(path, "r")
            if sf then
                sf:close()
            else
                table.insert(missing, script)
            end
        end
    end

    T:assert(#missing == 0,
        "Spell scripts referenced in XML but missing on disk: " .. table.concat(missing, ", "))
end)

-- Test: mana costs are non-negative (0 is valid for party spells that use manapercent)
T:test("spell mana costs are non-negative", function()
    local content = readSpellsXml()
    T:assertNotNil(content)

    local bad = {}
    for tag in content:gmatch("<instant%s(.-)[/]?>") do
        local name = tag:match('name="([^"]+)"') or "unknown"
        local mana = tag:match('mana="([^"]+)"')
        if mana then
            local num = tonumber(mana)
            if not num or num < 0 then
                table.insert(bad, string.format("%s (mana=%s)", name, tostring(mana)))
            end
        end
    end
    for tag in content:gmatch("<rune%s(.-)[/]?>") do
        local name = tag:match('name="([^"]+)"') or "unknown"
        local mana = tag:match('mana="([^"]+)"')
        if mana then
            local num = tonumber(mana)
            if not num or num < 0 then
                table.insert(bad, string.format("%s (mana=%s)", name, tostring(mana)))
            end
        end
    end

    T:assert(#bad == 0,
        "Spells with negative mana cost: " .. table.concat(bad, ", "))
end)

-- Test: spell levels are within a sane range (1-999)
T:test("spell levels are within range 1-999", function()
    local content = readSpellsXml()
    T:assertNotNil(content)

    local bad = {}
    for tag in content:gmatch("<instant%s(.-)[/]?>") do
        local name = tag:match('name="([^"]+)"') or "unknown"
        local lvl = tag:match('level="([^"]+)"')
        if lvl then
            local num = tonumber(lvl)
            if not num or num < 1 or num > 999 then
                table.insert(bad, string.format("%s (level=%s)", name, tostring(lvl)))
            end
        end
    end
    for tag in content:gmatch("<rune%s(.-)[/]?>") do
        local name = tag:match('name="([^"]+)"') or "unknown"
        local lvl = tag:match('level="([^"]+)"')
        if lvl then
            local num = tonumber(lvl)
            if not num or num < 1 or num > 999 then
                table.insert(bad, string.format("%s (level=%s)", name, tostring(lvl)))
            end
        end
    end

    T:assert(#bad == 0,
        "Spells with out-of-range levels: " .. table.concat(bad, ", "))
end)

-- Test: spell cooldowns are positive
T:test("all spell cooldowns are greater than zero", function()
    local content = readSpellsXml()
    T:assertNotNil(content)

    local bad = {}
    for tag in content:gmatch("<instant%s(.-)[/]?>") do
        local name = tag:match('name="([^"]+)"') or "unknown"
        local cd = tag:match('cooldown="([^"]+)"')
        if cd then
            local num = tonumber(cd)
            if not num or num <= 0 then
                table.insert(bad, string.format("%s (cooldown=%s)", name, tostring(cd)))
            end
        end
    end

    T:assert(#bad == 0,
        "Spells with non-positive cooldowns: " .. table.concat(bad, ", "))
end)

-- Test: no duplicate spell names within same tag type
-- Note: instant spells and rune spells can share names (conjure rune + rune use)
T:test("no duplicate instant spell names", function()
    local content = readSpellsXml()
    T:assertNotNil(content)

    local seen = {}
    local dupes = {}
    for tag in content:gmatch("<instant%s(.-)[/]?>") do
        local name = tag:match('name="([^"]+)"')
        if name then
            if seen[name] then
                dupes[name] = true
            end
            seen[name] = true
        end
    end

    local dupeList = {}
    for name in pairs(dupes) do table.insert(dupeList, name) end

    T:assert(#dupeList == 0,
        "Duplicate instant spell names: " .. table.concat(dupeList, ", "))
end)

-- Test: no duplicate spell words (incantations)
T:test("no duplicate spell words", function()
    local content = readSpellsXml()
    T:assertNotNil(content)

    local seen = {}
    local dupes = {}
    for tag in content:gmatch("<instant%s(.-)[/]?>") do
        local words = tag:match('words="([^"]+)"')
        if words then
            if seen[words] then
                dupes[words] = (dupes[words] or seen[words]) .. ", conflicts"
            end
            seen[words] = tag:match('name="([^"]+)"') or "unknown"
        end
    end

    local dupeList = {}
    for words in pairs(dupes) do table.insert(dupeList, words) end

    T:assert(#dupeList == 0,
        "Duplicate spell words: " .. table.concat(dupeList, ", "))
end)

-- Test: group cooldowns are reasonable (not excessively large)
-- Note: group cooldown CAN exceed individual spell cooldown (e.g., shared support group)
T:test("group cooldowns are reasonable", function()
    local content = readSpellsXml()
    T:assertNotNil(content)

    local bad = {}
    for tag in content:gmatch("<instant%s(.-)[/]?>") do
        local name = tag:match('name="([^"]+)"') or "unknown"
        local gcd = tonumber(tag:match('groupcooldown="([^"]+)"') or "0")
        -- Group cooldowns should not exceed 5 minutes (300000ms)
        if gcd and gcd > 300000 then
            table.insert(bad, string.format("%s (groupcooldown=%d)", name, gcd))
        end
    end

    T:assert(#bad == 0,
        "Spells with excessively large group cooldowns (>5min): " .. table.concat(bad, ", "))
end)

-- Test: spells with needtarget=1 should have range > 0
T:test("targeted spells have positive range", function()
    local content = readSpellsXml()
    T:assertNotNil(content)

    local bad = {}
    for tag in content:gmatch("<instant%s(.-)[/]?>") do
        local name = tag:match('name="([^"]+)"') or "unknown"
        local needTarget = tag:match('needtarget="([^"]+)"')
        local range = tag:match('range="([^"]+)"')
        if needTarget == "1" and range then
            local r = tonumber(range)
            if r and r <= 0 then
                table.insert(bad, name)
            end
        end
    end

    T:assert(#bad == 0,
        "Targeted spells with zero or negative range: " .. table.concat(bad, ", "))
end)
