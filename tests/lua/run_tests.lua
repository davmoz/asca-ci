#!/usr/bin/env lua
--[[
    TFS Lua Test Runner
    Validates Lua script syntax, data file structure, and shared library functions.
    Usage: lua tests/lua/run_tests.lua [test_name]

    Run from the project root directory.
]]

-- Minimal test framework
local TestRunner = {
    totalTests = 0,
    passedTests = 0,
    failedTests = 0,
    errors = {},
    currentSuite = "",
}

function TestRunner:suite(name)
    self.currentSuite = name
    print(string.format("\n=== Test Suite: %s ===", name))
end

function TestRunner:test(name, fn)
    self.totalTests = self.totalTests + 1
    local ok, err = pcall(fn)
    if ok then
        self.passedTests = self.passedTests + 1
        print(string.format("  PASS: %s", name))
    else
        self.failedTests = self.failedTests + 1
        table.insert(self.errors, {
            suite = self.currentSuite,
            test = name,
            error = tostring(err)
        })
        print(string.format("  FAIL: %s - %s", name, tostring(err)))
    end
end

function TestRunner:assert(condition, message)
    if not condition then
        error(message or "Assertion failed", 2)
    end
end

function TestRunner:assertEqual(a, b, message)
    if a ~= b then
        error(message or string.format("Expected %s, got %s", tostring(b), tostring(a)), 2)
    end
end

function TestRunner:assertNotNil(value, message)
    if value == nil then
        error(message or "Expected non-nil value", 2)
    end
end

function TestRunner:assertType(value, expectedType, message)
    if type(value) ~= expectedType then
        error(message or string.format("Expected type %s, got %s", expectedType, type(value)), 2)
    end
end

function TestRunner:summary()
    print(string.format("\n========================================"))
    print(string.format("Test Results: %d/%d passed, %d failed",
        self.passedTests, self.totalTests, self.failedTests))
    print(string.format("========================================"))

    if #self.errors > 0 then
        print("\nFailures:")
        for _, e in ipairs(self.errors) do
            print(string.format("  [%s] %s: %s", e.suite, e.test, e.error))
        end
    end

    return self.failedTests == 0
end

-- Utility: check if file exists
local function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- Utility: check Lua syntax of a file
local function checkLuaSyntax(path)
    local fn, err = loadfile(path)
    if fn then
        return true, nil
    else
        return false, err
    end
end

-- Utility: list files matching pattern in directory (using ls)
local function listFiles(dir, pattern)
    local files = {}
    local cmd = string.format('find "%s" -name "%s" -type f 2>/dev/null', dir, pattern)
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            table.insert(files, line)
        end
        handle:close()
    end
    return files
end

-- Utility: count lines in file
local function countLines(path)
    local count = 0
    local f = io.open(path, "r")
    if f then
        for _ in f:lines() do count = count + 1 end
        f:close()
    end
    return count
end

-- Determine which tests to run
local testFilter = arg and arg[1] or nil
local testModules = {
    "tests/lua/test_spells.lua",
    "tests/lua/test_monsters.lua",
    "tests/lua/test_items.lua",
    "tests/lua/test_npcs.lua",
    "tests/lua/test_actions.lua",
    "tests/lua/test_movements.lua",
    "tests/lua/test_talkactions.lua",
    "tests/lua/test_lib.lua",
    "tests/lua/test_crafting.lua",
    "tests/lua/test_crafting_integration.lua",
    "tests/lua/test_storage_keys.lua",
    "tests/lua/test_vocations.lua",
    "tests/lua/test_lib_loading.lua",
    "tests/lua/test_item_references.lua",
    "tests/lua/test_spell_formulas.lua",
    "tests/lua/test_npc_dialogues.lua",
    "tests/lua/test_events.lua",
    "tests/lua/test_negative_cases.lua",
    "tests/lua/test_new_systems.lua",
}

-- Export the runner for test modules
_G.TestRunner = TestRunner

print("TFS Lua Test Runner")
print("==================")

for _, module in ipairs(testModules) do
    local moduleName = module:match("test_(.+)%.lua$")
    if not testFilter or moduleName == testFilter then
        if fileExists(module) then
            local ok, err = pcall(dofile, module)
            if not ok then
                print(string.format("\nERROR loading %s: %s", module, tostring(err)))
                TestRunner.failedTests = TestRunner.failedTests + 1
            end
        else
            print(string.format("\nWARNING: Test module not found: %s", module))
        end
    end
end

local success = TestRunner:summary()
os.exit(success and 0 or 1)
