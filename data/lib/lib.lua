-- Core API functions implemented in Lua
dofile('data/lib/core/core.lua')

-- Compatibility library for our old Lua API
dofile('data/lib/compat/compat.lua')

-- Debugging helper function for Lua developers
dofile('data/lib/debugging/dump.lua')
dofile('data/lib/debugging/lua_version.lua')

-- Crafting systems (Phase 2)
dofile('data/lib/crafting.lua')
dofile('data/lib/crafting_lib.lua')
dofile('data/lib/crafting_mining.lua')
dofile('data/lib/crafting_smithing.lua')
dofile('data/lib/crafting_enchanting.lua')
dofile('data/lib/crafting_farming.lua')

-- Item systems (Phase 3)
dofile('data/lib/item_attributes.lua')
dofile('data/lib/item_ranks.lua')
dofile('data/lib/legendary_items.lua')

-- Task, Bestiary, and Achievement systems (Phase 4)
dofile('data/lib/task_system.lua')
dofile('data/lib/bestiary_system.lua')
dofile('data/lib/achievement_system.lua')

-- Seasonal Events system (Phase 4.6 + 5.5)
dofile('data/lib/seasonal_events.lua')

-- Housing, Party, and Dungeon enhancements (Phase 5)
dofile('data/lib/housing_enhanced.lua')
dofile('data/lib/party_enhanced.lua')
dofile('data/lib/weekly_dungeons.lua')

-- PvP and Guild systems (Phase 1.3 + 5)
dofile('data/lib/retro_pvp.lua')
dofile('data/lib/guild_enhanced.lua')
dofile('data/lib/pvp_systems.lua')
