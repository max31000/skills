---
name: colony-sim
description: >
  Guides architecture and technical implementation of strategy and simulation
  games. Use when designing or implementing game mechanics for strategy,
  simulation, colony sim, city builder, factory game, RTS, tycoon, or mentions
  "strategy game", "simulation", "colony sim", "city builder", "production chain",
  "factory", "RTS", "tycoon", "game architecture", "game systems", "entity system",
  "tick system", "deterministic simulation".
---

# Strategy & Simulation Game Architecture

Engine-agnostic technical patterns for designing and implementing strategy and simulation games. Covers architectural decisions, common mechanic implementations, performance patterns, and pitfalls. Based on proven approaches from Factorio, RimWorld, Cities: Skylines, Oxygen Not Included, Dwarf Fortress.

## Instructions

### Step 1: Decouple Simulation from Rendering

**Always separate simulation state from rendering.** This is the single most important architectural decision.

- Simulation layer: pure logic, no engine imports, deterministic. Advances in fixed-timestep ticks.
- Rendering layer: reads simulation state, interpolates between ticks for smooth visuals. Runs at variable framerate.
- Communication: simulation emits events / observer notifications → rendering subscribes and updates visuals.
- Never let rendering code modify simulation state. Never let simulation code call rendering APIs.

Benefits: testable logic, deterministic replays, multiplayer-ready, engine migration possible.

### Step 2: Use Tick-Based Simulation

Use fixed-timestep ticks, not frame-based updates.

- Simulation advances in discrete steps (e.g. 20 ticks/sec = 50ms per tick).
- Rendering interpolates between tick states for smooth display at any framerate.
- All systems process in deterministic order within each tick.
- **Tick budget:** with thousands of entities, all simulation must complete within the tick window.

**System tick frequency** — not all systems need to run every tick:
- Physics/movement: every tick
- Production/economy: every 2–5 ticks
- Pathfinding: on-demand + cached
- AI decisions: every 10–30 ticks
- Atmosphere/diffusion: every 10+ ticks

### Step 3: Choose Entity Architecture (Composition over Inheritance)

Deep class hierarchies break down in strategy games. Use composition.

**Component Pattern (RimWorld ThingComp):**
- Entity = ID + list of components. Behavior emerges from component combination.
- **CompProps** — immutable config data (from JSON/XML). **Comp** — runtime state + behavior with lifecycle: `OnAttached()`, `Tick(dt, context)`.
- **Registry/Factory** — maps type name → constructor. Adding new behavior = new Comp class + config entry. Core code unchanged.
- Best for games with rich per-entity behavior (colony sims, tycoons).

**ECS (Entity Component System):**
- Entities are IDs. Components are pure data structs. Systems are stateless logic on component queries.
- Cache-friendly SoA storage. Best for massive homogeneous entity groups (RTS, large-scale sims).
- Trade-off: more boilerplate, harder to debug individual entity behavior.

### Step 4: Make All Content Data-Driven

**All game content in external config files (JSON, XML, YAML). Never hardcode mechanics.**

- Recipes, buildings, units, resources, tech trees — all defined in data.
- Dedicated Loader classes parse configs into immutable data objects at startup.
- Adding content = new config entry. No code changes, no recompilation.
- Schema validation on load: reject invalid configs early with clear error messages.
- Separate files per domain: `buildings.json`, `recipes.json`, `units.json`, `tech_tree.json`.

This pattern directly enables modding (RimWorld, Factorio, Stellaris all use it).

### Step 5: Implement Common Mechanics

**Production / Crafting:**
- Recipe = `inputs[]` → `outputs[]` + `cycle_time` + `conditions[]`.
- State machine: Idle → WaitingForInput → Running → WaitingForOutput → Complete → Idle.
- **Back-pressure:** output buffer full → production pauses. Creates visible bottlenecks.
- Factorio insight: treat sequences of identical processors as single unit for performance.

**Resource Networks / Flow:**
- Connected entities share a resource pool. Connectivity via BFS/flood-fill on topology changes only.
- Continuous resources (power, fluid): float, network-wide. Discrete resources (items): int, physically transported.
- Factorio Fluids 2.0: realistic fluid physics doesn't scale — use network-like propagation.

**Agent AI / Tasks:**
- Centralized task scheduler: assign agents by priority × inverse distance.
- Reservation system: agent claims target exclusively, others skip it.
- Behavior trees for complex decisions (more scalable than FSMs for multi-factor AI).
- Needs/utility system: multiple needs with continuous depletion affecting behavior.

**Pathfinding:**
- Custom A* preferred for grid/tile games. Region system (~16×16 regions) with BFS for long paths.
- Reachability cache for quick connectivity checks. Rebuild nav data only on topology changes.

**Grid / Tiles:**
- Grid granularity defines gameplay scale (~1m survival, ~30m city builder).
- Separate grid data from visuals. Chunk-based loading for large worlds.

**Save / Load:**
- Serialize only pure data (IDs, states, numbers). Rebuild derived data on load.
- Version field in save header with migration functions. Roundtrip test: save → load → save → compare.

### Step 6: Apply Performance Patterns

**Data-Oriented Design:** SoA for hot data. Profile first — O(N²) is the #1 performance killer.

**Spatial Partitioning:** Grid cells for uniform entities, quadtrees for variable-size. Essential at 100+ entities.

**Rendering:** GPU instancing for identical objects, LOD for distance, culling for off-screen, object pooling for transient objects.

**System-Level:** Stagger heavy systems across frames. Amortize expensive operations. Factorio multithreading: up to 14.9x on isolated systems.

### Step 7: Ensure Determinism (if multiplayer/replay needed)

- **Seeded PRNG:** shared seed, identical call order.
- **Fixed-point math** or controlled floats to avoid cross-platform divergence.
- **Input-only networking:** transmit commands, not state. Bandwidth scales with players, not entities.
- **Desync detection:** periodic state checksums across clients.
- **Replay for free:** record inputs + seed → reconstruct any state.

### Step 8: Decouple Systems with Events

- Subject emits event (e.g. `BuildingDestroyed`). Doesn't know who listens.
- Observers subscribe to events they care about. No coupling between observers.
- **Event queue** for deterministic processing: ordered, processed in tick order.
- Prefer language-native events over engine signals for simulation logic.

## Examples

### Example 1: Designing a Production Chain

**User:** "Implement iron smelting: ore → iron ingots in a furnace"

**Actions:**
1. Define recipe in `recipes.json`: `{ inputs: [{ore: 2}], outputs: [{iron_ingot: 1}], cycle_time: 5.0 }`.
2. Create `ProductionComp` with state machine (Idle/Running/WaitingForInput/Complete).
3. Attach comp to "furnace" building definition in `buildings.json`.
4. Production ticks: check input buffer → consume → wait cycle_time → produce → check output buffer.

**Result:** New recipe added with zero code changes. Back-pressure works automatically.

### Example 2: Adding Agent Task Type

**User:** "Workers should haul items from production buildings to warehouses"

**Actions:**
1. Create `HaulTask` with source, destination, resource type, amount.
2. Register in TaskScheduler with priority and distance weighting.
3. Task flow: claim source items (reservation) → pathfind to source → pick up → pathfind to destination → deposit.
4. On failure (path blocked, source empty): release reservation, return task to pool.

**Result:** Hauling integrates with existing scheduler. Reservation prevents double-hauling.

### Example 3: Optimizing Entity Updates at Scale

**User:** "Game slows down with 2000+ buildings on the map"

**Actions:**
1. Profile: identify which system takes most time per tick.
2. If O(N²) pair-checks: add spatial partitioning (grid cells or quadtree).
3. If all buildings tick every frame: distribute — production every 5 ticks, atmosphere every 10.
4. If rendering: switch to GPU instancing (MultiMesh or equivalent).
5. Amortize connectivity: recalc 50 buildings/tick, not all 2000.

**Result:** Tick time drops below budget. Game runs smoothly at target tick rate.

## Anti-Patterns to Avoid

- **God objects:** single class managing production + storage + rendering + UI. Split into focused systems.
- **Hardcoded content:** recipes/units in code instead of config. Blocks iteration and modding.
- **Simulation in rendering:** game logic in `_Process()`/`Update()` tied to framerate.
- **O(N²) without profiling:** fast for 10 entities, dies at 1000. Always profile.
- **Premature optimization:** optimizing without profiling produces unreadable code with no measurable gain.
- **Singleton abuse:** global mutable state makes testing impossible and hides dependencies.
- **Deep inheritance:** `Unit → MilitaryUnit → RangedUnit → Archer → ElvenArcher`. Use composition.
- **Tight coupling:** physics calling UI directly. Use events/observer for decoupling.

## Troubleshooting

**Problem:** Simulation behaves differently on different machines (desync in multiplayer)
**Why:** Floating-point operations produce different results across CPUs/compilers.
**Fix:** Use fixed-point math or strictly controlled float operations. Verify with periodic state checksums.

**Problem:** Adding a new building type requires changes in 5+ files
**Why:** Behaviors are hardcoded in class hierarchy instead of composed from config.
**Fix:** Refactor to component pattern: building = config entry + list of comps. New building = new JSON entry.

**Problem:** Save files break after code changes
**Why:** No versioning in save format, or engine object references serialized.
**Fix:** Add version field to save header. Serialize only pure data (IDs, states, numbers). Write migration functions between versions.

## Modding-Friendly Architecture Checklist

- [ ] All content in external data files (JSON/XML), not in code
- [ ] Component system allows adding behaviors without core changes
- [ ] Registry/factory for entity creation from config
- [ ] Event system allows hooking into lifecycle without modifying core
- [ ] Clear separation: engine layer / game logic layer / content layer
- [ ] Config schemas documented
