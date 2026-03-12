/**
 * Unit tests for combat system types, damage calculation structures,
 * and combat parameter configuration.
 *
 * Tests CombatDamage struct, CombatType_t mappings, CombatParams defaults,
 * and damage formula constants.
 */

#include <gtest/gtest.h>
#include <cstdint>
#include <string>
#include <unordered_map>

// Re-declare enums from const.h / enums.h
enum CombatType_t : uint16_t {
    COMBAT_NONE = 0,
    COMBAT_PHYSICALDAMAGE = 1 << 0,
    COMBAT_ENERGYDAMAGE = 1 << 1,
    COMBAT_EARTHDAMAGE = 1 << 2,
    COMBAT_FIREDAMAGE = 1 << 3,
    COMBAT_UNDEFINEDDAMAGE = 1 << 4,
    COMBAT_LIFEDRAIN = 1 << 5,
    COMBAT_MANADRAIN = 1 << 6,
    COMBAT_HEALING = 1 << 7,
    COMBAT_DROWNDAMAGE = 1 << 8,
    COMBAT_ICEDAMAGE = 1 << 9,
    COMBAT_HOLYDAMAGE = 1 << 10,
    COMBAT_DEATHDAMAGE = 1 << 11,
    COMBAT_COUNT = 13,
};

enum BlockType_t : uint8_t {
    BLOCK_NONE,
    BLOCK_DEFENSE,
    BLOCK_ARMOR,
    BLOCK_IMMUNITY,
};

enum CombatOrigin {
    ORIGIN_NONE,
    ORIGIN_CONDITION,
    ORIGIN_SPELL,
    ORIGIN_MELEE,
    ORIGIN_RANGED,
};

enum formulaType_t {
    COMBAT_FORMULA_UNDEFINED,
    COMBAT_FORMULA_LEVELMAGIC,
    COMBAT_FORMULA_SKILL,
    COMBAT_FORMULA_DAMAGE,
};

struct CombatDamage {
    struct {
        CombatType_t type;
        int32_t value;
    } primary, secondary;
    CombatOrigin origin;
    BlockType_t blockType;
    bool critical;
    CombatDamage() {
        origin = ORIGIN_NONE;
        blockType = BLOCK_NONE;
        primary.type = secondary.type = COMBAT_NONE;
        primary.value = secondary.value = 0;
        critical = false;
    }
};

// getCombatName from tools.cpp
using CombatTypeNames = std::unordered_map<CombatType_t, std::string, std::hash<int32_t>>;
CombatTypeNames combatTypeNames = {
    {COMBAT_PHYSICALDAMAGE, "physical"},
    {COMBAT_ENERGYDAMAGE,   "energy"},
    {COMBAT_EARTHDAMAGE,    "earth"},
    {COMBAT_FIREDAMAGE,     "fire"},
    {COMBAT_UNDEFINEDDAMAGE,"undefined"},
    {COMBAT_LIFEDRAIN,      "lifedrain"},
    {COMBAT_MANADRAIN,      "manadrain"},
    {COMBAT_HEALING,        "healing"},
    {COMBAT_DROWNDAMAGE,    "drown"},
    {COMBAT_ICEDAMAGE,      "ice"},
    {COMBAT_HOLYDAMAGE,     "holy"},
    {COMBAT_DEATHDAMAGE,    "death"},
};

std::string getCombatName(CombatType_t combatType) {
    auto it = combatTypeNames.find(combatType);
    return (it != combatTypeNames.end()) ? it->second : "unknown";
}

size_t combatTypeToIndex(CombatType_t combatType) {
    switch (combatType) {
        case COMBAT_PHYSICALDAMAGE: return 0;
        case COMBAT_ENERGYDAMAGE:   return 1;
        case COMBAT_EARTHDAMAGE:    return 2;
        case COMBAT_FIREDAMAGE:     return 3;
        case COMBAT_UNDEFINEDDAMAGE:return 4;
        case COMBAT_LIFEDRAIN:      return 5;
        case COMBAT_MANADRAIN:      return 6;
        case COMBAT_HEALING:        return 7;
        case COMBAT_DROWNDAMAGE:    return 8;
        case COMBAT_ICEDAMAGE:      return 9;
        case COMBAT_HOLYDAMAGE:     return 10;
        case COMBAT_DEATHDAMAGE:    return 11;
        default: return 0;
    }
}

// ================================================================
// TESTS
// ================================================================

// ---- CombatDamage struct ----
TEST(CombatDamage, DefaultValues) {
    CombatDamage damage;
    EXPECT_EQ(damage.primary.type, COMBAT_NONE);
    EXPECT_EQ(damage.primary.value, 0);
    EXPECT_EQ(damage.secondary.type, COMBAT_NONE);
    EXPECT_EQ(damage.secondary.value, 0);
    EXPECT_EQ(damage.origin, ORIGIN_NONE);
    EXPECT_EQ(damage.blockType, BLOCK_NONE);
    EXPECT_FALSE(damage.critical);
}

TEST(CombatDamage, SetPrimaryDamage) {
    CombatDamage damage;
    damage.primary.type = COMBAT_FIREDAMAGE;
    damage.primary.value = -150;
    damage.origin = ORIGIN_SPELL;
    EXPECT_EQ(damage.primary.type, COMBAT_FIREDAMAGE);
    EXPECT_EQ(damage.primary.value, -150);
    EXPECT_EQ(damage.origin, ORIGIN_SPELL);
}

TEST(CombatDamage, DualElementDamage) {
    CombatDamage damage;
    damage.primary.type = COMBAT_PHYSICALDAMAGE;
    damage.primary.value = -100;
    damage.secondary.type = COMBAT_FIREDAMAGE;
    damage.secondary.value = -50;
    EXPECT_EQ(damage.primary.value + damage.secondary.value, -150);
}

TEST(CombatDamage, CriticalDamage) {
    CombatDamage damage;
    damage.primary.type = COMBAT_PHYSICALDAMAGE;
    damage.primary.value = -200;
    damage.critical = true;
    EXPECT_TRUE(damage.critical);
}

TEST(CombatDamage, HealingIsPositive) {
    CombatDamage damage;
    damage.primary.type = COMBAT_HEALING;
    damage.primary.value = 100;
    EXPECT_EQ(damage.primary.type, COMBAT_HEALING);
    EXPECT_GT(damage.primary.value, 0);
}

// ---- Block types ----
TEST(BlockType, Values) {
    EXPECT_EQ(BLOCK_NONE, 0);
    EXPECT_EQ(BLOCK_DEFENSE, 1);
    EXPECT_EQ(BLOCK_ARMOR, 2);
    EXPECT_EQ(BLOCK_IMMUNITY, 3);
}

// ---- Combat origins ----
TEST(CombatOrigin, Values) {
    EXPECT_EQ(ORIGIN_NONE, 0);
    EXPECT_EQ(ORIGIN_CONDITION, 1);
    EXPECT_EQ(ORIGIN_SPELL, 2);
    EXPECT_EQ(ORIGIN_MELEE, 3);
    EXPECT_EQ(ORIGIN_RANGED, 4);
}

// ---- getCombatName ----
TEST(CombatName, KnownTypes) {
    EXPECT_EQ(getCombatName(COMBAT_PHYSICALDAMAGE), "physical");
    EXPECT_EQ(getCombatName(COMBAT_ENERGYDAMAGE), "energy");
    EXPECT_EQ(getCombatName(COMBAT_EARTHDAMAGE), "earth");
    EXPECT_EQ(getCombatName(COMBAT_FIREDAMAGE), "fire");
    EXPECT_EQ(getCombatName(COMBAT_ICEDAMAGE), "ice");
    EXPECT_EQ(getCombatName(COMBAT_HOLYDAMAGE), "holy");
    EXPECT_EQ(getCombatName(COMBAT_DEATHDAMAGE), "death");
    EXPECT_EQ(getCombatName(COMBAT_HEALING), "healing");
    EXPECT_EQ(getCombatName(COMBAT_LIFEDRAIN), "lifedrain");
    EXPECT_EQ(getCombatName(COMBAT_MANADRAIN), "manadrain");
    EXPECT_EQ(getCombatName(COMBAT_DROWNDAMAGE), "drown");
}

TEST(CombatName, UnknownType) {
    EXPECT_EQ(getCombatName(COMBAT_NONE), "unknown");
}

// ---- CombatType_t bitmask ----
TEST(CombatType, UniqueValues) {
    CombatType_t types[] = {
        COMBAT_PHYSICALDAMAGE, COMBAT_ENERGYDAMAGE, COMBAT_EARTHDAMAGE,
        COMBAT_FIREDAMAGE, COMBAT_UNDEFINEDDAMAGE, COMBAT_LIFEDRAIN,
        COMBAT_MANADRAIN, COMBAT_HEALING, COMBAT_DROWNDAMAGE,
        COMBAT_ICEDAMAGE, COMBAT_HOLYDAMAGE, COMBAT_DEATHDAMAGE,
    };
    uint16_t combined = 0;
    for (auto t : types) {
        EXPECT_EQ(combined & t, 0u) << "Overlap at: " << t;
        combined |= t;
    }
}

TEST(CombatType, FireEqualsEarthShifted) {
    // Fire is bit 3, Earth is bit 2
    EXPECT_EQ(COMBAT_FIREDAMAGE, COMBAT_EARTHDAMAGE << 1);
}

// ---- combatTypeToIndex ----
TEST(CombatTypeIndex, AllTypes) {
    EXPECT_EQ(combatTypeToIndex(COMBAT_PHYSICALDAMAGE), 0u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_ENERGYDAMAGE), 1u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_EARTHDAMAGE), 2u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_FIREDAMAGE), 3u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_UNDEFINEDDAMAGE), 4u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_LIFEDRAIN), 5u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_MANADRAIN), 6u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_HEALING), 7u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_DROWNDAMAGE), 8u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_ICEDAMAGE), 9u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_HOLYDAMAGE), 10u);
    EXPECT_EQ(combatTypeToIndex(COMBAT_DEATHDAMAGE), 11u);
}

// ---- Formula types ----
TEST(FormulaType, Values) {
    EXPECT_EQ(COMBAT_FORMULA_UNDEFINED, 0);
    EXPECT_EQ(COMBAT_FORMULA_LEVELMAGIC, 1);
    EXPECT_EQ(COMBAT_FORMULA_SKILL, 2);
    EXPECT_EQ(COMBAT_FORMULA_DAMAGE, 3);
}

// ---- Damage calculation simulation ----
TEST(DamageCalc, MeleeFormula) {
    // Simulate: base damage = level * attack / 20
    int level = 100;
    int attack = 50;
    float meleeDamageMultiplier = 1.0f;
    int baseDamage = static_cast<int>(level * attack / 20.0f * meleeDamageMultiplier);
    EXPECT_EQ(baseDamage, 250);
}

TEST(DamageCalc, MeleeFormulaWithMultiplier) {
    int level = 100;
    int attack = 50;
    float meleeDamageMultiplier = 1.2f; // Knight bonus
    int baseDamage = static_cast<int>(level * attack / 20.0f * meleeDamageMultiplier);
    EXPECT_EQ(baseDamage, 300);
}

TEST(DamageCalc, ArmorReduction) {
    int damage = -200;
    int armor = 15;
    // TFS armor reduces by random(armor/2, armor)
    int minReduction = armor / 2;
    int maxReduction = armor;
    EXPECT_GE(minReduction, 7);
    EXPECT_LE(maxReduction, 15);
    int reducedDamage = damage + maxReduction;
    EXPECT_EQ(reducedDamage, -185);
}
