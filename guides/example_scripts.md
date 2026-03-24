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
    ], 
    max: [
      short: "-m", 
      long: "--max", 
      help: "Generate max features"
    ]
  ]
)

# Parse the CLI args and grab the project name
{:ok, %{project: project}} = PS.parse_args() 

if PS.cli_vals().max do 
  newargs = PS.cli_vals() |> Map.put(:ecto, true)
  ProGen.Env.put(:pg_cli_vals, newargs)
end

# Print a banner
PS.puts(" ----- CREATE PROJECT <#{project}> -----")

# Start a timer
PS.start()

if PS.cli_vals().force, do: PS.command("CLEANUP OLD PROJECT", "rm -rf #{project}")

# exit if validations do not pass
PS.validate "CHECK ENVIRONMENT", PV.Filesys, [:no_mix, :no_git]
  
# generate phoenix project
proj = [project: project]
args = if PS.cli_vals().ecto, do: [], else: [args: "--no-ecto"]
PS.action "GEN PHOENIX PROJECT", "new.phoenix", Keyword.merge(proj, args)

# Change to the project directory
PS.cd(project)

# Compile Code 
PS.command "COMPILE", "mix compile"

# Install max features 
if PS.cli_vals().max do 

  project_pascal = ProGen.Util.to_pascal(project) 
  seed_cmd = "mix run -e \"Ash.Seed.seed!(#{project_pascal}.Accounts.User, %{email: ~s(a@a.com), hashed_password: Bcrypt.hash_pwd_salt(~s(12345678))})\""

  PS.action  "Add ash",          "deps.install", [deps: "ash ash_phoenix ash_postgres"]
  PS.action  "Add auth",         "deps.install", [deps: "ash_authentication ash_authentication_phoenix", args: "--auth-strategy password"]
  PS.action  "Add ash_admin",    "deps.install", [deps: "ash_admin"]
  PS.action  "Add LV debugger",  "deps.install", [deps: "live_debugger"]
  PS.action  "Add git_ops",      "deps.install", [deps: "git_ops",                                       only: "dev,test"]
  PS.command "Create migration", "mix ash.codegen setup_auth"
  PS.command "Setup database",   "mix ecto.drop ; mix ash.setup"
  PS.command "Create seed user", seed_cmd
end

# run_cmd "Add Xpc"         "mix igniter.install xpc@path:/home/aleak/src/App/xpc --only dev,test --yes"
# run_cmd "Add AshMod"      "mix igniter.install ash_mod@path:/home/aleak/src/Lib/ash_mod --only dev,test --yes"
#
# [ "$USE_AUTH"  == "true" ] && run_cmd "Use uuidv7"       "mix ash.gen.resource $APP.Accounts.User --uuid-v7-primary-key id --conflicts replace --yes"
# [ "$USE_AUTH"  == "true" ] && run_cmd "Add accounts_gen" "mix ash_mod.template.render accounts_gen -m"
# [ "$USE_AUTH"  == "true" ] && run_cmd "Add migration"    "mix ash.codegen use_uuidv7"
# [ "$USE_ORG"   == "true" ] && run_cmd "Add User Slug"    "mix ash.gen.resource $APP.Accounts.User -a username:ci_string -a slug:ci_string -t --conflicts replace --yes"
# [ "$USE_ORG"   == "true" ] && run_cmd "Create Org"       "mix ash.gen.resource $APP.Camp.Org --uuid-v7-primary-key id -a name:string -a orgname:ci_string -a slug:ci_string -a type:atom -t -e postgres --default-actions create,read,update,destroy --yes"
# [ "$USE_ORG"   == "true" ] && run_cmd "Create Mem"       "mix ash.gen.resource $APP.Camp.Mem --uuid-v7-primary-key id -a mem_id:uuid -a user_id:uuid -a role:atom -t -e postgres --default-actions create,read,update,destroy --yes"
# [ "$USE_ORG"   == "true" ] && run_cmd "Add camp_gen"     "mix ash_mod.template.render camp_gen -m"
#
# SEED_CMD="mix run -e \"Ash.Seed.seed!($APP.Accounts.User, %{email: ~s(a@a.com), hashed_password: Bcrypt.hash_pwd_salt(~s(12345678))})\""
# [ "$USE_AUTH"  == "true" ] && echo "$SEED_CMD"
# [ "$USE_AUTH"  == "true" ] && run_cmd "Add a seed user" "$SEED_CMD"

PS.action "Install UsageRules", "deps.install",           [deps: "usage_rules"]
PS.action "Setup UsageRules",   "deps.usage_rules.setup", []
PS.action "Add Completions",    "mix_completions.run",    []

# Report the elapsed time
PS.finish()
```

## progen_phoenix_kamal

Generates a phoenix app which can be deployed using Kamal

**Run it:**

```bash
./scripts/progen_phoenix_kamal --help
```

**Source:** [`scripts/progen_phoenix_kamal`](https://github.com/andyl/pro_gen/blob/master/scripts/progen_phoenix_kamal)

```elixir
#!/usr/bin/env elixir

# Generates a phoenix app which can be deployed using Kamal

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

alias ProGen.Script,   as: PS
alias ProGen.Validate, as: PV

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
    max: [
      short: "-m", 
      long: "--max", 
      help: "Generate max features"
    ], 
    force: [
      short: "-f", 
      long: "--force", 
      help: "Overwrite project directory if it exists"
    ], 
  ]
)

# Parse the CLI args and grab the project name
{:ok, %{project: project}} = PS.parse_args() 

# set if max==true, set ecto=true
if PS.cli_vals().max do 
  newargs = PS.cli_vals() |> Map.put(:ecto, true)
  ProGen.Env.put(:pg_cli_vals, newargs)
end

# Print a banner
PS.puts(" ----- CREATE PROJECT <#{project}> -----")

# Start a timer
PS.start()

PS.validate "CHECK ENVIRONMENT", PV.Filesys, [:no_mix, :no_git]
PS.validate "CHECK RUBY",        PV.Lang,    [:has_ruby]

project = PS.cli_vals().project
ecto    = if PS.cli_vals().ecto,  do: "--ecto",  else: ""
max     = if PS.cli_vals().max,   do: "--max",   else: ""
force   = if PS.cli_vals().force, do: "--force", else: ""

PS.command "Build Base App", "progen_phoenix #{project} #{ecto} #{max} #{force}"

PS.cd project

PS.action  "Install kamal gem",  "gems.install",     [gems: "kamal"]
PS.action  "Add sourceror",      "deps.install",     [deps: "sourceror"]
PS.action  "Remove --only",      "deps.only.remove", [deps: "igniter sourceror"]
PS.action  "Install kamal_plug", "deps.install",     [deps: "kamal_plug@github:andyl/kamal_plug"]
PS.action  "Build release",      "release.new",      []
PS.action  "Generate release",   "release.gen",      []
PS.action  "Docker build",       "docker.build",     [project: project]

PS.puts("SUCCESS")

# kamal init 
# echo 'SECRET_KEY_BASE=$SECRET_KEY_BASE' > .kamal/secrets 
# # MANUAL EDIT: config/deploy.yml 
# # make sure you can ssh to root@<target>  (USE KEYSEND root@<target>)
# kamal setup 
# kamal deploy

# Report Elapsed Time
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

# Write a 'banner'
PS.puts(" ----- CREATE PROJECT <#{project}> -----")

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
PS.action "Install HeroIcons",  "deps.install",           [deps: "heroicons"]
PS.action "Install UsageRules", "deps.install",           [deps: "usage_rules"]
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
PS.puts(" ----- CREATE PROJECT <#{project}> -----")

# Print a banner
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
PS.action "Install UsageRules", "deps.install",           [deps: "usage_rules"]
PS.action "Setup UsageRules",   "deps.usage_rules.setup", []

# Report the elapsed time
PS.finish()
```
