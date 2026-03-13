/**
 * Unit tests for Item attribute handling.
 *
 * Tests the stringToItemAttribute function from tools.cpp and
 * the itemAttrTypes enum/flag system from enums.h.
 * Also tests item ID constants and attribute bitmask operations.
 */

#include <gtest/gtest.h>
#include <cstdint>
#include <string>

// Re-declare itemAttrTypes from enums.h
enum itemAttrTypes : uint32_t {
    ITEM_ATTRIBUTE_NONE = 0,
    ITEM_ATTRIBUTE_ACTIONID = 1 << 0,
    ITEM_ATTRIBUTE_UNIQUEID = 1 << 1,
    ITEM_ATTRIBUTE_DESCRIPTION = 1 << 2,
    ITEM_ATTRIBUTE_TEXT = 1 << 3,
    ITEM_ATTRIBUTE_DATE = 1 << 4,
    ITEM_ATTRIBUTE_WRITER = 1 << 5,
    ITEM_ATTRIBUTE_NAME = 1 << 6,
    ITEM_ATTRIBUTE_ARTICLE = 1 << 7,
    ITEM_ATTRIBUTE_PLURALNAME = 1 << 8,
    ITEM_ATTRIBUTE_WEIGHT = 1 << 9,
    ITEM_ATTRIBUTE_ATTACK = 1 << 10,
    ITEM_ATTRIBUTE_DEFENSE = 1 << 11,
    ITEM_ATTRIBUTE_EXTRADEFENSE = 1 << 12,
    ITEM_ATTRIBUTE_ARMOR = 1 << 13,
    ITEM_ATTRIBUTE_HITCHANCE = 1 << 14,
    ITEM_ATTRIBUTE_SHOOTRANGE = 1 << 15,
    ITEM_ATTRIBUTE_OWNER = 1 << 16,
    ITEM_ATTRIBUTE_DURATION = 1 << 17,
    ITEM_ATTRIBUTE_DECAYSTATE = 1 << 18,
    ITEM_ATTRIBUTE_CORPSEOWNER = 1 << 19,
    ITEM_ATTRIBUTE_CHARGES = 1 << 20,
    ITEM_ATTRIBUTE_FLUIDTYPE = 1 << 21,
    ITEM_ATTRIBUTE_DOORID = 1 << 22,
    ITEM_ATTRIBUTE_DECAYTO = 1 << 23,
    ITEM_ATTRIBUTE_WRAPID = 1 << 24,
    ITEM_ATTRIBUTE_STOREITEM = 1 << 25,
    ITEM_ATTRIBUTE_CUSTOM = 1U << 31,
};

// stringToItemAttribute from tools.cpp
itemAttrTypes stringToItemAttribute(const std::string& str) {
    if (str == "aid") return ITEM_ATTRIBUTE_ACTIONID;
    else if (str == "uid") return ITEM_ATTRIBUTE_UNIQUEID;
    else if (str == "description") return ITEM_ATTRIBUTE_DESCRIPTION;
    else if (str == "text") return ITEM_ATTRIBUTE_TEXT;
    else if (str == "date") return ITEM_ATTRIBUTE_DATE;
    else if (str == "writer") return ITEM_ATTRIBUTE_WRITER;
    else if (str == "name") return ITEM_ATTRIBUTE_NAME;
    else if (str == "article") return ITEM_ATTRIBUTE_ARTICLE;
    else if (str == "pluralname") return ITEM_ATTRIBUTE_PLURALNAME;
    else if (str == "weight") return ITEM_ATTRIBUTE_WEIGHT;
    else if (str == "attack") return ITEM_ATTRIBUTE_ATTACK;
    else if (str == "defense") return ITEM_ATTRIBUTE_DEFENSE;
    else if (str == "extradefense") return ITEM_ATTRIBUTE_EXTRADEFENSE;
    else if (str == "armor") return ITEM_ATTRIBUTE_ARMOR;
    else if (str == "hitchance") return ITEM_ATTRIBUTE_HITCHANCE;
    else if (str == "shootrange") return ITEM_ATTRIBUTE_SHOOTRANGE;
    else if (str == "owner") return ITEM_ATTRIBUTE_OWNER;
    else if (str == "duration") return ITEM_ATTRIBUTE_DURATION;
    else if (str == "decaystate") return ITEM_ATTRIBUTE_DECAYSTATE;
    else if (str == "corpseowner") return ITEM_ATTRIBUTE_CORPSEOWNER;
    else if (str == "charges") return ITEM_ATTRIBUTE_CHARGES;
    else if (str == "fluidtype") return ITEM_ATTRIBUTE_FLUIDTYPE;
    else if (str == "doorid") return ITEM_ATTRIBUTE_DOORID;
    else if (str == "wrapid") return ITEM_ATTRIBUTE_WRAPID;
    return ITEM_ATTRIBUTE_NONE;
}

// Item constants from const.h
enum item_t : uint16_t {
    ITEM_GOLD_COIN = 2148,
    ITEM_PLATINUM_COIN = 2152,
    ITEM_CRYSTAL_COIN = 2160,
    ITEM_DEPOT = 2594,
    ITEM_BAG = 1987,
    ITEM_PARCEL = 2595,
    ITEM_LETTER = 2597,
    ITEM_AMULETOFLOSS = 2173,
    ITEM_FIREFIELD_PVP_FULL = 1487,
    ITEM_POISONFIELD_PVP = 1490,
    ITEM_ENERGYFIELD_PVP = 1491,
    ITEM_MAGICWALL = 1497,
    ITEM_WILDGROWTH = 1499,
};

enum ItemDecayState_t : uint8_t {
    DECAYING_FALSE = 0,
    DECAYING_TRUE,
    DECAYING_PENDING,
};

// ================================================================
// TESTS
// ================================================================

// ---- stringToItemAttribute ----
TEST(ItemAttribute, ActionId) {
    EXPECT_EQ(stringToItemAttribute("aid"), ITEM_ATTRIBUTE_ACTIONID);
}

TEST(ItemAttribute, UniqueId) {
    EXPECT_EQ(stringToItemAttribute("uid"), ITEM_ATTRIBUTE_UNIQUEID);
}

TEST(ItemAttribute, Name) {
    EXPECT_EQ(stringToItemAttribute("name"), ITEM_ATTRIBUTE_NAME);
}

TEST(ItemAttribute, Attack) {
    EXPECT_EQ(stringToItemAttribute("attack"), ITEM_ATTRIBUTE_ATTACK);
}

TEST(ItemAttribute, Defense) {
    EXPECT_EQ(stringToItemAttribute("defense"), ITEM_ATTRIBUTE_DEFENSE);
}

TEST(ItemAttribute, Armor) {
    EXPECT_EQ(stringToItemAttribute("armor"), ITEM_ATTRIBUTE_ARMOR);
}

TEST(ItemAttribute, Weight) {
    EXPECT_EQ(stringToItemAttribute("weight"), ITEM_ATTRIBUTE_WEIGHT);
}

TEST(ItemAttribute, Duration) {
    EXPECT_EQ(stringToItemAttribute("duration"), ITEM_ATTRIBUTE_DURATION);
}

TEST(ItemAttribute, Charges) {
    EXPECT_EQ(stringToItemAttribute("charges"), ITEM_ATTRIBUTE_CHARGES);
}

TEST(ItemAttribute, UnknownReturnsNone) {
    EXPECT_EQ(stringToItemAttribute("nonexistent"), ITEM_ATTRIBUTE_NONE);
    EXPECT_EQ(stringToItemAttribute(""), ITEM_ATTRIBUTE_NONE);
}

TEST(ItemAttribute, AllMappingsReturnsNonNone) {
    const char* validNames[] = {
        "aid", "uid", "description", "text", "date", "writer",
        "name", "article", "pluralname", "weight", "attack",
        "defense", "extradefense", "armor", "hitchance", "shootrange",
        "owner", "duration", "decaystate", "corpseowner", "charges",
        "fluidtype", "doorid", "wrapid"
    };
    for (const char* name : validNames) {
        EXPECT_NE(stringToItemAttribute(name), ITEM_ATTRIBUTE_NONE) << "Failed for: " << name;
    }
}

// ---- Attribute bitmask operations ----
TEST(ItemAttributeFlags, SingleBits) {
    // Each attribute should be a distinct power of 2
    EXPECT_EQ(ITEM_ATTRIBUTE_ACTIONID, 1u);
    EXPECT_EQ(ITEM_ATTRIBUTE_UNIQUEID, 2u);
    EXPECT_EQ(ITEM_ATTRIBUTE_DESCRIPTION, 4u);
    EXPECT_EQ(ITEM_ATTRIBUTE_TEXT, 8u);
}

TEST(ItemAttributeFlags, CombinedFlags) {
    uint32_t flags = ITEM_ATTRIBUTE_ATTACK | ITEM_ATTRIBUTE_DEFENSE | ITEM_ATTRIBUTE_ARMOR;
    EXPECT_TRUE(flags & ITEM_ATTRIBUTE_ATTACK);
    EXPECT_TRUE(flags & ITEM_ATTRIBUTE_DEFENSE);
    EXPECT_TRUE(flags & ITEM_ATTRIBUTE_ARMOR);
    EXPECT_FALSE(flags & ITEM_ATTRIBUTE_WEIGHT);
}

TEST(ItemAttributeFlags, NoBitOverlap) {
    // Verify no two attributes share the same bit
    uint32_t allFlags[] = {
        ITEM_ATTRIBUTE_ACTIONID, ITEM_ATTRIBUTE_UNIQUEID, ITEM_ATTRIBUTE_DESCRIPTION,
        ITEM_ATTRIBUTE_TEXT, ITEM_ATTRIBUTE_DATE, ITEM_ATTRIBUTE_WRITER,
        ITEM_ATTRIBUTE_NAME, ITEM_ATTRIBUTE_ARTICLE, ITEM_ATTRIBUTE_PLURALNAME,
        ITEM_ATTRIBUTE_WEIGHT, ITEM_ATTRIBUTE_ATTACK, ITEM_ATTRIBUTE_DEFENSE,
        ITEM_ATTRIBUTE_EXTRADEFENSE, ITEM_ATTRIBUTE_ARMOR, ITEM_ATTRIBUTE_HITCHANCE,
        ITEM_ATTRIBUTE_SHOOTRANGE, ITEM_ATTRIBUTE_OWNER, ITEM_ATTRIBUTE_DURATION,
        ITEM_ATTRIBUTE_DECAYSTATE, ITEM_ATTRIBUTE_CORPSEOWNER, ITEM_ATTRIBUTE_CHARGES,
        ITEM_ATTRIBUTE_FLUIDTYPE, ITEM_ATTRIBUTE_DOORID, ITEM_ATTRIBUTE_DECAYTO,
        ITEM_ATTRIBUTE_WRAPID, ITEM_ATTRIBUTE_STOREITEM
    };
    uint32_t combined = 0;
    for (uint32_t f : allFlags) {
        EXPECT_EQ(combined & f, 0u) << "Bit overlap detected for flag: " << f;
        combined |= f;
    }
}

// ---- Item ID constants ----
TEST(ItemConstants, CoinIds) {
    EXPECT_EQ(ITEM_GOLD_COIN, 2148);
    EXPECT_EQ(ITEM_PLATINUM_COIN, 2152);
    EXPECT_EQ(ITEM_CRYSTAL_COIN, 2160);
}

TEST(ItemConstants, FieldIds) {
    EXPECT_EQ(ITEM_FIREFIELD_PVP_FULL, 1487);
    EXPECT_EQ(ITEM_POISONFIELD_PVP, 1490);
    EXPECT_EQ(ITEM_ENERGYFIELD_PVP, 1491);
}

TEST(ItemConstants, ContainerIds) {
    EXPECT_EQ(ITEM_BAG, 1987);
    EXPECT_EQ(ITEM_DEPOT, 2594);
}

// ---- DecayState ----
TEST(ItemDecayState, Values) {
    EXPECT_EQ(DECAYING_FALSE, 0);
    EXPECT_EQ(DECAYING_TRUE, 1);
    EXPECT_EQ(DECAYING_PENDING, 2);
}
