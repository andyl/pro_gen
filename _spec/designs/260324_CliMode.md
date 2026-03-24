# ProGen CLI Mode

## Requirement 

Currently, the ProGen actions and commands are primarily driven by elixir
scripts.

I'd also like to be able to run ProGen actions from the command line, in two
ways:
- one-at-a-time, interactively right in a bash terminal  
- in a bash script 

In order to do this, I'd like to have ProGen installed in a way that is
globally accessible, from within a Mix project, or anywhere in the filesystem. 

## Mix Tasks 

The way I prefer is to have project available as a Mix task from anywhere in
the filesystem, using the following commands:

```
mix progen.install 
mix progen.action.run "message" <action_module> <args...> 
mix progen.action.edit <action_module>
mix progen.action.cat <action_module>
mix progen.action.info <action_module>
mix progen.action.list [--format <fmt>]
mix progen.validate.run "validate_module" <args>
mix progen.validate.edit <validate_module>
mix progen.validate.cat <validate_module>
mix progen.validate.info <validate_module>
mix progen.validate.list [--format <fmt>] 
mix progen.command.run "message" "command" 
mix progen.puts "message"
```

## Installation 

The mix tasks should be installed using the following command:

`mix archive.install github andyl/pro_gen`

## Error Code 

If a mix command encounters an error condition, the error message should be
written to stdout, and a non-zero error code should be returned.

In this way, a bash script could terminate immediately if an error was encountered:

```bash 
#!/usr/bin/env bash 

# demo script 

set -euo pipefail   # -e: exit on error
                    # -u: exit on undefined variable
                    # -o pipefail: catch errors in pipes too

alias par="mix progen.action.run"

# command 1
par "Install Phonix" deps.install "<args>"
# if command1 fails, the following commands will not run
par "Install UsageRules" deps.install "<args>"
...
```

## Module Reference 

Some commands refer to an "action_module" or a "validation_module".

In this case, either form should be accepted:

1. the "string form", like "deps.install"
2. the "module form", like "Deps.Install"

## Args 

I'm not sure what is the best way to capture <args> for actions and validations. 

Note that each Action and Validation takes unique arguments.

I ask Claude to give suggestions as to the simplest and most effective format.
If appropriate, present alternatives with pros and cons.

Probably valid args could be listed in an info message, and echoed in an error
message when an invalid args are given.

EG 
- mix progen.action.info <action_module>
- mix progen.validate.info <action_module>

## 3rd party Libraries 

ProGen has built-in Actions and Validations.  I want the tool to also work with
third party libraries.  Perhaps this is a way it could be done:

- Have a config file ~/.config/pro_gen/config.yml 
- Allow definition of 3rd party libraries 
- Have a command to incorporate libs eg `mix progen.install` 
- Use an 'install' mechanism that compares somewhat to `Mix.install ...`
- Perhaps the github and hex deps could be saved into ~/.config/pro_gen/deps
  (path deps should probably stay in place...)

eg 
- ~/.config/pro_gen/config.yml 
- ~/.config/pro_gen/deps/*

Config file example: 

```yaml
libs: 
  - {:proj1, path: "path/to/my/proj"}
  - {:proj2, github: "user/repo"}
  - {:proj3, "~> 0.4"}
```

In this way, we could use Actions and Validations written by 3rd parties.

Maybe ProGen itself should be included in this libs directory...

## Listing 

It should be possible to list Action and Validation modules - their stringified
names, module names and description.  Valid output formats could be: table
(TableRex, text, json, yaml, ...)

## Info 

info fields:
- string name 
- module name
- description 
- filepath 
- arguments 
- more?

## Cat 

It might be nice to be able to cat an Action or Validation module to stdout. 

## Editing 

Launch an editor on the module.  Editor specified in EDITOR environment variable.

After a module is edited - code edits should re-compile, as in dev-mode in an elixir project.

Should we have a "mix progen.compile" command?

## Git Commits 

Every Action and Command should use the Git commit logic already built into
ProGen.
- commit if git present 
- construction of git commit messages
- use of Conventional Commit messages 

## Questions 

Long list of clauses: We've specified 13 mix clauses.  When we use "mix help"
it makes for a very long output list.  Is that a problem?  Do other archives
have such a long list of clauses? Maybe we should conolidate under a single
command?

Core question: is Mix the right structure for this project?  Should we use a
standalone script instead (like Xamal...)?  Let's discuss before going forward.

