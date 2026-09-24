# ViDot

`@vidot/vitest` runs Vitest-shaped TypeScript tests inside an editable Godot
project. Godot owns collection and execution; Vitest owns file discovery and
reporting.

Install the pinned tools and run the repository proof with:

```bash
mise install
mise run setup
mise run test
```

Set `GODOT_BIN` to override the pinned Godot editor when needed.

The Godot runner and Node adapter are authored in TypeScript. `build` generates
GDScript and JavaScript, both committed for Git-based consumers. See [the ViDot guide](docs/vidot.md) for the
current API and configuration.

ViDot expects each runtime-imported Godot package to be a built tstogd library.
It mounts these libraries under the target project's `tstogd_modules`
directory before Godot loads a generated test wrapper.

The Godot test context can instantiate external GDScript fixtures and perform
frame-driven bounded waits; the complete contract is documented there.
