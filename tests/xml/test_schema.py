#!/usr/bin/env python3
"""
XML schema validation tests.

Validates that critical XML data files conform to expected schemas:
- spells.xml: <instant> tags have name, words, level
- monsters.xml: <monster> tags have name, file
- items.xml: <item> tags have id or fromid+toid
- vocations.xml: <vocation> tags have id, name
- Numeric attributes (id, level, mana) are valid numbers

Usage: python3 tests/xml/test_schema.py
"""

import sys
import os
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


def find_project_root():
    path = Path(__file__).resolve().parent
    while path != path.parent:
        if (path / "CMakeLists.txt").exists() and (path / "data").exists():
            return path
        path = path.parent
    return Path.cwd()


PROJECT_ROOT = find_project_root()


class TestSpellsSchema(unittest.TestCase):
    """Validate spells.xml schema: all <instant> tags have name, words, level."""

    @classmethod
    def setUpClass(cls):
        cls.spells_path = PROJECT_ROOT / "data" / "spells" / "spells.xml"
        cls.tree = None
        cls.root = None
        if cls.spells_path.exists():
            cls.tree = ET.parse(str(cls.spells_path))
            cls.root = cls.tree.getroot()

    def test_spells_xml_exists(self):
        self.assertTrue(self.spells_path.exists(),
                        f"spells.xml not found at {self.spells_path}")

    def test_spells_root_element(self):
        if self.root is None:
            self.skipTest("spells.xml not loaded")
        self.assertEqual(self.root.tag, "spells",
                         f"Root element is '{self.root.tag}', expected 'spells'")

    def test_instant_spells_have_name(self):
        if self.root is None:
            self.skipTest("spells.xml not loaded")
        missing = []
        for spell in self.root.findall("instant"):
            if not spell.get("name"):
                words = spell.get("words", "<no words>")
                missing.append(f"instant spell with words='{words}' missing 'name'")
        self.assertEqual(len(missing), 0,
                         "Instant spells missing 'name' attribute:\n  " +
                         "\n  ".join(missing[:20]))

    def test_instant_spells_have_words(self):
        if self.root is None:
            self.skipTest("spells.xml not loaded")
        missing = []
        for spell in self.root.findall("instant"):
            name = spell.get("name", "<unnamed>")
            if not spell.get("words"):
                missing.append(f"instant spell '{name}' missing 'words'")
        self.assertEqual(len(missing), 0,
                         "Instant spells missing 'words' attribute:\n  " +
                         "\n  ".join(missing[:20]))

    def test_instant_spells_with_words_have_level(self):
        """Player-castable instant spells (real words, not monster ###N) should have a level."""
        if self.root is None:
            self.skipTest("spells.xml not loaded")
        missing = []
        for spell in self.root.findall("instant"):
            name = spell.get("name", "<unnamed>")
            words = spell.get("words", "")
            # Skip monster spells (###N pattern) and house management spells
            if not words or words.startswith("###"):
                continue
            if name.lower().startswith("house ") or words.startswith("aleta") or words.startswith("alana"):
                continue
            if spell.get("level") is None:
                missing.append(f"instant spell '{name}' (words='{words}') missing 'level'")
        self.assertEqual(len(missing), 0,
                         "Player-castable instant spells missing 'level' attribute:\n  " +
                         "\n  ".join(missing[:20]))

    def test_spell_level_is_numeric(self):
        if self.root is None:
            self.skipTest("spells.xml not loaded")
        bad = []
        for tag in ("instant", "rune", "conjure"):
            for spell in self.root.findall(tag):
                name = spell.get("name", "<unnamed>")
                level = spell.get("level")
                if level is not None:
                    try:
                        val = int(level)
                        if val < 0:
                            bad.append(f"{tag} spell '{name}': negative level {val}")
                    except ValueError:
                        bad.append(f"{tag} spell '{name}': non-numeric level '{level}'")
        self.assertEqual(len(bad), 0,
                         "Invalid level values:\n  " + "\n  ".join(bad[:20]))

    def test_spell_mana_is_numeric(self):
        if self.root is None:
            self.skipTest("spells.xml not loaded")
        bad = []
        for tag in ("instant", "rune", "conjure"):
            for spell in self.root.findall(tag):
                name = spell.get("name", "<unnamed>")
                mana = spell.get("mana")
                if mana is not None:
                    try:
                        int(mana)
                    except ValueError:
                        bad.append(f"{tag} spell '{name}': non-numeric mana '{mana}'")
        self.assertEqual(len(bad), 0,
                         "Invalid mana values:\n  " + "\n  ".join(bad[:20]))

    def test_spell_cooldown_is_numeric(self):
        if self.root is None:
            self.skipTest("spells.xml not loaded")
        bad = []
        for tag in ("instant", "rune", "conjure"):
            for spell in self.root.findall(tag):
                name = spell.get("name", "<unnamed>")
                cooldown = spell.get("cooldown")
                if cooldown is not None:
                    try:
                        val = int(cooldown)
                        if val < 0:
                            bad.append(f"{tag} spell '{name}': negative cooldown {val}")
                    except ValueError:
                        bad.append(f"{tag} spell '{name}': non-numeric cooldown '{cooldown}'")
        self.assertEqual(len(bad), 0,
                         "Invalid cooldown values:\n  " + "\n  ".join(bad[:20]))


class TestMonstersSchema(unittest.TestCase):
    """Validate monsters.xml schema: all <monster> tags have name, file."""

    @classmethod
    def setUpClass(cls):
        cls.monsters_path = PROJECT_ROOT / "data" / "monster" / "monsters.xml"
        cls.tree = None
        cls.root = None
        if cls.monsters_path.exists():
            cls.tree = ET.parse(str(cls.monsters_path))
            cls.root = cls.tree.getroot()

    def test_monsters_xml_exists(self):
        self.assertTrue(self.monsters_path.exists(),
                        f"monsters.xml not found at {self.monsters_path}")

    def test_monsters_root_element(self):
        if self.root is None:
            self.skipTest("monsters.xml not loaded")
        self.assertEqual(self.root.tag, "monsters",
                         f"Root element is '{self.root.tag}', expected 'monsters'")

    def test_all_monsters_have_name(self):
        if self.root is None:
            self.skipTest("monsters.xml not loaded")
        missing = []
        for i, monster in enumerate(self.root.findall("monster")):
            if not monster.get("name"):
                file_attr = monster.get("file", f"entry #{i+1}")
                missing.append(f"monster entry '{file_attr}' missing 'name'")
        self.assertEqual(len(missing), 0,
                         "Monster entries missing 'name':\n  " +
                         "\n  ".join(missing[:20]))

    def test_all_monsters_have_file(self):
        if self.root is None:
            self.skipTest("monsters.xml not loaded")
        missing = []
        for monster in self.root.findall("monster"):
            name = monster.get("name", "<unnamed>")
            if not monster.get("file"):
                missing.append(f"monster '{name}' missing 'file' attribute")
        self.assertEqual(len(missing), 0,
                         "Monster entries missing 'file':\n  " +
                         "\n  ".join(missing[:20]))

    def test_monster_files_exist(self):
        if self.root is None:
            self.skipTest("monsters.xml not loaded")
        missing = []
        for monster in self.root.findall("monster"):
            name = monster.get("name", "<unnamed>")
            file_attr = monster.get("file")
            if file_attr:
                full_path = PROJECT_ROOT / "data" / "monster" / file_attr
                if not full_path.exists():
                    missing.append(f"monster '{name}': file '{file_attr}' not found")
        self.assertEqual(len(missing), 0,
                         "Monster files not found:\n  " +
                         "\n  ".join(missing[:20]))


class TestItemsSchema(unittest.TestCase):
    """Validate items.xml schema: all <item> tags have id or fromid+toid."""

    @classmethod
    def setUpClass(cls):
        cls.items_path = PROJECT_ROOT / "data" / "items" / "items.xml"
        cls.tree = None
        cls.root = None
        if cls.items_path.exists():
            cls.tree = ET.parse(str(cls.items_path))
            cls.root = cls.tree.getroot()

    def test_items_xml_exists(self):
        self.assertTrue(self.items_path.exists(),
                        f"items.xml not found at {self.items_path}")

    def test_items_root_element(self):
        if self.root is None:
            self.skipTest("items.xml not loaded")
        self.assertEqual(self.root.tag, "items",
                         f"Root element is '{self.root.tag}', expected 'items'")

    def test_all_items_have_id_or_range(self):
        if self.root is None:
            self.skipTest("items.xml not loaded")
        bad = []
        for i, item in enumerate(self.root.findall("item")):
            item_id = item.get("id")
            fromid = item.get("fromid")
            toid = item.get("toid")
            if not item_id and not (fromid and toid):
                bad.append(f"item entry #{i+1}: missing 'id' and 'fromid'/'toid'")
        self.assertEqual(len(bad), 0,
                         "Items missing identification:\n  " +
                         "\n  ".join(bad[:20]))

    def test_item_id_is_numeric(self):
        if self.root is None:
            self.skipTest("items.xml not loaded")
        bad = []
        for item in self.root.findall("item"):
            item_id = item.get("id")
            if item_id:
                try:
                    val = int(item_id)
                    if val < 0:
                        bad.append(f"item id={item_id}: negative value")
                except ValueError:
                    bad.append(f"item id='{item_id}': not a valid number")
        self.assertEqual(len(bad), 0,
                         "Invalid item IDs:\n  " + "\n  ".join(bad[:20]))

    def test_item_range_ids_are_numeric(self):
        if self.root is None:
            self.skipTest("items.xml not loaded")
        bad = []
        for item in self.root.findall("item"):
            fromid = item.get("fromid")
            toid = item.get("toid")
            if fromid or toid:
                try:
                    from_val = int(fromid) if fromid else None
                    to_val = int(toid) if toid else None
                    if from_val is not None and to_val is not None:
                        if from_val > to_val:
                            bad.append(f"item range fromid={fromid} > toid={toid}")
                    elif from_val is None or to_val is None:
                        # One is present without the other
                        if not item.get("id"):
                            bad.append(f"item has fromid={fromid} toid={toid} (incomplete range)")
                except ValueError:
                    bad.append(f"item range non-numeric: fromid={fromid}, toid={toid}")
        self.assertEqual(len(bad), 0,
                         "Invalid item ranges:\n  " + "\n  ".join(bad[:20]))

    def test_item_attributes_have_key_and_value(self):
        if self.root is None:
            self.skipTest("items.xml not loaded")
        bad = []
        for item in self.root.findall("item"):
            item_id = item.get("id") or f"range {item.get('fromid')}-{item.get('toid')}"
            for attr in item.findall("attribute"):
                if not attr.get("key"):
                    bad.append(f"item {item_id}: attribute missing 'key'")
                if attr.get("value") is None:
                    key = attr.get("key", "?")
                    bad.append(f"item {item_id}: attribute '{key}' missing 'value'")
        self.assertEqual(len(bad), 0,
                         "Invalid item attributes:\n  " + "\n  ".join(bad[:20]))


class TestVocationsSchema(unittest.TestCase):
    """Validate vocations.xml schema: all <vocation> tags have id, name."""

    @classmethod
    def setUpClass(cls):
        cls.vocations_path = PROJECT_ROOT / "data" / "XML" / "vocations.xml"
        cls.tree = None
        cls.root = None
        if cls.vocations_path.exists():
            cls.tree = ET.parse(str(cls.vocations_path))
            cls.root = cls.tree.getroot()

    def test_vocations_xml_exists(self):
        self.assertTrue(self.vocations_path.exists(),
                        f"vocations.xml not found at {self.vocations_path}")

    def test_vocations_root_element(self):
        if self.root is None:
            self.skipTest("vocations.xml not loaded")
        self.assertEqual(self.root.tag, "vocations",
                         f"Root element is '{self.root.tag}', expected 'vocations'")

    def test_all_vocations_have_id(self):
        if self.root is None:
            self.skipTest("vocations.xml not loaded")
        missing = []
        for voc in self.root.findall("vocation"):
            if voc.get("id") is None:
                name = voc.get("name", "<unnamed>")
                missing.append(f"vocation '{name}' missing 'id' attribute")
        self.assertEqual(len(missing), 0,
                         "Vocations missing 'id':\n  " +
                         "\n  ".join(missing[:20]))

    def test_all_vocations_have_name(self):
        if self.root is None:
            self.skipTest("vocations.xml not loaded")
        missing = []
        for voc in self.root.findall("vocation"):
            voc_id = voc.get("id", "?")
            if not voc.get("name"):
                missing.append(f"vocation id={voc_id} missing 'name' attribute")
        self.assertEqual(len(missing), 0,
                         "Vocations missing 'name':\n  " +
                         "\n  ".join(missing[:20]))

    def test_vocation_id_is_numeric(self):
        if self.root is None:
            self.skipTest("vocations.xml not loaded")
        bad = []
        for voc in self.root.findall("vocation"):
            voc_id = voc.get("id")
            if voc_id is not None:
                try:
                    val = int(voc_id)
                    if val < 0:
                        bad.append(f"vocation '{voc.get('name', '?')}': negative id {val}")
                except ValueError:
                    bad.append(f"vocation '{voc.get('name', '?')}': non-numeric id '{voc_id}'")
        self.assertEqual(len(bad), 0,
                         "Invalid vocation IDs:\n  " + "\n  ".join(bad[:20]))

    def test_vocation_numeric_attributes_valid(self):
        """Check that gaincap, gainhp, gainmana etc. are valid numbers."""
        if self.root is None:
            self.skipTest("vocations.xml not loaded")
        numeric_attrs = [
            "gaincap", "gainhp", "gainmana", "gainhpticks", "gainhpamount",
            "gainmanaticks", "gainmanaamount", "attackspeed", "basespeed",
            "soulmax", "gainsoulticks",
        ]
        bad = []
        for voc in self.root.findall("vocation"):
            name = voc.get("name", f"id={voc.get('id', '?')}")
            for attr in numeric_attrs:
                val = voc.get(attr)
                if val is not None:
                    try:
                        num = float(val)
                        if num < 0:
                            bad.append(f"vocation '{name}': {attr}={val} is negative")
                    except ValueError:
                        bad.append(f"vocation '{name}': {attr}='{val}' is not a number")
        self.assertEqual(len(bad), 0,
                         "Invalid numeric vocation attributes:\n  " +
                         "\n  ".join(bad[:20]))

    def test_vocation_manamultiplier_is_numeric(self):
        if self.root is None:
            self.skipTest("vocations.xml not loaded")
        bad = []
        for voc in self.root.findall("vocation"):
            name = voc.get("name", f"id={voc.get('id', '?')}")
            mm = voc.get("manamultiplier")
            if mm is not None:
                try:
                    val = float(mm)
                    if val <= 0:
                        bad.append(f"vocation '{name}': manamultiplier={val} not positive")
                except ValueError:
                    bad.append(f"vocation '{name}': manamultiplier='{mm}' not a number")
        self.assertEqual(len(bad), 0,
                         "Invalid manamultiplier values:\n  " +
                         "\n  ".join(bad[:20]))

    def test_no_duplicate_vocation_ids(self):
        if self.root is None:
            self.skipTest("vocations.xml not loaded")
        seen = {}
        duplicates = []
        for voc in self.root.findall("vocation"):
            voc_id = voc.get("id")
            if voc_id is not None:
                if voc_id in seen:
                    duplicates.append(
                        f"id={voc_id} used by both '{seen[voc_id]}' and '{voc.get('name', '?')}'")
                else:
                    seen[voc_id] = voc.get("name", "?")
        self.assertEqual(len(duplicates), 0,
                         "Duplicate vocation IDs:\n  " +
                         "\n  ".join(duplicates[:20]))


if __name__ == "__main__":
    os.chdir(str(PROJECT_ROOT))
    unittest.main(verbosity=2)
