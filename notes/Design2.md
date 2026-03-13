# ProGen Design Notes - Version 2

This document follows the initial design notes in Version 1.

## Script DSL

Commands:

- command "DESCRIPTION", "CMD"
- action "DESCRIPTION", ACTION, ARGS
- puts "TEXT"
- ...

DESCRIPTION | a string
CMD         | a bash command (string)
ACTION      | An Action Name (string?)
ARGS        | Action arguments (keyword list)

