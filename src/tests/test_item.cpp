/**
 * Boost.Test unit tests for the item attribute system.
 *
 * Tests ItemAttributes storage (int/string attributes), attribute bitmask
 * operations, weight calculation, stackable item logic, and the
 * stringToItemAttribute mapping. Functions are re-implemented here to
 * avoid pulling in the full TFS dependency graph.
 */

#define BOOST_TEST_MODULE item
#include <boost/test/unit_test.hpp>

#include <cstdint>
#include <map>
#include <string>
#include <vector>

// ----------------------------------------------------------------
// Re-implemented item attribute types from enums.h
// ----------------------------------------------------------------

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

// ----------------------------------------------------------------
// Minimal ItemAttributes re-implementation (mirrors src/item.h)
// ----------------------------------------------------------------

class ItemAttributes {
public:
	void setIntAttr(itemAttrTypes type, int64_t value) {
		intAttrs[type] = value;
		attributeBits |= type;
	}

	int64_t getIntAttr(itemAttrTypes type) const {
		auto it = intAttrs.find(type);
		if (it != intAttrs.end()) {
			return it->second;
		}
		return 0;
	}

	void setStrAttr(itemAttrTypes type, const std::string& value) {
		strAttrs[type] = value;
		attributeBits |= type;
	}

	const std::string& getStrAttr(itemAttrTypes type) const {
		auto it = strAttrs.find(type);
		if (it != strAttrs.end()) {
			return it->second;
		}
		static const std::string empty;
		return empty;
	}

	bool hasAttribute(itemAttrTypes type) const {
		return (attributeBits & type) != 0;
	}

	void removeAttribute(itemAttrTypes type) {
		attributeBits &= ~type;
		intAttrs.erase(type);
		strAttrs.erase(type);
	}

	void setActionId(uint16_t n) { setIntAttr(ITEM_ATTRIBUTE_ACTIONID, n); }
	uint16_t getActionId() const { return static_cast<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ACTIONID)); }

	void setUniqueId(uint16_t n) { setIntAttr(ITEM_ATTRIBUTE_UNIQUEID, n); }
	uint16_t getUniqueId() const { return static_cast<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_UNIQUEID)); }

	void setCharges(uint16_t n) { setIntAttr(ITEM_ATTRIBUTE_CHARGES, n); }
	uint16_t getCharges() const { return static_cast<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_CHARGES)); }

	void setDuration(int32_t time) { setIntAttr(ITEM_ATTRIBUTE_DURATION, time); }
	uint32_t getDuration() const { return static_cast<uint32_t>(getIntAttr(ITEM_ATTRIBUTE_DURATION)); }

	void setSpecialDescription(const std::string& desc) { setStrAttr(ITEM_ATTRIBUTE_DESCRIPTION, desc); }
	const std::string& getSpecialDescription() const { return getStrAttr(ITEM_ATTRIBUTE_DESCRIPTION); }

	void setText(const std::string& text) { setStrAttr(ITEM_ATTRIBUTE_TEXT, text); }
	const std::string& getText() const { return getStrAttr(ITEM_ATTRIBUTE_TEXT); }

	void setWriter(const std::string& writer) { setStrAttr(ITEM_ATTRIBUTE_WRITER, writer); }
	const std::string& getWriter() const { return getStrAttr(ITEM_ATTRIBUTE_WRITER); }

private:
	uint32_t attributeBits = 0;
	std::map<itemAttrTypes, int64_t> intAttrs;
	std::map<itemAttrTypes, std::string> strAttrs;
};

// ----------------------------------------------------------------
// stringToItemAttribute from tools.cpp
// ----------------------------------------------------------------

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

// ----------------------------------------------------------------
// Weight calculation logic (mirrors Item::getWeight)
// ----------------------------------------------------------------

uint32_t calculateWeight(uint32_t baseWeight, bool stackable, uint16_t count) {
	if (stackable) {
		return baseWeight * std::max<uint16_t>(1, count);
	}
	return baseWeight;
}

// ================================================================
//  TESTS: Attribute int get/set
// ================================================================

BOOST_AUTO_TEST_CASE(test_int_attr_default_zero)
{
	ItemAttributes attrs;
	BOOST_TEST(attrs.getActionId() == 0);
	BOOST_TEST(attrs.getUniqueId() == 0);
	BOOST_TEST(attrs.getCharges() == 0);
	BOOST_TEST(attrs.getDuration() == 0u);
}

BOOST_AUTO_TEST_CASE(test_set_action_id)
{
	ItemAttributes attrs;
	attrs.setActionId(1234);
	BOOST_TEST(attrs.getActionId() == 1234);
}

BOOST_AUTO_TEST_CASE(test_set_unique_id)
{
	ItemAttributes attrs;
	attrs.setUniqueId(5678);
	BOOST_TEST(attrs.getUniqueId() == 5678);
}

BOOST_AUTO_TEST_CASE(test_set_charges)
{
	ItemAttributes attrs;
	attrs.setCharges(100);
	BOOST_TEST(attrs.getCharges() == 100);
}

BOOST_AUTO_TEST_CASE(test_set_duration)
{
	ItemAttributes attrs;
	attrs.setDuration(300000);
	BOOST_TEST(attrs.getDuration() == 300000u);
}

BOOST_AUTO_TEST_CASE(test_overwrite_int_attr)
{
	ItemAttributes attrs;
	attrs.setActionId(100);
	attrs.setActionId(200);
	BOOST_TEST(attrs.getActionId() == 200);
}

BOOST_AUTO_TEST_CASE(test_multiple_int_attrs_independent)
{
	ItemAttributes attrs;
	attrs.setActionId(111);
	attrs.setUniqueId(222);
	attrs.setCharges(333);
	BOOST_TEST(attrs.getActionId() == 111);
	BOOST_TEST(attrs.getUniqueId() == 222);
	BOOST_TEST(attrs.getCharges() == 333);
}

// ================================================================
//  TESTS: Attribute string get/set
// ================================================================

BOOST_AUTO_TEST_CASE(test_str_attr_default_empty)
{
	ItemAttributes attrs;
	BOOST_TEST(attrs.getSpecialDescription().empty());
	BOOST_TEST(attrs.getText().empty());
	BOOST_TEST(attrs.getWriter().empty());
}

BOOST_AUTO_TEST_CASE(test_set_special_description)
{
	ItemAttributes attrs;
	attrs.setSpecialDescription("A magical sword");
	BOOST_TEST(attrs.getSpecialDescription() == "A magical sword");
}

BOOST_AUTO_TEST_CASE(test_set_text)
{
	ItemAttributes attrs;
	attrs.setText("You see a scroll of fire.");
	BOOST_TEST(attrs.getText() == "You see a scroll of fire.");
}

BOOST_AUTO_TEST_CASE(test_set_writer)
{
	ItemAttributes attrs;
	attrs.setWriter("Ferumbras");
	BOOST_TEST(attrs.getWriter() == "Ferumbras");
}

BOOST_AUTO_TEST_CASE(test_overwrite_str_attr)
{
	ItemAttributes attrs;
	attrs.setText("old text");
	attrs.setText("new text");
	BOOST_TEST(attrs.getText() == "new text");
}

// ================================================================
//  TESTS: hasAttribute / removeAttribute
// ================================================================

BOOST_AUTO_TEST_CASE(test_has_attribute_false_initially)
{
	ItemAttributes attrs;
	BOOST_TEST(!attrs.hasAttribute(ITEM_ATTRIBUTE_ACTIONID));
	BOOST_TEST(!attrs.hasAttribute(ITEM_ATTRIBUTE_TEXT));
}

BOOST_AUTO_TEST_CASE(test_has_attribute_after_set)
{
	ItemAttributes attrs;
	attrs.setActionId(42);
	BOOST_TEST(attrs.hasAttribute(ITEM_ATTRIBUTE_ACTIONID));
	BOOST_TEST(!attrs.hasAttribute(ITEM_ATTRIBUTE_UNIQUEID));
}

BOOST_AUTO_TEST_CASE(test_remove_int_attribute)
{
	ItemAttributes attrs;
	attrs.setActionId(42);
	BOOST_TEST(attrs.hasAttribute(ITEM_ATTRIBUTE_ACTIONID));
	attrs.removeAttribute(ITEM_ATTRIBUTE_ACTIONID);
	BOOST_TEST(!attrs.hasAttribute(ITEM_ATTRIBUTE_ACTIONID));
	BOOST_TEST(attrs.getActionId() == 0);
}

BOOST_AUTO_TEST_CASE(test_remove_str_attribute)
{
	ItemAttributes attrs;
	attrs.setText("hello");
	BOOST_TEST(attrs.hasAttribute(ITEM_ATTRIBUTE_TEXT));
	attrs.removeAttribute(ITEM_ATTRIBUTE_TEXT);
	BOOST_TEST(!attrs.hasAttribute(ITEM_ATTRIBUTE_TEXT));
	BOOST_TEST(attrs.getText().empty());
}

BOOST_AUTO_TEST_CASE(test_remove_does_not_affect_others)
{
	ItemAttributes attrs;
	attrs.setActionId(100);
	attrs.setUniqueId(200);
	attrs.removeAttribute(ITEM_ATTRIBUTE_ACTIONID);
	BOOST_TEST(attrs.getUniqueId() == 200);
	BOOST_TEST(attrs.hasAttribute(ITEM_ATTRIBUTE_UNIQUEID));
}

// ================================================================
//  TESTS: Attribute bitmask flags
// ================================================================

BOOST_AUTO_TEST_CASE(test_attribute_bits_are_powers_of_two)
{
	uint32_t allFlags[] = {
		ITEM_ATTRIBUTE_ACTIONID, ITEM_ATTRIBUTE_UNIQUEID, ITEM_ATTRIBUTE_DESCRIPTION,
		ITEM_ATTRIBUTE_TEXT, ITEM_ATTRIBUTE_DATE, ITEM_ATTRIBUTE_WRITER,
		ITEM_ATTRIBUTE_NAME, ITEM_ATTRIBUTE_ARTICLE, ITEM_ATTRIBUTE_PLURALNAME,
		ITEM_ATTRIBUTE_WEIGHT, ITEM_ATTRIBUTE_ATTACK, ITEM_ATTRIBUTE_DEFENSE,
		ITEM_ATTRIBUTE_EXTRADEFENSE, ITEM_ATTRIBUTE_ARMOR, ITEM_ATTRIBUTE_HITCHANCE,
		ITEM_ATTRIBUTE_SHOOTRANGE, ITEM_ATTRIBUTE_OWNER, ITEM_ATTRIBUTE_DURATION,
		ITEM_ATTRIBUTE_DECAYSTATE, ITEM_ATTRIBUTE_CORPSEOWNER, ITEM_ATTRIBUTE_CHARGES,
		ITEM_ATTRIBUTE_FLUIDTYPE, ITEM_ATTRIBUTE_DOORID, ITEM_ATTRIBUTE_DECAYTO,
		ITEM_ATTRIBUTE_WRAPID, ITEM_ATTRIBUTE_STOREITEM, ITEM_ATTRIBUTE_CUSTOM
	};
	for (uint32_t flag : allFlags) {
		// A power of two has exactly one bit set
		BOOST_TEST((flag & (flag - 1)) == 0u);
		BOOST_TEST(flag != 0u);
	}
}

BOOST_AUTO_TEST_CASE(test_attribute_no_overlap)
{
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
		BOOST_TEST((combined & f) == 0u);
		combined |= f;
	}
}

BOOST_AUTO_TEST_CASE(test_combined_bitmask)
{
	uint32_t flags = ITEM_ATTRIBUTE_ATTACK | ITEM_ATTRIBUTE_DEFENSE | ITEM_ATTRIBUTE_ARMOR;
	BOOST_TEST((flags & ITEM_ATTRIBUTE_ATTACK) != 0u);
	BOOST_TEST((flags & ITEM_ATTRIBUTE_DEFENSE) != 0u);
	BOOST_TEST((flags & ITEM_ATTRIBUTE_ARMOR) != 0u);
	BOOST_TEST((flags & ITEM_ATTRIBUTE_WEIGHT) == 0u);
}

// ================================================================
//  TESTS: stringToItemAttribute
// ================================================================

BOOST_AUTO_TEST_CASE(test_string_to_attr_known)
{
	BOOST_TEST(stringToItemAttribute("aid") == ITEM_ATTRIBUTE_ACTIONID);
	BOOST_TEST(stringToItemAttribute("uid") == ITEM_ATTRIBUTE_UNIQUEID);
	BOOST_TEST(stringToItemAttribute("name") == ITEM_ATTRIBUTE_NAME);
	BOOST_TEST(stringToItemAttribute("attack") == ITEM_ATTRIBUTE_ATTACK);
	BOOST_TEST(stringToItemAttribute("defense") == ITEM_ATTRIBUTE_DEFENSE);
	BOOST_TEST(stringToItemAttribute("armor") == ITEM_ATTRIBUTE_ARMOR);
	BOOST_TEST(stringToItemAttribute("weight") == ITEM_ATTRIBUTE_WEIGHT);
	BOOST_TEST(stringToItemAttribute("duration") == ITEM_ATTRIBUTE_DURATION);
	BOOST_TEST(stringToItemAttribute("charges") == ITEM_ATTRIBUTE_CHARGES);
}

BOOST_AUTO_TEST_CASE(test_string_to_attr_all_valid)
{
	const char* validNames[] = {
		"aid", "uid", "description", "text", "date", "writer",
		"name", "article", "pluralname", "weight", "attack",
		"defense", "extradefense", "armor", "hitchance", "shootrange",
		"owner", "duration", "decaystate", "corpseowner", "charges",
		"fluidtype", "doorid", "wrapid"
	};
	for (const char* name : validNames) {
		BOOST_TEST(stringToItemAttribute(name) != ITEM_ATTRIBUTE_NONE);
	}
}

BOOST_AUTO_TEST_CASE(test_string_to_attr_unknown)
{
	BOOST_TEST(stringToItemAttribute("nonexistent") == ITEM_ATTRIBUTE_NONE);
	BOOST_TEST(stringToItemAttribute("") == ITEM_ATTRIBUTE_NONE);
	BOOST_TEST(stringToItemAttribute("AID") == ITEM_ATTRIBUTE_NONE); // case sensitive
}

// ================================================================
//  TESTS: Weight calculation
// ================================================================

BOOST_AUTO_TEST_CASE(test_weight_non_stackable)
{
	// Non-stackable items always return base weight regardless of count
	BOOST_TEST(calculateWeight(500, false, 1) == 500u);
	BOOST_TEST(calculateWeight(500, false, 5) == 500u);
	BOOST_TEST(calculateWeight(500, false, 0) == 500u);
}

BOOST_AUTO_TEST_CASE(test_weight_stackable)
{
	// Stackable items multiply base weight by count (min 1)
	BOOST_TEST(calculateWeight(10, true, 1) == 10u);
	BOOST_TEST(calculateWeight(10, true, 5) == 50u);
	BOOST_TEST(calculateWeight(10, true, 100) == 1000u);
}

BOOST_AUTO_TEST_CASE(test_weight_stackable_zero_count)
{
	// Zero count treated as 1 for stackable
	BOOST_TEST(calculateWeight(10, true, 0) == 10u);
}

BOOST_AUTO_TEST_CASE(test_weight_zero_base)
{
	BOOST_TEST(calculateWeight(0, false, 1) == 0u);
	BOOST_TEST(calculateWeight(0, true, 100) == 0u);
}

// ================================================================
//  TESTS: Item ID constants
// ================================================================

enum item_t : uint16_t {
	ITEM_GOLD_COIN = 2148,
	ITEM_PLATINUM_COIN = 2152,
	ITEM_CRYSTAL_COIN = 2160,
	ITEM_DEPOT = 2594,
	ITEM_BAG = 1987,
	ITEM_PARCEL = 2595,
	ITEM_LETTER = 2597,
};

BOOST_AUTO_TEST_CASE(test_coin_ids)
{
	BOOST_TEST(ITEM_GOLD_COIN == 2148);
	BOOST_TEST(ITEM_PLATINUM_COIN == 2152);
	BOOST_TEST(ITEM_CRYSTAL_COIN == 2160);
}

BOOST_AUTO_TEST_CASE(test_coin_ordering)
{
	// Gold < Platinum < Crystal
	BOOST_TEST(ITEM_GOLD_COIN < ITEM_PLATINUM_COIN);
	BOOST_TEST(ITEM_PLATINUM_COIN < ITEM_CRYSTAL_COIN);
}

BOOST_AUTO_TEST_CASE(test_container_ids)
{
	BOOST_TEST(ITEM_BAG == 1987);
	BOOST_TEST(ITEM_DEPOT == 2594);
}

BOOST_AUTO_TEST_CASE(test_mail_ids)
{
	BOOST_TEST(ITEM_PARCEL == 2595);
	BOOST_TEST(ITEM_LETTER == 2597);
}
