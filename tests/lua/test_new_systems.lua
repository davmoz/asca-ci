--[[
    Tests for new library systems:
    - DailyRewards (data/lib/daily_rewards.lua)
    - PreySystem   (data/lib/prey_system.lua)
    - ImbuingSystem (data/lib/imbuing_system.lua)
    - FactionSystem (data/lib/faction_system.lua)

    These files reference TFS APIs that are not available in standalone Lua,
    so we verify syntax via loadfile() and validate structure by pattern-matching
    the file content.
]]

local T = TestRunner

-- Utility: read entire file into a string
local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- Utility: count pattern matches in a string
local function countMatches(str, pattern)
    local count = 0
    for _ in str:gmatch(pattern) do
        count = count + 1
    end
    return count
end

-- ============================================================================
-- DailyRewards
-- ============================================================================
T:suite("DailyRewards")

local dailyPath = "data/lib/daily_rewards.lua"
local dailyContent = readFile(dailyPath)

T:test("daily_rewards.lua exists", function()
    T:assertNotNil(dailyContent, dailyPath .. " not found")
end)

T:test("daily_rewards.lua has valid Lua syntax", function()
    local fn, err = loadfile(dailyPath)
    T:assertNotNil(fn, "Syntax error: " .. tostring(err))
end)

T:test("DailyRewards table is defined", function()
    T:assertNotNil(dailyContent, dailyPath .. " not found")
    T:assert(dailyContent:find("DailyRewards%s*=%s*{}") ~= nil,
        "DailyRewards table definition not found")
end)

T:test("Rewards array has entries for 7 days", function()
    T:assertNotNil(dailyContent, dailyPath .. " not found")
    -- Count [N] = { entries inside DailyRewards.rewards
    local dayCount = 0
    for d in dailyContent:gmatch("%[(%d+)%]%s*=%s*{%s*\n%s*gold") do
        local num = tonumber(d)
        if num and num >= 1 and num <= 7 then
            dayCount = dayCount + 1
        end
    end
    T:assertEqual(dayCount, 7,
        "Expected 7 day entries in rewards, found " .. dayCount)
end)

T:test("Each reward has a description", function()
    T:assertNotNil(dailyContent, dailyPath .. " not found")
    local descCount = 0
    -- Count description fields inside the rewards table
    for _ in dailyContent:gmatch('description%s*=%s*"[^"]+"') do
        descCount = descCount + 1
    end
    T:assert(descCount >= 7,
        "Expected at least 7 reward descriptions, found " .. descCount)
end)

T:test("Storage key constants are defined", function()
    T:assertNotNil(dailyContent, dailyPath .. " not found")
    local keys = {
        "STORAGE_STREAK",
        "STORAGE_LAST_CLAIM",
        "STORAGE_LAST_YEAR",
        "STORAGE_LAST_YDAY",
        "STORAGE_BONUS_XP",
    }
    local missing = {}
    for _, key in ipairs(keys) do
        if not dailyContent:find("DailyRewards%." .. key .. "%s*=") then
            table.insert(missing, key)
        end
    end
    T:assert(#missing == 0,
        "Missing storage keys: " .. table.concat(missing, ", "))
end)

-- ============================================================================
-- PreySystem
-- ============================================================================
T:suite("PreySystem")

local preyPath = "data/lib/prey_system.lua"
local preyContent = readFile(preyPath)

T:test("prey_system.lua exists", function()
    T:assertNotNil(preyContent, preyPath .. " not found")
end)

T:test("prey_system.lua has valid Lua syntax", function()
    local fn, err = loadfile(preyPath)
    T:assertNotNil(fn, "Syntax error: " .. tostring(err))
end)

T:test("PreySystem table is defined", function()
    T:assertNotNil(preyContent, preyPath .. " not found")
    T:assert(preyContent:find("PreySystem%s*=%s*{}") ~= nil,
        "PreySystem table definition not found")
end)

T:test("Slot count is reasonable (1-10)", function()
    T:assertNotNil(preyContent, preyPath .. " not found")
    local slots = preyContent:match("MAX_SLOTS%s*=%s*(%d+)")
    T:assertNotNil(slots, "MAX_SLOTS not found")
    local n = tonumber(slots)
    T:assert(n >= 1 and n <= 10,
        "MAX_SLOTS should be 1-10, got " .. tostring(n))
end)

T:test("Bonus types are defined", function()
    T:assertNotNil(preyContent, preyPath .. " not found")
    local bonusTypes = {
        "BONUS_NONE",
        "BONUS_XP",
        "BONUS_LOOT",
        "BONUS_DAMAGE",
        "BONUS_DEFENSE",
    }
    local missing = {}
    for _, bt in ipairs(bonusTypes) do
        if not preyContent:find("PreySystem%." .. bt .. "%s*=") then
            table.insert(missing, bt)
        end
    end
    T:assert(#missing == 0,
        "Missing bonus types: " .. table.concat(missing, ", "))
end)

T:test("Storage key constants are defined", function()
    T:assertNotNil(preyContent, preyPath .. " not found")
    local keys = {
        "STORAGE_NAME_BASE",
        "STORAGE_BONUS_TYPE_BASE",
        "STORAGE_BONUS_TIER_BASE",
        "STORAGE_ACTIVATE_BASE",
        "STORAGE_REROLL_BASE",
    }
    local missing = {}
    for _, key in ipairs(keys) do
        if not preyContent:find("PreySystem%." .. key .. "%s*=") then
            table.insert(missing, key)
        end
    end
    T:assert(#missing == 0,
        "Missing storage keys: " .. table.concat(missing, ", "))
end)

-- ============================================================================
-- ImbuingSystem
-- ============================================================================
T:suite("ImbuingSystem")

local imbuPath = "data/lib/imbuing_system.lua"
local imbuContent = readFile(imbuPath)

T:test("imbuing_system.lua exists", function()
    T:assertNotNil(imbuContent, imbuPath .. " not found")
end)

T:test("imbuing_system.lua has valid Lua syntax", function()
    local fn, err = loadfile(imbuPath)
    T:assertNotNil(fn, "Syntax error: " .. tostring(err))
end)

T:test("ImbuingSystem table is defined", function()
    T:assertNotNil(imbuContent, imbuPath .. " not found")
    T:assert(imbuContent:find("ImbuingSystem%s*=%s*{}") ~= nil,
        "ImbuingSystem table definition not found")
end)

T:test("At least 5 imbue types are defined", function()
    T:assertNotNil(imbuContent, imbuPath .. " not found")
    -- Count IMBUE_ constants
    local count = countMatches(imbuContent, "ImbuingSystem%.IMBUE_%w+%s*=")
    T:assert(count >= 5,
        "Expected at least 5 imbue type constants, found " .. count)
end)

T:test("At least 5 imbue type entries in Types table", function()
    T:assertNotNil(imbuContent, imbuPath .. " not found")
    -- Count [N] = { name = entries in the Types table
    local count = countMatches(imbuContent, '%[%d+%]%s*=%s*{%s*\n%s*name%s*=')
    T:assert(count >= 5,
        "Expected at least 5 entries in ImbuingSystem.Types, found " .. count)
end)

T:test("At least 3 tiers are defined", function()
    T:assertNotNil(imbuContent, imbuPath .. " not found")
    local tierConstants = {
        "TIER_BASIC",
        "TIER_INTRICATE",
        "TIER_POWERFUL",
    }
    local missing = {}
    for _, tc in ipairs(tierConstants) do
        if not imbuContent:find("ImbuingSystem%." .. tc .. "%s*=") then
            table.insert(missing, tc)
        end
    end
    T:assert(#missing == 0,
        "Missing tier constants: " .. table.concat(missing, ", "))

    -- Also check TierNames table has at least 3 entries
    local tierNameCount = countMatches(imbuContent, '%[%d+%]%s*=%s*"[^"]+"')
    -- This counts all indexed string assignments; TierNames has 3, LEVEL_NAMES etc may add more
    -- Just check the TierNames block exists
    T:assert(imbuContent:find("TierNames%s*=%s*{") ~= nil,
        "TierNames table not found")
end)

T:test("Duration value is positive", function()
    T:assertNotNil(imbuContent, imbuPath .. " not found")
    local duration = imbuContent:match("ImbuingSystem%.DURATION%s*=%s*(%d+)")
    T:assertNotNil(duration, "DURATION not found")
    T:assert(tonumber(duration) > 0,
        "DURATION should be positive, got " .. tostring(duration))
end)

T:test("Storage key constants are defined", function()
    T:assertNotNil(imbuContent, imbuPath .. " not found")
    T:assert(imbuContent:find("ImbuingSystem%.Storage") ~= nil,
        "ImbuingSystem.Storage not found")
    T:assert(imbuContent:find("BASE%s*=%s*%d+") ~= nil,
        "Storage BASE key not found")
end)

-- ============================================================================
-- FactionSystem
-- ============================================================================
T:suite("FactionSystem")

local factionPath = "data/lib/faction_system.lua"
local factionContent = readFile(factionPath)

T:test("faction_system.lua exists", function()
    T:assertNotNil(factionContent, factionPath .. " not found")
end)

T:test("faction_system.lua has valid Lua syntax", function()
    local fn, err = loadfile(factionPath)
    T:assertNotNil(fn, "Syntax error: " .. tostring(err))
end)

T:test("FactionSystem table is defined", function()
    T:assertNotNil(factionContent, factionPath .. " not found")
    T:assert(factionContent:find("FactionSystem%s*=%s*{}") ~= nil,
        "FactionSystem table definition not found")
end)

T:test("At least 2 factions are defined", function()
    T:assertNotNil(factionContent, factionPath .. " not found")
    -- Count faction entries in FactionSystem.factions table
    local count = countMatches(factionContent, '%[%d+%]%s*=%s*{%s*\n%s*id%s*=')
    T:assert(count >= 2,
        "Expected at least 2 factions, found " .. count)
end)

T:test("Each faction has a name", function()
    T:assertNotNil(factionContent, factionPath .. " not found")
    -- Extract the factions block and count name fields within it
    local factionsBlock = factionContent:match("FactionSystem%.factions%s*=%s*(%b{})")
    T:assertNotNil(factionsBlock, "FactionSystem.factions table not found")

    local nameCount = countMatches(factionsBlock, 'name%s*=%s*"[^"]+"')
    T:assert(nameCount >= 2,
        "Expected at least 2 faction names, found " .. nameCount)

    -- Count faction entries (by id =) and verify they match
    local idCount = countMatches(factionsBlock, 'id%s*=%s*%d+')
    T:assertEqual(nameCount, idCount,
        "Mismatch: " .. idCount .. " faction ids but " .. nameCount .. " names")
end)

T:test("Reputation levels/ranks are defined", function()
    T:assertNotNil(factionContent, factionPath .. " not found")
    local levels = {
        "LEVEL_HOSTILE",
        "LEVEL_UNFRIENDLY",
        "LEVEL_NEUTRAL",
        "LEVEL_FRIENDLY",
        "LEVEL_HONORED",
        "LEVEL_REVERED",
        "LEVEL_EXALTED",
    }
    local missing = {}
    for _, lv in ipairs(levels) do
        if not factionContent:find("FactionSystem%." .. lv .. "%s*=") then
            table.insert(missing, lv)
        end
    end
    T:assert(#missing == 0,
        "Missing reputation levels: " .. table.concat(missing, ", "))

    -- Also verify LEVEL_NAMES table exists
    T:assert(factionContent:find("LEVEL_NAMES%s*=%s*{") ~= nil,
        "LEVEL_NAMES table not found")

    -- And LEVEL_THRESHOLDS table exists
    T:assert(factionContent:find("LEVEL_THRESHOLDS%s*=%s*{") ~= nil,
        "LEVEL_THRESHOLDS table not found")
end)

T:test("Storage key constants are defined", function()
    T:assertNotNil(factionContent, factionPath .. " not found")
    T:assert(factionContent:find("FactionSystem%.STORAGE_BASE%s*=%s*%d+") ~= nil,
        "STORAGE_BASE not found")
    -- Each faction should have a storageKey field
    local factionsBlock = factionContent:match("FactionSystem%.factions%s*=%s*(%b{})")
    T:assertNotNil(factionsBlock, "FactionSystem.factions table not found")
    local skCount = countMatches(factionsBlock, "storageKey%s*=%s*%d+")
    T:assert(skCount >= 2,
        "Expected at least 2 storageKey fields in factions, found " .. skCount)
end)
