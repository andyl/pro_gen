# ProGen CLI Parsing Design

Overview: We modified ProGen CLI parsing to use `ProGen.Env` variables. The goal
is to streamline and simplify CLI parsing by storing the schema once and using
lower-arity convenience functions.

## Current Situation

Currently a ProGen script has these functions for CLI processing:

    * `parse_args/2`  — Parse argv against an Optimus schema
    * `usage/1`       — Generate help text from an Optimus schema

A script might look like:

```elixir
schema = [
    name: "greeter",
    description: "A greeting script",
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
  ]

results = parse_args(schema, argv)

# ... and separately

usage(schema)
```

## New Functions

New CLI processing functions (existing `parse_args/2` and `usage/1` remain unchanged):

    * `put_arg_schema/1` — Store the Optimus schema in Env under atom key `:pg_arg_schema`
    * `get_arg_schema/0` — Retrieve the stored schema from `:pg_arg_schema`
    * `parse_args/1`     — Parse argv using the stored schema, store merged results in `:pg_args`
    * `parse_args/0`     — Convenience for `parse_args(System.argv())`
    * `usage/0`          — Generate help text from the stored schema

A new script looks like:

```elixir
put_arg_schema(
  name: "greeter",
  description: "A greeting script",
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
    # ...
  :help -> System.halt(0)
  :version -> System.halt(0)
  {:error, _} -> System.halt(1)
end
```

## Design Decisions

- **Atom key `:pg_arg_schema`** — uses atom keys in `ProGen.Env`, avoiding the
  env-var fallback that happens with string keys.
- **Merged map in `:pg_args`** — `parse_args/1` merges `parsed.args`,
  `parsed.options`, and `parsed.flags` into one flat map, so
  `Env.get(:pg_args)[:name]` works for any arg type.
- **`--help` and `--version` auto-print but don't halt** — `parse_args/1`
  prints usage/version automatically and returns `:help`/`:version` atoms,
  letting the script decide whether to halt. This keeps tests working (no
  `System.halt` mid-test).
