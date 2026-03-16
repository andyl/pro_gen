# gen_phx1

A Phoenix project generator that demonstrates validation checks,
system commands, and directory navigation with ProGen.Script.

**Run it:**

```bash
./scripts/gen_phx1 --help
```

**Source:** [`scripts/gen_phx1`](https://github.com/andyl/pro_gen/blob/master/scripts/gen_phx1)

```elixir
#!/usr/bin/env elixir

# A Phoenix project generator that demonstrates validation checks,
# system commands, and directory navigation with ProGen.Script.

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

alias ProGen.Script, as: PG

PG.clear() 

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

PG.start()
PG.command "CLEANUP",            "rm -rf #{project}"
PG.action  "CHECK ENVIRONMENT",  "validate", [:no_mix, :no_git, {:no_dir, project}]
PG.command "GEN PHX PROJECT",    "mix igniter.new #{project} --with=phx.new --with-args --no-ecto"

PG.cd(project)
PG.command "PWD",                "pwd"
PG.command "COMPILE",            "mix compile"

PG.finish()
```
