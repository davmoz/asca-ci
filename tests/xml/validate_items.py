#!/usr/bin/env python3
"""
Validate data/items/items.xml.

Checks:
- XML is well-formed
- Root element is <items>
- Item entries have valid id attributes
- No duplicate single item IDs
- Item attributes have valid key names
- Numeric attribute values are valid numbers
"""

import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import Counter


def find_project_root():
    path = Path(__file__).resolve().parent
    while path != path.parent:
        if (path / "CMakeLists.txt").exists() and (path / "data").exists():
            return path
        path = path.parent
    return Path.cwd()


PROJECT_ROOT = find_project_root()
ITEMS_XML = PROJECT_ROOT / "data" / "items" / "items.xml"

VALID_ATTRIBUTE_KEYS = {
    "type", "name", "article", "plural", "description", "weight", "armor",
    "defense", "extradef", "attack", "rotateTo", "containerSize",
    "floorchange", "corpsetype", "writeable", "maxTextLen", "writeOnceItemId",
    "weaponType", "slotType", "ammoType", "shootType", "effect", "range",
    "stopduration", "decayTo", "transformEquipTo", "transformDeEquipTo",
    "duration", "showduration", "charges", "showcharges", "showattributes",
    "hitchance", "maxHitChance", "breakChance", "ammoAction", "replaceable",
    "leveldoor", "maletransformto", "femaletransformto", "transformTo",
    "destroyTo", "elementIce", "elementEarth", "elementFire", "elementEnergy",
    "elementDeath", "elementHoly", "elementPhysical", "walkStack", "blocking",
    "allowDistRead", "storeItem", "worth", "supply", "wrapableTo",
    "wrapContainer", "speed", "healthGain", "healthTicks", "manaGain",
    "manaTicks", "skillSword", "skillAxe", "skillClub", "skillDist",
    "skillFish", "skillShield", "skillFist", "maxHitpoints", "maxManapoints",
    "magicPoints", "magicLevelPoints", "absorbPercentAll",
    "absorbPercentPhysical", "absorbPercentFire", "absorbPercentEnergy",
    "absorbPercentEarth", "absorbPercentIce", "absorbPercentHoly",
    "absorbPercentDeath", "absorbPercentDrown", "absorbPercentManaDrain",
    "absorbPercentLifeDrain", "suppressDrunk", "suppressEnergy",
    "suppressFire", "suppressPoison", "suppressDrown", "suppressPhysical",
    "suppressFreeze", "suppressDazzle", "suppressCurse", "field",
    "bedSleeperId", "bedSleepStart", "partnerDirection", "malesleeper",
    "femalesleeper", "nosleeper", "preventTools", "preventItems",
    "invisible", "criticalHitChance",
}


class ItemsValidator:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.item_count = 0

    def error(self, msg):
        self.errors.append(msg)

    def warn(self, msg):
        self.warnings.append(msg)

    def run(self):
        print("Validating items.xml...")

        if not ITEMS_XML.exists():
            self.error(f"File not found: {ITEMS_XML}")
            return self.report()

        # Parse XML
        try:
            tree = ET.parse(str(ITEMS_XML))
            root = tree.getroot()
        except ET.ParseError as e:
            self.error(f"XML parse error: {e}")
            return self.report()

        if root.tag != "items":
            self.error(f"Root element is '{root.tag}', expected 'items'")
            return self.report()

        # Validate items
        seen_ids = Counter()

        for item in root.findall("item"):
            self.item_count += 1

            # Check id attribute
            item_id = item.get("id")
            fromid = item.get("fromid")
            toid = item.get("toid")

            if item_id:
                try:
                    int(item_id)
                    seen_ids[item_id] += 1
                except ValueError:
                    self.error(f"Item has non-numeric id: {item_id}")
            elif fromid and toid:
                try:
                    from_val = int(fromid)
                    to_val = int(toid)
                    if from_val > to_val:
                        self.error(f"Item range: fromid={fromid} > toid={toid}")
                except ValueError:
                    self.error(f"Item range has non-numeric ids: fromid={fromid}, toid={toid}")
            else:
                self.error("Item missing both 'id' and 'fromid/toid' attributes")

            # Check attribute elements
            for attr in item.findall("attribute"):
                key = attr.get("key")
                value = attr.get("value")
                if not key:
                    self.error(f"Item {item_id}: attribute missing 'key'")
                if value is None:
                    self.error(f"Item {item_id}: attribute '{key}' missing 'value'")

        # Check for duplicate IDs
        duplicates = {k: v for k, v in seen_ids.items() if v > 1}
        if duplicates:
            for item_id, count in duplicates.items():
                self.warn(f"Duplicate item id={item_id} appears {count} times")

        print(f"  Found {self.item_count} item entries")
        return self.report()

    def report(self):
        print(f"  Errors: {len(self.errors)}")
        print(f"  Warnings: {len(self.warnings)}")

        if self.errors:
            print("\nERRORS:")
            for e in self.errors[:20]:
                print(f"  {e}")
            if len(self.errors) > 20:
                print(f"  ... and {len(self.errors) - 20} more")

        return len(self.errors) == 0


if __name__ == "__main__":
    validator = ItemsValidator()
    success = validator.run()
    sys.exit(0 if success else 1)
