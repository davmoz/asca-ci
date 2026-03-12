# Phase 3: Equipment Rebalancing for Custom Vocation System

## Overview

All existing equipment must be rebalanced to support the custom vocation system
(Mage, Druid, Archer, Knight) and the new item attribute/rank/crafting systems.
This document outlines the key balance changes needed.

## Vocations and Their Equipment Roles

| Vocation | Primary Stats | Weapon Types | Armor Weight Class |
|----------|--------------|--------------|-------------------|
| Knight (Imperial Knight) | HP, Melee Skills | Swords, Axes, Clubs | Heavy plate |
| Archer (Royal Archer) | Distance, balanced HP/Mana | Bows, Crossbows | Medium leather/chain |
| Mage (High Mage) | Mana, Magic Level | War Hammers (low-level), Runes | Light robes |
| Druid (Guardian Druid) | Mana, Magic Level, Healing | War Hammers (low-level), Runes | Light robes |

## Key Balance Changes Needed

### 1. Weapon Tier Restructuring

- **Remove wands and rods** from all shop inventories, NPC sell lists, and monster loot tables
  (engine code stays intact for potential future use).
- **Add war hammers** as low-level mage/druid weapons (levels 1-30 gap filler).
- **Create Archer-specific bows/crossbows** with distance skill scaling:
  - Short Bow / Hunting Bow / Composite Bow / Royal Bow progression.
  - Bolt and arrow tiers to match (copper, iron, steel, mithril ammunition).
- **Establish three equipment sources** with clear power ranking:
  - Shop-bought < Monster-dropped < Crafted (smithing).

### 2. Armor Rebalancing by Vocation Class

- **Heavy armor** (plate, golden, magic plate): Knight-only or heavy movement penalty for others.
- **Medium armor** (chain, scale, studded): Archer-optimized, small penalty for mages.
- **Light armor** (robes, cloth): Mage/Druid-optimized with magic level or healing bonuses.
- Add vocation restriction attributes to `items.xml` where appropriate.

### 3. Crafted Equipment Sets

Design craftable equipment sets that represent best-in-slot for their tier:

| Set Name | Vocation | Tier | Key Materials |
|----------|----------|------|---------------|
| Revenant Set | Knight | High | Mithril bars + demon parts |
| Windwalker Set | Archer | High | Steel bars + elven components |
| Arcane Regalia | Mage | High | Gold bars + energy crystals |
| Lifewood Set | Druid | High | Silver bars + nature essences |

Each set should provide a **set bonus** when 3+ pieces are equipped (e.g., +5% melee damage
for Revenant, +3% critical hit for Windwalker).

### 4. Stat Progression Curves

- Weapon damage should scale linearly from level 1-100, then taper logarithmically.
- Armor defense values should follow the same curve to prevent one-shot scenarios at any level.
- Crafted gear at max smithing should be roughly 10-15% better than best monster drops.
- Legendary items should be on par with max-crafted gear but with unique effects instead of
  raw stat advantages.

### 5. Item Attribute Pools per Equipment Slot

Each equipment slot should have a defined pool of possible random attributes:

- **Weapons**: Attack, Critical Hit, Berserk, Crushing Blow, Dazing Blow
- **Helmets**: Intelligence, Magic Level bonus, Mana regeneration
- **Armor**: Defense, HP bonus, Damage reduction %
- **Legs**: Speed, Dodge chance, Stamina regeneration
- **Boots**: Speed, Lean (movement), Kick damage
- **Shields**: Defense, Block chance, Reflect damage

### 6. Files That Need Changes

| File | Change |
|------|--------|
| `data/XML/vocations.xml` | Already updated with custom vocations |
| `data/items/items.xml` | Add vocation restrictions, adjust stats, remove wand/rod shop flags |
| `data/npc/*.xml` | Update shop inventories to remove wands/rods, add new equipment |
| `data/monster/*.xml` | Update loot tables for new tiered drops, add crafting material drops |
| `data/scripts/crafting/smithing.lua` | Define new equipment recipes |
| `data/scripts/crafting/enchanting.lua` | Define attribute pools per slot |
| `docs/phase3-items.md` | Cross-reference with existing item system overhaul doc |

## Implementation Order

1. Remove wands/rods from loot and shops (quick win, no balance risk).
2. Add war hammer weapon line for low-level mages.
3. Add vocation restrictions to existing armor pieces.
4. Design and implement Archer bow/crossbow progression.
5. Create the four craftable equipment sets with set bonuses.
6. Rebalance all existing equipment stat values against the new progression curve.
7. Populate attribute pools per slot and test generation distribution.

## Dependencies

- Smithing system (Phase 2) must be complete for crafted equipment.
- Item attribute system (Phase 3.1) must be complete for random bonuses.
- Item rank system (Phase 3.2) must be complete for Properties scaling.
