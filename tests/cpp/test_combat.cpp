/**
 * Unit tests for combat system types, damage calculation structures,
 * and combat parameter configuration.
 *
 * Tests CombatDamage struct, CombatType_t mappings, CombatParams defaults,
 * and damage formula constants.
 */

#include <gtest/gtest.h>
#include <cmath>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

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

TEST(DamageCalc, ZeroArmorNoReduction) {
    int damage = -200;
    int armor = 0;
    int maxReduction = armor;
    EXPECT_EQ(damage + maxReduction, -200);
}

TEST(DamageCalc, LevelMagicFormula) {
    // Simulates COMBAT_FORMULA_LEVELMAGIC:
    //   min = (level * 2 + magLevel * 3) * mina + minb
    //   max = (level * 2 + magLevel * 3) * maxa + maxb
    int level = 100;
    int magLevel = 70;
    double mina = -1.0, minb = -10.0;
    double maxa = -1.4, maxb = -20.0;
    double levelBase = level * 2 + magLevel * 3; // 200 + 210 = 410
    double minDamage = levelBase * mina + minb;  // -410 + -10 = -420
    double maxDamage = levelBase * maxa + maxb;  // -574 + -20 = -594
    EXPECT_DOUBLE_EQ(minDamage, -420.0);
    EXPECT_DOUBLE_EQ(maxDamage, -594.0);
    EXPECT_LE(maxDamage, minDamage); // max is more negative (more damage)
}

TEST(DamageCalc, SkillFormula) {
    // Simulates COMBAT_FORMULA_SKILL:
    //   min = skill * mina + minb
    //   max = skill * maxa + maxb
    int skill = 90;
    double mina = 0.0, minb = 0.0;
    double maxa = 0.085, maxb = 1.0;
    double minDamage = skill * mina + minb; // 0
    double maxDamage = skill * maxa + maxb; // 7.65 + 1.0 = 8.65
    EXPECT_DOUBLE_EQ(minDamage, 0.0);
    EXPECT_NEAR(maxDamage, 8.65, 0.001);
}

// ---- ConditionType_t <-> CombatType_t mappings ----
// Re-declare condition types from enums.h
enum ConditionType_t : uint32_t {
    CONDITION_NONE = 0,
    CONDITION_POISON = 1 << 0,
    CONDITION_FIRE = 1 << 1,
    CONDITION_ENERGY = 1 << 2,
    CONDITION_BLEEDING = 1 << 3,
    CONDITION_DROWN = 1 << 15,
    CONDITION_FREEZING = 1 << 20,
    CONDITION_DAZZLED = 1 << 21,
    CONDITION_CURSED = 1 << 22,
};

// Extracted from Combat::ConditionToDamageType (combat.cpp)
CombatType_t conditionToDamageType(ConditionType_t type) {
    switch (type) {
        case CONDITION_FIRE:     return COMBAT_FIREDAMAGE;
        case CONDITION_ENERGY:   return COMBAT_ENERGYDAMAGE;
        case CONDITION_BLEEDING: return COMBAT_PHYSICALDAMAGE;
        case CONDITION_DROWN:    return COMBAT_DROWNDAMAGE;
        case CONDITION_POISON:   return COMBAT_EARTHDAMAGE;
        case CONDITION_FREEZING: return COMBAT_ICEDAMAGE;
        case CONDITION_DAZZLED:  return COMBAT_HOLYDAMAGE;
        case CONDITION_CURSED:   return COMBAT_DEATHDAMAGE;
        default: return COMBAT_NONE;
    }
}

// Extracted from Combat::DamageToConditionType (combat.cpp)
ConditionType_t damageToConditionType(CombatType_t type) {
    switch (type) {
        case COMBAT_FIREDAMAGE:     return CONDITION_FIRE;
        case COMBAT_ENERGYDAMAGE:   return CONDITION_ENERGY;
        case COMBAT_DROWNDAMAGE:    return CONDITION_DROWN;
        case COMBAT_EARTHDAMAGE:    return CONDITION_POISON;
        case COMBAT_ICEDAMAGE:      return CONDITION_FREEZING;
        case COMBAT_HOLYDAMAGE:     return CONDITION_DAZZLED;
        case COMBAT_DEATHDAMAGE:    return CONDITION_CURSED;
        case COMBAT_PHYSICALDAMAGE: return CONDITION_BLEEDING;
        default: return CONDITION_NONE;
    }
}

TEST(ConditionDamageMapping, FireRoundTrip) {
    EXPECT_EQ(conditionToDamageType(CONDITION_FIRE), COMBAT_FIREDAMAGE);
    EXPECT_EQ(damageToConditionType(COMBAT_FIREDAMAGE), CONDITION_FIRE);
}

TEST(ConditionDamageMapping, EnergyRoundTrip) {
    EXPECT_EQ(conditionToDamageType(CONDITION_ENERGY), COMBAT_ENERGYDAMAGE);
    EXPECT_EQ(damageToConditionType(COMBAT_ENERGYDAMAGE), CONDITION_ENERGY);
}

TEST(ConditionDamageMapping, EarthPoisonRoundTrip) {
    EXPECT_EQ(conditionToDamageType(CONDITION_POISON), COMBAT_EARTHDAMAGE);
    EXPECT_EQ(damageToConditionType(COMBAT_EARTHDAMAGE), CONDITION_POISON);
}

TEST(ConditionDamageMapping, IceFreezingRoundTrip) {
    EXPECT_EQ(conditionToDamageType(CONDITION_FREEZING), COMBAT_ICEDAMAGE);
    EXPECT_EQ(damageToConditionType(COMBAT_ICEDAMAGE), CONDITION_FREEZING);
}

TEST(ConditionDamageMapping, HolyDazzledRoundTrip) {
    EXPECT_EQ(conditionToDamageType(CONDITION_DAZZLED), COMBAT_HOLYDAMAGE);
    EXPECT_EQ(damageToConditionType(COMBAT_HOLYDAMAGE), CONDITION_DAZZLED);
}

TEST(ConditionDamageMapping, DeathCursedRoundTrip) {
    EXPECT_EQ(conditionToDamageType(CONDITION_CURSED), COMBAT_DEATHDAMAGE);
    EXPECT_EQ(damageToConditionType(COMBAT_DEATHDAMAGE), CONDITION_CURSED);
}

TEST(ConditionDamageMapping, DrownRoundTrip) {
    EXPECT_EQ(conditionToDamageType(CONDITION_DROWN), COMBAT_DROWNDAMAGE);
    EXPECT_EQ(damageToConditionType(COMBAT_DROWNDAMAGE), CONDITION_DROWN);
}

TEST(ConditionDamageMapping, BleedingPhysicalRoundTrip) {
    EXPECT_EQ(conditionToDamageType(CONDITION_BLEEDING), COMBAT_PHYSICALDAMAGE);
    EXPECT_EQ(damageToConditionType(COMBAT_PHYSICALDAMAGE), CONDITION_BLEEDING);
}

TEST(ConditionDamageMapping, UnknownCondition) {
    EXPECT_EQ(conditionToDamageType(CONDITION_NONE), COMBAT_NONE);
}

TEST(ConditionDamageMapping, UnknownDamageType) {
    EXPECT_EQ(damageToConditionType(COMBAT_NONE), CONDITION_NONE);
    EXPECT_EQ(damageToConditionType(COMBAT_HEALING), CONDITION_NONE);
    EXPECT_EQ(damageToConditionType(COMBAT_LIFEDRAIN), CONDITION_NONE);
    EXPECT_EQ(damageToConditionType(COMBAT_MANADRAIN), CONDITION_NONE);
}

// ---- Critical hit simulation (from Combat::checkCriticalHit) ----
// Re-implements the logic without needing a Player object
void simulateCriticalHit(CombatDamage& damage, CombatOrigin origin,
                         uint16_t critChance, uint16_t critAmount, int roll) {
    if (damage.critical || origin == ORIGIN_CONDITION) {
        return;
    }
    if (damage.primary.value > 0 || damage.secondary.value > 0) {
        return; // only applies to damage (negative values), not healing
    }
    if (critAmount != 0 && critChance != 0 && roll <= critChance) {
        damage.primary.value += std::round(damage.primary.value * (critAmount / 100.0));
        damage.secondary.value += std::round(damage.secondary.value * (critAmount / 100.0));
        damage.critical = true;
    }
}

TEST(CriticalHit, AppliesCritWhenRollSucceeds) {
    CombatDamage damage;
    damage.primary.value = -200;
    damage.secondary.value = -50;
    // 10% crit chance, 50% crit amount, roll of 5 (succeeds since 5 <= 10)
    simulateCriticalHit(damage, ORIGIN_SPELL, 10, 50, 5);
    EXPECT_TRUE(damage.critical);
    EXPECT_EQ(damage.primary.value, -300);  // -200 + round(-200 * 0.5) = -200 + -100
    EXPECT_EQ(damage.secondary.value, -75); // -50 + round(-50 * 0.5) = -50 + -25
}

TEST(CriticalHit, NoCritWhenRollFails) {
    CombatDamage damage;
    damage.primary.value = -200;
    simulateCriticalHit(damage, ORIGIN_SPELL, 10, 50, 50); // roll 50 > chance 10
    EXPECT_FALSE(damage.critical);
    EXPECT_EQ(damage.primary.value, -200);
}

TEST(CriticalHit, NoCritOnConditionDamage) {
    CombatDamage damage;
    damage.primary.value = -100;
    simulateCriticalHit(damage, ORIGIN_CONDITION, 100, 50, 1); // 100% chance but origin is condition
    EXPECT_FALSE(damage.critical);
    EXPECT_EQ(damage.primary.value, -100);
}

TEST(CriticalHit, NoCritOnHealing) {
    CombatDamage damage;
    damage.primary.value = 100; // positive = healing
    simulateCriticalHit(damage, ORIGIN_SPELL, 100, 50, 1);
    EXPECT_FALSE(damage.critical);
    EXPECT_EQ(damage.primary.value, 100);
}

TEST(CriticalHit, NoCritWhenAlreadyCritical) {
    CombatDamage damage;
    damage.primary.value = -200;
    damage.critical = true; // already crit
    simulateCriticalHit(damage, ORIGIN_SPELL, 100, 50, 1);
    EXPECT_EQ(damage.primary.value, -200); // unchanged
}

TEST(CriticalHit, ZeroCritChance) {
    CombatDamage damage;
    damage.primary.value = -200;
    simulateCriticalHit(damage, ORIGIN_SPELL, 0, 50, 1);
    EXPECT_FALSE(damage.critical);
}

TEST(CriticalHit, ZeroCritAmount) {
    CombatDamage damage;
    damage.primary.value = -200;
    simulateCriticalHit(damage, ORIGIN_SPELL, 100, 0, 1);
    EXPECT_FALSE(damage.critical);
}

// ---- PvP damage scaling (from doTargetCombat) ----
// In TFS, PvP damage is halved against non-black-skull players
TEST(PvPScaling, DamageHalved) {
    CombatDamage damage;
    damage.primary.value = -200;
    damage.secondary.value = -100;
    // PvP halving
    damage.primary.value /= 2;
    damage.secondary.value /= 2;
    EXPECT_EQ(damage.primary.value, -100);
    EXPECT_EQ(damage.secondary.value, -50);
}

TEST(PvPScaling, OddDamageRoundsDown) {
    CombatDamage damage;
    damage.primary.value = -201;
    damage.primary.value /= 2;
    EXPECT_EQ(damage.primary.value, -100); // integer division truncates toward zero
}

TEST(PvPScaling, ZeroDamageUnchanged) {
    CombatDamage damage;
    damage.primary.value = 0;
    damage.primary.value /= 2;
    EXPECT_EQ(damage.primary.value, 0);
}

// ---- MatrixArea (from combat.h) ----
// Simplified re-implementation for testing
class TestMatrixArea {
public:
    TestMatrixArea(uint32_t rows, uint32_t cols)
        : centerX(0), centerY(0), rows_(rows), cols_(cols) {
        data_.resize(rows * cols, false);
    }

    void setValue(uint32_t row, uint32_t col, bool value) {
        data_[row * cols_ + col] = value;
    }
    bool getValue(uint32_t row, uint32_t col) const {
        return data_[row * cols_ + col];
    }
    void setCenter(uint32_t y, uint32_t x) {
        centerX = x;
        centerY = y;
    }
    void getCenter(uint32_t& y, uint32_t& x) const {
        x = centerX;
        y = centerY;
    }
    uint32_t getRows() const { return rows_; }
    uint32_t getCols() const { return cols_; }

private:
    uint32_t centerX, centerY;
    uint32_t rows_, cols_;
    std::vector<bool> data_;
};

TEST(MatrixArea, Create3x3) {
    TestMatrixArea area(3, 3);
    EXPECT_EQ(area.getRows(), 3u);
    EXPECT_EQ(area.getCols(), 3u);
    // All values should default to false
    for (uint32_t r = 0; r < 3; ++r) {
        for (uint32_t c = 0; c < 3; ++c) {
            EXPECT_FALSE(area.getValue(r, c));
        }
    }
}

TEST(MatrixArea, SetAndGetValues) {
    TestMatrixArea area(3, 3);
    area.setValue(0, 0, true);
    area.setValue(1, 1, true);
    area.setValue(2, 2, true);
    EXPECT_TRUE(area.getValue(0, 0));
    EXPECT_FALSE(area.getValue(0, 1));
    EXPECT_TRUE(area.getValue(1, 1));
    EXPECT_TRUE(area.getValue(2, 2));
}

TEST(MatrixArea, Center) {
    TestMatrixArea area(5, 5);
    area.setCenter(2, 2);
    uint32_t cy, cx;
    area.getCenter(cy, cx);
    EXPECT_EQ(cx, 2u);
    EXPECT_EQ(cy, 2u);
}

TEST(MatrixArea, CrossPattern) {
    // A 3x3 cross pattern (like a basic area spell)
    TestMatrixArea area(3, 3);
    area.setCenter(1, 1);
    area.setValue(0, 1, true); // top
    area.setValue(1, 0, true); // left
    area.setValue(1, 1, true); // center
    area.setValue(1, 2, true); // right
    area.setValue(2, 1, true); // bottom

    int count = 0;
    for (uint32_t r = 0; r < 3; ++r) {
        for (uint32_t c = 0; c < 3; ++c) {
            if (area.getValue(r, c)) ++count;
        }
    }
    EXPECT_EQ(count, 5);
    // Corners should be empty
    EXPECT_FALSE(area.getValue(0, 0));
    EXPECT_FALSE(area.getValue(0, 2));
    EXPECT_FALSE(area.getValue(2, 0));
    EXPECT_FALSE(area.getValue(2, 2));
}

TEST(MatrixArea, SingleCell) {
    TestMatrixArea area(1, 1);
    area.setCenter(0, 0);
    area.setValue(0, 0, true);
    EXPECT_TRUE(area.getValue(0, 0));
    EXPECT_EQ(area.getRows(), 1u);
    EXPECT_EQ(area.getCols(), 1u);
}

TEST(MatrixArea, WideBeam) {
    // Simulates a beam area: 1 row, 7 cols
    TestMatrixArea area(1, 7);
    area.setCenter(0, 0);
    for (uint32_t c = 0; c < 7; ++c) {
        area.setValue(0, c, true);
    }
    int count = 0;
    for (uint32_t c = 0; c < 7; ++c) {
        if (area.getValue(0, c)) ++count;
    }
    EXPECT_EQ(count, 7);
}

// ---- Total damage calculation ----
TEST(DamageCalc, TotalDamageWithDualElement) {
    CombatDamage damage;
    damage.primary.type = COMBAT_PHYSICALDAMAGE;
    damage.primary.value = -150;
    damage.secondary.type = COMBAT_FIREDAMAGE;
    damage.secondary.value = -75;
    int32_t totalDamage = damage.primary.value + damage.secondary.value;
    EXPECT_EQ(totalDamage, -225);
}

TEST(DamageCalc, CritThenPvPOrdering) {
    // Simulate the doTargetCombat ordering: PvP halving first, then crit
    CombatDamage damage;
    damage.primary.value = -400;
    damage.secondary.value = 0;

    // Step 1: PvP halving
    damage.primary.value /= 2; // -200

    // Step 2: Critical hit (50% bonus)
    simulateCriticalHit(damage, ORIGIN_MELEE, 100, 50, 1);
    // -200 + round(-200 * 0.5) = -200 + -100 = -300
    EXPECT_TRUE(damage.critical);
    EXPECT_EQ(damage.primary.value, -300);
}

TEST(DamageCalc, NoDamageNoCrit) {
    CombatDamage damage;
    damage.primary.value = 0;
    damage.secondary.value = 0;
    // No damage means no crit (values are not < 0)
    simulateCriticalHit(damage, ORIGIN_MELEE, 100, 50, 1);
    EXPECT_FALSE(damage.critical);
}
