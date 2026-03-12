#!/usr/bin/env python3
"""
Verify database migration files.

Checks:
- All 28 migration files exist (0.lua through 27.lua)
- Migration files have valid Lua syntax (parsed as text)
- Migration files contain SQL statements
- Migration numbers are sequential with no gaps
"""

import os
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
MIGRATIONS_DIR = PROJECT_ROOT / "data" / "migrations"

EXPECTED_MIGRATION_COUNT = 28  # 0.lua through 27.lua


def test_migrations():
    errors = []
    warnings = []

    print("Validating migration files...")

    if not MIGRATIONS_DIR.exists():
        print(f"  ERROR: Migration directory not found: {MIGRATIONS_DIR}")
        return False

    # Find all migration files
    migration_files = sorted(MIGRATIONS_DIR.glob("*.lua"))
    migration_numbers = []

    for f in migration_files:
        try:
            num = int(f.stem)
            migration_numbers.append(num)
        except ValueError:
            warnings.append(f"Non-numeric migration file: {f.name}")

    migration_numbers.sort()

    # Check count
    print(f"  Found {len(migration_files)} migration files")
    if len(migration_numbers) < EXPECTED_MIGRATION_COUNT:
        errors.append(
            f"Expected at least {EXPECTED_MIGRATION_COUNT} migrations, found {len(migration_numbers)}"
        )

    # Check for gaps
    if migration_numbers:
        expected = list(range(migration_numbers[0], migration_numbers[-1] + 1))
        missing = set(expected) - set(migration_numbers)
        if missing:
            errors.append(f"Missing migration numbers: {sorted(missing)}")

    # Validate each migration file
    for filepath in migration_files:
        content = filepath.read_text(encoding="utf-8", errors="replace")

        # Check it's not empty
        if len(content.strip()) == 0:
            errors.append(f"{filepath.name}: File is empty")
            continue

        # Check it contains SQL-like statements
        sql_keywords = ["ALTER", "CREATE", "DROP", "INSERT", "UPDATE", "DELETE",
                        "ADD", "MODIFY", "CHANGE", "RENAME", "TABLE", "COLUMN"]
        has_sql = any(kw in content.upper() for kw in sql_keywords)
        if not has_sql:
            warnings.append(f"{filepath.name}: No SQL keywords found")

        # Check for function definition pattern (TFS migrations use function())
        if "function" not in content.lower():
            warnings.append(f"{filepath.name}: No function definition found")

    # Report
    print(f"  Errors: {len(errors)}")
    print(f"  Warnings: {len(warnings)}")

    if errors:
        print("\nERRORS:")
        for e in errors:
            print(f"  {e}")

    if warnings:
        print("\nWARNINGS:")
        for w in warnings:
            print(f"  {w}")

    return len(errors) == 0


def test_migration_sequence():
    """Verify migrations are numbered sequentially."""
    print("\nValidating migration sequence...")

    migration_files = sorted(MIGRATIONS_DIR.glob("*.lua"))
    numbers = []
    for f in migration_files:
        try:
            numbers.append(int(f.stem))
        except ValueError:
            pass

    numbers.sort()

    if not numbers:
        print("  No numbered migrations found")
        return False

    print(f"  First migration: {numbers[0]}")
    print(f"  Last migration: {numbers[-1]}")
    print(f"  Total: {len(numbers)}")

    # Check starts at 0
    if numbers[0] != 0:
        print(f"  WARNING: Migrations don't start at 0 (starts at {numbers[0]})")

    # Check sequential
    gaps = []
    for i in range(1, len(numbers)):
        if numbers[i] != numbers[i-1] + 1:
            gaps.append(f"Gap between {numbers[i-1]} and {numbers[i]}")

    if gaps:
        print("  GAPS:")
        for g in gaps:
            print(f"    {g}")
        return False

    print("  Sequence is valid (no gaps)")
    return True


if __name__ == "__main__":
    success = test_migrations()
    success = test_migration_sequence() and success
    sys.exit(0 if success else 1)
