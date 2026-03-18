# 260318 File Mods

## Introduction 

When I install the `usage_rules` dependency, it gives instruction to do manual post-installation configuration:

```
* UsageRules: Manage your AGENTS.md file and agent skills from dependencies.

  Add configuration to your mix.exs project/0.:

      def project do
        [
          usage_rules: usage_rules()
        ]
      end

      defp usage_rules do
        # Example for those using claude.
        [
          file: "CLAUDE.md",
          # rules to include directly in CLAUDE.md
          usage_rules: ["usage_rules:all"],
          skills: [
            location: ".claude/skills",
            # build skills that combine multiple usage rules
            build: [
              "ash-framework": [
                # The description tells people how to use this skill.
                description: "Use this skill working with Ash Framework or any of its extensions. Always consult this when making any domain changes, features or fixes.",
                # Include all Ash dependencies
                usage_rules: [:ash, ~r/^ash_/]
              ],
              "phoenix-framework": [
                description: "Use this skill working with Phoenix Framework. Consult this when working with the web layer, controllers, views, liveviews etc.",
                # Include all Phoenix dependencies
                usage_rules: [:phoenix, ~r/^phoenix_/]
              ]
            ]
          ]
        ]
      end

  Then run:

      mix usage_rules.sync

  For more info: `mix help usage_rules.sync`
```

So there are two manual operations: 

1. add a line `usage_rules: usage_rules(),` to the `def project` list in mix.exs.

2. add a private function `defp usage_rules` 

I need a codemod to make these changes.  The changes need to be automated and idempotent.

The codemode module should be generic and reusable, probably relying on either 'igniter' and/or 'sourceror' to make changes.

The codemode function would look something like:

```
def line_in_project_block(mixfile, line)

def private_function(mixfile, function_text)
```

The exact function signatures are TBD.

