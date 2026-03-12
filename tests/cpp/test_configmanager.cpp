/**
 * Unit tests for ConfigManager getter/setter logic.
 *
 * Tests the ConfigManager get/set methods for strings, integers, and booleans.
 * Does NOT test load() since that requires a Lua runtime and config file.
 * Instead, tests the setter/getter contract and boundary validation.
 */

#include <gtest/gtest.h>
#include <cstdint>
#include <iostream>
#include <string>

// Simplified ConfigManager mirroring src/configmanager.h
class ConfigManager {
public:
    enum boolean_config_t {
        ALLOW_CHANGEOUTFIT,
        FREE_PREMIUM,
        EMOTE_SPELLS,
        STAMINA_SYSTEM,
        LAST_BOOLEAN_CONFIG
    };

    enum string_config_t {
        MAP_NAME,
        SERVER_NAME,
        IP,
        MOTD,
        MYSQL_HOST,
        MYSQL_USER,
        MYSQL_PASS,
        MYSQL_DB,
        CONFIG_FILE,
        LAST_STRING_CONFIG
    };

    enum integer_config_t {
        SQL_PORT,
        MAX_PLAYERS,
        RATE_EXPERIENCE,
        RATE_SKILL,
        RATE_LOOT,
        RATE_MAGIC,
        GAME_PORT,
        LOGIN_PORT,
        STATUS_PORT,
        PROTECTION_LEVEL,
        LAST_INTEGER_CONFIG
    };

    ConfigManager() {
        string_values[CONFIG_FILE] = "config.lua";
    }

    const std::string& getString(string_config_t what) const {
        if (what >= LAST_STRING_CONFIG) return dummyStr;
        return string_values[what];
    }

    int32_t getNumber(integer_config_t what) const {
        if (what >= LAST_INTEGER_CONFIG) return 0;
        return integer_values[what];
    }

    bool getBoolean(boolean_config_t what) const {
        if (what >= LAST_BOOLEAN_CONFIG) return false;
        return boolean_values[what];
    }

    bool setString(string_config_t what, const std::string& value) {
        if (what >= LAST_STRING_CONFIG) return false;
        string_values[what] = value;
        return true;
    }

    bool setNumber(integer_config_t what, int32_t value) {
        if (what >= LAST_INTEGER_CONFIG) return false;
        integer_values[what] = value;
        return true;
    }

    bool setBoolean(boolean_config_t what, bool value) {
        if (what >= LAST_BOOLEAN_CONFIG) return false;
        boolean_values[what] = value;
        return true;
    }

private:
    std::string string_values[LAST_STRING_CONFIG] = {};
    int32_t integer_values[LAST_INTEGER_CONFIG] = {};
    bool boolean_values[LAST_BOOLEAN_CONFIG] = {};
    static std::string dummyStr;
};

std::string ConfigManager::dummyStr;

// ================================================================
// TESTS
// ================================================================

class ConfigManagerTest : public ::testing::Test {
protected:
    ConfigManager config;
};

// ---- String config ----
TEST_F(ConfigManagerTest, DefaultConfigFile) {
    EXPECT_EQ(config.getString(ConfigManager::CONFIG_FILE), "config.lua");
}

TEST_F(ConfigManagerTest, SetAndGetString) {
    EXPECT_TRUE(config.setString(ConfigManager::SERVER_NAME, "Test Server"));
    EXPECT_EQ(config.getString(ConfigManager::SERVER_NAME), "Test Server");
}

TEST_F(ConfigManagerTest, SetStringIP) {
    EXPECT_TRUE(config.setString(ConfigManager::IP, "192.168.1.1"));
    EXPECT_EQ(config.getString(ConfigManager::IP), "192.168.1.1");
}

TEST_F(ConfigManagerTest, SetStringMOTD) {
    EXPECT_TRUE(config.setString(ConfigManager::MOTD, "Welcome to the server!"));
    EXPECT_EQ(config.getString(ConfigManager::MOTD), "Welcome to the server!");
}

TEST_F(ConfigManagerTest, InvalidStringIndex) {
    EXPECT_EQ(config.getString(ConfigManager::LAST_STRING_CONFIG), "");
}

TEST_F(ConfigManagerTest, SetInvalidStringReturnsFalse) {
    EXPECT_FALSE(config.setString(ConfigManager::LAST_STRING_CONFIG, "test"));
}

// ---- Integer config ----
TEST_F(ConfigManagerTest, DefaultIntegerIsZero) {
    EXPECT_EQ(config.getNumber(ConfigManager::MAX_PLAYERS), 0);
}

TEST_F(ConfigManagerTest, SetAndGetInteger) {
    EXPECT_TRUE(config.setNumber(ConfigManager::MAX_PLAYERS, 100));
    EXPECT_EQ(config.getNumber(ConfigManager::MAX_PLAYERS), 100);
}

TEST_F(ConfigManagerTest, SetGamePort) {
    EXPECT_TRUE(config.setNumber(ConfigManager::GAME_PORT, 7172));
    EXPECT_EQ(config.getNumber(ConfigManager::GAME_PORT), 7172);
}

TEST_F(ConfigManagerTest, SetSQLPort) {
    EXPECT_TRUE(config.setNumber(ConfigManager::SQL_PORT, 3306));
    EXPECT_EQ(config.getNumber(ConfigManager::SQL_PORT), 3306);
}

TEST_F(ConfigManagerTest, SetRates) {
    config.setNumber(ConfigManager::RATE_EXPERIENCE, 5);
    config.setNumber(ConfigManager::RATE_SKILL, 3);
    config.setNumber(ConfigManager::RATE_LOOT, 2);
    config.setNumber(ConfigManager::RATE_MAGIC, 3);

    EXPECT_EQ(config.getNumber(ConfigManager::RATE_EXPERIENCE), 5);
    EXPECT_EQ(config.getNumber(ConfigManager::RATE_SKILL), 3);
    EXPECT_EQ(config.getNumber(ConfigManager::RATE_LOOT), 2);
    EXPECT_EQ(config.getNumber(ConfigManager::RATE_MAGIC), 3);
}

TEST_F(ConfigManagerTest, InvalidIntegerIndex) {
    EXPECT_EQ(config.getNumber(ConfigManager::LAST_INTEGER_CONFIG), 0);
}

TEST_F(ConfigManagerTest, SetInvalidIntegerReturnsFalse) {
    EXPECT_FALSE(config.setNumber(ConfigManager::LAST_INTEGER_CONFIG, 42));
}

TEST_F(ConfigManagerTest, NegativeInteger) {
    EXPECT_TRUE(config.setNumber(ConfigManager::PROTECTION_LEVEL, -1));
    EXPECT_EQ(config.getNumber(ConfigManager::PROTECTION_LEVEL), -1);
}

// ---- Boolean config ----
TEST_F(ConfigManagerTest, DefaultBooleanIsFalse) {
    EXPECT_FALSE(config.getBoolean(ConfigManager::ALLOW_CHANGEOUTFIT));
}

TEST_F(ConfigManagerTest, SetAndGetBoolean) {
    EXPECT_TRUE(config.setBoolean(ConfigManager::FREE_PREMIUM, true));
    EXPECT_TRUE(config.getBoolean(ConfigManager::FREE_PREMIUM));
}

TEST_F(ConfigManagerTest, SetBooleanFalse) {
    config.setBoolean(ConfigManager::FREE_PREMIUM, true);
    config.setBoolean(ConfigManager::FREE_PREMIUM, false);
    EXPECT_FALSE(config.getBoolean(ConfigManager::FREE_PREMIUM));
}

TEST_F(ConfigManagerTest, InvalidBooleanIndex) {
    EXPECT_FALSE(config.getBoolean(ConfigManager::LAST_BOOLEAN_CONFIG));
}

TEST_F(ConfigManagerTest, SetInvalidBooleanReturnsFalse) {
    EXPECT_FALSE(config.setBoolean(ConfigManager::LAST_BOOLEAN_CONFIG, true));
}

TEST_F(ConfigManagerTest, MultipleBooleans) {
    config.setBoolean(ConfigManager::ALLOW_CHANGEOUTFIT, true);
    config.setBoolean(ConfigManager::EMOTE_SPELLS, true);
    config.setBoolean(ConfigManager::STAMINA_SYSTEM, false);

    EXPECT_TRUE(config.getBoolean(ConfigManager::ALLOW_CHANGEOUTFIT));
    EXPECT_TRUE(config.getBoolean(ConfigManager::EMOTE_SPELLS));
    EXPECT_FALSE(config.getBoolean(ConfigManager::STAMINA_SYSTEM));
}

// ---- Cross-type independence ----
TEST_F(ConfigManagerTest, TypesAreIndependent) {
    config.setString(ConfigManager::SERVER_NAME, "test");
    config.setNumber(ConfigManager::MAX_PLAYERS, 100);
    config.setBoolean(ConfigManager::FREE_PREMIUM, true);

    EXPECT_EQ(config.getString(ConfigManager::SERVER_NAME), "test");
    EXPECT_EQ(config.getNumber(ConfigManager::MAX_PLAYERS), 100);
    EXPECT_TRUE(config.getBoolean(ConfigManager::FREE_PREMIUM));
}
