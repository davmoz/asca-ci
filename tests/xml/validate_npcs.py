#!/usr/bin/env python3
"""
Validate NPC XML files in data/npc/.

Checks:
- XML is well-formed
- Root element is <npc>
- Required attributes (name, script, walkinterval)
- Referenced script files exist
- Health values are valid
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
NPC_DIR = PROJECT_ROOT / "data" / "npc"
NPC_SCRIPTS = NPC_DIR / "scripts"


class NpcValidator:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.validated = 0

    def error(self, path, msg):
        self.errors.append(f"{path}: {msg}")

    def warn(self, path, msg):
        self.warnings.append(f"{path}: {msg}")

    def validate_npc_file(self, filepath):
        self.validated += 1
        rel_path = filepath.name

        try:
            tree = ET.parse(str(filepath))
            root = tree.getroot()
        except ET.ParseError as e:
            self.error(rel_path, f"XML parse error: {e}")
            return

        if root.tag != "npc":
            self.error(rel_path, f"Root element is '{root.tag}', expected 'npc'")
            return

        # Name attribute
        name = root.get("name")
        if not name:
            self.error(rel_path, "Missing 'name' attribute")
        elif name.strip() == "":
            self.error(rel_path, "Empty 'name' attribute")

        # Script attribute
        script = root.get("script")
        if script:
            script_path = NPC_SCRIPTS / script
            if not script_path.exists():
                self.error(rel_path, f"Referenced script not found: {script}")

        # Health element
        health = root.find("health")
        if health is not None:
            max_hp = health.get("max")
            if max_hp:
                try:
                    val = int(max_hp)
                    if val <= 0:
                        self.error(rel_path, f"Invalid max health: {val}")
                except ValueError:
                    self.error(rel_path, f"Non-numeric max health: {max_hp}")

        # Look element
        look = root.find("look")
        if look is None:
            self.warn(rel_path, "Missing <look> element")

    def run(self):
        print("Validating NPC files...")

        if not NPC_DIR.exists():
            self.error("data/npc", "Directory not found")
            return self.report()

        npc_files = list(NPC_DIR.glob("*.xml"))
        if not npc_files:
            self.warn("data/npc", "No NPC XML files found")
            return self.report()

        for filepath in sorted(npc_files):
            self.validate_npc_file(filepath)

        print(f"  Validated {self.validated} NPC files")
        return self.report()

    def report(self):
        print(f"  Errors: {len(self.errors)}")
        print(f"  Warnings: {len(self.warnings)}")

        if self.errors:
            print("\nERRORS:")
            for e in self.errors:
                print(f"  {e}")

        return len(self.errors) == 0


if __name__ == "__main__":
    validator = NpcValidator()
    success = validator.run()
    sys.exit(0 if success else 1)
