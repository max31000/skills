#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


PACKAGE_NAME_MAPPINGS = {
    ("brew", "python@3.12"): "python",
    ("brew", "dotnet"): "dotnet",
    ("winget", "Git.Git"): "git",
    ("winget", "jqlang.jq"): "jq",
    ("winget", "BurntSushi.ripgrep.MSVC"): "ripgrep",
    ("winget", "sharkdp.fd"): "fd",
    ("winget", "GitHub.cli"): "gh",
    ("winget", "Python.Python.3.12"): "python",
    ("winget", "jdx.mise"): "mise",
    ("winget", "Oven-sh.Bun"): "bun",
    ("winget", "OpenJS.NodeJS.LTS"): "node",
    ("winget", "GoLang.Go"): "go",
    ("winget", "Microsoft.DotNet.SDK.8"): "dotnet",
}

WINGET_IDS_BY_CANONICAL = {
    "git": "Git.Git",
    "jq": "jqlang.jq",
    "ripgrep": "BurntSushi.ripgrep.MSVC",
    "fd": "sharkdp.fd",
    "gh": "GitHub.cli",
    "python": "Python.Python.3.12",
    "mise": "jdx.mise",
    "bun": "Oven-sh.Bun",
    "node": "OpenJS.NodeJS.LTS",
    "go": "GoLang.Go",
    "dotnet": "Microsoft.DotNet.SDK.8",
}


def normalize_truthy_env(value: str) -> bool:
    return value.lower() in {"1", "true", "yes"}


def resolve_overwrite_mode(explicit_overwrite: bool, env_value: str, noninteractive: bool) -> str:
    if explicit_overwrite:
        return "overwrite"
    if normalize_truthy_env(env_value):
        return "overwrite"
    if noninteractive:
        return "skip"
    return "prompt"


def overwrite_usage_examples() -> list[str]:
    return [
        "bash bootstrap.sh --overwrite-skills",
        "bash install-skills.sh --overwrite",
        "powershell -ExecutionPolicy Bypass -File bootstrap.ps1 -OverwriteSkills",
        "powershell -ExecutionPolicy Bypass -File install-skills.ps1 -Overwrite",
    ]


def referenced_runtime_paths() -> set[str]:
    return {
        "bootstrap.sh",
        "bootstrap.ps1",
        "install-skills.sh",
        "install-skills.ps1",
        "scripts/bootstrap.sh",
        "scripts/bootstrap.ps1",
        "scripts/install-skills.sh",
        "scripts/install-skills.ps1",
    }


def load_dependency_policy(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_package_name(manager: str, raw_name: str) -> str:
    return PACKAGE_NAME_MAPPINGS.get((manager, raw_name), raw_name)


def classify_action(item: dict) -> str:
    if not item["installed"]:
        return "install"
    if item["outdated"]:
        return "update"
    return "skip"


def classify_status(required_now: bool, returncode: int) -> str:
    if returncode == 0:
        return "ok"
    return "fail" if required_now else "warn"


def build_phase_summary(label: str, items: list[dict]) -> str:
    counts = {"skip": 0, "install": 0, "update": 0, "warn": 0}
    for item in items:
        action = item["action"]
        counts[action] = counts.get(action, 0) + 1
    return (
        f"{label}: {counts['skip']} skip, {counts['install']} install, "
        f"{counts['update']} update, {counts['warn']} warn"
    )


def phase_requires_stop(results: list[dict]) -> bool:
    return any(item.get("required_now") and item.get("status") == "fail" for item in results)


def plan_package_actions(packages: list[dict]) -> list[dict]:
    planned = []
    for package in packages:
        item = dict(package)
        item["action"] = classify_action(package)
        planned.append(item)
    return planned


def plan_tool_actions(tools: list[dict]) -> list[dict]:
    planned = []
    for tool in tools:
        item = dict(tool)
        item["action"] = classify_action(tool)
        planned.append(item)
    return planned


def summarize_results(results: list[dict]) -> dict:
    warnings = 0
    failures = 0
    for item in results:
        status = item.get("status")
        if status == "fail" and item.get("required_now"):
            failures += 1
        elif status in {"warn", "fail"}:
            warnings += 1
    return {"warnings": warnings, "failures": failures}


def tool_version_satisfies(installed: str, requested: str) -> bool:
    if requested in {"latest", "lts"}:
        return bool(installed)
    return installed == requested or installed.startswith(f"{requested}.")


def is_brew_package_outdated(name: str, outdated: set[str]) -> bool:
    return name in outdated


def is_winget_package_outdated(package_id: str, upgradeable: set[str]) -> bool:
    return package_id in upgradeable


def build_bootstrap_plan_lines(
    package_summary: str,
    tool_summary: str,
    required_items: list[str],
    log_dir: str,
) -> list[str]:
    return [
        "==> Bootstrap plan",
        package_summary,
        tool_summary,
        f"Required for continuation: {', '.join(required_items)}",
        f"Detailed logs: {log_dir}",
    ]


def build_result_lines(results: list[dict]) -> list[str]:
    lines = []
    for item in results:
        line = f"{item['status']} {item['name']}"
        if item["status"] in {"warn", "fail"}:
            line = f"{line} -> see {item['log_file']}"
        lines.append(line)
    return lines


def parse_brewfile(path: Path) -> list[str]:
    formulas = []
    pattern = re.compile(r'^\s*brew\s+"([^"]+)"')
    for line in path.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if match:
            formulas.append(match.group(1))
    return formulas


def parse_mise_toml(path: Path) -> dict[str, str]:
    tools: dict[str, str] = {}
    in_tools = False
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            in_tools = line == "[tools]"
            continue
        if not in_tools or "=" not in line:
            continue
        key, value = line.split("=", 1)
        tools[key.strip()] = value.strip().strip('"')
    return tools


def parse_winget_manifest(path: Path) -> list[str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return [entry["id"] for entry in data.get("packages", [])]


def run_command(command: list[str], log_file: Path) -> tuple[int, str]:
    log_file.parent.mkdir(parents=True, exist_ok=True)
    with log_file.open("w", encoding="utf-8") as handle:
        process = subprocess.run(command, stdout=handle, stderr=subprocess.STDOUT, text=True, check=False)
    output = log_file.read_text(encoding="utf-8") if log_file.exists() else ""
    return process.returncode, output


def command_output(command: list[str]) -> str:
    process = subprocess.run(command, capture_output=True, text=True, check=False)
    if process.returncode != 0:
        return ""
    return process.stdout


def build_package_items(root: Path, policy: dict) -> list[dict]:
    items: list[dict] = []
    if sys.platform == "darwin":
        brewfile = root / "manifest" / "packages" / "Brewfile"
        packages = parse_brewfile(brewfile)
        installed = set(command_output(["brew", "list", "--formula"]).split()) if shutil_which("brew") else set()
        outdated = set(command_output(["brew", "outdated", "--formula"]).split()) if shutil_which("brew") else set()
        for raw_name in packages:
            canonical = normalize_package_name("brew", raw_name)
            items.append(
                {
                    "name": canonical,
                    "display_name": raw_name,
                    "manager": "brew",
                    "required_now": policy["packages"].get(canonical, {}).get("required_now", False),
                    "installed": raw_name in installed,
                    "outdated": is_brew_package_outdated(raw_name, outdated),
                }
            )
    elif sys.platform.startswith("win"):
        manifest = root / "manifest" / "packages" / "winget-packages.json"
        package_ids = parse_winget_manifest(manifest)
        for package_id in package_ids:
            canonical = normalize_package_name("winget", package_id)
            items.append(
                {
                    "name": canonical,
                    "display_name": package_id,
                    "manager": "winget",
                    "required_now": policy["packages"].get(canonical, {}).get("required_now", False),
                    "installed": False,
                    "outdated": False,
                }
            )
    return items


def build_tool_items(root: Path, policy: dict) -> list[dict]:
    items: list[dict] = []
    mise_toml = root / "manifest" / "tools" / "mise.toml"
    requested = parse_mise_toml(mise_toml)
    current_output = command_output(["mise", "ls", "--json", "--cd", str(mise_toml.parent)]) if shutil_which("mise") else "{}"
    current = json.loads(current_output or "{}")
    for name, requested_version in requested.items():
        entries = current.get(name, [])
        active_entry = next((entry for entry in entries if entry.get("active") or entry.get("installed")), None)
        installed_version = active_entry.get("version", "") if active_entry else ""
        installed = bool(active_entry and active_entry.get("installed", False))
        items.append(
            {
                "name": name,
                "display_name": name,
                "manager": "mise",
                "required_now": policy["tools"].get(name, {}).get("required_now", False),
                "installed": installed,
                "installed_version": installed_version,
                "requested_version": requested_version,
                "outdated": installed and not tool_version_satisfies(installed_version, requested_version),
            }
        )
    return items


def preflight_payload(root: Path, log_dir: Path) -> dict:
    policy = load_dependency_policy(root / "manifest" / "dependencies" / "bootstrap-priority.json")
    packages = plan_package_actions(build_package_items(root, policy))
    tools = plan_tool_actions(build_tool_items(root, policy))
    warnings = []
    package_summary = build_phase_summary("Packages", packages)
    tool_summary = build_phase_summary("Tools", tools)
    required_items = sorted(
        {
            item["name"]
            for item in packages + tools
            if item.get("required_now")
        }
    )
    lines = build_bootstrap_plan_lines(package_summary, tool_summary, required_items, str(log_dir))
    return {
        "log_dir": str(log_dir),
        "package_summary": package_summary,
        "tool_summary": tool_summary,
        "required_items": required_items,
        "package_items": packages,
        "tool_items": tools,
        "warnings": warnings,
        "failures": [],
        "lines": lines,
    }


def execute_package_install(root: Path, log_dir: Path) -> dict:
    planned = plan_package_actions(build_package_items(root, load_dependency_policy(root / "manifest" / "dependencies" / "bootstrap-priority.json")))
    results = []
    for item in planned:
        action = item["action"]
        log_file = log_dir / f"packages-{item['name']}.log"
        result = {
            "name": item["name"],
            "required_now": item["required_now"],
            "action": action,
            "status": "skip",
            "log_file": str(log_file),
        }
        if action == "skip":
            results.append(result)
            continue
        if item["manager"] == "brew":
            command = ["brew", "install" if action == "install" else "upgrade", item["display_name"]]
        else:
            package_id = WINGET_IDS_BY_CANONICAL.get(item["name"], item["display_name"])
            command = [
                "winget",
                "install" if action == "install" else "upgrade",
                "--id",
                package_id,
                "--accept-source-agreements",
                "--accept-package-agreements",
                "--silent",
                "--disable-interactivity",
            ]
        if not shutil_which(command[0]):
            result["status"] = classify_status(item["required_now"], 1)
            result["message"] = f"{command[0]} not found"
            results.append(result)
            continue
        returncode, _ = run_command(command, log_file)
        result["status"] = classify_status(item["required_now"], returncode)
        results.append(result)
    return build_execution_payload(results)


def execute_tool_install(root: Path, log_dir: Path) -> dict:
    planned = plan_tool_actions(build_tool_items(root, load_dependency_policy(root / "manifest" / "dependencies" / "bootstrap-priority.json")))
    results = []
    for item in planned:
        action = item["action"]
        log_file = log_dir / f"tools-{item['name']}.log"
        result = {
            "name": item["name"],
            "required_now": item["required_now"],
            "action": action,
            "status": "skip",
            "log_file": str(log_file),
        }
        if action == "skip":
            results.append(result)
            continue
        if not shutil_which("mise"):
            result["status"] = classify_status(item["required_now"], 1)
            result["message"] = "mise not found"
            results.append(result)
            continue
        command = ["mise", "install", "--yes", f"{item['name']}@{item['requested_version']}", "--cd", str(root / 'manifest' / 'tools')]
        returncode, _ = run_command(command, log_file)
        result["status"] = classify_status(item["required_now"], returncode)
        results.append(result)
    return build_execution_payload(results)


def build_execution_payload(results: list[dict]) -> dict:
    return {"results": results, "lines": build_result_lines(results), **summarize_results(results)}


def shutil_which(name: str) -> str | None:
    from shutil import which

    return which(name)


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    for name in ("preflight", "install-packages", "install-tools"):
        subparser = subparsers.add_parser(name)
        subparser.add_argument("--root", required=True)
        subparser.add_argument("--log-dir", required=True)

    args = parser.parse_args()
    root = Path(args.root)
    log_dir = Path(args.log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)

    if args.command == "preflight":
        payload = preflight_payload(root, log_dir)
        print(json.dumps(payload))
        return

    if args.command == "install-packages":
        payload = execute_package_install(root, log_dir)
        print(json.dumps(payload))
        raise SystemExit(1 if payload["failures"] else 0)

    payload = execute_tool_install(root, log_dir)
    print(json.dumps(payload))
    raise SystemExit(1 if payload["failures"] else 0)


if __name__ == "__main__":
    main()
