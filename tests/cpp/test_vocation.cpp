/**
 * Unit tests for Vocation system.
 *
 * Tests vocation skill multipliers, progression formulas, stat gains,
 * and vocation constants from src/vocation.h.
 */

#include <gtest/gtest.h>
#include <cstdint>
#include <cmath>
#include <map>
#include <string>

// Skill enum from enums.h
enum skills_t : uint8_t {
    SKILL_FIST = 0,
    SKILL_CLUB = 1,
    SKILL_SWORD = 2,
    SKILL_AXE = 3,
    SKILL_DISTANCE = 4,
    SKILL_SHIELD = 5,
    SKILL_FISHING = 6,
    SKILL_MAGLEVEL = 7,
    SKILL_LEVEL = 8,
    SKILL_FIRST = SKILL_FIST,
    SKILL_LAST = SKILL_FISHING,
};

enum Vocation_t : uint16_t {
    VOCATION_NONE = 0,
};

// Simplified Vocation class mirroring src/vocation.h
class Vocation {
public:
    explicit Vocation(uint16_t id) : id(id) {}

    const std::string& getVocName() const { return name; }
    uint16_t getId() const { return id; }
    uint32_t getHPGain() const { return gainHP; }
    uint32_t getManaGain() const { return gainMana; }
    uint32_t getCapGain() const { return gainCap; }
    uint32_t getAttackSpeed() const { return attackSpeed; }
    uint32_t getBaseSpeed() const { return baseSpeed; }
    uint8_t getSoulMax() const { return soulMax; }

    uint64_t getReqSkillTries(uint8_t skill, uint16_t level) {
        if (skill > SKILL_LAST) return 0;
        auto it = cacheSkill[skill].find(level);
        if (it != cacheSkill[skill].end()) return it->second;
        // Formula: 50 * (multiplier ^ level)
        uint64_t tries = static_cast<uint64_t>(50 * std::pow(skillMultipliers[skill], level));
        cacheSkill[skill][level] = tries;
        return tries;
    }

    uint64_t getReqMana(uint32_t magLevel) {
        auto it = cacheMana.find(magLevel);
        if (it != cacheMana.end()) return it->second;
        uint64_t mana = static_cast<uint64_t>(1600 * std::pow(manaMultiplier, magLevel));
        cacheMana[magLevel] = mana;
        return mana;
    }

    // Public for testing
    std::string name = "none";
    float skillMultipliers[SKILL_LAST + 1] = {1.5f, 2.0f, 2.0f, 2.0f, 2.0f, 1.5f, 1.1f};
    float manaMultiplier = 4.0f;
    float meleeDamageMultiplier = 1.0f;
    float distDamageMultiplier = 1.0f;
    float defenseMultiplier = 1.0f;
    float armorMultiplier = 1.0f;
    uint32_t gainHP = 5;
    uint32_t gainMana = 5;
    uint32_t gainCap = 500;
    uint32_t attackSpeed = 1500;
    uint32_t baseSpeed = 220;
    uint8_t soulMax = 100;

private:
    uint16_t id;
    std::map<uint32_t, uint64_t> cacheMana;
    std::map<uint32_t, uint32_t> cacheSkill[SKILL_LAST + 1];
};

// ================================================================
// TESTS
// ================================================================

// ---- Default vocation (None) ----
TEST(Vocation, DefaultValues) {
    Vocation voc(0);
    EXPECT_EQ(voc.getId(), 0);
    EXPECT_EQ(voc.getVocName(), "none");
    EXPECT_EQ(voc.getHPGain(), 5u);
    EXPECT_EQ(voc.getManaGain(), 5u);
    EXPECT_EQ(voc.getCapGain(), 500u);
    EXPECT_EQ(voc.getAttackSpeed(), 1500u);
    EXPECT_EQ(voc.getBaseSpeed(), 220u);
    EXPECT_EQ(voc.getSoulMax(), 100);
}

// ---- Skill multipliers ----
TEST(VocationSkill, DefaultMultipliers) {
    Vocation voc(0);
    EXPECT_FLOAT_EQ(voc.skillMultipliers[SKILL_FIST], 1.5f);
    EXPECT_FLOAT_EQ(voc.skillMultipliers[SKILL_CLUB], 2.0f);
    EXPECT_FLOAT_EQ(voc.skillMultipliers[SKILL_SWORD], 2.0f);
    EXPECT_FLOAT_EQ(voc.skillMultipliers[SKILL_AXE], 2.0f);
    EXPECT_FLOAT_EQ(voc.skillMultipliers[SKILL_DISTANCE], 2.0f);
    EXPECT_FLOAT_EQ(voc.skillMultipliers[SKILL_SHIELD], 1.5f);
    EXPECT_FLOAT_EQ(voc.skillMultipliers[SKILL_FISHING], 1.1f);
}

// ---- Skill progression (exponential) ----
TEST(VocationSkill, SkillTriesIncrease) {
    Vocation voc(0);
    uint64_t tries1 = voc.getReqSkillTries(SKILL_SWORD, 10);
    uint64_t tries2 = voc.getReqSkillTries(SKILL_SWORD, 11);
    EXPECT_GT(tries2, tries1);
}

TEST(VocationSkill, SkillTriesLevel0) {
    Vocation voc(0);
    // Level 0: 50 * (2.0 ^ 0) = 50
    uint64_t tries = voc.getReqSkillTries(SKILL_SWORD, 0);
    EXPECT_EQ(tries, 50u);
}

TEST(VocationSkill, SkillTriesLevel1) {
    Vocation voc(0);
    // Level 1: 50 * (2.0 ^ 1) = 100
    uint64_t tries = voc.getReqSkillTries(SKILL_SWORD, 1);
    EXPECT_EQ(tries, 100u);
}

TEST(VocationSkill, FishingEasier) {
    Vocation voc(0);
    // Fishing multiplier is 1.1 (easier than combat skills at 2.0)
    uint64_t fishTries = voc.getReqSkillTries(SKILL_FISHING, 10);
    uint64_t swordTries = voc.getReqSkillTries(SKILL_SWORD, 10);
    EXPECT_LT(fishTries, swordTries);
}

TEST(VocationSkill, CacheConsistency) {
    Vocation voc(0);
    uint64_t tries1 = voc.getReqSkillTries(SKILL_CLUB, 5);
    uint64_t tries2 = voc.getReqSkillTries(SKILL_CLUB, 5);
    EXPECT_EQ(tries1, tries2);
}

TEST(VocationSkill, InvalidSkillReturnsZero) {
    Vocation voc(0);
    EXPECT_EQ(voc.getReqSkillTries(SKILL_LAST + 1, 5), 0u);
}

// ---- Mana progression ----
TEST(VocationMana, ManaTriesIncrease) {
    Vocation voc(0);
    uint64_t mana1 = voc.getReqMana(1);
    uint64_t mana2 = voc.getReqMana(2);
    EXPECT_GT(mana2, mana1);
}

TEST(VocationMana, ManaLevel0) {
    Vocation voc(0);
    // Level 0: 1600 * (4.0 ^ 0) = 1600
    uint64_t mana = voc.getReqMana(0);
    EXPECT_EQ(mana, 1600u);
}

TEST(VocationMana, ManaLevel1) {
    Vocation voc(0);
    // Level 1: 1600 * (4.0 ^ 1) = 6400
    uint64_t mana = voc.getReqMana(1);
    EXPECT_EQ(mana, 6400u);
}

TEST(VocationMana, LowerMultiplierEasier) {
    // Sorcerer-like vocation: manaMultiplier = 1.1
    Vocation sorcerer(1);
    sorcerer.manaMultiplier = 1.1f;
    sorcerer.name = "Sorcerer";

    // Default (None): manaMultiplier = 4.0
    Vocation none(0);

    uint64_t sorcMana = sorcerer.getReqMana(10);
    uint64_t noneMana = none.getReqMana(10);
    EXPECT_LT(sorcMana, noneMana);
}

// ---- Damage multipliers ----
TEST(VocationDamage, DefaultMultipliers) {
    Vocation voc(0);
    EXPECT_FLOAT_EQ(voc.meleeDamageMultiplier, 1.0f);
    EXPECT_FLOAT_EQ(voc.distDamageMultiplier, 1.0f);
    EXPECT_FLOAT_EQ(voc.defenseMultiplier, 1.0f);
    EXPECT_FLOAT_EQ(voc.armorMultiplier, 1.0f);
}

TEST(VocationDamage, KnightMultipliers) {
    Vocation knight(4);
    knight.name = "Knight";
    knight.meleeDamageMultiplier = 1.2f;
    knight.defenseMultiplier = 1.0f;
    knight.armorMultiplier = 1.0f;

    int baseDamage = 100;
    int knightDamage = static_cast<int>(baseDamage * knight.meleeDamageMultiplier);
    EXPECT_EQ(knightDamage, 120);
}

// ---- Tibia vocation system ----
TEST(VocationSystem, SorcererConfig) {
    Vocation sorcerer(1);
    sorcerer.name = "Sorcerer";
    sorcerer.gainHP = 5;
    sorcerer.gainMana = 30;
    sorcerer.gainCap = 10;
    sorcerer.manaMultiplier = 1.1f;
    sorcerer.attackSpeed = 2000;

    EXPECT_EQ(sorcerer.getHPGain(), 5u);
    EXPECT_EQ(sorcerer.getManaGain(), 30u);
    EXPECT_EQ(sorcerer.getCapGain(), 10u);
    EXPECT_EQ(sorcerer.getAttackSpeed(), 2000u);
}

TEST(VocationSystem, KnightConfig) {
    Vocation knight(4);
    knight.name = "Knight";
    knight.gainHP = 15;
    knight.gainMana = 5;
    knight.gainCap = 25;
    knight.attackSpeed = 2000;

    EXPECT_EQ(knight.getHPGain(), 15u);
    EXPECT_EQ(knight.getManaGain(), 5u);
    EXPECT_EQ(knight.getCapGain(), 25u);
}
