defmodule ProGen.Action.Deps.Only.Remove do
  @moduledoc """
  Remove the 'only' argument from a dependency in mix.exs.
  """

  use ProGen.Action

  @impl true
  def opts_def do
    [
      dep: [type: :string, required: true, doc: "dependency to modify" ]
    ]
  end

  @impl true
  def validate(args) do
    IO.inspect(args, label: "VALIDATE")
    [
      {"filesys", [{:has_file, "mix.exs"}]},
      {"mix",     [{:has_dep,  args[:dep]}]}
    ]
  end

  # @impl true
  # def depends_on(_args) do
  #   [{"deps.install", [deps: "usage_rules"]}]
  # end

  # @impl true
  # def needed?(_args) do
  #   not File.exists?("RULES.md")
  # end

  @impl true
  def perform(args) do
    # Make the change
    IO.inspect(args, label: "PERFORM")
    ProGen.CodeMods.DepsTweaks.remove_only(args[:dep])
    :ok
  end

  # @impl true
  # def confirm(_result, _args) do
  #   if File.exists?("RULES.md") do
  #     :ok
  #   else
  #     {:error, "RULES.md was not created"}
  #   end
  # end

end
