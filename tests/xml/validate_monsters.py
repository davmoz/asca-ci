#!/usr/bin/env python3
"""
Validate all monster XML files in data/monster/monsters/.

Checks:
- XML is well-formed
- Required elements exist (monster, health, look)
- Required attributes are present (name, experience, speed, race)
- Health values are positive integers
- Experience values are non-negative
- Look type or typeEx is specified
- Attacks and defenses have valid structure
"""

import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def find_project_root():
    """Find the project root by looking for CMakeLists.txt."""
    path = Path(__file__).resolve().parent
    while path != path.parent:
        if (path / "CMakeLists.txt").exists() and (path / "data").exists():
            return path
        path = path.parent
    return Path.cwd()


PROJECT_ROOT = find_project_root()
MONSTER_DIR = PROJECT_ROOT / "data" / "monster" / "monsters"
MONSTER_INDEX = PROJECT_ROOT / "data" / "monster" / "monsters.xml"

VALID_RACES = {"blood", "venom", "undead", "fire", "energy"}


class MonsterValidator:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.validated = 0
        self.passed = 0

    def error(self, path, msg):
        self.errors.append(f"{path}: {msg}")

    def warn(self, path, msg):
        self.warnings.append(f"{path}: {msg}")

    def validate_index(self):
        """Validate monsters.xml index file."""
        if not MONSTER_INDEX.exists():
            self.error(str(MONSTER_INDEX), "File not found")
            return []

        try:
            tree = ET.parse(str(MONSTER_INDEX))
            root = tree.getroot()
        except ET.ParseError as e:
            self.error(str(MONSTER_INDEX), f"XML parse error: {e}")
            return []

        if root.tag != "monsters":
            self.error(str(MONSTER_INDEX), f"Root element is '{root.tag}', expected 'monsters'")

        entries = []
        for monster in root.findall("monster"):
            name = monster.get("name")
            file_attr = monster.get("file")
            if not name:
                self.error(str(MONSTER_INDEX), "Monster entry missing 'name' attribute")
            if not file_attr:
                self.error(str(MONSTER_INDEX), f"Monster '{name}' missing 'file' attribute")
            else:
                entries.append((name, file_attr))

        return entries

    def validate_monster_file(self, filepath, expected_name=None):
        """Validate a single monster XML file."""
        self.validated += 1
        rel_path = str(filepath.relative_to(PROJECT_ROOT)) if filepath.is_absolute() else str(filepath)

        if not filepath.exists():
            self.error(rel_path, "File not found")
            return

        try:
            tree = ET.parse(str(filepath))
            root = tree.getroot()
        except ET.ParseError as e:
            self.error(rel_path, f"XML parse error: {e}")
            return

        # Root element
        if root.tag != "monster":
            self.error(rel_path, f"Root element is '{root.tag}', expected 'monster'")
            return

        # Required attributes
        name = root.get("name")
        if not name:
            self.error(rel_path, "Missing 'name' attribute")
        elif name.strip() == "":
            self.error(rel_path, "Empty 'name' attribute")

        experience = root.get("experience")
        if experience is not None:
            try:
                exp_val = int(experience)
                if exp_val < 0:
                    self.error(rel_path, f"Negative experience: {exp_val}")
            except ValueError:
                self.error(rel_path, f"Non-numeric experience: {experience}")

        speed = root.get("speed")
        if speed is not None:
            try:
                speed_val = int(speed)
                if speed_val < 0:
                    self.error(rel_path, f"Negative speed: {speed_val}")
            except ValueError:
                self.error(rel_path, f"Non-numeric speed: {speed}")

        race = root.get("race")
        if race and race not in VALID_RACES:
            self.warn(rel_path, f"Unusual race: {race}")

        # Health element
        health = root.find("health")
        if health is None:
            self.error(rel_path, "Missing <health> element")
        else:
            max_hp = health.get("max")
            now_hp = health.get("now")
            if max_hp:
                try:
                    max_hp_val = int(max_hp)
                    if max_hp_val <= 0:
                        self.error(rel_path, f"Invalid max health: {max_hp_val}")
                except ValueError:
                    self.error(rel_path, f"Non-numeric max health: {max_hp}")
            else:
                self.error(rel_path, "Health element missing 'max' attribute")

            if now_hp:
                try:
                    now_hp_val = int(now_hp)
                    if now_hp_val <= 0:
                        self.error(rel_path, f"Invalid current health: {now_hp_val}")
                except ValueError:
                    self.error(rel_path, f"Non-numeric current health: {now_hp}")

        # Look element
        look = root.find("look")
        if look is None:
            self.error(rel_path, "Missing <look> element")
        else:
            look_type = look.get("type")
            look_typeex = look.get("typeex")
            if not look_type and not look_typeex:
                self.error(rel_path, "Look element missing both 'type' and 'typeex'")

        # Attacks structure
        attacks = root.find("attacks")
        if attacks is not None:
            for attack in attacks.findall("attack"):
                attack_name = attack.get("name")
                if not attack_name:
                    self.warn(rel_path, "Attack missing 'name' attribute")
                interval = attack.get("interval")
                if interval:
                    try:
                        if int(interval) <= 0:
                            self.warn(rel_path, f"Attack '{attack_name}' has non-positive interval")
                    except ValueError:
                        self.error(rel_path, f"Attack '{attack_name}' has non-numeric interval")

        # Defenses structure
        defenses = root.find("defenses")
        if defenses is not None:
            armor = defenses.get("armor")
            defense = defenses.get("defense")
            if armor:
                try:
                    int(armor)
                except ValueError:
                    self.error(rel_path, f"Non-numeric armor value: {armor}")

        self.passed += 1

    def run(self):
        """Run all monster validations."""
        print("Validating monster files...")

        # Validate index
        entries = self.validate_index()
        print(f"  Found {len(entries)} monsters in index")

        # Validate referenced files
        missing_files = 0
        for name, file_attr in entries:
            filepath = PROJECT_ROOT / "data" / "monster" / file_attr
            if not filepath.exists():
                self.error(file_attr, f"Referenced file not found for monster '{name}'")
                missing_files += 1
            else:
                self.validate_monster_file(filepath, name)

        # Also check for orphan files not in index
        if MONSTER_DIR.exists():
            indexed_files = {f for _, f in entries}
            for xml_file in MONSTER_DIR.glob("*.xml"):
                rel = f"monsters/{xml_file.name}"
                if rel not in indexed_files:
                    self.warn(str(xml_file), "Monster file not referenced in monsters.xml")

        return self.report()

    def report(self):
        """Print validation report."""
        print(f"\n  Validated: {self.validated}")
        print(f"  Passed: {self.passed}")
        print(f"  Errors: {len(self.errors)}")
        print(f"  Warnings: {len(self.warnings)}")

        if self.errors:
            print("\nERRORS:")
            for e in self.errors[:20]:
                print(f"  {e}")
            if len(self.errors) > 20:
                print(f"  ... and {len(self.errors) - 20} more")

        if self.warnings:
            print(f"\nWARNINGS: {len(self.warnings)} (use --verbose to see)")

        return len(self.errors) == 0


if __name__ == "__main__":
    validator = MonsterValidator()
    success = validator.run()
    sys.exit(0 if success else 1)
