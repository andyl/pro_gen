# Example Scripts

## progen_deploy_fly

Generates a simple phoenix app which can be deployed using Fly

**Run it:**

```bash
./scripts/progen_deploy_fly --help
```

**Source:** [`scripts/progen_deploy_fly`](https://github.com/andyl/pro_gen/blob/master/scripts/progen_deploy_fly)

```elixir
#!/usr/bin/env elixir

# Generates a simple phoenix app which can be deployed using Fly

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

PG.puts "UNDER CONSTRUCTION"
```

## progen_deploy_kamal

Generates a simple phoenix app which can be deployed using Kamal

**Run it:**

```bash
./scripts/progen_deploy_kamal --help
```

**Source:** [`scripts/progen_deploy_kamal`](https://github.com/andyl/pro_gen/blob/master/scripts/progen_deploy_kamal)

```elixir
#!/usr/bin/env elixir

# Generates a simple phoenix app which can be deployed using Kamal

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

PG.puts "UNDER CONSTRUCTION"
```

## progen_hello_world

A simple greeting script that demonstrates CLI argument parsing,
flags, and basic ProGen.Script usage.

**Run it:**

```bash
./scripts/progen_hello_world --help
```

**Source:** [`scripts/progen_hello_world`](https://github.com/andyl/pro_gen/blob/master/scripts/progen_hello_world)

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

## progen_phoenix

A Phoenix project generator that demonstrates validation checks,
system commands, and directory navigation with ProGen.Script.

**Run it:**

```bash
./scripts/progen_phoenix --help
```

**Source:** [`scripts/progen_phoenix`](https://github.com/andyl/pro_gen/blob/master/scripts/progen_phoenix)

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
    ], 
    ecto: [
      short: "-e", 
      long: "--ecto", 
      help: "Generate ecto files"
    ]
  ]
)

# Parse the CLI args and grab the project name
{:ok, %{project: project}} = PS.parse_args() 

# Clear the screen
PS.clear() 

# Start a timer
PS.start()

if PS.cli_vals().force, do: PS.command "CLEANUP OLD PROJECT", "rm -rf #{project}"

# exit if validations do not pass
PS.validate "CHECK ENVIRONMENT", PV.Filesys, [:no_mix, :no_git, {:no_dir, project}]
  
# generate project using igniter
phx_gen_opts = if PS.cli_vals().ecto, do: "", else: "--with-args --no-ecto"
phx_gen_cmd = "mix igniter.new #{project} --with=phx.new #{phx_gen_opts}"
PS.command  "GEN PHX PROJECT", phx_gen_cmd

# Change to the project directory
PS.cd(project)

# Compile Code 
PS.command "COMPILE", "mix compile"

# Report the elapsed time
PS.finish()
```

## progen_tableau

Generates a [Tableau](https://github.com/elixir-tools/tableau) app.

**Run it:**

```bash
./scripts/progen_tableau --help
```

**Source:** [`scripts/progen_tableau`](https://github.com/andyl/pro_gen/blob/master/scripts/progen_tableau)

```elixir
#!/usr/bin/env elixir

# Generates a [Tableau](https://github.com/elixir-tools/tableau) app.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

alias ProGen.Script, as: PS 

PS.cli_args( 
  description: "Basic Tableau Project Generator", 
  allow_unknown_args: false, 
  args: [
    project: [
      value_name: "PROJECT",
      help: "Tableau Project name", 
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
PS.validate "CHECK ENVIRONMENT",  "filesys", [:no_mix, :no_git]

# generate project using igniter
PS.action  "GEN TABLEAU PROJECT", "new.tableau", [project: project]

# Change to the project directory
PS.cd(project)

# Compile Code 
PS.command "COMPILE",           "mix compile"
PS.action "Install HeroIcons",  "deps.install",           [dep: "heroicons"]
PS.action "Install UsageRules", "deps.install",           [dep: "usage_rules"]
PS.action "Setup UsageRules",   "deps.usage_rules.setup", []
# run_cmd "Add Daisy"        "npm i -D daisyui@latest" 
# run_cmd "Update CSS"       "echo '@plugin \"daisyui\";' >> assets/css/site.css"
# run_cmd "Fix CSS"          "sed -i 's/\"$/\";/' assets/css/site.css"
PS.action "Add Completions", "mix_completions.run", []

# Report the elapsed time
PS.finish()
```

## progen_termui

Generates a [TermUI](https://github.com/pcharbon70/term_ui) app.

**Run it:**

```bash
./scripts/progen_termui --help
```

**Source:** [`scripts/progen_termui`](https://github.com/andyl/pro_gen/blob/master/scripts/progen_termui)

```elixir
#!/usr/bin/env elixir

# Generates a [TermUI](https://github.com/pcharbon70/term_ui) app.

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
