# ProGen Action Validate

In an action (ProGen.Action), sometimes we'd like to specify a validation to be
run before #perform.

For example, in ProGen.Actions.Igniter.Install, I should not execute #perform until I know:
- that there is a mix.exs file in the current directory 
- that there is a .git directory in the current directory 

If one or both of these things are missing, the action should halt execution
and raise with an error message.

We already have nice validation tooling:
- ProGen.Validate.* 
- ProGen.Script.validate 

Probably we need a nice way to call out to these validations in the
ProGen.Action call chain.

Question: What is the best way to specify these Action validations?

Options:
1) just run the validation in the 'perform' function:
    a) how would the validation be invoked?
    b) by calling something in ProGen.Validate?
2) have a 'validate' module attribute?
3) have a 'validate' behavior?

