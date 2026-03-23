defmodule ProGen.Action.Release.New do
  @moduledoc """
  Create new release files. (Dockerfile)
  """

  use ProGen.Action
  alias ProGen.Sys

  @impl true
  def validate(_args), do: [{"filesys", [:has_mix, :has_git]}]

  @impl true
  def needed?(_args) do
    not File.exists?("Dockerfile")
  end

  @impl true
  def perform(_args) do
    cmd = "mix phx.gen.release --docker "
    ProGen.Script.puts(cmd)
    Sys.cmd(cmd)
  end

  @impl true
  def confirm(_result, _args) do
    if File.exists?("Dockerfile") do
      :ok
    else
      {:error, "Dockerfile not found"}
    end
  end
end
