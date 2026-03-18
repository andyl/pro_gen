# ProGen

A scriptable Elixir project generator.

Code generation is based on [Igniter](https://github.com/ash-project/igniter),
possible future to handle things like deployment, CI/CD, monitoring, and DevOps
tasks.

**Status:** Early-stage development (v0.0.1)

## Core Architecture

| Element     | Purpose                        | Implementation |
|-------------|--------------------------------|----------------|
| **Actions** | Composable generation tasks    | Elixir Modules |
| **Scripts** | Shareable generation workflows | Elixir Scripts |

### Actions

Actions are small, composable units of work, implemented in a standalone
module.  ProGen comes with a collection of built-in Actions.  Third parties can
independently write their own actions.

```elixir
defmodule ProGen.Action.Run do
  use ProGen.Action

  @description "Run a system command"
  @opts_def [
    command: [type: :string, required: true, doc: "The command to execute"],
    args: [type: {:list, :string}, default: [], doc: "Arguments to pass"],
    dir: [type: :string, default: ".", doc: "Working directory"]
  ]

  @impl true
  def perform(args) do
    command = Keyword.fetch!(args, :command)
    cmd_args = Keyword.get(args, :args, [])
    dir = Keyword.get(args, :dir, ".")

    System.cmd(command, cmd_args, cd: dir)
  end
end
```

**Action metadata** is declared via module attributes:

- `@description` — Short human-readable description (required)
- `@opts_def` — [NimbleOptions](https://github.com/dashbitco/nimble_options) schema describing accepted options (defaults to `[]`)

Using `ProGen.Action` injects: `name/0`, `description/0`, `opts_def/0`,
`validate_args/1`, and `usage/0` (overridable).

**Auto-discovery:** Any module named `ProGen.Action.<Name>` is automatically
registered. The name is derived from the segments after `ProGen.Action`,
downcased/underscored and dot-joined (e.g. `ProGen.Action.Run` becomes `"run"`,
`ProGen.Action.Test.Echo2` becomes `"test.echo2"`). Namespaces are arbitrarily
deep. No manual registration needed. Goal is to make it easy to create custom
actions.

**Running actions:**

```elixir
ProGen.Actions.run("run", command: "echo", args: ["hello"])
#=> {"hello\n", 0}

ProGen.Actions.run("run", [])
#=> {:error, "required option :command not found..."}
```

**Inspecting actions:**

```elixir
ProGen.Actions.list_actions()
#=> ["echo", "inspect", "run", "test.echo2", "validate"]

ProGen.Actions.action_info("run")
#=> {:ok, %{module: ProGen.Action.Run, name: "run", description: "Run a system command", usage: "...", opts_def: [...]}}
```

### Scripts

Scripts are executable files that use `ProGen.Script` functions to define
end-user generation workflows. CLI parsing is handled by
[Optimus](https://github.com/funbox/optimus).

**Full example** (`scripts/greet`):

```elixir
#!/usr/bin/env elixir

Mix.install([{:pro_gen, path: "."}])

alias ProGen.Script, as: PG

PG.cli_args(
  name: "greet",
  description: "A simple greeting script",
  version: "0.1.0",
  options: [
    name: [
      short: "-n",
      long: "--name",
      help: "Name to greet",
      required: true
    ]
  ],
  flags: [
    loud: [
      short: "-l",
      long: "--loud",
      help: "Greet loudly"
    ]
  ]
)

PG.parse_args()

PG.puts "HELLO WORLD"
```

Run it:

```bash
./scripts/greet --name World
```

**Script functions:**

| Function             | Description                                               |
|----------------------|-----------------------------------------------------------|
| `cli_args/1`         | Store an Optimus schema in `ProGen.Env`                   |
| `cli_args/0`         | Retrieve the stored schema                                |
| `cli_vals/0`         | Retrieve the parsed CLI values                            |
| `parse_args/2`       | Parse argv against an explicit schema                     |
| `parse_args/1`       | Parse argv using the stored schema (merges into flat map) |
| `parse_args/0`       | Parse `System.argv()` using the stored schema             |
| `usage/1`            | Generate help text from an explicit schema                |
| `usage/0`            | Generate help text from the stored schema                 |
| `puts/1`             | Print a formatted message                                 |
| `log/1`              | Log an info message via Logger                            |
| `command/2`          | Print description, then run a system command              |
| `action/3`           | Run a ProGen action                                       |
| `git/1`              | Run a git command (string or list)                        |
| `commit/1`           | Stage all files and commit                                |
| `start/1`            | Log a start message and record the start time             |
| `finish/1`           | Log a finish message with elapsed time                    |
| `cd/1`               | Change the working directory                              |
| `clear/0`            | Clear the terminal screen                                 |

The `parse_args/1` convenience function merges `parsed.args`, `parsed.options`,
and `parsed.flags` into a single flat map and stores it in `ProGen.Env` under
`:pg_cli_vals`. It also auto-prints usage on `--help` and version on `--version`.

## Extending ProGen

### Actions

Create a module under your project's namespace that starts with `ProGen.Action.`.
It will be auto-discovered at runtime — no manual registration needed.

```elixir
defmodule ProGen.Action.MyCustom do
  use ProGen.Action

  @description "Does something custom"
  @opts_def [
    name: [type: :string, required: true, doc: "The name"]
  ]

  @impl true
  def perform(args) do
    name = Keyword.fetch!(args, :name)
    {:ok, "Hello, #{name}!"}
  end
end
```

The module name segments after `ProGen.Action` determine the action string name
(e.g. `ProGen.Action.MyCustom` becomes `"my_custom"`).

### Validations

Create a module under your project's namespace that starts with
`ProGen.Validate.`. Define checks using the `defcheck` block DSL:

```elixir
defmodule ProGen.Validate.Deploy do
  use ProGen.Validate

  @description "Deployment readiness checks"

  defcheck :has_dockerfile do
    desc "Pass if Dockerfile exists"
    fail "Dockerfile not found"
    test fn _ -> File.exists?("Dockerfile") end
  end

  defcheck {:has_env, "var"} do
    desc "Pass if environment variable is set"
    fail fn {:has_env, var} -> "Environment variable '#{var}' is not set" end
    test fn {:has_env, var} -> System.get_env(var) != nil end
  end
end
```

Each `defcheck` block requires three statements:

| Statement | Purpose                                                                     |
|-----------|-----------------------------------------------------------------------------|
| `desc`    | Human-readable description (used in docs table and `checks/0`)              |
| `fail`    | Error message string, or a `fn term -> string end` for parameterized checks |
| `test`    | `fn term -> boolean end` that performs the actual check                     |

The `defcheck` macro auto-generates `all_checks/0` and appends an
"Available Checks" table to the module's `@moduledoc`.

**Formatter configuration:** Add the following to your `.formatter.exs` so
`mix format` preserves the clean `defcheck` block syntax:

```elixir
# .formatter.exs
[
  locals_without_parens: [defcheck: 2, desc: 1, fail: 1, test: 1],
  # ...
]
```

Without this, the formatter will add parentheses to `desc`, `fail`, and `test`
calls inside the `defcheck` block.

## Supporting Modules

### `ProGen.Env`

An ETS-backed key-value store with OS environment variable fallback. The table is
created lazily on first access.

```elixir
ProGen.Env.put(:color, "blue")
ProGen.Env.get(:color)
#=> "blue"

# Falls back to env vars for missing keys
# :database_url checks DATABASE_URL
ProGen.Env.get(:database_url, "default")

# Bulk operations
ProGen.Env.put(fruit: "apple", veggie: "carrot")
ProGen.Env.list()
#=> [fruit: "apple", veggie: "carrot"]
```

## Installation

Add `pro_gen` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pro_gen, github: "andyl/pro_gen"}
  ]
end
```

For standalone scripts, use `Mix.install`:

```elixir
Mix.install([{:pro_gen, github: "andyl/pro_gen"}])
import ProGen.Script
```

## Development

```bash
mix deps.get                    # Fetch dependencies
mix compile                     # Compile the project
mix test                        # Run all tests
mix test test/file.exs:LINE     # Run a specific test by line number
mix format                      # Format code
mix format --check-formatted    # Check formatting
```

## Dependencies

| Dependency       | Purpose                                         |
|------------------|-------------------------------------------------|
| igniter          | Elixir code generation framework                |
| nimble_options   | Action argument validation                      |
| optimus          | CLI argv parsing for Scripts                    |
| usage_rules      | Claude Code rules integration                   |
| ex_doc           | Documentation generation (dev only)             |

## License

See [LICENSE](LICENSE.txt) for details.
