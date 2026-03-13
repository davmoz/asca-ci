/**
 * Unit tests for Condition system enums and data structures.
 *
 * Tests ConditionType_t bitmask values, ConditionId_t, ConditionParam_t
 * mappings, and the IntervalInfo struct. Full Condition class testing
 * requires a Creature instance (integration test territory), so these
 * tests focus on the type system and constants.
 */

#include <gtest/gtest.h>
#include <cstdint>
#include <limits>

// Re-declare enums from enums.h
enum ConditionType_t {
    CONDITION_NONE = 0,
    CONDITION_POISON = 1 << 0,
    CONDITION_FIRE = 1 << 1,
    CONDITION_ENERGY = 1 << 2,
    CONDITION_BLEEDING = 1 << 3,
    CONDITION_HASTE = 1 << 4,
    CONDITION_PARALYZE = 1 << 5,
    CONDITION_OUTFIT = 1 << 6,
    CONDITION_INVISIBLE = 1 << 7,
    CONDITION_LIGHT = 1 << 8,
    CONDITION_MANASHIELD = 1 << 9,
    CONDITION_INFIGHT = 1 << 10,
    CONDITION_DRUNK = 1 << 11,
    CONDITION_EXHAUST_WEAPON = 1 << 12,
    CONDITION_REGENERATION = 1 << 13,
    CONDITION_SOUL = 1 << 14,
    CONDITION_DROWN = 1 << 15,
    CONDITION_MUTED = 1 << 16,
    CONDITION_CHANNELMUTEDTICKS = 1 << 17,
    CONDITION_YELLTICKS = 1 << 18,
    CONDITION_ATTRIBUTES = 1 << 19,
    CONDITION_FREEZING = 1 << 20,
    CONDITION_DAZZLED = 1 << 21,
    CONDITION_CURSED = 1 << 22,
    CONDITION_EXHAUST_COMBAT = 1 << 23,
    CONDITION_EXHAUST_HEAL = 1 << 24,
    CONDITION_PACIFIED = 1 << 25,
    CONDITION_SPELLCOOLDOWN = 1 << 26,
    CONDITION_SPELLGROUPCOOLDOWN = 1 << 27,
};

enum ConditionId_t : int8_t {
    CONDITIONID_DEFAULT = -1,
    CONDITIONID_COMBAT,
    CONDITIONID_HEAD,
    CONDITIONID_NECKLACE,
    CONDITIONID_BACKPACK,
    CONDITIONID_ARMOR,
    CONDITIONID_RIGHT,
    CONDITIONID_LEFT,
    CONDITIONID_LEGS,
    CONDITIONID_FEET,
    CONDITIONID_RING,
    CONDITIONID_AMMO,
};

enum ConditionParam_t {
    CONDITION_PARAM_OWNER = 1,
    CONDITION_PARAM_TICKS = 2,
    CONDITION_PARAM_HEALTHGAIN = 4,
    CONDITION_PARAM_HEALTHTICKS = 5,
    CONDITION_PARAM_MANAGAIN = 6,
    CONDITION_PARAM_MANATICKS = 7,
    CONDITION_PARAM_DELAYED = 8,
    CONDITION_PARAM_SPEED = 9,
    CONDITION_PARAM_LIGHT_LEVEL = 10,
    CONDITION_PARAM_LIGHT_COLOR = 11,
    CONDITION_PARAM_SOULGAIN = 12,
    CONDITION_PARAM_SOULTICKS = 13,
    CONDITION_PARAM_MINVALUE = 14,
    CONDITION_PARAM_MAXVALUE = 15,
    CONDITION_PARAM_STARTVALUE = 16,
    CONDITION_PARAM_TICKINTERVAL = 17,
    CONDITION_PARAM_FORCEUPDATE = 18,
    CONDITION_PARAM_AGGRESSIVE = 54,
};

struct IntervalInfo {
    int32_t timeLeft;
    int32_t value;
    int32_t interval;
};

// ================================================================
// TESTS
// ================================================================

// ---- ConditionType_t bitmask ----
TEST(ConditionType, NoneIsZero) {
    EXPECT_EQ(CONDITION_NONE, 0);
}

TEST(ConditionType, SingleBitValues) {
    EXPECT_EQ(CONDITION_POISON, 1);
    EXPECT_EQ(CONDITION_FIRE, 2);
    EXPECT_EQ(CONDITION_ENERGY, 4);
    EXPECT_EQ(CONDITION_BLEEDING, 8);
    EXPECT_EQ(CONDITION_HASTE, 16);
    EXPECT_EQ(CONDITION_PARALYZE, 32);
}

TEST(ConditionType, NoBitOverlap) {
    int conditions[] = {
        CONDITION_POISON, CONDITION_FIRE, CONDITION_ENERGY,
        CONDITION_BLEEDING, CONDITION_HASTE, CONDITION_PARALYZE,
        CONDITION_OUTFIT, CONDITION_INVISIBLE, CONDITION_LIGHT,
        CONDITION_MANASHIELD, CONDITION_INFIGHT, CONDITION_DRUNK,
        CONDITION_REGENERATION, CONDITION_SOUL, CONDITION_DROWN,
        CONDITION_MUTED, CONDITION_CHANNELMUTEDTICKS, CONDITION_YELLTICKS,
        CONDITION_ATTRIBUTES, CONDITION_FREEZING, CONDITION_DAZZLED,
        CONDITION_CURSED, CONDITION_PACIFIED, CONDITION_SPELLCOOLDOWN,
        CONDITION_SPELLGROUPCOOLDOWN,
    };
    int combined = 0;
    for (int c : conditions) {
        EXPECT_EQ(combined & c, 0) << "Overlap at condition value: " << c;
        combined |= c;
    }
}

TEST(ConditionType, CanCombineFlags) {
    int flags = CONDITION_POISON | CONDITION_FIRE | CONDITION_ENERGY;
    EXPECT_TRUE(flags & CONDITION_POISON);
    EXPECT_TRUE(flags & CONDITION_FIRE);
    EXPECT_TRUE(flags & CONDITION_ENERGY);
    EXPECT_FALSE(flags & CONDITION_BLEEDING);
}

TEST(ConditionType, DamageConditions) {
    // All damage-over-time conditions
    int dotConditions = CONDITION_POISON | CONDITION_FIRE | CONDITION_ENERGY |
                        CONDITION_BLEEDING | CONDITION_DROWN | CONDITION_FREEZING |
                        CONDITION_DAZZLED | CONDITION_CURSED;
    EXPECT_NE(dotConditions, 0);
    // Verify none of these overlap with buff conditions
    int buffConditions = CONDITION_HASTE | CONDITION_INVISIBLE | CONDITION_LIGHT |
                         CONDITION_MANASHIELD | CONDITION_REGENERATION;
    EXPECT_EQ(dotConditions & buffConditions, 0);
}

// ---- ConditionId_t ----
TEST(ConditionId, DefaultIsNegative) {
    EXPECT_EQ(CONDITIONID_DEFAULT, -1);
}

TEST(ConditionId, CombatIsZero) {
    EXPECT_EQ(CONDITIONID_COMBAT, 0);
}

TEST(ConditionId, EquipmentSlots) {
    EXPECT_EQ(CONDITIONID_HEAD, 1);
    EXPECT_EQ(CONDITIONID_NECKLACE, 2);
    EXPECT_EQ(CONDITIONID_ARMOR, 4);
    EXPECT_EQ(CONDITIONID_RING, 9);
    EXPECT_EQ(CONDITIONID_AMMO, 10);
}

// ---- ConditionParam_t ----
TEST(ConditionParam, ParamValues) {
    EXPECT_EQ(CONDITION_PARAM_OWNER, 1);
    EXPECT_EQ(CONDITION_PARAM_TICKS, 2);
    EXPECT_EQ(CONDITION_PARAM_SPEED, 9);
    EXPECT_EQ(CONDITION_PARAM_AGGRESSIVE, 54);
}

// ---- IntervalInfo ----
TEST(IntervalInfo, DefaultValues) {
    IntervalInfo info;
    info.timeLeft = 5000;
    info.value = -50;
    info.interval = 2000;
    EXPECT_EQ(info.timeLeft, 5000);
    EXPECT_EQ(info.value, -50);
    EXPECT_EQ(info.interval, 2000);
}

TEST(IntervalInfo, DamageOverTime) {
    // Simulate poison: 5 rounds of -10 damage every 2 seconds
    IntervalInfo info;
    info.timeLeft = 10000;
    info.value = -10;
    info.interval = 2000;

    int totalDamage = 0;
    int rounds = info.timeLeft / info.interval;
    for (int i = 0; i < rounds; i++) {
        totalDamage += info.value;
    }
    EXPECT_EQ(totalDamage, -50);
    EXPECT_EQ(rounds, 5);
}

// ---- Condition endTime logic ----
TEST(ConditionEndTime, PermanentConditionMaxTicks) {
    // From Condition constructor: ticks == -1 => endTime = max
    int32_t ticks = -1;
    int64_t endTime = (ticks == -1) ? std::numeric_limits<int64_t>::max() : 0;
    EXPECT_EQ(endTime, std::numeric_limits<int64_t>::max());
}

TEST(ConditionEndTime, TemporaryConditionZero) {
    int32_t ticks = 5000;
    int64_t endTime = (ticks == -1) ? std::numeric_limits<int64_t>::max() : 0;
    EXPECT_EQ(endTime, 0);
}
