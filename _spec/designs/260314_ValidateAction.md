# Validate Action 

## Overview 

We wish to create a validation action, which packages a number of
configureable/selectable validations into one action. These are preliminary
Design Notes to be fed into the specification and planning process.

## Name of the Action 

The action should be called "ProGen.Action.Validate".

## Calling Validations from Scripts 

```elixir 
alias ProGen.Script, as: PG
PG.action "Check Dependencies", :validate, [{:dir_free, "path"}, :no_mix, :no_git]
```

## Validation Arguments and the Check Function

The validate action takes a list of arguments.  Each argument is (most likely) 
an atom or a tuple.

The validation action has a set of built-in check functions.  (not sure if the
check function should be public or private) Check function has the following
signature:

check/1 -> :ok or {:error, message}

Here's a pseudocode example

```elixir 
@doc "Returns :ok if 'mix.exs' does not exist."
def check(:no_mix) do 
  check({:no_file, "mix.exs"})
end

@doc "Returns :ok if 'mix.exs' exists."
def check(:has_mix) do 
  check({:has_file, "mix.exs"})
end

@doc "Returns :ok if path does not exist."
def check({:no_file, path}) do 
  case File.exists?(path) do 
    true -> {:error, "File (#{path}) already present"}
    false -> :ok 
  end
end

@doc "Returns :ok if path exists."
def check({:has_file, path}) do 
  case File.exists?(path) do 
    false -> {:error, "File (#{path}) not present"}
    true -> :ok 
  end
end

@doc "Returns :ok if directory does not exist."
def check({:no_dir, path}) do 
  case File.dir?(path) do 
    true -> {:error, "Directory (path) already present"}
    false -> :ok 
  end
end

@doc "Returns :ok if directory exists."
def check({:has_dir, path}) do 
  case File.dir?(path) do 
    false -> {:error, "Directory (path) not present"}
    true -> :ok 
  end
end

```

## Introspectible Check Function 

Over time, more check-function clauses will be added.  I'd like developers to
discover the current list of valid clauses, without having to read the code.
Possible introspection methods: documentation, error messages, lookup
functions, etc.

How to do this?

Idea1: let the check function be some sort of macro.
Idea2: drive the check function from a data structure - 

```elixir 
@checks %{
    {:has_dir, path} => 
      desc: "Returns :ok if directory exists", 
      func: fn {:has_dir, path} -> 
          case File.dir?(path) do 
            false -> {:error, "Directory (path) not present"}
            true -> :ok 
          end
       end, 
    ...
     
}
```

Open to other ideas.  

Note: I do NOT want to solve the 'discoverability' issue by putting each
'check' clause into a separate module.  Everything must be self-contained in
ProGen.Actions.Validate.
