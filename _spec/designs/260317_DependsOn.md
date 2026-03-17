# ProGen DependsOn 

In an action (ProGen.Action), sometimes we'd like to specify that an action
depends on another action.

IE the other action should run BEFORE the current action.

For example, ProGen.Action.Tableau.New does depend_on ProGen.Action.Tableau.Install.

Question: What is the best way to handle this recurring event?

Options:
1) just run the dependency task in the 'perform' function:
    a) how would the dependency be invoked?
    b) by calling ProGen.Actions.run?  or by calling the dependency directly?
2) have a 'depends_on' module attribute
3) have a 'depends_on' behavior

