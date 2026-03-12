-- ============================================================================
-- Storage Keys Registry - Central Reference
-- ============================================================================
-- This file documents all storage key allocations to prevent conflicts.
-- Always check this file before adding new storage keys.
--
-- IMPORTANT: This file is loaded first in lib.lua. It does NOT define the
-- actual storage values used by each system (those live in their own files).
-- This is a reference/documentation file to help developers avoid collisions.
-- ============================================================================

--[[
  STORAGE KEY ALLOCATION MAP
  ==========================

  Range           System                  File
  --------------- ----------------------- ------------------------------------------
  45100 - 45102   Mining                  data/lib/crafting_mining.lua
  45200 - 45202   Farming                 data/lib/crafting_farming.lua
  45300 - 45302   Smithing                data/lib/crafting_smithing.lua
  45400           Enchanting (cooldown)   data/lib/crafting_enchanting.lua
  45500 - 45599   (reserved for crafting)

  50000 - 50999   TaskSystem              data/lib/task_system.lua

  53000 - 53999   Bestiary kills          data/lib/bestiary_system.lua
  55000 - 55099   AchievementSystem       data/lib/achievement_system.lua

  57000 - 57006   PvPSystems              data/lib/pvp_systems.lua

  58000 - 58008   RetroPvP                data/lib/retro_pvp.lua

  59000 - 59499   GuildEnhanced bank      data/lib/guild_enhanced.lua
  59500 - 59899   GuildEnhanced XP        data/lib/guild_enhanced.lua
  59900 - 60499   GuildEnhanced level     data/lib/guild_enhanced.lua
  60500 - 60999   GuildEnhanced allies    data/lib/guild_enhanced.lua
  61000 - 61499   GuildEnhanced war kills data/lib/guild_enhanced.lua
  61500           GuildEnhanced contrib   data/lib/guild_enhanced.lua

  62000 - 62999   HousingEnhanced         data/lib/housing_enhanced.lua

  63000 - 63099   SeasonalEvents          data/lib/seasonal_events.lua
  63100 - 63104   SeasonalEvents player   data/lib/seasonal_events.lua

  63200 - 63208   Moderation              data/talkactions/scripts/moderation.lua

  63300 - 63999   (reserved for future use)
]]

print(">> Storage keys registry loaded")
