defmodule ProGen.Action.Deps.Only.Remove do
  @moduledoc """
  Remove the 'only' argument from one or more dependencies in mix.exs.

  The `deps` option is a space-separated string of dependency names.
  """

  use ProGen.Action

  @impl true
  def opts_def do
    [
      deps: [type: :string, required: true, doc: "space-separated dependencies to modify"]
    ]
  end

  @impl true
  def validate(args) do
    dep_checks = args[:deps] |> String.split(" ", trim: true) |> Enum.map(&{:has_dep, &1})

    [
      {"filesys", [{:has_file, "mix.exs"}]},
      {"mix", dep_checks}
    ]
  end

  @impl true
  def perform(args) do
    args[:deps]
    |> String.split(" ", trim: true)
    |> Enum.each(&ProGen.Patch.MixDeps.remove_only/1)

    :ok
  end
end
