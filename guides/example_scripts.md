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

alias ProGen.Script, as: PS

# Declare the CLI schema
# These values can be retrieved using PS.cli_args()
PS.cli_args(
  description: "A simple greeting script",
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

# Parse the CLI args, returning an error message for invalid args.
# CLI args can be retrieved using PS.cli_vals()
PS.parse_args() 

# Start a timer
PS.start()

# Get the input name using cli_vals
name = PS.cli_vals().name

if PS.cli_vals().loud do 
  PS.puts "HELLO #{String.upcase(name)}" 
else 
  PS.puts "Hello #{name}"
end

# Report the elapsed time
PS.finish()
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

alias ProGen.Script,    as: PS
alias ProGen.Validate,  as: PV

# Declare the CLI schema.
# These values can be retrieved using PS.cli_args()
PS.cli_args( 
  description: "Phoenix Project Generator with Ecto database", 
  allow_unknown_args: false, 
  args: [
    project: [
      value_name: "PROJECT",
      help: "Phoenix Project name", 
      required: true, 
      parser: :string
    ]
  ],
  flags: [ 
    force: [
      short: "-f", 
      long: "--force", 
      help: "Overwrite project directory if it exists"
    ]
  ]
)

# Parse the CLI args and grab the project name
{:ok, %{project: project}} = PS.parse_args() 

# Clear the screen
PS.clear() 

# Start a timer
PS.start()

if PS.cli_vals().force do 
  PS.command "CLEANUP OLD PROJECT", "rm -rf #{project}"
end

# exit if validations do not pass
# LSP hover on PV.Basics for definitions
PS.validate "CHECK ENVIRONMENT",  PV.Basics, [:no_mix, :no_git, {:no_dir, project}]

# generate project using igniter
PS.command  "GEN PHX PROJECT",    "mix igniter.new #{project} --with=phx.new"

# Change to the project directory
PS.cd(project)

# compile and setup app
PS.command "Compile",          "mix compile"
PS.command "Add ash",          "mix igniter.install ash --yes"
PS.command "Add ash_phoenix",  "mix igniter.install ash_phoenix --yes"
PS.command "Add ash_postgres", "mix igniter.install ash_postgres --yes"
PS.command "Add auth",         "mix igniter.install ash_authentication --auth-strategy password --yes"
PS.command "Add auth_phx",     "mix igniter.install ash_authentication_phoenix --auth-strategy password --yes"
PS.command "Add migration",    "mix ash.codegen auth_migration"
PS.command "Setup database",   "mix ecto.drop ; mix ash.setup"
PS.command "Add ash_admin",    "mix igniter.install ash_admin --yes"

# Report the elapsed time
PS.finish()
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

alias ProGen.Script,    as: PS
alias ProGen.Validate,  as: PV

# Declare the CLI schema.
# These values can be retrieved using PS.cli_args()
PS.cli_args( 
  description: "Basic Phoenix Project Generator", 
  allow_unknown_args: false, 
  args: [
    project: [
      value_name: "PROJECT",
      help: "Phoenix Project name", 
      required: true, 
      parser: :string
    ]
  ],
  flags: [ 
    force: [
      short: "-f", 
      long: "--force", 
      help: "Overwrite project directory if it exists"
    ]
  ]
)

# Parse the CLI args and grab the project name
{:ok, %{project: project}} = PS.parse_args() 

# Clear the screen
PS.clear() 

# Start a timer
PS.start()

if PS.cli_vals().force do 
  PS.command "CLEANUP OLD PROJECT", "rm -rf #{project}"
end

# exit if validations do not pass
# LSP hover on PV.Basics for definitions
PS.validate "CHECK ENVIRONMENT",  PV.Basics, [:no_mix, :no_git, {:no_dir, project}]

# generate project using igniter
PS.command  "GEN PHX PROJECT",    "mix igniter.new #{project} --with=phx.new --with-args --no-ecto"

# Change to the project directory
PS.cd(project)

# Compile Code 
PS.command "COMPILE", "mix compile"

# Report the elapsed time
PS.finish()
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

alias ProGen.Script,    as: PS
alias ProGen.Validate,  as: PV

# Declare the CLI schema.
# These values can be retrieved using PS.cli_args()
PS.cli_args( 
  description: "Phoenix Project Generator with Ecto database", 
  allow_unknown_args: false, 
  args: [
    project: [
      value_name: "PROJECT",
      help: "Phoenix Project name", 
      required: true, 
      parser: :string
    ]
  ],
  flags: [ 
    force: [
      short: "-f", 
      long: "--force", 
      help: "Overwrite project directory if it exists"
    ]
  ]
)

# Parse the CLI args and grab the project name
{:ok, %{project: project}} = PS.parse_args() 

# Clear the screen
PS.clear() 

# Start a timer
PS.start()

if PS.cli_vals().force do 
  PS.command "CLEANUP OLD PROJECT", "rm -rf #{project}"
end

# exit if validations do not pass
# LSP hover on PV.Basics for definitions
PS.validate "CHECK ENVIRONMENT",  PV.Basics, [:no_mix, :no_git, {:no_dir, project}]

# generate project using igniter
PS.command  "GEN PHX PROJECT",    "mix igniter.new #{project} --with=phx.new"

# Change to the project directory
PS.cd(project)

# compile and setup database
PS.command "COMPILE",  "mix compile"
PS.command "SETUP DB", "mix do ecto.drop, ecto.create, ecto.migrate"

# Report the elapsed time
PS.finish()
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

## pg_termui_base

Generates a basic TermUI app.

**Run it:**

```bash
./scripts/pg_termui_base --help
```

**Source:** [`scripts/pg_termui_base`](https://github.com/andyl/pro_gen/blob/master/scripts/pg_termui_base)

```elixir
#!/usr/bin/env elixir

# Generates a basic TermUI app.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

alias ProGen.Script,    as: PS
alias ProGen.Validate,  as: PV

PS.cli_args( 
  description: "Basic TermUI Project Generator", 
  allow_unknown_args: false, 
  args: [
    project: [
      value_name: "PROJECT",
      help: "TermUI Project name", 
      required: true, 
      parser: :string
    ]
  ],
  flags: [ 
    force: [
      short: "-f", 
      long: "--force", 
      help: "Overwrite project directory if it exists"
    ]
  ]
)
  
# Parse the CLI args and grab the project name
{:ok, %{project: project}} = PS.parse_args() 

# Clear the screen
PS.clear() 

# Start a timer
PS.start()

# exit if validations do not pass
# LSP hover on PV.Basics for definitions
PS.validate "CHECK ENVIRONMENT",  PV.Basics, [:no_mix, :no_git, {:no_dir, project}]

if PS.cli_vals().force do 
  PS.command "CLEANUP OLD PROJECT", "rm -rf #{project}"
end

# generate TermUI project 
PS.action  "GEN TermUI PROJECT", "termui.new", [project: project]

# Change to the project directory
PS.cd(project)

# Compile Code 
PS.command "COMPILE", "mix compile"

# Report the elapsed time
PS.finish()
```
