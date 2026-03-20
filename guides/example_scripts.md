# Example Scripts

## progen_greet

A simple greeting script that demonstrates CLI argument parsing,
flags, and basic ProGen.Script usage.

**Run it:**

```bash
./scripts/progen_greet --help
```

**Source:** [`scripts/progen_greet`](https://github.com/andyl/pro_gen/blob/master/scripts/progen_greet)

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

## progen_phoenix_kamal

Generates a simple phoenix app which can be deployed using Kamal

**Run it:**

```bash
./scripts/progen_phoenix_kamal --help
```

**Source:** [`scripts/progen_phoenix_kamal`](https://github.com/andyl/pro_gen/blob/master/scripts/progen_phoenix_kamal)

```elixir
#!/usr/bin/env elixir

# Generates a simple phoenix app which can be deployed using Kamal

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

alias ProGen.Script, as: PS 

PS.cli_args( 
  description: "Phoenix Project and Kamal Deploy Generator", 
  allow_unknown_args: false, 
  args: [
    project: [
      value_name: "PROJECT",
      help: "Phoenix Project name", 
      required: true, 
      parser: :string
    ], 
    server: [
      value_name: "HOST",
      help: "Deployment Host", 
      required: true, 
      parser: :string
    ], 
  ],
  flags: [ 
    ecto: [
      short: "-e", 
      long: "--ecto", 
      help: "Generate ecto files"
    ], 
    force: [
      short: "-f", 
      long: "--force", 
      help: "Overwrite project directory if it exists"
    ], 
  ]
)

PS.puts "= UNDER CONSTRUCTION =\n... Script Outline ..."

outline = """
mix igniter.new myapp --with phx.new --with-args=--no-ecto --yes
# MANUAL EDIT: remove [:dev, :test] from igniter
cd myapp 
git init && git add . && git commit -am'First commit'
mix igniter.install kamal_plug@github:andyl/kamal_plug
echo "/rel/" >> .gitignore
mix phx.gen.release 
MIX_ENV=prod mix release
# see DOCKERFILE_TIMEOUT_ISSUE below...
rerun mix phx.gen.release --docker   
docker build -t myapp . 
kamal init 
echo 'SECRET_KEY_BASE=$SECRET_KEY_BASE' > .kamal/secrets 
# MANUAL EDIT: config/deploy.yml 
# make sure you can ssh to root@<target>  (USE KEYSEND root@<target>)
kamal setup 
kamal deploy
"""

PS.puts outline
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

PS.command "COMPILE",           "mix compile"
PS.action "Install HeroIcons",  "deps.install",           [dep: "heroicons"]
PS.action "Install UsageRules", "deps.install",           [dep: "usage_rules"]
PS.action "Setup UsageRules",   "deps.usage_rules.setup", []
PS.action "Setup Daisy",        "deps.tableau.daisy",     []
PS.action "Add Completions",    "mix_completions.run",    []

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
