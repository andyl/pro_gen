# ProGen Design Notes - Version 2

This document follows the initial design notes in Version 1.

## Script DSL

Commands:

- cmd "DESCRIPTION", "CMD"
- op "DESCRIPTION", ACTION, ARGS
- msg "TEXT"
- ...

DESCRIPTION | a string
CMD         | a bash command (string)
ACTION      | An Action Name (string?)
ARGS        | Action arguments (keyword list)

