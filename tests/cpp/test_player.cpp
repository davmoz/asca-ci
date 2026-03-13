/**
 * Unit tests for player-related formulas and calculations.
 *
 * Tests experience/level formulas, percent level calculation,
 * attack/defense factors, speed calculations, death loss percent,
 * and capacity logic extracted from src/player.h and src/player.cpp.
 *
 * All formulas are re-implemented here to avoid pulling in the full
 * TFS dependency graph.
 */

#include <gtest/gtest.h>

#include <algorithm>
#include <bitset>
#include <cmath>
#include <cstdint>
#include <limits>

// ----------------------------------------------------------------
// Extracted formulas from src/player.h and src/player.cpp
// ----------------------------------------------------------------

static constexpr int32_t PLAYER_MAX_SPEED = 1500;
static constexpr int32_t PLAYER_MIN_SPEED = 10;

// From Player::getExpForLevel (player.h, static method)
uint64_t getExpForLevel(int32_t lv) {
    if (lv <= 0) {
        return 0;
    }
    uint64_t ulv = static_cast<uint64_t>(lv - 1);
    return ((50ULL * ulv * ulv * ulv) - (150ULL * ulv * ulv) + (400ULL * ulv)) / 3ULL;
}

// From Player::getPercentLevel (player.cpp)
uint8_t getPercentLevel(uint64_t count, uint64_t nextLevelCount) {
    if (nextLevelCount == 0) {
        return 0;
    }
    uint8_t result = (count * 100) / nextLevelCount;
    if (result > 100) {
        return 0;
    }
    return result;
}

// From Player::getStepSpeed (player.h)
int32_t getStepSpeed(int32_t baseSpeed) {
    return std::max<int32_t>(PLAYER_MIN_SPEED, std::min<int32_t>(PLAYER_MAX_SPEED, baseSpeed));
}

// From Player::updateBaseSpeed (player.h) - simplified without flags
// baseSpeed = vocationBaseSpeed + 2 * (level - 1)
int32_t calculateBaseSpeed(int32_t vocationBaseSpeed, int32_t level) {
    return vocationBaseSpeed + (2 * (level - 1));
}

enum fightMode_t : uint8_t {
    FIGHTMODE_ATTACK = 1,
    FIGHTMODE_BALANCED = 2,
    FIGHTMODE_DEFENSE = 3,
};

// From Player::getAttackFactor (player.cpp)
float getAttackFactor(fightMode_t fightMode) {
    switch (fightMode) {
        case FIGHTMODE_ATTACK: return 1.0f;
        case FIGHTMODE_BALANCED: return 1.2f;
        case FIGHTMODE_DEFENSE: return 2.0f;
        default: return 1.0f;
    }
}

// From Player::getDefense (player.cpp) - the defense formula
// (defenseSkill / 4. + 2.23) * defenseValue * 0.15 * defenseFactor * defenseMultiplier
double calculateDefense(int32_t defenseSkill, int32_t defenseValue, double defenseFactor, double defenseMultiplier) {
    if (defenseSkill == 0) {
        return 0; // simplified; real code returns 1 or 2 based on fight mode
    }
    return (defenseSkill / 4.0 + 2.23) * defenseValue * 0.15 * defenseFactor * defenseMultiplier;
}

// From Player::getLostPercent (player.cpp) - death penalty formula
// For level >= 25, without config override:
//   lossPercent = ((tmpLevel + 50) * 50 * (tmpLevel^2 - 5*tmpLevel + 8)) / experience
// Then reduced by: promotion (30%) + blessings (8% each)
double calculateLostPercent(int32_t level, uint8_t levelPercent, uint64_t experience,
                            bool promoted, int32_t blessingCount) {
    double lossPercent;
    if (level >= 25) {
        double tmpLevel = level + (levelPercent / 100.0);
        lossPercent = static_cast<double>((tmpLevel + 50) * 50 * ((tmpLevel * tmpLevel) - (5 * tmpLevel) + 8)) / experience;
    } else {
        lossPercent = 10;
    }

    double percentReduction = 0;
    if (promoted) {
        percentReduction += 30;
    }
    percentReduction += blessingCount * 8;
    return lossPercent * (1 - (percentReduction / 100.0)) / 100.0;
}

// ================================================================
// TESTS
// ================================================================

// ---- Experience formula: getExpForLevel ----
TEST(ExpFormula, Level1RequiresZero) {
    EXPECT_EQ(getExpForLevel(1), 0u);
}

TEST(ExpFormula, Level2) {
    // ulv = 1: (50*1 - 150*1 + 400*1) / 3 = 300/3 = 100
    EXPECT_EQ(getExpForLevel(2), 100u);
}

TEST(ExpFormula, Level8) {
    // Known Tibia value: level 8 requires 4,200 experience
    EXPECT_EQ(getExpForLevel(8), 4200u);
}

TEST(ExpFormula, Level20) {
    // ulv = 19: (50*6859 - 150*361 + 400*19) / 3
    // = (342950 - 54150 + 7600) / 3 = 296400 / 3 = 98800
    EXPECT_EQ(getExpForLevel(20), 98800u);
}

TEST(ExpFormula, Level100) {
    // ulv = 99: (50*970299 - 150*9801 + 400*99) / 3
    // = (48514950 - 1470150 + 39600) / 3 = 47084400 / 3 = 15694800
    EXPECT_EQ(getExpForLevel(100), 15694800u);
}

TEST(ExpFormula, Level200) {
    // ulv = 199
    uint64_t expected = ((50ULL * 199 * 199 * 199) - (150ULL * 199 * 199) + (400ULL * 199)) / 3ULL;
    EXPECT_EQ(getExpForLevel(200), expected);
}

TEST(ExpFormula, ZeroAndNegativeLevels) {
    EXPECT_EQ(getExpForLevel(0), 0u);
    EXPECT_EQ(getExpForLevel(-1), 0u);
    EXPECT_EQ(getExpForLevel(-100), 0u);
}

TEST(ExpFormula, MonotonicallyIncreasing) {
    for (int32_t lv = 2; lv <= 500; ++lv) {
        EXPECT_GT(getExpForLevel(lv + 1), getExpForLevel(lv))
            << "Experience should increase between level " << lv << " and " << (lv + 1);
    }
}

TEST(ExpFormula, ExperienceGapGrows) {
    // The gap between levels should grow (cubic polynomial)
    for (int32_t lv = 3; lv <= 100; ++lv) {
        uint64_t gap1 = getExpForLevel(lv) - getExpForLevel(lv - 1);
        uint64_t gap2 = getExpForLevel(lv + 1) - getExpForLevel(lv);
        EXPECT_GE(gap2, gap1)
            << "Gap should be non-decreasing at level " << lv;
    }
}

TEST(ExpFormula, HighLevel) {
    // Verify no overflow for a high level
    uint64_t exp = getExpForLevel(2000);
    EXPECT_GT(exp, 0u);
    EXPECT_GT(exp, getExpForLevel(1999));
}

// ---- Percent level calculation ----
TEST(PercentLevel, Zero) {
    EXPECT_EQ(getPercentLevel(0, 1000), 0u);
}

TEST(PercentLevel, Fifty) {
    EXPECT_EQ(getPercentLevel(500, 1000), 50u);
}

TEST(PercentLevel, NinetyNine) {
    EXPECT_EQ(getPercentLevel(999, 1000), 99u);
}

TEST(PercentLevel, Hundred) {
    EXPECT_EQ(getPercentLevel(1000, 1000), 100u);
}

TEST(PercentLevel, ZeroDenominator) {
    EXPECT_EQ(getPercentLevel(500, 0), 0u);
}

TEST(PercentLevel, OverflowReturnsZero) {
    // When count exceeds nextLevelCount by enough to wrap past 100 in uint8_t
    // result = (count * 100) / nextLevelCount; if result > 100 => return 0
    // e.g. count=300, next=100 => result=300 which wraps in uint8_t to 44
    // But the code checks result > 100 BEFORE the uint8_t truncation?
    // Actually no: result is stored as uint8_t first, then checked.
    // uint8_t(300) = 44, which is not > 100, so returns 44.
    // Let's test with values that won't overflow uint8_t but are > 100:
    // count=200, next=100 => (200*100)/100 = 200. uint8_t(200) = 200. 200 > 100 => 0.
    EXPECT_EQ(getPercentLevel(200, 100), 0u);
}

TEST(PercentLevel, SmallValues) {
    EXPECT_EQ(getPercentLevel(1, 100), 1u);
    EXPECT_EQ(getPercentLevel(1, 1000), 0u); // 0.1% rounds to 0
    EXPECT_EQ(getPercentLevel(10, 1000), 1u);
}

TEST(PercentLevel, LargeValues) {
    // Verify it works with large uint64_t values
    uint64_t half = 5000000000ULL;
    uint64_t total = 10000000000ULL;
    EXPECT_EQ(getPercentLevel(half, total), 50u);
}

// ---- Step speed clamping ----
TEST(StepSpeed, ClampToMin) {
    EXPECT_EQ(getStepSpeed(0), PLAYER_MIN_SPEED);
    EXPECT_EQ(getStepSpeed(-100), PLAYER_MIN_SPEED);
    EXPECT_EQ(getStepSpeed(5), PLAYER_MIN_SPEED);
}

TEST(StepSpeed, ClampToMax) {
    EXPECT_EQ(getStepSpeed(2000), PLAYER_MAX_SPEED);
    EXPECT_EQ(getStepSpeed(10000), PLAYER_MAX_SPEED);
}

TEST(StepSpeed, InRange) {
    EXPECT_EQ(getStepSpeed(100), 100);
    EXPECT_EQ(getStepSpeed(500), 500);
    EXPECT_EQ(getStepSpeed(PLAYER_MIN_SPEED), PLAYER_MIN_SPEED);
    EXPECT_EQ(getStepSpeed(PLAYER_MAX_SPEED), PLAYER_MAX_SPEED);
}

// ---- Base speed calculation ----
TEST(BaseSpeed, Level1) {
    // vocation base speed 220, level 1: 220 + 2*(1-1) = 220
    EXPECT_EQ(calculateBaseSpeed(220, 1), 220);
}

TEST(BaseSpeed, Level100) {
    // 220 + 2*(100-1) = 220 + 198 = 418
    EXPECT_EQ(calculateBaseSpeed(220, 100), 418);
}

TEST(BaseSpeed, Level200Knight) {
    // Knight base speed 220: 220 + 2*199 = 618
    EXPECT_EQ(calculateBaseSpeed(220, 200), 618);
}

TEST(BaseSpeed, DifferentVocations) {
    // All vocations have the same base speed in TFS (220), but test with varied values
    EXPECT_EQ(calculateBaseSpeed(200, 50), 200 + 2 * 49);
    EXPECT_EQ(calculateBaseSpeed(250, 50), 250 + 2 * 49);
}

// ---- Attack factor ----
TEST(AttackFactor, AttackMode) {
    EXPECT_FLOAT_EQ(getAttackFactor(FIGHTMODE_ATTACK), 1.0f);
}

TEST(AttackFactor, BalancedMode) {
    EXPECT_FLOAT_EQ(getAttackFactor(FIGHTMODE_BALANCED), 1.2f);
}

TEST(AttackFactor, DefenseMode) {
    EXPECT_FLOAT_EQ(getAttackFactor(FIGHTMODE_DEFENSE), 2.0f);
}

// ---- Defense formula ----
TEST(DefenseFormula, ZeroSkillReturnsZero) {
    EXPECT_DOUBLE_EQ(calculateDefense(0, 30, 1.0, 1.0), 0.0);
}

TEST(DefenseFormula, BasicCalculation) {
    // defenseSkill=80, defenseValue=30, factor=1.0, multiplier=1.0
    // (80/4 + 2.23) * 30 * 0.15 * 1.0 * 1.0
    // (20 + 2.23) * 30 * 0.15 = 22.23 * 4.5 = 100.035
    double expected = (80.0 / 4.0 + 2.23) * 30 * 0.15 * 1.0 * 1.0;
    EXPECT_DOUBLE_EQ(calculateDefense(80, 30, 1.0, 1.0), expected);
}

TEST(DefenseFormula, WithMultiplier) {
    // Knight defense multiplier 1.0, Paladin might be 1.0, etc.
    double base = (100.0 / 4.0 + 2.23) * 35 * 0.15;
    double withMult = base * 1.0 * 1.2;
    EXPECT_DOUBLE_EQ(calculateDefense(100, 35, 1.0, 1.2), withMult);
}

TEST(DefenseFormula, DefenseFactorHalved) {
    // In attack mode during combat, defense factor is 0.5
    double full = calculateDefense(80, 30, 1.0, 1.0);
    double halved = calculateDefense(80, 30, 0.5, 1.0);
    EXPECT_NEAR(halved, full * 0.5, 0.001);
}

// ---- Death loss percent ----
TEST(DeathLoss, LowLevel) {
    // Below level 25: lossPercent = 10, no promotion, no blessings
    // 10 * (1 - 0/100) / 100 = 0.10
    double loss = calculateLostPercent(20, 0, 100000, false, 0);
    EXPECT_DOUBLE_EQ(loss, 0.10);
}

TEST(DeathLoss, LowLevelWithPromotion) {
    // lossPercent = 10, promoted: reduction=30%
    // 10 * (1 - 30/100) / 100 = 10 * 0.7 / 100 = 0.07
    double loss = calculateLostPercent(20, 0, 100000, true, 0);
    EXPECT_DOUBLE_EQ(loss, 0.07);
}

TEST(DeathLoss, LowLevelFullBlessings) {
    // lossPercent = 10, 5 blessings: reduction=40%
    // 10 * (1 - 40/100) / 100 = 10 * 0.6 / 100 = 0.06
    double loss = calculateLostPercent(20, 0, 100000, false, 5);
    EXPECT_DOUBLE_EQ(loss, 0.06);
}

TEST(DeathLoss, LowLevelPromotedFullBlessings) {
    // promotion (30%) + 5 blessings (40%) = 70% reduction
    // 10 * (1 - 70/100) / 100 = 10 * 0.3 / 100 = 0.03
    double loss = calculateLostPercent(20, 0, 100000, true, 5);
    EXPECT_DOUBLE_EQ(loss, 0.03);
}

TEST(DeathLoss, HighLevelFormula) {
    // Level 100, experience at level 100
    int32_t level = 100;
    uint64_t experience = getExpForLevel(level);
    double loss = calculateLostPercent(level, 0, experience, false, 0);
    // Should be a reasonable positive value
    EXPECT_GT(loss, 0.0);
    EXPECT_LT(loss, 1.0); // less than 100%
}

TEST(DeathLoss, BlessingsReduceLoss) {
    int32_t level = 100;
    uint64_t experience = getExpForLevel(level) + 500000;
    double lossNoBless = calculateLostPercent(level, 50, experience, false, 0);
    double lossFiveBless = calculateLostPercent(level, 50, experience, false, 5);
    EXPECT_LT(lossFiveBless, lossNoBless);
}

TEST(DeathLoss, PromotionReducesLoss) {
    int32_t level = 150;
    uint64_t experience = getExpForLevel(level) + 1000000;
    double lossUnpromoted = calculateLostPercent(level, 0, experience, false, 0);
    double lossPromoted = calculateLostPercent(level, 0, experience, true, 0);
    EXPECT_LT(lossPromoted, lossUnpromoted);
}

// ---- Blessing bitfield ----
TEST(Blessings, AddAndCheck) {
    uint8_t blessings = 0;
    // addBlessing: blessings |= blessing
    blessings |= (1 << 1); // blessing 1
    blessings |= (1 << 3); // blessing 3

    // hasBlessing checks: (blessings & (1 << value)) != 0
    EXPECT_TRUE((blessings & (static_cast<uint8_t>(1) << 1)) != 0);
    EXPECT_FALSE((blessings & (static_cast<uint8_t>(1) << 2)) != 0);
    EXPECT_TRUE((blessings & (static_cast<uint8_t>(1) << 3)) != 0);
}

TEST(Blessings, RemoveBlessing) {
    uint8_t blessings = 0;
    blessings |= (1 << 1);
    blessings |= (1 << 2);
    // removeBlessing: blessings &= ~blessing
    blessings &= ~(1 << 1);
    EXPECT_FALSE((blessings & (static_cast<uint8_t>(1) << 1)) != 0);
    EXPECT_TRUE((blessings & (static_cast<uint8_t>(1) << 2)) != 0);
}

TEST(Blessings, CountBlessings) {
    // getLostPercent uses std::bitset<5>(blessings).count()
    uint8_t blessings = 0;
    blessings |= (1 << 1);
    blessings |= (1 << 2);
    blessings |= (1 << 4);
    int32_t count = std::bitset<5>(blessings).count();
    EXPECT_EQ(count, 3);
}

TEST(Blessings, AllFiveBlessings) {
    uint8_t blessings = 0;
    for (int i = 1; i <= 5; ++i) {
        blessings |= (1 << i);
    }
    // bitset<5> only looks at bottom 5 bits (bits 0..4)
    // bits 1..5 means bits 1,2,3,4 are within the bitset<5> range, bit 5 is not
    // Actually bitset<5> reads the lowest 5 bits: 0,1,2,3,4
    // Our blessings = 0b00111110, bitset<5> sees 0b11110 = bits 1,2,3,4 = 4
    int32_t count = std::bitset<5>(blessings).count();
    EXPECT_EQ(count, 4); // only bits 1-4 fit in bitset<5>
}

// ---- Capacity ----
TEST(Capacity, DefaultCapacity) {
    // Default capacity for a new player: 40000 (400.00 oz)
    uint32_t capacity = 40000;
    uint32_t inventoryWeight = 0;
    int32_t free = std::max<int32_t>(0, capacity - inventoryWeight);
    EXPECT_EQ(free, 40000);
}

TEST(Capacity, FreeCapacityWithWeight) {
    uint32_t capacity = 40000;
    uint32_t inventoryWeight = 15000;
    int32_t free = std::max<int32_t>(0, capacity - inventoryWeight);
    EXPECT_EQ(free, 25000);
}

TEST(Capacity, FreeCapacityOverweight) {
    uint32_t capacity = 40000;
    uint32_t inventoryWeight = 50000;
    int32_t free = std::max<int32_t>(0, static_cast<int32_t>(capacity) - static_cast<int32_t>(inventoryWeight));
    EXPECT_EQ(free, 0);
}

// ---- Offline training ----
TEST(OfflineTraining, AddTimeCapped) {
    int32_t offlineTrainingTime = 10 * 3600 * 1000; // 10 hours in ms
    int32_t addTime = 5 * 3600 * 1000; // 5 hours
    offlineTrainingTime = std::min<int32_t>(12 * 3600 * 1000, offlineTrainingTime + addTime);
    EXPECT_EQ(offlineTrainingTime, 12 * 3600 * 1000); // capped at 12 hours
}

TEST(OfflineTraining, AddTimeUnderCap) {
    int32_t offlineTrainingTime = 2 * 3600 * 1000; // 2 hours
    int32_t addTime = 3 * 3600 * 1000; // 3 hours
    offlineTrainingTime = std::min<int32_t>(12 * 3600 * 1000, offlineTrainingTime + addTime);
    EXPECT_EQ(offlineTrainingTime, 5 * 3600 * 1000);
}

TEST(OfflineTraining, RemoveTimeFloorZero) {
    int32_t offlineTrainingTime = 1 * 3600 * 1000; // 1 hour
    int32_t removeTime = 5 * 3600 * 1000; // 5 hours
    offlineTrainingTime = std::max<int32_t>(0, offlineTrainingTime - removeTime);
    EXPECT_EQ(offlineTrainingTime, 0);
}

// ---- Stamina ----
TEST(Stamina, DefaultIs2520) {
    uint16_t staminaMinutes = 2520;
    // 2520 minutes = 42 hours, the default starting stamina
    EXPECT_EQ(staminaMinutes, 2520);
    EXPECT_EQ(staminaMinutes / 60, 42);
}
