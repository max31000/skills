#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


SUPPORTED_TARGETS = {
    "compound-bunx": {"opencode", "copilot", "codex", "droid", "pi", "gemini", "kiro", "openclaw", "windsurf", "qwen", "all"},
    "manual-plugin": set(),
}

# Targets that support the --scope flag in compound-plugin
SCOPE_SUPPORTED_TARGETS = {"claude", "all"}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text())


def status(kind: str, message: str) -> None:
    print(f"[{kind}] {message}")


def check_network() -> bool:
    try:
        subprocess.run(
            [sys.executable, "-c", "import socket; socket.create_connection(('github.com', 443), 3).close()"],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except Exception:
        return False


def expand_verify_paths(paths: list[str], home: Path) -> list[Path]:
    return [Path(str(path).replace("${HOME}", str(home)).replace("~", str(home))) for path in paths]


# compound-plugin writes skill directories named "ce:<skill>" which contain a
# colon — a character that is illegal in Windows paths.  Until upstream fixes
# this, skip compound-bunx installs on Windows.
COMPOUND_BUNX_WINDOWS_BLOCKED = sys.platform.startswith("win")


def preflight(plugin: dict, home: Path) -> tuple[bool, list[str]]:
    errors: list[str] = []
    for binary in plugin.get("requiredBinaries", []):
        if shutil.which(binary) is None:
            errors.append(f"missing binary: {binary}")

    if plugin.get("requiresNetwork") and not check_network():
        errors.append("network check failed")

    method = str(plugin.get("installMethod", ""))

    if method == "compound-bunx" and COMPOUND_BUNX_WINDOWS_BLOCKED:
        errors.append(
            "compound-bunx is not supported on Windows: plugin writes directories "
            "with ':' in the name (e.g. 'ce:brainstorm') which is illegal on Windows paths"
        )
        return (False, errors)

    supported = SUPPORTED_TARGETS.get(method, set())
    for target in plugin.get("targets", []):
        if supported and target not in supported:
            errors.append(f"unsupported target for {method}: {target}")

    for path in expand_verify_paths(plugin.get("verifyPaths", []), home):
        parent = path.parent
        if not parent.exists():
            errors.append(f"verify parent path missing: {parent}")

    return (len(errors) == 0, errors)


def run_compound(plugin: dict) -> None:
    mode = plugin.get("mode", "install")
    plugin_id = plugin["pluginId"]
    for target in plugin.get("targets", []):
        if mode in {"install", "install+sync"}:
            cmd = ["bunx", "@every-env/compound-plugin", "install", plugin_id, "--to", target]
            if plugin.get("scope") and target in SCOPE_SUPPORTED_TARGETS:
                cmd.extend(["--scope", plugin["scope"]])
            status("RUN", " ".join(cmd))
            subprocess.run(cmd, check=True)
        if mode in {"sync", "install+sync"}:
            cmd = ["bunx", "@every-env/compound-plugin", "sync", "--target", target]
            status("RUN", " ".join(cmd))
            subprocess.run(cmd, check=True)


def verify_plugin(plugin: dict, home: Path) -> bool:
    ok = True
    for path in expand_verify_paths(plugin.get("verifyPaths", []), home):
        if path.exists():
            status("OK", f"verified {path}")
        else:
            status("WARN", f"missing expected path {path}")
            ok = False
    return ok


def process_manifest(manifest_path: Path, home: Path, dry_run: bool) -> int:
    manifest = load_json(manifest_path)
    exit_code = 0
    for plugin in manifest.get("plugins", []):
        if not plugin.get("enabled"):
            status("SKIP", f"plugin {plugin['id']}: disabled")
            continue

        allowed, errors = preflight(plugin, home)
        if not allowed:
            for error in errors:
                status("WARN", f"plugin {plugin['id']}: {error}")
            if plugin.get("required", False):
                exit_code = 1
            else:
                status("SKIP", f"plugin {plugin['id']}: optional plugin skipped due to preflight failure")
            continue

        method = plugin.get("installMethod")
        if dry_run:
            status("DRYRUN", f"plugin {plugin['id']} via {method}")
        else:
            try:
                if method == "compound-bunx":
                    run_compound(plugin)
                elif method == "manual-plugin":
                    status("MANUAL", f"plugin {plugin['id']}: {plugin.get('notes', '')}")
                else:
                    status("WARN", f"plugin {plugin['id']}: unknown install method {method}")
                    exit_code = 1
                    continue
            except subprocess.CalledProcessError as exc:
                status("WARN", f"plugin {plugin['id']}: command failed with exit code {exc.returncode}")
                exit_code = 1
                continue

        if not verify_plugin(plugin, home):
            exit_code = 1
    return exit_code


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--home", default=str(Path.home()))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    raise SystemExit(process_manifest(Path(args.manifest), Path(args.home), args.dry_run))


if __name__ == "__main__":
    main()
