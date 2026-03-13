/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2019  Mark Samman <mark.samman@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef FS_TOOLS_H_5F9A9742DA194628830AA1C64909AE43
#define FS_TOOLS_H_5F9A9742DA194628830AA1C64909AE43

#include <random>

#include "position.h"
#include "const.h"
#include "enums.h"

void printXMLError(std::string_view where, const std::string& fileName, const pugi::xml_parse_result& result);

[[nodiscard]] std::string transformToSHA1(std::string_view input);
[[nodiscard]] std::string generateToken(std::string_view key, uint32_t ticks);

void replaceString(std::string& str, std::string_view sought, const std::string& replacement);
void trim_right(std::string& source, char t);
void trim_left(std::string& source, char t);
void toLowerCaseString(std::string& source);
[[nodiscard]] std::string asLowerCaseString(std::string source);
[[nodiscard]] std::string asUpperCaseString(std::string source);

using StringVector = std::vector<std::string>;
using IntegerVector = std::vector<int32_t>;

[[nodiscard]] StringVector explodeString(std::string_view inString, std::string_view separator, int32_t limit = -1);
[[nodiscard]] IntegerVector vectorAtoi(const StringVector& stringVector);
constexpr bool hasBitSet(uint32_t flag, uint32_t flags) {
	return (flags & flag) != 0;
}

std::mt19937& getRandomGenerator();
int32_t uniform_random(int32_t minNumber, int32_t maxNumber);
int32_t normal_random(int32_t minNumber, int32_t maxNumber);
bool boolean_random(double probability = 0.5);

Direction getDirection(std::string_view string);
Position getNextPosition(Direction direction, Position pos);
Direction getDirectionTo(const Position& from, const Position& to);

[[nodiscard]] std::string getFirstLine(std::string_view str);

[[nodiscard]] std::string formatDate(time_t time);
[[nodiscard]] std::string formatDateShort(time_t time);
std::string convertIPToString(uint32_t ip);

void trimString(std::string& str);

MagicEffectClasses getMagicEffect(const std::string& strValue);
ShootType_t getShootType(const std::string& strValue);
Ammo_t getAmmoType(const std::string& strValue);
WeaponAction_t getWeaponAction(const std::string& strValue);
Skulls_t getSkullType(const std::string& strValue);
std::string getCombatName(CombatType_t combatType);

std::string getSpecialSkillName(uint8_t skillid);
std::string getSkillName(uint8_t skillid);

uint32_t adlerChecksum(const uint8_t* data, size_t length);

std::string ucfirst(std::string str);
std::string ucwords(std::string str);
bool booleanString(std::string_view str);

std::string getWeaponName(WeaponType_t weaponType);

size_t combatTypeToIndex(CombatType_t combatType);
CombatType_t indexToCombatType(size_t v);

uint8_t serverFluidToClient(uint8_t serverFluid);
uint8_t clientFluidToServer(uint8_t clientFluid);

itemAttrTypes stringToItemAttribute(std::string_view str);

const char* getReturnMessage(ReturnValue value);

int64_t OTSYS_TIME();

SpellGroup_t stringToSpellGroup(std::string_view value);

#endif
