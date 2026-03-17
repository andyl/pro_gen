# New Validations

In the module ProGen.Action.Validate, add some new validations:

```
%{
  term: :has_igniter,
  desc: "Pass if igniter is installed",
  fail: "No igniter (install with 'mix archive.install hex igniter_new --force')",
  test: fn _ -> <TBD - please write> end
},
%{
  term: :no_igniter,
  desc: "Pass if igniter is not installed",
  fail: "Igniter is installed",
  test: fn _ -> <TBD - please write> end
},
%{
  term: :has_phx_new,
  desc: "Pass if phx_new is installed",
  fail: "No phx_new (install with 'mix archive.install hex phx_new_new --force')",
  test: fn _ -> <TBD - please write> end
},
%{
  term: :no_phx_new,
  desc: "Pass if phx_new is not installed",
  fail: "phx_new is installed",
  test: fn _ -> <TBD - please write> end
},
%{
  term: :has_elixir,
  desc: "Pass if elixir is installed",
  fail: "No elixir - please install",
  test: fn _ -> <TBD - please write> end
},
%{
  term: :no_elixir,
  desc: "Pass if elixir is not installed",
  fail: "elixir is installed",
  test: fn _ -> <TBD - please write> end
},
```

Use the given term, desc and fail attributes.

Write the tests:
- for igniter and phx_new - maybe check by grepping the output of 'mix help'.
- for elixir, maybe check the output of 'which elixir'

Please make the tests as concise as possible - ideally to fit on a single line.

Add these finished validations to the 'all_checks' data structure.
