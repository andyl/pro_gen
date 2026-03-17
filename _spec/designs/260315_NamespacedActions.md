# Namespaced Actions

With Mix tasks, it is possible to create namespaced actions.

For example:

```bash 
mix myapp.init 
mix myapp.compile 
mix myapp.migrate 
mix init 
mix anotherapp.compile
```

This is done by simply examining the Module name - everything after the
"Mix.Tasks" becomes the task name:

```elixir 
Mix.Tasks.Myapp.Init 
Mix.Tasks.Myapp.Compile
Mix.Tasks.Myapp.Migrate
Mix.Tasks.Init
Mix.Tasks.Anotherapp.Compile
```

By contrast, currently, ProGen has a flat namespace:

```
ProGen.Action.Echo         -> :echo 
ProGen.Action.Test.Echo2   -> :echo2
```

Similar to Mix tasks, we wish for ProGen actions to support namespaces:

```
ProGen.Action.Echo             -> "echo"
ProGen.Action.Test.Echo        -> "test.echo"
ProGen.Action.Test.Echo2       -> "test.echo2"
ProGen.Action.Test.Alt.Echo2   -> "test.alt.echo2"
```

Possibly this will require the use of strings rather than atoms for the action keys.

Desires:
- namespaced actions, per the spec above
- decide on the best representation for action keys: strings vs atoms vs ??
- support nested namespaces, arbitrarily deep

