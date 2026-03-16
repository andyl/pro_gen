# Example Scripts

## pg_base_cli

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

## pg_deploy_fly

Generates a simple phoenix app which can be deployed using Fly

**Run it:**

```bash
./scripts/pg_deploy_fly --help
```

**Source:** [`scripts/pg_deploy_fly`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_deploy_fly)

```elixir
#!/usr/bin/env elixir

# Generates a simple phoenix app which can be deployed using Fly

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

PG.puts "UNDER CONSTRUCTION"
```

## pg_deploy_kamal

Generates a simple phoenix app which can be deployed using Kamal

**Run it:**

```bash
./scripts/pg_deploy_kamal --help
```

**Source:** [`scripts/pg_deploy_kamal`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_deploy_kamal)

```elixir
#!/usr/bin/env elixir

# Generates a simple phoenix app which can be deployed using Kamal

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

PG.puts "UNDER CONSTRUCTION"
```

## pg_phx_ash

Generates a phoenix app with an Ash datalayer.

**Run it:**

```bash
./scripts/pg_phx_ash --help
```

**Source:** [`scripts/pg_phx_ash`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_phx_ash)

```elixir
#!/usr/bin/env elixir

# Generates a phoenix app with an Ash datalayer.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

PG.puts "UNDER CONSTRUCTION"
```

## pg_phx_base

A Phoenix project generator that demonstrates validation checks,
system commands, and directory navigation with ProGen.Script.

**Run it:**

```bash
./scripts/pg_phx_base --help
```

**Source:** [`scripts/pg_phx_base`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_phx_base)

```elixir
#!/usr/bin/env elixir

# A Phoenix project generator that demonstrates validation checks,
# system commands, and directory navigation with ProGen.Script.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

alias ProGen.Script,   as: PG
alias ProGen.Validate, as: PV

PG.cli_args( 
  name: "gen_phx1",
  description: "Phoenix Generator 1", 
  allow_unknown_args: false, 
  args: [
    project: [
      value_name: "PROJECT",
      help: "Project name", 
      required: true, 
      parser: :string
    ]
  ]
)

{:ok, %{project: project}} = PG.parse_args() 

PG.clear() 

PG.start()

PG.validate "CHECK ENVIRONMENT",  PV.Basics, [:no_mix, :no_git, {:no_dir, project}]
PG.command  "GEN PHX PROJECT",    "mix igniter.new #{project} --with=phx.new --with-args --no-ecto"

PG.cd(project)
PG.command "COMPILE",            "mix compile"

PG.finish()
```

## pg_phx_ecto

A basic phoenix generator that includes an Ecto database.

**Run it:**

```bash
./scripts/pg_phx_ecto --help
```

**Source:** [`scripts/pg_phx_ecto`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_phx_ecto)

```elixir
#!/usr/bin/env elixir

# A basic phoenix generator that includes an Ecto database.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

PG.puts "UNDER CONSTRUCTION"
```

## pg_phx_max

Generates a phoenix app with many configuration options.

**Run it:**

```bash
./scripts/pg_phx_max --help
```

**Source:** [`scripts/pg_phx_max`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_phx_max)

```elixir
#!/usr/bin/env elixir

# Generates a phoenix app with many configuration options.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

PG.puts "UNDER CONSTRUCTION"
```

## pg_phx_pwa

Generates a phoenix app with a PWA interface.

**Run it:**

```bash
./scripts/pg_phx_pwa --help
```

**Source:** [`scripts/pg_phx_pwa`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_phx_pwa)

```elixir
#!/usr/bin/env elixir

# Generates a phoenix app with a PWA interface.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

PG.puts "UNDER CONSTRUCTION"
```

## pg_tableau_base

Generates a basic tableau app.

**Run it:**

```bash
./scripts/pg_tableau_base --help
```

**Source:** [`scripts/pg_tableau_base`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_tableau_base)

```elixir
#!/usr/bin/env elixir

# Generates a basic tableau app.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

PG.puts "UNDER CONSTRUCTION"
```

## pg_tableau_pwa

Generates a tableau app with a PWA interface.

**Run it:**

```bash
./scripts/pg_tableau_pwa --help
```

**Source:** [`scripts/pg_tableau_pwa`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_tableau_pwa)

```elixir
#!/usr/bin/env elixir

# Generates a tableau app with a PWA interface.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

PG.puts "UNDER CONSTRUCTION"
```
