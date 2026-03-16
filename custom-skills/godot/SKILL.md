---
name: godot
description: >
  Godot Engine game development. Use when working with Godot, GDScript,
  C# in Godot, scenes, nodes, signals, physics, animation, or mentions
  "Godot", "GDScript", "gdscript", "scene tree", "node", "signal",
  "autoload", "export", "Godot 4".
---

# Godot Engine

Assist with Godot 4 game development using GDScript and C#.

## Scene & Node Architecture
- Everything is a Node. Scenes are reusable trees of nodes.
- Prefer composition over deep inheritance. Use `extends` sparingly.
- Scene root naming: match the scene file name.
- Use `@export` to expose properties to the Inspector — enables data-driven design.
- Pick the right base: `Node2D` for 2D, `Node3D` for 3D, plain `Node` only for logic.

## GDScript Patterns
```gdscript
# Typed GDScript — always annotate types in Godot 4
var health: int = 100
@export var speed: float = 200.0

# Signal declaration
signal died
signal health_changed(new_value: int)

func take_damage(amount: int) -> void:
    health -= amount
    health_changed.emit(health)
    if health <= 0:
        died.emit()
```

## Signals
- Prefer signals over direct node references for decoupling.
- Connect in `_ready()` or via the editor — not in `_process()`.
- Use typed signals: `signal foo(value: int)`.
- `call_deferred()` when modifying the scene tree from within a signal callback.

## Autoloads (Singletons)
- Use for global state: game settings, audio manager, save system.
- Keep autoloads small — not a dumping ground for everything.
- Access directly by autoload name: `GameManager.do_something()`.

## Physics
- `CharacterBody2D`/`3D` + `move_and_slide()` for player characters.
- `RigidBody` for physics-driven objects.
- Collision layers: plan your layer matrix early and document it.
- Use `_physics_process(delta)` for movement, never `_process()`.

## Performance
- Cache node references in `_ready()` — never call `get_node()` in hot loops.
- `MultiMeshInstance3D` for many identical objects.
- `VisibleOnScreenNotifier` to pause AI/animations when off-screen.
- `@tool` scripts for editor-time computation; avoid heavy `_process()` in tools.

## C# in Godot 4
- `[Export]` attribute instead of `@export`.
- Signals: declare with `[Signal]` delegate, emit via `EmitSignal(SignalName.Foo)`.
- Use Godot lifecycle methods (`_Ready`, `_Process`) — avoid constructor logic.
- NuGet packages are supported; avoid heavy reflection-based libraries.

## Export & Platform
- Set `application/config/name` and version in Project Settings before first export.
- Test on target platform early — especially mobile (touch input, aspect ratio).
- Use `OS.get_name()` for platform-specific code paths.
- Always use Export -> Release for distribution builds.
