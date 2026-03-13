# Phase 4: Quest Content Implementation Plan

## Overview

ASCA needs a rich quest system to drive player engagement and give meaning to the
custom vocation, crafting, and equipment systems built in Phases 1-3. This phase covers
a main storyline, side quest framework, boss encounters, and quest-specific rewards
including custom outfits and addons.

## 1. Custom Main Questline

The main questline introduces ASCA lore and guides players through the world's zones
in a level-appropriate progression.

### Story Arc

- **Act 1 (Levels 1-30)**: The Awakening — player discovers the ancient threat to the realm.
  Tutorial-style quests that teach core mechanics (combat, crafting, vocation abilities).
- **Act 2 (Levels 30-60)**: The Gathering — player recruits allies and gathers artifacts.
  Introduces party-oriented content and harder solo challenges.
- **Act 3 (Levels 60-100)**: The Reckoning — player confronts the main antagonist through
  a series of dungeon crawls and scripted boss fights.
- **Epilogue (Level 100+)**: Endgame quest chains that unlock legendary crafting recipes,
  secret areas, and cosmetic rewards.

### Implementation Approach

- Each act consists of 8-12 sequential quests chained via storage keys.
- Quest progression gates access to new zones and NPC services.
- Cutscene-like moments delivered through timed NPC dialogue sequences.
- Key decision points that affect minor dialogue variations (not branching outcomes).

## 2. Side Quest Framework

### Repeatable Daily Quests

- 5-8 daily quests available from a "Bounty Board" NPC in each major town.
- Quest types: monster hunt (kill X), gathering (deliver X materials), escort, arena.
- Daily reset tracked via storage key + timestamp comparison.
- Reward scaling based on player level at time of completion.

### One-Time Discovery Quests

- Hidden quests triggered by interacting with specific world objects or locations.
- No quest log entry until triggered — encourages exploration.
- Examples: deciphering ancient tablets, finding lost caches, completing jumping puzzles.
- Approximately 20-30 discovery quests spread across the map.

### Quest Chain System

- Side quest chains of 3-5 quests that tell smaller stories about specific NPCs or zones.
- Each town/zone should have at least one unique chain.
- Completion unlocks zone-specific titles or cosmetic items.

## 3. Quest Reward System

| Reward Type | Description | Use Case |
|-------------|-------------|----------|
| XP Bonus | Flat XP grant scaled to quest difficulty | All quests |
| Items | Equipment, consumables, crafting materials | Boss kills, chain completions |
| Reputation | Faction standing points | Repeatable and chain quests |
| Achievements | Tracked milestones with title rewards | Discovery and main quests |
| Currency | Special quest tokens for vendor rewards | Daily quests |

### Reputation Factions

- 3-4 factions tied to world lore (e.g., Merchant Guild, Arcane Order, Ranger Corps).
- Reputation unlocks faction-specific vendors, recipes, and cosmetic items.
- Tracked via dedicated storage key range per faction.

## 4. Quest Tracking via Storage Keys

All quest state is stored using player storage keys in the range **65000-65999**.

| Range | Purpose |
|-------|---------|
| 65000-65099 | Main questline progress (act/quest step) |
| 65100-65199 | Side quest chain states |
| 65200-65299 | Daily quest completion timestamps |
| 65300-65399 | Discovery quest flags (0 = undiscovered, 1 = complete) |
| 65400-65499 | Reputation values per faction |
| 65500-65599 | Boss kill tracking and lockout timers |
| 65600-65699 | Outfit and addon quest progress |
| 65700-65999 | Reserved for future expansion |

### Storage Key Conventions

- Each quest uses a base key + offset for multi-step tracking.
- Timestamps stored as `os.time()` values for daily reset checks.
- Helper functions in a shared `lib/quest_utils.lua` module for common operations:
  `hasCompletedQuest(player, questId)`, `advanceQuest(player, questId, step)`,
  `canRepeatDaily(player, questId)`.

## 5. Boss Encounters

### Scripted Boss Fights with Phases

Each act finale features a scripted boss with multiple phases:

- **Phase transitions** triggered at HP thresholds (e.g., 75%, 50%, 25%).
- **Mechanics per phase**: adds spawning, arena hazards, enrage timers.
- **Loot lockout**: boss rewards claimable once per 24h (tracked via storage 65500+).

### Boss Roster

| Boss | Location | Level Range | Phases | Key Mechanic |
|------|----------|-------------|--------|--------------|
| The Hollow Knight | Forsaken Crypt | 25-35 | 2 | Summons undead waves |
| Serpent Queen | Sunken Temple | 50-60 | 3 | Poison pools, tail swipe AoE |
| Archlich Valthorne | Shadow Citadel | 80-100 | 4 | Phase-specific immunities |
| The Colossus | Endgame Arena | 100+ | 3 | Destructible armor segments |

### Implementation

- Boss scripts in `data/scripts/creatures/bosses/`.
- Use `onThink` for phase logic and timed ability casts.
- Arena boundary enforcement via movement event scripts.
- Death callback triggers loot chest spawn + quest storage update.

## 6. Custom Outfit/Addon Quests (#147)

Implements GitHub issue #147 — custom outfits and addons earned through gameplay.

### Outfit Unlock Structure

- Each custom outfit requires completing a dedicated quest chain (3-5 steps).
- Addon 1: secondary quest requiring rare material gathering.
- Addon 2: tertiary quest requiring a boss kill or achievement.

### Planned Outfits

| Outfit | Unlock Quest | Addon 1 Requirement | Addon 2 Requirement |
|--------|-------------|---------------------|---------------------|
| Forgemaster | Complete smithing quest chain | Craft 50 items | Defeat The Colossus |
| Shadow Stalker | Stealth mission chain | Collect 10 shadow essences | Complete all discovery quests |
| Archon Robes | Arcane Order reputation max | Enchant 20 items | Defeat Archlich Valthorne |
| Beastcaller | Tame 5 creature types | Gather nature essences | Complete druid quest chain |

### Technical Notes

- Outfit grants via `player:addOutfit(lookType)` and `player:addOutfitAddon(lookType, addon)`.
- Storage keys 65600-65699 track progress.
- Outfit preview NPC in main city for players to see locked outfits.

## 7. Quest NPC Dialogue System

### Dialogue Structure

- NPCs use keyword-based dialogue trees (standard TFS approach).
- Quest NPCs check storage keys to determine available dialogue branches.
- Multi-step dialogues use modal windows for important choices.

### Shared Dialogue Utilities

- `lib/npc_quest_dialog.lua` — helper module for common patterns:
  - `offerQuest(npc, player, questId, description)` — standard quest offer flow.
  - `checkQuestItems(player, itemList)` — verify player has required turn-in items.
  - `grantQuestReward(player, questId, rewards)` — give rewards and advance state.
- Standardized greeting/farewell messages per NPC archetype (guard, merchant, scholar).

### NPC Quest Markers

- Visual indicators for quest state (configurable via NPC outfit changes or effects):
  - Available quest: NPC has a specific idle animation or particle effect.
  - In-progress quest: different visual cue.
  - Completed quest: normal NPC appearance.

## 8. Implementation Priority and Phases

### Phase 4.1 — Foundation (Weeks 1-2)

1. Create `lib/quest_utils.lua` and `lib/npc_quest_dialog.lua` helper modules.
2. Define all storage key ranges and document conventions.
3. Build daily quest reset system and bounty board NPC template.
4. Implement 2-3 daily quests as proof of concept.

### Phase 4.2 — Main Questline Act 1 (Weeks 3-4)

1. Write Act 1 quest scripts (8-10 quests).
2. Create Act 1 boss encounter (The Hollow Knight).
3. Place quest NPCs and configure dialogue trees.
4. Test full Act 1 flow from level 1 to 30.

### Phase 4.3 — Side Content and Outfits (Weeks 5-6)

1. Implement 10+ discovery quests across existing zones.
2. Build 2 side quest chains.
3. Implement first custom outfit quest chain (Forgemaster).
4. Add reputation system and faction vendors.

### Phase 4.4 — Remaining Main Questline (Weeks 7-10)

1. Acts 2 and 3 quest scripts and boss encounters.
2. Remaining outfit/addon quest chains.
3. Epilogue endgame quest content.
4. Full balance pass on all quest rewards.

## Dependencies

- Phase 1 (vocations) must be complete for vocation-gated quest content.
- Phase 2 (crafting/smithing) must be complete for material-based quest rewards.
- Phase 3 (equipment rebalance) must be complete for balanced item rewards.
- Monster scripts must support `onDeath` callbacks for boss kill tracking.

## Files That Need Changes

| File | Change |
|------|--------|
| `data/lib/quest_utils.lua` | New — shared quest helper functions |
| `data/lib/npc_quest_dialog.lua` | New — NPC dialogue helpers |
| `data/scripts/quests/main/*.lua` | New — main questline scripts |
| `data/scripts/quests/daily/*.lua` | New — daily quest scripts |
| `data/scripts/quests/discovery/*.lua` | New — discovery quest scripts |
| `data/scripts/creatures/bosses/*.lua` | New — boss encounter scripts |
| `data/npc/*.xml` | Add/modify quest NPCs |
| `data/npc/scripts/*.lua` | Quest NPC dialogue scripts |
