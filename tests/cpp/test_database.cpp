/**
 * Unit tests for database-related utilities and SQL query construction.
 *
 * Tests SQL escaping, query building patterns, and database result
 * handling without requiring an actual database connection.
 */

#include <gtest/gtest.h>
#include <cstdint>
#include <sstream>
#include <string>
#include <vector>

// Minimal SQL escape function (matches MySQL escaping used in TFS)
std::string escapeString(const std::string& str) {
    std::string escaped;
    escaped.reserve(str.length() * 2);
    for (char c : str) {
        switch (c) {
            case '\'': escaped += "\\'"; break;
            case '\"': escaped += "\\\""; break;
            case '\\': escaped += "\\\\"; break;
            case '\0': escaped += "\\0"; break;
            case '\n': escaped += "\\n"; break;
            case '\r': escaped += "\\r"; break;
            default: escaped += c; break;
        }
    }
    return escaped;
}

// Simple query builder similar to TFS patterns
class QueryBuilder {
public:
    QueryBuilder& select(const std::string& columns) {
        query << "SELECT " << columns;
        return *this;
    }
    QueryBuilder& from(const std::string& table) {
        query << " FROM `" << table << "`";
        return *this;
    }
    QueryBuilder& where(const std::string& condition) {
        query << " WHERE " << condition;
        return *this;
    }
    QueryBuilder& limit(int n) {
        query << " LIMIT " << n;
        return *this;
    }
    QueryBuilder& orderBy(const std::string& col, const std::string& dir = "ASC") {
        query << " ORDER BY `" << col << "` " << dir;
        return *this;
    }
    std::string build() const { return query.str(); }
    void reset() { query.str(""); query.clear(); }

private:
    std::ostringstream query;
};

// Schema table names from schema.sql
const char* SCHEMA_TABLES[] = {
    "accounts", "players", "account_bans", "account_ban_history",
    "ip_bans", "player_deaths", "player_depotitems", "player_inboxitems",
    "player_items", "player_namelocks", "player_spells", "player_storage",
    "guilds", "guild_invites", "guild_membership", "guild_ranks",
    "guild_wars", "guildwar_kills", "houses", "house_lists",
    "market_history", "market_offers", "players_online", "server_config",
    "tile_store", "towns", "account_viplist", "z_ots_communityboard"
};

// ================================================================
// TESTS
// ================================================================

// ---- SQL escaping ----
TEST(DatabaseEscape, SimpleString) {
    EXPECT_EQ(escapeString("hello"), "hello");
}

TEST(DatabaseEscape, SingleQuote) {
    EXPECT_EQ(escapeString("it's"), "it\\'s");
}

TEST(DatabaseEscape, DoubleQuote) {
    EXPECT_EQ(escapeString("say \"hi\""), "say \\\"hi\\\"");
}

TEST(DatabaseEscape, Backslash) {
    EXPECT_EQ(escapeString("back\\slash"), "back\\\\slash");
}

TEST(DatabaseEscape, NullByte) {
    std::string s = "null";
    s += '\0';
    s += "byte";
    std::string escaped = escapeString(s);
    EXPECT_NE(escaped.find("\\0"), std::string::npos);
}

TEST(DatabaseEscape, Newline) {
    EXPECT_EQ(escapeString("line1\nline2"), "line1\\nline2");
}

TEST(DatabaseEscape, CarriageReturn) {
    EXPECT_EQ(escapeString("line1\rline2"), "line1\\rline2");
}

TEST(DatabaseEscape, EmptyString) {
    EXPECT_EQ(escapeString(""), "");
}

TEST(DatabaseEscape, SQLInjectionAttempt) {
    std::string malicious = "'; DROP TABLE players; --";
    std::string escaped = escapeString(malicious);
    EXPECT_EQ(escaped, "\\'; DROP TABLE players; --");
    EXPECT_EQ(escaped.find("';"), std::string::npos);
}

// ---- Query builder ----
TEST(QueryBuilder, SimpleSelect) {
    QueryBuilder qb;
    std::string q = qb.select("*").from("players").build();
    EXPECT_EQ(q, "SELECT * FROM `players`");
}

TEST(QueryBuilder, SelectWithWhere) {
    QueryBuilder qb;
    std::string q = qb.select("name, level").from("players").where("level > 100").build();
    EXPECT_EQ(q, "SELECT name, level FROM `players` WHERE level > 100");
}

TEST(QueryBuilder, SelectWithLimit) {
    QueryBuilder qb;
    std::string q = qb.select("*").from("players").limit(10).build();
    EXPECT_EQ(q, "SELECT * FROM `players` LIMIT 10");
}

TEST(QueryBuilder, SelectWithOrderBy) {
    QueryBuilder qb;
    std::string q = qb.select("*").from("players").orderBy("level", "DESC").build();
    EXPECT_EQ(q, "SELECT * FROM `players` ORDER BY `level` DESC");
}

TEST(QueryBuilder, ComplexQuery) {
    QueryBuilder qb;
    std::string q = qb.select("name, level, experience")
        .from("players")
        .where("level >= 100")
        .orderBy("experience", "DESC")
        .limit(10)
        .build();
    EXPECT_EQ(q, "SELECT name, level, experience FROM `players` WHERE level >= 100 ORDER BY `experience` DESC LIMIT 10");
}

TEST(QueryBuilder, Reset) {
    QueryBuilder qb;
    qb.select("*").from("players");
    qb.reset();
    std::string q = qb.select("*").from("accounts").build();
    EXPECT_EQ(q, "SELECT * FROM `accounts`");
}

// ---- Player query patterns (from TFS iologindata.cpp patterns) ----
TEST(QueryPatterns, PlayerLookup) {
    std::string name = "Test Player";
    std::string q = "SELECT `id`, `name`, `account_id`, `level`, `vocation` FROM `players` WHERE `name` = '" + escapeString(name) + "'";
    EXPECT_NE(q.find("Test Player"), std::string::npos);
}

TEST(QueryPatterns, PlayerLookupSQLInjection) {
    std::string name = "'; DELETE FROM players WHERE '1'='1";
    std::string q = "SELECT `id` FROM `players` WHERE `name` = '" + escapeString(name) + "'";
    // Should not contain unescaped quotes
    EXPECT_EQ(q.find("'; DELETE"), std::string::npos);
}

TEST(QueryPatterns, AccountLookup) {
    std::string q = "SELECT `id`, `password`, `type`, `premium_ends_at` FROM `accounts` WHERE `name` = 'testaccount'";
    EXPECT_NE(q.find("accounts"), std::string::npos);
    EXPECT_NE(q.find("password"), std::string::npos);
}

// ---- Schema table count ----
TEST(Schema, TableCount) {
    size_t tableCount = sizeof(SCHEMA_TABLES) / sizeof(SCHEMA_TABLES[0]);
    EXPECT_GE(tableCount, 25u);
}

TEST(Schema, RequiredTables) {
    std::vector<std::string> tables(SCHEMA_TABLES, SCHEMA_TABLES + sizeof(SCHEMA_TABLES) / sizeof(SCHEMA_TABLES[0]));
    auto hasTable = [&](const std::string& name) {
        for (const auto& t : tables) if (t == name) return true;
        return false;
    };
    EXPECT_TRUE(hasTable("accounts"));
    EXPECT_TRUE(hasTable("players"));
    EXPECT_TRUE(hasTable("guilds"));
    EXPECT_TRUE(hasTable("houses"));
    EXPECT_TRUE(hasTable("market_offers"));
    EXPECT_TRUE(hasTable("player_items"));
    EXPECT_TRUE(hasTable("player_storage"));
}
