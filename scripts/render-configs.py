#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import json
from pathlib import Path


def load_json(path: Path) -> dict:
    return json.loads(path.read_text())


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def install_manifest_assets(root: Path, manifest_rel: str, assets_rel: str, home_dir: Path, subdir_key: str, target: str) -> None:
    manifest = load_json(root / manifest_rel)
    target_meta = load_json(root / "manifest" / "targets" / f"{target}.json")
    target_root = home_dir / target_meta["homeSubdir"]
    destination_dir = target_root / target_meta[subdir_key]
    ensure_dir(destination_dir)

    shared_dir = root / "assets" / "shared" / assets_rel
    target_dir = root / "assets" / target / assets_rel

    key = assets_rel
    for entry in manifest[key]:
        if target not in entry["targets"]:
            continue

        target_path = target_dir / entry["path"]
        if target_path.exists():
            source_path = target_path
        else:
            source_name = entry["source"]
            source_root = shared_dir if source_name == "shared" else target_dir
            source_path = source_root / entry["path"]
        if not source_path.exists():
            continue

        destination_path = destination_dir / entry["path"]
        ensure_dir(destination_path.parent)
        if source_path.is_dir():
            if destination_path.exists():
                shutil.rmtree(destination_path)
            shutil.copytree(source_path, destination_path)
        else:
            shutil.copy2(source_path, destination_path)


def render(root: Path) -> None:
    home_dir = Path.home()
    claude_base = load_json(root / "assets" / "claude" / "settings.base.json")
    claude_dir = home_dir / ".claude"
    ensure_dir(claude_dir)
    claude_path = claude_dir / "settings.json"
    if claude_path.exists():
        try:
            existing = load_json(claude_path)
        except json.JSONDecodeError:
            existing = claude_base
        claude_path.write_text(json.dumps(existing, indent=2) + "\n")
    else:
        claude_path.write_text(json.dumps(claude_base, indent=2) + "\n")

    opencode_base = load_json(root / "assets" / "opencode" / "opencode.base.json")
    opencode_dir = home_dir / ".config" / "opencode"
    ensure_dir(opencode_dir)
    opencode_path = opencode_dir / "opencode.json"
    if opencode_path.exists():
        try:
            existing = load_json(opencode_path)
        except json.JSONDecodeError:
            existing = opencode_base
        existing.setdefault("$schema", opencode_base["$schema"])
        opencode_path.write_text(json.dumps(existing, indent=2) + "\n")
    else:
        opencode_path.write_text(json.dumps(opencode_base, indent=2) + "\n")

    install_manifest_assets(root, "manifest/commands/commands.manifest.json", "commands", home_dir, "commandsDir", "claude")
    install_manifest_assets(root, "manifest/commands/commands.manifest.json", "commands", home_dir, "commandsDir", "opencode")
    install_manifest_assets(root, "manifest/agents/agents.manifest.json", "agents", home_dir, "agentsDir", "claude")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    args = parser.parse_args()
    render(Path(args.root))


if __name__ == "__main__":
    main()
