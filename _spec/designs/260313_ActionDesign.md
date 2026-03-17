# Action Design 

## Overview 

We wish to overhaul the ProGen.Action module prepare or the implementation of a
number of Action modules.  These are preliminary Design Notes to be fed into
the specification and planning process.

## Calling Actions from Scripts

use `ProGen.Script.action(<desc>, <action>, <args>)`

```elixir 
def action(desc, action, opts \\ []) do
  puts(desc)
ProGen.Actions.run(action, opts)
end
```

## Example Actions

`PG.action :echo,     "string"`
`PG.action "Inspect Element", :inspect,  element`
`PG.action "Check Environment", :validate, [{:dir_free, "path"}, :no_mix, :no_git]`

## Action Data Elements

Hardcoded: these elements are hardcoded to the Action module
- name        | action name        | one-line string
- description | action description | multi-line string
- arg_schema  | nimble_options     | nested keyword list

Props: variable elements, validated by the nimble_options cli_schema 

## Inherited Action Functions (defined in the __using__ macro) 

- validate_args 
- usage 

## Behavior functions (@callbacks)

- perform/1 
- ???

## Questions 

- Should there be an Action struct?  Possible fields: module, options, validation, performance_result, ???
- What is the best way to capture Hardcoded data elements:
    * in functions 
    * as module attributes
    * something else?
- Can we create custom module attributes?  eg @name, @description, @arg_schema 
- What is the best name for @arg_schema ?
- If use module attributes for hardcoded data elements, how would we inspect their values from outside the module:
    * as functions defined in the __using__ macro? [eg name(), description(), arg_schema()]
    * something else?

