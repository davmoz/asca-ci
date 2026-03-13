--[[
    Storage key conflict detection tests.
    Scans all Lua library files for storage key usage and detects conflicts.
]]

local T = TestRunner

T:suite("Storage Keys")

-- Utility: scan a file for storage key patterns
local function findStorageKeys(path)
    local keys = {}
    local f = io.open(path, "r")
    if not f then return keys end
    local lineNum = 0
    for line in f:lines() do
        lineNum = lineNum + 1
        -- Skip comment-only lines and data lines (xpReward, goldReward, etc.)
        if not line:match("^%s*%-%-") then
            -- Only match lines that look like storage key definitions:
            -- STORAGE_XXX = NNNNN, or .storage_xxx = NNNNN, or Storage = { key = NNNNN }
            local isStorageLine = line:match("[Ss][Tt][Oo][Rr][Aa][Gg][Ee]")
                or line:match("STORAGE_")
                or line:match("%.Storage%.")
                or line:match("skillLevel%s*=")
                or line:match("skillTries%s*=")
                or line:match("lastCraft%w*%s*=")
                or line:match("last%w*Time%s*=")
                or line:match("COOLDOWN%s*=")
            if isStorageLine then
                for key in line:gmatch("=%s*(%d%d%d%d%d+)") do
                    local num = tonumber(key)
                    if num and num >= 40000 and num <= 70000 then
                        table.insert(keys, {value = num, file = path, line = lineNum, text = line:match("^%s*(.-)%s*$")})
                    end
                end
            end
        end
    end
    f:close()
    return keys
end

-- Test: no storage key conflicts between library files
T:test("no storage key conflicts between library files", function()
    local handle = io.popen('find data/lib -name "*.lua" -type f 2>/dev/null')
    if not handle then
        T:assert(true)
        return
    end

    local allKeys = {}
    local conflicts = {}

    for path in handle:lines() do
        local keys = findStorageKeys(path)
        for _, keyInfo in ipairs(keys) do
            local existing = allKeys[keyInfo.value]
            if existing and existing.file ~= keyInfo.file then
                table.insert(conflicts, string.format(
                    "Key %d used in both %s:%d and %s:%d",
                    keyInfo.value,
                    existing.file, existing.line,
                    keyInfo.file, keyInfo.line
                ))
            else
                allKeys[keyInfo.value] = keyInfo
            end
        end
    end
    handle:close()

    T:assert(#conflicts == 0,
        "Storage key conflicts found:\n  " .. table.concat(conflicts, "\n  "))
end)

-- Test: vocations.xml uses new vocation names
T:test("vocations.xml uses new custom vocation names", function()
    local f = io.open("data/XML/vocations.xml", "r")
    if not f then
        T:assert(true)
        return
    end
    local content = f:read("*a")
    f:close()

    local newNames = {"Mage", "Druid", "Archer", "Knight"}
    local foundNew = 0
    for _, name in ipairs(newNames) do
        if content:find('name="' .. name .. '"') then
            foundNew = foundNew + 1
        end
    end
    T:assert(foundNew >= 4, string.format("Expected at least 4 base vocation names, found %d", foundNew))
end)
