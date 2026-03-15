# Multi Validation Design

Currently we have a single validation action: ProGen.Action.Validate.

I would like to be able to make the Validation scheme extensible, so that
anyone can add another Validation module.

Let's discuss design alternatives.

## Validations as Actions 

We could maintain Validations as a type of Action 

```
ProGen.Action.Validate.Basics
ProGen.Action.Validate.Networking
ProGen.Action.Validate.Environment
```

A 'Validation' could be a special type of Action that has two behaviors:

```
ProGen.Action
ProGen.Actions.Validate  # I don't really love this...
```

## Validations as a Separate Behavior 

We could maintain Validations as a Separate type of Behavior 

```
ProGen.Validate                     # The behavior 
ProGen.Validate.Basics              # An implementation module 
ProGen.Validate.Networking          # An implementation module 
ProGen.Validate.Environment         # An implementation module
```

With this approach we would need:

- a Script function `ProGen.Script.validate "Description", "basics", [:condition1, :condition2]`
- validation 'discovery' code, for 3rd party extensibility, like we have with Actions 

## Decisions 

Questions: 
- can a module inherit two behaviors?  Please confirm.
- would it be a better design to have a completely separate and distinct behavior modules:
    * a behavior module ProGen.Action 
    * a behavior module ProGen.Validate  (Should it be called "Validate" or "Validation")
- is there another design alternative beyond the two that I have described here?

