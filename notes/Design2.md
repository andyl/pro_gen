# ProGen Design Notes - Version 2

This document follows the initial design notes in Version 1.

## Script DSL 

Commands:

- cmd "DESCRIPTION", "CMD"
- op "DESCRIPTION", OPERATION, ARGS
- msg "TEXT"
- ...

DESCRIPTION | a string
CMD         | a bash command (string)
OPERATION   | An Operation Name (string?)
ARGS        | Operation arguments (keyword list)

