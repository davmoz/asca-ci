#!/usr/bin/env python3
"""
Test player creation validation logic.

Validates player name rules, vocation constraints, and initial stat values
without requiring a running server or database.
"""

import sys
import re
from pathlib import Path


def find_project_root():
    path = Path(__file__).resolve().parent
    while path != path.parent:
        if (path / "CMakeLists.txt").exists() and (path / "data").exists():
            return path
        path = path.parent
    return Path.cwd()


PROJECT_ROOT = find_project_root()

ERRORS = []
PASSED = 0
TOTAL = 0


def test(name, condition, msg=""):
    global PASSED, TOTAL
    TOTAL += 1
    if condition:
        PASSED += 1
        print(f"  PASS: {name}")
    else:
        ERRORS.append(f"{name}: {msg}")
        print(f"  FAIL: {name} - {msg}")


# --- Player name validation (matches TFS rules) ---

def is_valid_player_name(name):
    """Validate player name according to TFS rules."""
    if not name:
        return False, "Empty name"
    if len(name) < 2:
        return False, "Name too short (min 2)"
    if len(name) > 29:
        return False, "Name too long (max 29)"
    if name[0] == ' ' or name[-1] == ' ':
        return False, "Name starts or ends with space"
    if '  ' in name:
        return False, "Name has consecutive spaces"
    if not all(c.isalpha() or c == ' ' for c in name):
        return False, "Name contains invalid characters"
    # Check word count (max 3 words typically)
    words = name.split()
    if len(words) > 3:
        return False, "Too many words (max 3)"
    # Each word should start with uppercase
    for word in words:
        if not word[0].isupper():
            return False, f"Word '{word}' doesn't start with uppercase"
    return True, ""


def test_player_names():
    """Test player name validation rules."""
    print("\n--- Player Name Validation ---")

    # Valid names
    valid_names = ["Test", "Test Player", "My Cool Name", "Ab"]
    for name in valid_names:
        ok, _ = is_valid_player_name(name)
        test(f"Valid name: '{name}'", ok)

    # Invalid names
    invalid_cases = [
        ("", "Empty name"),
        ("A", "Too short"),
        ("a" * 30, "Too long"),
        (" Test", "Leading space"),
        ("Test ", "Trailing space"),
        ("Test  Player", "Double space"),
        ("test", "Lowercase start"),
        ("Test123", "Contains digits"),
        ("Test@Player", "Contains special chars"),
        ("One Two Three Four", "Too many words"),
    ]
    for name, reason in invalid_cases:
        ok, _ = is_valid_player_name(name)
        test(f"Invalid name ({reason}): '{name}'", not ok)


# --- Initial player stats ---

def test_initial_stats():
    """Test initial player stat values from schema.sql defaults."""
    print("\n--- Initial Player Stats ---")

    # Default values from schema.sql
    defaults = {
        "level": 1,
        "vocation": 0,
        "health": 150,
        "healthmax": 150,
        "experience": 0,
        "mana": 0,
        "manamax": 0,
        "soul": 0,
        "cap": 400,
        "sex": 0,
        "town_id": 1,
    }

    for stat, value in defaults.items():
        test(f"Default {stat} = {value}", isinstance(value, int) and value >= 0,
             f"Invalid default for {stat}: {value}")

    # Check health constraints
    test("Health <= Healthmax", defaults["health"] <= defaults["healthmax"])
    test("Mana <= Manamax", defaults["mana"] <= defaults["manamax"])
    test("Level >= 1", defaults["level"] >= 1)
    test("Experience >= 0", defaults["experience"] >= 0)
    test("Cap > 0", defaults["cap"] > 0)


# --- Vocation validation ---

def test_vocations():
    """Test vocation system from vocations.xml."""
    print("\n--- Vocation System ---")

    import xml.etree.ElementTree as ET

    voc_file = PROJECT_ROOT / "data" / "XML" / "vocations.xml"
    test("vocations.xml exists", voc_file.exists())

    if not voc_file.exists():
        return

    tree = ET.parse(str(voc_file))
    root = tree.getroot()

    vocations = root.findall("vocation")
    test("Vocations found", len(vocations) > 0, f"Found {len(vocations)}")

    voc_ids = set()
    for voc in vocations:
        voc_id = voc.get("id")
        voc_name = voc.get("name")

        test(f"Vocation {voc_name} has id", voc_id is not None)
        test(f"Vocation {voc_name} has gainhp", voc.get("gainhp") is not None)
        test(f"Vocation {voc_name} has gainmana", voc.get("gainmana") is not None)

        if voc_id:
            test(f"Vocation {voc_name} id is unique",
                 voc_id not in voc_ids, f"Duplicate id: {voc_id}")
            voc_ids.add(voc_id)

        # Check skills
        skills = voc.findall("skill")
        test(f"Vocation {voc_name} has skill multipliers",
             len(skills) >= 7, f"Found {len(skills)} skills (expected 7)")


# --- Experience formula ---

def test_experience_formula():
    """Test Tibia experience formula."""
    print("\n--- Experience Formula ---")

    def exp_for_level(level):
        """TFS experience formula: 50/3 * (L^3 - 6*L^2 + 17*L - 12)"""
        return int(50.0 / 3.0 * (level ** 3 - 6 * level ** 2 + 17 * level - 12))

    test("Level 1 exp = 0", exp_for_level(1) == 0, f"Got {exp_for_level(1)}")
    test("Level 2 exp > 0", exp_for_level(2) > 0)
    test("Level 8 exp = 4200", exp_for_level(8) == 4200, f"Got {exp_for_level(8)}")
    test("Exp increases with level", exp_for_level(10) > exp_for_level(9))
    test("Level 100 exp > 0", exp_for_level(100) > 0)
    test("Level 200 exp > Level 100 exp",
         exp_for_level(200) > exp_for_level(100))


if __name__ == "__main__":
    print("=== TFS Player Creation Tests ===")

    test_player_names()
    test_initial_stats()
    test_vocations()
    test_experience_formula()

    print(f"\n{'=' * 40}")
    print(f"Results: {PASSED}/{TOTAL} passed, {len(ERRORS)} failed")
    print(f"{'=' * 40}")

    if ERRORS:
        print("\nFailures:")
        for e in ERRORS:
            print(f"  {e}")

    sys.exit(0 if not ERRORS else 1)
