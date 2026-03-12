-- Test schema creation for TFS database.
-- Verifies that schema.sql creates all expected tables.
-- Usage: mysql -u root < tests/db/test_schema.sql

-- Create test database
DROP DATABASE IF EXISTS tfs_test;
CREATE DATABASE tfs_test;
USE tfs_test;

-- Source the main schema
SOURCE schema.sql;

-- Verify all expected tables exist
SELECT 'accounts' AS expected_table,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'tfs_test' AND table_name = 'accounts') AS found;

SELECT 'players' AS expected_table,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'tfs_test' AND table_name = 'players') AS found;

SELECT 'player_items' AS expected_table,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'tfs_test' AND table_name = 'player_items') AS found;

SELECT 'player_spells' AS expected_table,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'tfs_test' AND table_name = 'player_spells') AS found;

SELECT 'player_storage' AS expected_table,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'tfs_test' AND table_name = 'player_storage') AS found;

SELECT 'guilds' AS expected_table,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'tfs_test' AND table_name = 'guilds') AS found;

SELECT 'guild_ranks' AS expected_table,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'tfs_test' AND table_name = 'guild_ranks') AS found;

SELECT 'houses' AS expected_table,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'tfs_test' AND table_name = 'houses') AS found;

SELECT 'market_offers' AS expected_table,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'tfs_test' AND table_name = 'market_offers') AS found;

SELECT 'server_config' AS expected_table,
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'tfs_test' AND table_name = 'server_config') AS found;

-- Verify table structure
SELECT 'accounts columns' AS test,
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'tfs_test' AND table_name = 'accounts';

SELECT 'players columns' AS test,
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'tfs_test' AND table_name = 'players';

-- Test basic insert operations
INSERT INTO accounts (name, password, type, email, creation)
VALUES ('testaccount', SHA1('testpassword'), 1, 'test@test.com', UNIX_TIMESTAMP());

INSERT INTO players (name, account_id, level, vocation, health, healthmax, experience, mana, manamax, town_id, conditions)
VALUES ('Test Player', 1, 8, 1, 185, 185, 4200, 90, 90, 1, '');

-- Verify inserts
SELECT 'account insert' AS test,
    (SELECT COUNT(*) FROM accounts WHERE name = 'testaccount') AS success;

SELECT 'player insert' AS test,
    (SELECT COUNT(*) FROM players WHERE name = 'Test Player') AS success;

-- Verify foreign key relationship
SELECT 'player-account FK' AS test,
    (SELECT COUNT(*) FROM players p JOIN accounts a ON p.account_id = a.id WHERE a.name = 'testaccount') AS success;

-- Test guild creation
INSERT INTO guilds (name, ownerid, creationdata, motd)
VALUES ('Test Guild', 1, UNIX_TIMESTAMP(), 'Test MOTD');

SELECT 'guild insert' AS test,
    (SELECT COUNT(*) FROM guilds WHERE name = 'Test Guild') AS success;

-- Cleanup
DROP DATABASE IF EXISTS tfs_test;
SELECT 'Schema test complete' AS status;
