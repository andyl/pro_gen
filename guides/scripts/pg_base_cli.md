# pg_base_cli

A simple greeting script that demonstrates CLI argument parsing,
flags, and basic ProGen.Script usage.

**Run it:**

```bash
./scripts/pg_base_cli --help
```

**Source:** [`scripts/pg_base_cli`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_base_cli)

```elixir
#!/usr/bin/env elixir

# A simple greeting script that demonstrates CLI argument parsing,
# flags, and basic ProGen.Script usage.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

alias ProGen.Script, as: PG

PG.cli_args(
  name: "greet",
  description: "A simple greeting script",
  version: "0.1.0",
  args: [
    name: [
      value_name: "NAME", 
      help: "Name to greet",
      required: true, 
      parser: :string
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

PG.start()
PG.inspect "CLI Values", PG.cli_vals()

name = PG.cli_vals().name
output = if PG.cli_vals().loud, do: String.upcase(name), else: name

PG.puts "Hello #{output}"

PG.finish()
```
