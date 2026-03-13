# Phase 5: Social Systems Implementation Plan

## Overview

Social systems are critical for long-term player retention. This phase enhances guilds,
parties, housing, and introduces a cosmetic store framework. These systems build on the
quest and reputation systems from Phase 4 to create a cohesive multiplayer experience.

## 1. Guild System Enhancements

### Guild Wars

- Guilds can declare war on other guilds via the guild leader.
- War parameters: duration (1-7 days), kill limit (first to X kills wins), entry fee.
- Kill tracking stored in the `guild_wars` database table.
- War score displayed on guild channel and website.
- Rewards: winning guild receives the combined entry fee + a trophy item for members.

### Guild Levels

- Guilds earn XP from member activities: quest completions, boss kills, PvP victories.
- Level thresholds unlock perks:

| Guild Level | Requirement | Perk Unlocked |
|-------------|-------------|---------------|
| 1 | Default | Basic guild chat and ranks |
| 2 | 5,000 GXP | +5% shared XP bonus for online members |
| 3 | 15,000 GXP | Guild bank access |
| 4 | 40,000 GXP | +2 max guild rank slots |
| 5 | 100,000 GXP | Guild hall decoration bonuses, guild emblem |

- Guild XP tracked via a new `guild_experience` column in the `guilds` table.

### Guild Bank

- Shared gold storage accessible by guild leaders and designated ranks.
- Deposit/withdraw via a guild-specific NPC or guild hall object.
- Transaction log stored in `guild_bank_log` table (who, amount, timestamp, type).
- Configurable withdrawal limits per rank to prevent abuse.
- Maximum balance cap based on guild level.

## 2. Party System Improvements

### Shared XP Bonuses

- Party members within screen range receive a stacking XP bonus:
  - 2 members: +5% XP each
  - 3 members: +10% XP each
  - 4 members: +15% XP each (cap)
- Vocation diversity bonus: +3% additional XP if party has 3+ different vocations.
- Bonus applied in `Party::shareExperience()` in the source.

### Party Quests

- Specific quests in Phase 4 that require a full party to enter/complete.
- Party-gated areas using tile-based scripts that check party size.
- Shared quest progress: all party members advance when objectives are met.
- Party quest instances that reset independently per group.

### Party Finder

- Global channel or NPC-based system for players to list "looking for party" status.
- Players specify: desired activity (quest name, hunting zone), level range, roles needed.
- Stored temporarily in a server-side Lua table, cleared on logout.

## 3. Premium/Store System (#146)

Implements GitHub issue #146 — a cosmetic-only shop framework.

### Store Framework

- In-game store accessible via a talkaction command (`!store`) or UI button.
- Store inventory defined in `data/store/store_items.lua` for easy content updates.
- Payment via premium tokens (earned through gameplay or donation).
- All items are **cosmetic only** — no pay-to-win stat advantages.

### Store Categories

| Category | Examples | Token Cost Range |
|----------|----------|-----------------|
| Outfits | Exclusive cosmetic outfits and addons | 50-150 tokens |
| Mounts | Visual mounts (no speed advantage over earned mounts) | 80-200 tokens |
| House Decorations | Exclusive furniture and wall items | 10-50 tokens |
| Name Change | One-time character rename | 100 tokens |
| Effects | Aura effects, login animations | 30-80 tokens |

### Token Economy

- Tokens earned via: daily login streak, achievement milestones, event participation.
- Optional donation integration (external, not handled by game server).
- Token balance stored in player storage key or dedicated `account_tokens` table.
- Earning rates balanced so free players can purchase items at a reasonable pace.

### Technical Implementation

- `data/scripts/talkactions/store.lua` — opens store modal window.
- `data/store/store_items.lua` — item definitions with category, price, grant function.
- Purchase handler validates token balance, deducts tokens, grants item.
- Transaction log in `store_purchases` table for support/audit purposes.

## 4. Player Housing Improvements

### Customizable House Items

- Expand the set of placeable house items beyond standard furniture:
  - Functional items: personal crafting stations, storage chests with expanded capacity.
  - Decorative items: trophies from boss kills, quest completion plaques, paintings.
  - Interactive items: training dummies (grant small skill XP), bookshelves (lore text).

### House Auctions

- Automated house auction system replacing manual admin assignment.
- Auction cycle: houses go up for bid when vacated or at server-defined intervals.
- Minimum bid based on house size (sqm count * base rate).
- Auction duration: 7 days. Highest bidder wins at cycle end.
- Outbid notifications via in-game mail system.

### House Ranking Perks

- Houses in premium locations provide minor convenience bonuses:
  - Closer to temple = faster respawn return.
  - Depot proximity = reduced travel time.
- No combat or stat advantages tied to housing.

### Implementation

- Auction logic in `data/scripts/globalevents/house_auctions.lua`.
- Bid tracking in `house_auctions` table (house_id, player_id, bid_amount, timestamp).
- House item definitions extended in `items.xml` with `housePlaceable="1"` attribute.

## 5. Mail System Enhancements

### Current Limitations

- Standard TFS mail supports item parcels and text letters between players.

### Planned Improvements

- **System mail**: server-generated mail for auction results, guild invites, event notices.
- **Mail attachments**: attach up to 5 items per mail (up from 1 parcel).
- **Mail expiry**: unread mail auto-deleted after 30 days to prevent database bloat.
- **COD (Cash on Delivery)**: sender sets a gold price; recipient must pay to claim items.
- **Mail notifications**: flash inbox icon or chat message when new mail arrives.

### Technical Notes

- System mail sent via `Game.sendSystemMail(playerId, subject, body, items)` helper.
- COD tracked via additional fields in the mail/depot system tables.
- Expiry handled by a daily global event that purges old entries.

## 6. Friend List and Social Features

### Enhanced Friend List

- Online status indicators (online, offline, away, do-not-disturb).
- Status set via `!status` talkaction, stored in player storage.
- Friend notes: short text annotation per friend (e.g., "good healer, plays evenings").
- Mutual friend indicator to help identify shared connections.

### Block/Ignore Improvements

- Blocked players cannot send mail, party invites, or trade requests.
- Block list persisted in database (currently session-only in some TFS versions).
- `/ignore` and `/unignore` commands with confirmation.

### Social Activity Feed

- Optional global channel showing notable player achievements:
  - First boss kills, quest completions, rare item drops, level milestones.
  - Configurable: players can opt out of appearing in the feed.
- Implemented via a broadcast function called from quest/boss/level scripts.

## 7. Implementation Priority and Phases

### Phase 5.1 — Party and Social Foundation (Weeks 1-2)

1. Implement shared XP bonus in party system (source code change).
2. Add vocation diversity bonus calculation.
3. Enhance friend list with status indicators and notes.
4. Implement block list persistence in database.

### Phase 5.2 — Guild Enhancements (Weeks 3-4)

1. Add guild XP tracking and level system.
2. Implement guild bank with transaction logging.
3. Build guild war declaration and scoring system.
4. Create guild management NPCs and talkactions.

### Phase 5.3 — Store and Housing (Weeks 5-7)

1. Build store framework and modal window UI.
2. Define initial store inventory (5-10 items per category).
3. Implement token earning system via daily logins and achievements.
4. Build house auction system and global event.
5. Add new house-placeable item types.

### Phase 5.4 — Mail and Polish (Weeks 8-9)

1. Implement system mail helper function.
2. Add COD mail support.
3. Add mail expiry global event.
4. Implement social activity feed.
5. Integration testing across all social systems.

## Dependencies

- Phase 4 (quest content) for achievement-based token earning and social feed triggers.
- Source code access required for party XP bonus modifications.
- Database schema changes required for guild bank, auctions, and store purchases.
- Web integration for guild war scores and house auction display (optional).

## Database Schema Changes

| Table | Purpose |
|-------|---------|
| `guilds` (alter) | Add `experience` and `level` columns |
| `guild_bank_log` | Transaction history for guild bank |
| `guild_wars` (extend) | War parameters, scores, and status |
| `house_auctions` | Active bids and auction state |
| `store_purchases` | Purchase log for audit and support |
| `account_tokens` | Token balance per account |

## Files That Need Changes

| File | Change |
|------|--------|
| `src/party.cpp` | Modify `shareExperience()` for XP bonuses |
| `data/scripts/talkactions/store.lua` | New — store command handler |
| `data/store/store_items.lua` | New — store item definitions |
| `data/scripts/globalevents/house_auctions.lua` | New — auction cycle logic |
| `data/scripts/globalevents/mail_expiry.lua` | New — purge old mail |
| `data/scripts/talkactions/guild_bank.lua` | New — guild bank commands |
| `data/scripts/talkactions/guild_war.lua` | New — war declaration commands |
| `data/scripts/talkactions/status.lua` | New — player status command |
| `data/lib/social_utils.lua` | New — shared social helper functions |
| `schema.sql` | Add new tables and alter existing ones |
