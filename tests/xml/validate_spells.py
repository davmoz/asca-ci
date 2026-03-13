#!/usr/bin/env python3
"""
Validate data/spells/spells.xml.

Checks:
- XML is well-formed
- Root element is <spells>
- Spell entries have required attributes (name, words, level, mana)
- Spell groups are valid (attack, healing, support, special)
- Cooldowns are positive integers
- Referenced script files exist
- Vocation elements have name attributes
"""

import os
import sys
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
SPELLS_XML = PROJECT_ROOT / "data" / "spells" / "spells.xml"
SPELLS_SCRIPTS = PROJECT_ROOT / "data" / "spells" / "scripts"

VALID_GROUPS = {"attack", "healing", "support", "special"}


class SpellsValidator:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.instant_count = 0
        self.rune_count = 0
        self.conjure_count = 0

    def error(self, msg):
        self.errors.append(msg)

    def warn(self, msg):
        self.warnings.append(msg)

    def run(self):
        print("Validating spells.xml...")

        if not SPELLS_XML.exists():
            self.error(f"File not found: {SPELLS_XML}")
            return self.report()

        try:
            tree = ET.parse(str(SPELLS_XML))
            root = tree.getroot()
        except ET.ParseError as e:
            self.error(f"XML parse error: {e}")
            return self.report()

        if root.tag != "spells":
            self.error(f"Root element is '{root.tag}', expected 'spells'")
            return self.report()

        # Validate instant spells
        for spell in root.findall("instant"):
            self.instant_count += 1
            self._validate_spell(spell, "instant")

        # Validate rune spells
        for spell in root.findall("rune"):
            self.rune_count += 1
            self._validate_spell(spell, "rune")

        # Validate conjure spells
        for spell in root.findall("conjure"):
            self.conjure_count += 1
            self._validate_spell(spell, "conjure")

        print(f"  Instant spells: {self.instant_count}")
        print(f"  Rune spells: {self.rune_count}")
        print(f"  Conjure spells: {self.conjure_count}")

        return self.report()

    def _validate_spell(self, spell, spell_type):
        name = spell.get("name")
        if not name:
            self.error(f"{spell_type} spell missing 'name' attribute")
            name = "<unknown>"

        # Words required for instant spells
        if spell_type == "instant":
            words = spell.get("words")
            if not words:
                self.error(f"Instant spell '{name}' missing 'words' attribute")

        # Level
        level = spell.get("level")
        if level:
            try:
                level_val = int(level)
                if level_val < 0:
                    self.error(f"Spell '{name}' has negative level: {level_val}")
            except ValueError:
                self.error(f"Spell '{name}' has non-numeric level: {level}")

        # Mana
        mana = spell.get("mana")
        if mana:
            try:
                mana_val = int(mana)
                if mana_val < 0:
                    self.error(f"Spell '{name}' has negative mana: {mana_val}")
            except ValueError:
                self.error(f"Spell '{name}' has non-numeric mana: {mana}")

        # Group
        group = spell.get("group")
        if group and group not in VALID_GROUPS:
            self.error(f"Spell '{name}' has invalid group: {group}")

        # Cooldown
        cooldown = spell.get("cooldown")
        if cooldown:
            try:
                cd_val = int(cooldown)
                if cd_val <= 0:
                    self.warn(f"Spell '{name}' has non-positive cooldown: {cd_val}")
            except ValueError:
                self.error(f"Spell '{name}' has non-numeric cooldown: {cooldown}")

        # Script file
        script = spell.get("script")
        if script:
            script_path = SPELLS_SCRIPTS / script
            if not script_path.exists():
                self.error(f"Spell '{name}' references missing script: {script}")

        # Vocation elements
        for voc in spell.findall("vocation"):
            voc_name = voc.get("name")
            if not voc_name:
                self.error(f"Spell '{name}' has vocation element without name")

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
    validator = SpellsValidator()
    success = validator.run()
    sys.exit(0 if success else 1)
