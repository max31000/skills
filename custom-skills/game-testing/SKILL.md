---
name: game-testing
description: >
  Guides writing and running tests for game code, especially simulation logic
  in Godot C# projects. Use when asked to write tests, test simulation, unit
  test game logic, or mentions "game testing", "test game", "unit test game",
  "GdUnit", "game QA", "test simulation", "test production", "test pathfinding",
  "write tests for game", "test coverage".
---

# Game Code Testing

Guide for AI agents writing and running tests for game projects, especially Godot 4 C# with simulation/presentation architecture.

## Instructions

### Step 1: Identify What to Test

Focus tests on the **simulation layer** (pure logic, no engine dependency).

**High-Value Targets:**
- **Production logic:** recipe consumes correct inputs, produces correct outputs, pauses when input missing or output full.
- **Resource network:** connectivity after adding/removing buildings, shared storage correctness.
- **Task scheduler:** priority ordering, worker assignment, reservation prevents double-assignment.
- **Needs system:** depletion rates, threshold transitions, productivity multiplier at each zone.
- **Pathfinding:** reachability between two points, path correctness, layer transitions.
- **Component lifecycle:** comp receives OnAttached, Tick updates state correctly.
- **Save/Load roundtrip:** serialize → deserialize → verify all fields match.
- **Config loading:** JSON parsed correctly, missing fields handled, invalid data rejected.

**Skip or Test Separately:**
- Visual rendering (screenshot tests are expensive and brittle).
- Input handling (test through integration or manual play).
- UI layout and styling (verify manually).
- Engine lifecycle timing (_Ready order, signal connections).

### Step 2: Choose Testing Framework

**GdUnit4Net (Primary for Godot C#):**
- VSTest-compatible. Works in Rider, Visual Studio, VS Code.
- **Lightweight mode** (default): tests run without Godot runtime — up to 10x faster.
- `[RequireGodotRuntime]` attribute: opt-in for tests that need engine features.

**xUnit / NUnit (Pure Logic):**
- For simulation layer code with zero Godot dependency.
- Standard .NET test project referencing the simulation assembly.
- Fastest option: runs in any CI without Godot installed.

**Mocking:**
- **LightMock.Generator** — compile-time mock generation (Moq uses runtime reflection, fails in Godot).
- Prefer creating real objects over mocking: if a class is pure data, just instantiate it.

### Step 3: Build Minimal Test Context

Create the smallest possible world state for each test:

```csharp
// Pattern: create only what the test needs
var world = new SimulationWorld();
var building = world.PlaceBuilding(buildingConfig, position);
var comp = building.GetComp<ProductionComp>();

// Tick N times
for (int i = 0; i < 10; i++)
    world.Tick(1.0f);

// Assert one behavior
Assert.Equal(expectedOutput, comp.OutputBuffer.Count);
```

- Create a helper that steps only the systems needed for the test.
- Don't run the full simulation loop if you only need to test one comp.
- Expose `Tick(float dt)` on each system/comp for isolated stepping.
- CompProps can be created directly from test data (no need to load JSON).

### Step 4: Follow Naming and Structure Conventions

**Naming:**
```
[Scenario]_[Condition]_[ExpectedResult]

ProductionComp_WhenInputAvailable_StartsProduction()
TaskScheduler_WhenAllWorkersBusy_QueuesTask()
ResourceNetwork_WhenBuildingRemoved_RecalculatesConnectivity()
```

**Structure:**
- One behavior per test. One reason to fail.
- Setup → Act → Assert, keep it short.
- Factory methods for common test objects (BuildingConfig, Recipe, Worker).
- Realistic but minimal data (2–3 buildings, not 100).

### Step 5: Run Tests and Integrate CI

```bash
# Pure C# tests — no Godot needed
dotnet test MyGame.Tests.csproj

# GdUnit4Net lightweight — same command, VSTest adapter handles it
dotnet test MyGame.GdTests.csproj
```

- Separate test projects: `MyGame.Tests.csproj` referencing `MyGame.csproj`. Don't put tests in the main project.
- GdUnit4Net runtime tests require Godot headless binary in CI — use `[RequireGodotRuntime]` sparingly.

## Examples

### Example 1: Testing Production Logic

**User:** "Write tests for the iron smelting recipe"

**Actions:**
1. Create test with minimal context: world + furnace building + production comp.
2. Add ore to input buffer, tick simulation for cycle_time duration.
3. Assert iron ingots appear in output buffer with correct count.
4. Test edge cases: no input → stays idle; output full → pauses.

**Result:** Four focused tests covering happy path + three failure states.

### Example 2: Testing Save/Load Roundtrip

**User:** "Make sure saving and loading preserves game state"

**Actions:**
1. Create world with buildings, workers, resources, active production.
2. Serialize to bytes/JSON.
3. Deserialize into new world instance.
4. Compare all fields: building positions, comp states, resource counts, worker assignments.
5. Optional: serialize again and byte-compare with first save.

**Result:** Roundtrip test catches missing serialization fields and broken references.

### Example 3: Testing Pathfinding

**User:** "Test that workers can navigate between buildings"

**Actions:**
1. Create test grid with buildings and corridors.
2. Assert: path exists between connected buildings.
3. Assert: path does not exist to disconnected area.
4. Assert: path updates after building/removing corridor.
5. Assert: path goes through gateway nodes when crossing layers.

**Result:** Pathfinding validated without engine — pure grid + A* logic tested in isolation.

## Practical Tips for AI Agents

1. **Read existing tests first.** Match the project's test style and naming before writing new tests.
2. **Don't mock what you can create.** Pure data classes — just instantiate them.
3. **Start with the happy path.** Normal flow first, then edge cases.
4. **Test failure states explicitly:** power off, worker dies mid-task, storage full.
5. **If a test fails — check the test first.** Wrong setup and stale assumptions are common.
6. **Deterministic tests only.** No randomness, no timing-dependent assertions. Seed RNG if needed.
7. **Keep tests fast.** Each test in milliseconds. Mark engine-dependent tests explicitly.
8. **Roundtrip tests for serialization:** save → load → save → compare bytes.

## Troubleshooting

**Error:** `System.Reflection.ReflectionTypeLoadException` when running tests
**Why:** Moq or other reflection-based mocking framework fails in Godot's .NET runtime.
**Fix:** Replace with LightMock.Generator (compile-time mocking). Or avoid mocking — create real objects.

**Error:** Tests pass locally but fail in CI
**Why:** Tests depend on Godot runtime but CI has no Godot installed.
**Fix:** Ensure simulation tests have zero Godot dependency. Mark engine-dependent tests with `[RequireGodotRuntime]` and install Godot headless in CI, or skip them.

**Error:** Test is flaky — passes sometimes, fails sometimes
**Why:** Non-deterministic behavior: unseeded RNG, timing dependency, or shared mutable state between tests.
**Fix:** Seed all RNG. Use fixed timestep. Ensure each test creates its own world instance — no shared state.

**Error:** Test setup is 50 lines, assertion is 1 line
**Why:** No test helpers or factory methods for common objects.
**Fix:** Extract builders: `TestWorld.WithBuilding("furnace").WithResource("ore", 10).Build()`.
