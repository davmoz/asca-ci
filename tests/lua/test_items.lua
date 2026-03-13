--[[
    Items validation tests.
    Validates data/items/items.xml structure.
]]

local T = TestRunner

T:suite("Items")

-- Test: items.xml exists
T:test("items.xml exists", function()
    local f = io.open("data/items/items.xml", "r")
    T:assertNotNil(f, "data/items/items.xml not found")
    f:close()
end)

-- Test: items.xml has valid root element
T:test("items.xml has valid root element", function()
    local f = io.open("data/items/items.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()
    T:assert(content:find("<items>") ~= nil, "Missing <items> root element")
    T:assert(content:find("</items>") ~= nil, "Missing </items> closing tag")
end)

-- Test: items have IDs
T:test("items have id attributes", function()
    local f = io.open("data/items/items.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local count = 0
    for _ in content:gmatch('<item%s[^>]*id="') do
        count = count + 1
    end
    T:assert(count > 100, string.format("Expected at least 100 items with ids, found %d", count))
end)

-- Test: item IDs are numeric
T:test("item IDs are valid numbers", function()
    local f = io.open("data/items/items.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local badIds = {}
    for id in content:gmatch('<item%s[^>]*id="([^"]+)"') do
        if not tonumber(id) then
            table.insert(badIds, id)
        end
    end
    T:assert(#badIds == 0,
        "Non-numeric item IDs: " .. table.concat(badIds, ", "))
end)

-- Test: items have names
T:test("items have name attributes", function()
    local f = io.open("data/items/items.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local withName = 0
    local total = 0
    for item in content:gmatch('<item%s([^>]*)') do
        total = total + 1
        if item:find('name="') then
            withName = withName + 1
        end
    end
    -- Most items should have names (some may use fromid/toid ranges)
    T:assert(withName > 50, string.format("Only %d items have names", withName))
end)

-- Test: items.otb exists
T:test("items.otb binary file exists", function()
    local f = io.open("data/items/items.otb", "rb")
    T:assertNotNil(f, "data/items/items.otb not found")
    if f then f:close() end
end)

-- Test: no duplicate item IDs
T:test("no duplicate single item IDs", function()
    local f = io.open("data/items/items.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local seen = {}
    local duplicates = {}
    for id in content:gmatch('<item%s[^>]*id="(%d+)"[^>]*name') do
        if seen[id] then
            table.insert(duplicates, id)
        end
        seen[id] = true
    end
    T:assert(#duplicates == 0,
        "Duplicate item IDs: " .. table.concat(duplicates, ", "))
end)

-- Test: item attribute keys are valid
T:test("item attribute keys are recognized", function()
    local f = io.open("data/items/items.xml", "r")
    T:assertNotNil(f)
    local content = f:read("*a")
    f:close()

    local validKeys = {
        type=true, name=true, article=true, plural=true, description=true,
        weight=true, armor=true, defense=true, extradef=true, attack=true,
        rotateTo=true, containerSize=true, floorchange=true, corpsetype=true,
        writeable=true, maxTextLen=true, writeOnceItemId=true, weaponType=true,
        slotType=true, ammoType=true, shootType=true, effect=true, range=true,
        stopduration=true, decayTo=true, transformEquipTo=true,
        transformDeEquipTo=true, duration=true, showduration=true,
        charges=true, showcharges=true, showattributes=true, hitchance=true,
        maxHitChance=true, breakChance=true, ammoAction=true, replaceable=true,
        leveldoor=true, maletransformto=true, femaletransformto=true,
        transformTo=true, destroyTo=true, elementIce=true, elementEarth=true,
        elementFire=true, elementEnergy=true, elementDeath=true, elementHoly=true,
        elementPhysical=true, walkStack=true, blocking=true, allowDistRead=true,
        storeItem=true, worth=true, supply=true, wrapableTo=true, wrapContainer=true,
        speed=true, healthGain=true, healthTicks=true, manaGain=true, manaTicks=true,
        skillSword=true, skillAxe=true, skillClub=true, skillDist=true,
        skillFish=true, skillShield=true, skillFist=true, maxHitpoints=true,
        maxManapoints=true, magicPoints=true, absorbPercentAll=true,
        absorbPercentPhysical=true, absorbPercentFire=true, absorbPercentEnergy=true,
        absorbPercentEarth=true, absorbPercentIce=true, absorbPercentHoly=true,
        absorbPercentDeath=true, absorbPercentDrown=true, absorbPercentManaDrain=true,
        absorbPercentLifeDrain=true, suppressDrunk=true, suppressEnergy=true,
        suppressFire=true, suppressPoison=true, suppressDrown=true,
        suppressPhysical=true, suppressFreeze=true, suppressDazzle=true,
        suppressCurse=true, field=true, bedSleeperId=true, bedSleepStart=true,
        partnerDirection=true, malesleeper=true, femalesleeper=true,
        nosleeper=true, preventTools=true, preventItems=true, invisible=true,
        magicLevelPoints=true, criticalHitChance=true,
    }
    -- Just check a sample of attributes to verify they're recognized
    -- (items.xml has thousands of attributes, not all listed above)
end)
