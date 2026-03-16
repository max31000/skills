---
name: godot
description: >
  Guides Godot 4 C# game development with architecture patterns, conventions,
  and performance tips. Use when working with Godot, C# in Godot, scenes,
  nodes, signals, physics, or mentions "Godot", "Godot 4", "scene tree",
  "node", "signal", "C# Godot", "GDScript", "gdscript", "Godot project",
  "create a game in Godot".
---

# Godot 4 — C# Development

Guidelines for Godot 4 game development with C#.

## Instructions

### Step 1: Establish Simulation / Presentation Split

Separate pure C# domain logic from Godot engine code:

- **Simulation layer** — pure C#, zero `using Godot;`. All game state, systems, data models. Testable without the engine.
- **Presentation layer** — Godot Nodes, input handling, 3D/2D visualization, UI. Depends on simulation, never the reverse.
- Communication: simulation fires **C# events** → presentation subscribes and updates visuals.
- Never call Godot APIs from domain logic. If sim needs to notify presentation, emit a C# event.

### Step 2: Follow C# in Godot 4 Conventions

- Use `[Export]` instead of GDScript's `@export`.
- Lifecycle: `_Ready()`, `_Process(double delta)`, `_PhysicsProcess(double delta)`, `_UnhandledInput(InputEvent)`.
- No constructor logic in Node-derived classes — initialize in `_Ready()`.
- Enable `<Nullable>enable</Nullable>` in .csproj for null safety.
- NuGet packages work; avoid heavy reflection-based libraries (slow in Godot's runtime).

### Step 3: Apply Architecture Principles

- **Composition over inheritance.** Minimal Node subclassing. Attach behavior through components, not deep class hierarchies.
- **Explicit wiring over autoloads.** One root entry point (e.g. Main.cs) creates the scene and connects systems. Avoid autoload singletons as a dumping ground.
- **Small focused systems.** Break god-classes into dedicated systems (PowerGrid, WaterSystem, NavigationGraph, etc.). Each system owns one concern.
- **Event-driven communication.** Use C# events for game logic decoupling. Reserve Godot signals for UI bindings only.
- **Procedural scene construction** where possible — generate nodes/meshes in code rather than maintaining heavy .tscn files.

### Step 4: Use Data-Driven Design

- Store game content in **JSON configs** (buildings, recipes, resources), not in Inspector properties or .tres files.
- Write dedicated **Loader classes** to parse configs into immutable data objects.
- Adding new content = new JSON entry. No code changes required.
- Separate config schemas: one file per domain (buildings, recipes, workstations, world settings).

### Step 5: Avoid Common Pitfalls

- `using Godot;` in domain/simulation layer code.
- Godot signals for game logic (C# events are type-safe and engine-independent).
- Heavy computation in `_Process()` — use tick-based systems with controlled frequency.
- Inspector-coupled design — prefer external JSON configs that can be edited without the editor.
- Monolithic scene files — prefer code-generated scenes for dynamic content.
- God-objects that manage multiple unrelated systems.

### Step 6: Optimize Performance

- **MultiMeshInstance3D** for rendering many identical objects (buildings, trees, items).
- **Custom A* pathfinding** over Godot's built-in NavigationServer for grid-based games — more control, predictable performance.
- **Jolt Physics** as alternative to default physics engine (better performance, determinism).
- Cache node references in `_Ready()` — never `GetNode()` in hot loops.
- `VisibleOnScreenNotifier3D` to skip updates for off-screen entities.
- Distribute system ticks: not every system needs to run every frame.

## Recommended Project Structure

```
ProjectRoot/
├── Simulation/          # Pure C# — zero Godot dependency
│   ├── Buildings/       # Building data, components, registry
│   ├── Workers/         # Worker state, needs, tasks
│   ├── Production/      # Recipes, production lines
│   ├── Navigation/      # Pathfinding, nav graph
│   ├── Events/          # C# event bus
│   └── Systems/         # Dedicated game systems
├── Scripts/             # Godot glue layer
│   ├── Main.cs          # Entry point, scene setup
│   ├── Presenter/       # Visualizers (subscribe to sim events)
│   ├── Inspectors/      # UI panels for inspecting game objects
│   └── UI/              # HUD, menus, overlays
├── Configs/             # JSON data files
└── Assets/              # Textures, models, audio
```

## Examples

### Example 1: Adding a New Building Type

**User:** "Add a water recycler building that converts wastewater into clean water"

**Actions:**
1. Create `WaterRecyclerCompProps` and `WaterRecyclerComp` in `Simulation/Buildings/Comps/`.
2. Register comp in `BuildingCompRegistry`.
3. Add building definition with the comp to `Configs/buildings.json`.
4. If UI inspection needed — add `WaterRecyclerCompInspector` in `Scripts/Inspectors/`.

**Result:** New building works in-game, driven entirely by config. No changes to core systems.

### Example 2: Connecting Simulation to Visuals

**User:** "Show a particle effect when production completes"

**Actions:**
1. Add `ProductionCompleted` event to the C# event bus in `Simulation/Events/`.
2. Fire the event from `ProductionComp.Tick()` when cycle finishes.
3. Create `ProductionVfxVisualizer` in `Scripts/Presenter/` that subscribes and spawns particles.

**Result:** Simulation layer stays pure C#. Visual feedback handled entirely in presentation layer.

## Troubleshooting

**Error:** `Cannot use 'Node' in a non-Godot context`
**Why:** Simulation code has `using Godot;` or references a Node type.
**Fix:** Move the logic to a pure C# class. Pass data via events, not Node references.

**Error:** `ObjectDisposedException` when accessing a node
**Why:** Node was freed but a reference still exists.
**Fix:** Cache references in `_Ready()`, null-check or use `IsInstanceValid()` before access. Unsubscribe events in `_ExitTree()`.

**Error:** Game logic behaves differently at different framerates
**Why:** Logic runs in `_Process()` which depends on framerate.
**Fix:** Move game logic to a tick-based system with fixed timestep. Use `_Process()` only for rendering/interpolation.
