# pg_phx_base

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
