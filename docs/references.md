# References

These upstream sources support ViDot's test runner and package decisions.

- [Vitest](https://vitest.dev/) — The outer runner used for candidate-file discovery and reporting while Godot collects and executes tests.
- [Vitest 4.1.10: Custom Pool API](https://github.com/vitest-dev/vitest/blob/v4.1.10/docs/guide/advanced/pool.md#api) — The advanced, experimental `PoolRunnerInitializer` and worker boundary selected for ViDot's thin Node.js adapter, which forwards a file batch to one Godot runner instead of evaluating the tests in Node.js.
- [Vitest 4.1.10: Test Collection](https://github.com/vitest-dev/vitest/blob/v4.1.10/packages/runner/src/collect.ts) — The upstream collection orchestration used as a semantic reference for ViDot's Godot-side collector and compatibility fixtures, not as a Node-side collector in ViDot's runtime.
- [Vitest 4.1.10: Task Utilities](https://github.com/vitest-dev/vitest/blob/v4.1.10/packages/runner/src/utils/tasks.ts) — The upstream recursive failure check reused when ViDot derives a file result from its reported task tree.
- [Godot 4.3: RegEx](https://docs.godotengine.org/en/4.3/classes/class_regex.html) — The PCRE2-backed regular-expression API used by ViDot to apply Vitest test-name patterns inside the Godot runner before execution.
- [Vitest: Expect](https://vitest.dev/api/expect) — The matcher contract used for ViDot's initial `toBe` and `toEqual` assertions; ViDot records matcher failures while test authors write any desired fail-fast return explicitly.
- [Vitest: Setup and Teardown](https://vitest.dev/guide/learn/setup-teardown) — The lifecycle contract requiring `afterEach` cleanup even when a test fails.
- [Vitest: Test Run Lifecycle](https://vitest.dev/guide/lifecycle) — The collection, hook, test, and reporting order mirrored by the Godot-side runner.
- [Vitest: Test Context](https://vitest.dev/guide/test-context) — The callback-context model followed by ViDot's Godot-native `tree` context.
- [Vitest: Reporters](https://vitest.dev/guide/reporters) — The native result and reporting system populated by ViDot's custom-pool adapter.
- [Godot 4.3: Command-Line Tutorial](https://docs.godotengine.org/en/4.3/tutorials/editor/command_line_tutorial.html) — The `--path` and `--script` launch boundaries used by the editable-project runner.
- [Godot 4.3: GDScript Lambda Functions](https://docs.godotengine.org/en/4.3/tutorials/scripting/gdscript/gdscript_basics.html#lambda-functions) — The capture boundary inherited by ViDot's local test callbacks: scalar locals are captured by value, while Array, Dictionary, and Object contents remain shared by reference.
- [Godot 4.3: GDScript Classes as Resources](https://docs.godotengine.org/en/4.3/tutorials/scripting/gdscript/gdscript_basics.html#classes-as-resources) — The script loading and instantiation model used by ViDot's external fixture helper.
- [Godot 4.3 source: Scripted `SceneTree` Startup](https://github.com/godotengine/godot/blob/4.3-stable/main/main.cpp#L3505-L3704) — The startup path showing that an external runner script replaces the default main-scene entry while the target's configured Autoloads are still instantiated.
- [typescript-to-gdscript commit 78058f1: Programmatic Converter](https://github.com/LemonNekoGH/typescript-to-gdscript/blob/78058f173ef8d38949532037998b3c86407eec7d/src/converter/ts-to-gd/index.ts) — The public per-file conversion seam used by tstogd's CLI after ViDot generates a class-shaped TypeScript wrapper.
- [Execa Termination](https://github.com/sindresorhus/execa/blob/v10.0.1/docs/termination.md) — The graceful and forceful termination behavior used to bound ViDot process cleanup.
- [Godot 4.3 Stable Release](https://github.com/godotengine/godot-builds/releases/tag/4.3-stable) — The official engine release pinned for ViDot's editable-project test proof.
