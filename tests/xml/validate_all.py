#!/usr/bin/env python3
"""
Run all XML validators for the TFS project.

Usage: python3 tests/xml/validate_all.py
"""

import sys
import os
from pathlib import Path

# Add test directory to path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from validate_monsters import MonsterValidator
from validate_items import ItemsValidator
from validate_spells import SpellsValidator
from validate_npcs import NpcValidator


def find_project_root():
    path = Path(__file__).resolve().parent
    while path != path.parent:
        if (path / "CMakeLists.txt").exists() and (path / "data").exists():
            return path
        path = path.parent
    return Path.cwd()


def main():
    project_root = find_project_root()
    os.chdir(str(project_root))

    print("=" * 60)
    print("TFS XML Validation Suite")
    print("=" * 60)

    all_passed = True

    # Also validate other XML files
    validators = [
        ("Monsters", MonsterValidator()),
        ("Items", ItemsValidator()),
        ("Spells", SpellsValidator()),
        ("NPCs", NpcValidator()),
    ]

    # Validate additional XML files
    import xml.etree.ElementTree as ET
    extra_xml_files = [
        ("data/XML/vocations.xml", "vocations"),
        ("data/XML/groups.xml", "groups"),
        ("data/XML/outfits.xml", "outfits"),
        ("data/XML/mounts.xml", "mounts"),
        ("data/XML/quests.xml", "quests"),
        ("data/XML/stages.xml", "stages"),
    ]

    for name, validator in validators:
        print(f"\n--- {name} ---")
        passed = validator.run()
        if not passed:
            all_passed = False

    print(f"\n--- Additional XML Files ---")
    for filepath, expected_root in extra_xml_files:
        full_path = project_root / filepath
        if full_path.exists():
            try:
                tree = ET.parse(str(full_path))
                root = tree.getroot()
                if root.tag == expected_root:
                    print(f"  PASS: {filepath}")
                else:
                    print(f"  FAIL: {filepath} - root element is '{root.tag}', expected '{expected_root}'")
                    all_passed = False
            except ET.ParseError as e:
                print(f"  FAIL: {filepath} - {e}")
                all_passed = False
        else:
            print(f"  SKIP: {filepath} - not found")

    print(f"\n{'=' * 60}")
    if all_passed:
        print("ALL XML VALIDATIONS PASSED")
    else:
        print("SOME XML VALIDATIONS FAILED")
    print(f"{'=' * 60}")

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
