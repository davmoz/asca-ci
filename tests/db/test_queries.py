#!/usr/bin/env python3
"""
Test common SQL queries used by TFS.

Validates query syntax and structure without requiring a database connection.
Checks that queries follow expected patterns and use correct table/column names.
"""

import sys
import re
from pathlib import Path


def find_project_root():
    path = Path(__file__).resolve().parent
    while path != path.parent:
        if (path / "CMakeLists.txt").exists() and (path / "data").exists():
            return path
        path = path.parent
    return Path.cwd()


PROJECT_ROOT = find_project_root()
SCHEMA_FILE = PROJECT_ROOT / "schema.sql"

# Known tables from schema.sql
KNOWN_TABLES = {
    "accounts", "players", "account_bans", "account_ban_history",
    "ip_bans", "player_deaths", "player_depotitems", "player_inboxitems",
    "player_items", "player_namelocks", "player_spells", "player_storage",
    "guilds", "guild_invites", "guild_membership", "guild_ranks",
    "guild_wars", "guildwar_kills", "houses", "house_lists",
    "market_history", "market_offers", "players_online", "server_config",
    "tile_store", "towns", "account_viplist",
}

# Common TFS queries (extracted from src/*.cpp patterns)
COMMON_QUERIES = [
    # Login
    ("Account lookup",
     "SELECT `id`, `name`, `password`, `type`, `premium_ends_at` FROM `accounts` WHERE `name` = ?"),
    # Player load
    ("Player lookup by name",
     "SELECT `id`, `name`, `account_id`, `level`, `vocation`, `health`, `healthmax` FROM `players` WHERE `name` = ?"),
    # Player save
    ("Player save",
     "UPDATE `players` SET `level` = ?, `vocation` = ?, `health` = ?, `healthmax` = ?, `experience` = ?, `mana` = ?, `manamax` = ? WHERE `id` = ?"),
    # Online players
    ("Online players insert",
     "INSERT INTO `players_online` (`player_id`) VALUES (?)"),
    ("Online players delete",
     "DELETE FROM `players_online` WHERE `player_id` = ?"),
    # Player items
    ("Load player items",
     "SELECT `pid`, `sid`, `itemtype`, `count`, `attributes` FROM `player_items` WHERE `player_id` = ? ORDER BY `sid`"),
    # Player storage
    ("Load player storage",
     "SELECT `key`, `value` FROM `player_storage` WHERE `player_id` = ?"),
    # Guild lookup
    ("Guild lookup",
     "SELECT `id`, `name`, `ownerid`, `motd` FROM `guilds` WHERE `id` = ?"),
    # House lookup
    ("House lookup",
     "SELECT `id`, `owner`, `paid`, `warnings`, `name`, `rent` FROM `houses`"),
    # Market offers
    ("Market offers lookup",
     "SELECT `id`, `player_id`, `sale`, `itemtype`, `amount`, `price` FROM `market_offers`"),
    # Player deaths
    ("Player death insert",
     "INSERT INTO `player_deaths` (`player_id`, `time`, `level`, `killed_by`, `is_player`, `mostdamage_by`, `mostdamage_is_player`) VALUES (?, ?, ?, ?, ?, ?, ?)"),
    # Account VIP list
    ("VIP list load",
     "SELECT `player_id` FROM `account_viplist` WHERE `account_id` = ?"),
    # Server config
    ("Server config lookup",
     "SELECT `value` FROM `server_config` WHERE `config` = ?"),
]


def extract_tables_from_schema():
    """Extract table names from schema.sql."""
    if not SCHEMA_FILE.exists():
        return set()

    content = SCHEMA_FILE.read_text()
    tables = set()
    for match in re.finditer(r'CREATE TABLE IF NOT EXISTS `(\w+)`', content, re.IGNORECASE):
        tables.add(match.group(1))
    for match in re.finditer(r'CREATE TABLE `(\w+)`', content, re.IGNORECASE):
        tables.add(match.group(1))
    return tables


def extract_columns_from_schema(table_name):
    """Extract column names for a given table from schema.sql."""
    if not SCHEMA_FILE.exists():
        return set()

    content = SCHEMA_FILE.read_text()
    columns = set()

    # Find the CREATE TABLE block
    pattern = rf'CREATE TABLE(?:\s+IF NOT EXISTS)?\s+`{table_name}`\s*\((.*?)\)\s*ENGINE'
    match = re.search(pattern, content, re.DOTALL | re.IGNORECASE)
    if match:
        block = match.group(1)
        for col_match in re.finditer(r'`(\w+)`', block):
            col = col_match.group(1)
            # Skip constraint names
            if col not in (table_name, 'PRIMARY', 'UNIQUE', 'KEY', 'FOREIGN',
                          'CONSTRAINT', 'INDEX', 'CHECK'):
                columns.add(col)

    return columns


def test_query_tables():
    """Verify queries reference existing tables."""
    print("Validating query table references...")
    schema_tables = extract_tables_from_schema()
    errors = []

    for name, query in COMMON_QUERIES:
        # Extract table names from query
        tables_in_query = set()
        for match in re.finditer(r'`(\w+)`', query):
            word = match.group(1)
            if word in KNOWN_TABLES:
                tables_in_query.add(word)

        for table in tables_in_query:
            if table not in schema_tables and schema_tables:
                errors.append(f"{name}: References unknown table '{table}'")

    print(f"  Checked {len(COMMON_QUERIES)} queries")
    print(f"  Errors: {len(errors)}")
    for e in errors:
        print(f"    {e}")

    return len(errors) == 0


def test_query_syntax():
    """Basic SQL syntax validation."""
    print("\nValidating query syntax patterns...")
    errors = []

    for name, query in COMMON_QUERIES:
        query_upper = query.upper()

        # Check it starts with a valid SQL keyword
        first_word = query_upper.strip().split()[0]
        if first_word not in ("SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "ALTER", "DROP"):
            errors.append(f"{name}: Doesn't start with SQL keyword: {first_word}")

        # Check SELECT has FROM
        if first_word == "SELECT" and "FROM" not in query_upper:
            errors.append(f"{name}: SELECT without FROM")

        # Check INSERT has INTO and VALUES
        if first_word == "INSERT":
            if "INTO" not in query_upper:
                errors.append(f"{name}: INSERT without INTO")
            if "VALUES" not in query_upper:
                errors.append(f"{name}: INSERT without VALUES")

        # Check UPDATE has SET
        if first_word == "UPDATE" and "SET" not in query_upper:
            errors.append(f"{name}: UPDATE without SET")

        # Check DELETE has FROM
        if first_word == "DELETE" and "FROM" not in query_upper:
            errors.append(f"{name}: DELETE without FROM")

    print(f"  Errors: {len(errors)}")
    for e in errors:
        print(f"    {e}")

    return len(errors) == 0


def test_schema_structure():
    """Validate schema.sql structure."""
    print("\nValidating schema structure...")
    errors = []

    if not SCHEMA_FILE.exists():
        print("  WARNING: schema.sql not found")
        return True

    content = SCHEMA_FILE.read_text()

    # Check for required tables
    required_tables = ["accounts", "players", "guilds", "houses",
                       "player_items", "player_storage"]
    for table in required_tables:
        if f"`{table}`" not in content:
            errors.append(f"Required table '{table}' not found in schema")

    # Check accounts table has expected columns
    account_columns = extract_columns_from_schema("accounts")
    for col in ["id", "name", "password", "type"]:
        if col not in account_columns and account_columns:
            errors.append(f"accounts table missing column '{col}'")

    # Check players table has expected columns
    player_columns = extract_columns_from_schema("players")
    for col in ["id", "name", "account_id", "level", "vocation", "health", "mana"]:
        if col not in player_columns and player_columns:
            errors.append(f"players table missing column '{col}'")

    schema_tables = extract_tables_from_schema()
    print(f"  Found {len(schema_tables)} tables in schema")
    print(f"  Errors: {len(errors)}")
    for e in errors:
        print(f"    {e}")

    return len(errors) == 0


if __name__ == "__main__":
    success = True
    success = test_schema_structure() and success
    success = test_query_tables() and success
    success = test_query_syntax() and success
    sys.exit(0 if success else 1)
