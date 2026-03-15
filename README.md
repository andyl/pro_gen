# ProGen

A scriptable Elixir project generator.

Code generation is based on [Igniter](https://github.com/ash-project/igniter),
possible future to handle things like deployment, CI/CD, monitoring, and DevOps
tasks.

**Status:** Early-stage development (v0.0.1)

## Architecture

ProGen is organized around four pillars:

| Pillar         | Purpose                                      | Status               |
|----------------|----------------------------------------------|----------------------|
| **Actions**    | Composable, self-describing generation tasks | Basic Implementation |
| **Scripts**    | Shareable end-user generation workflows      | Basic Implementation |
| **Menus**      | TUI menus for interactive script creation    | Future               |
| **Chats**      | Chat interface to create scripts             | Future               |

### Actions

Actions are small, composable units of work. Each action is a module that
implements three callbacks:

- `perform/1` — execute the action with validated args
- `description/0` — short human-readable description
- `option_schema/0` — [NimbleOptions](https://github.com/dashbitco/nimble_options) schema for argument validation

```elixir
defmodule ProGen.Action.Run do
  use ProGen.Action

  @impl true
  def description, do: "Run a system command"

  @impl true
  def option_schema do
    [
      command: [type: :string, required: true, doc: "The command to execute"],
      args: [type: {:list, :string}, default: [], doc: "Arguments to pass"],
      dir: [type: :string, default: ".", doc: "Working directory"]
    ]
  end

  @impl true
  def perform(args) do
    System.cmd(Keyword.fetch!(args, :command), Keyword.get(args, :args, []),
      cd: Keyword.get(args, :dir, "."))
  end
end
```

**Auto-discovery:** Any module named `ProGen.Action.<Name>` is automatically
registered. The name is derived from the segments after `ProGen.Action`,
downcased and dot-joined (e.g. `ProGen.Action.Run` becomes `"run"`,
`ProGen.Action.Test.Echo` becomes `"test.echo"`). Namespaces are arbitrarily
deep. No manual registration needed. Goal is to make it easy to create custom
actions.

**Running actions:**

```elixir
ProGen.Actions.run("run", command: "echo", args: ["hello"])
#=> {:ok, {"hello\n", 0}}

ProGen.Actions.run("run", [])
#=> {:error, "required option :command not found..."}
```

**Inspecting actions:**

```elixir
ProGen.Actions.list_actions()
#=> ["echo", "inspect", "run", "test.echo2", "validate"]

ProGen.Actions.action_info("run")
#=> {:ok, %{description: "Run a system command", usage: "...", option_schema: [...]}}
```

### Scripts

Scripts are `.exs` files that use `ProGen.Script` functions to define end-user
generation workflows. CLI parsing is handled by
[Optimus](https://github.com/funbox/optimus).

**Full example** (`examples/greeter.exs`):

```elixir
Mix.install([{:pro_gen, path: ".."}])

import ProGen.Script

cli_args(
  name: "greeter",
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

case parse_args(System.argv()) do
  {:ok, args} ->
    name = args[:name]
    greeting = "Hello, #{name}!"

    if args[:loud] do
      IO.puts(String.upcase(greeting))
    else
      IO.puts(greeting)
    end

  :help -> System.halt(0)
  :version -> System.halt(0)
  {:error, _errors} -> System.halt(1)
end
```

Run it:

```bash
elixir examples/greeter.exs --name World
# Hello, World!

elixir examples/greeter.exs --name World --loud
# HELLO, WORLD!

elixir examples/greeter.exs --help
# (prints usage)
```

**Script functions:**

| Function             | Description                                               |
|----------------------|-----------------------------------------------------------|
| `cli_args/1`   | Store an Optimus schema in `ProGen.Env`                   |
| `cli_args/0`   | Retrieve the stored schema                                |
| `parse_args/2`       | Parse argv against an explicit schema                     |
| `parse_args/1`       | Parse argv using the stored schema (merges into flat map)  |
| `parse_args/0`       | Parse `System.argv()` using the stored schema             |
| `usage/1`            | Generate help text from an explicit schema                |
| `usage/0`            | Generate help text from the stored schema                 |
| `puts/1`             | Print a formatted message                                 |
| `command/2`          | Print description, then run a system command               |
| `action/3`           | Run a ProGen action (stub)                                 |
| `git/1`              | Run a git command (string or list)                        |
| `commit/1`           | Stage all files and commit                                |

The `parse_args/1` convenience function merges `parsed.args`, `parsed.options`,
and `parsed.flags` into a single flat map and stores it in `ProGen.Env` under
`:pg_args`. It also auto-prints usage on `--help` and version on `--version`.

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

## License

See [LICENSE](LICENSE.txt) for details.
