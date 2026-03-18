defmodule ProGen.Action.TableauNew.Install do
  @moduledoc """
  Install tableau.

  Skips installation when the archive is already present.
  Pass `force: true` to reinstall regardless.
  """

  use ProGen.Action

  @opts_def []

  @impl true
  def needed?(_args) do
    not tableau_installed?()
  end

  @impl true
  def perform(_args) do
    ProGen.Sys.cmd("mix archive.install hex tableau_new --force")
    :ok
  end

  @impl true
  def confirm(_result, _args) do
    if tableau_installed?() do
      :ok
    else
      {:error, "tableau_new archive was not found after installation"}
    end
  end

  defp tableau_installed? do
    case System.cmd("mix", ["archive"], stderr_to_stdout: true) do
      {output, 0} -> output =~ "tableau_new"
      _ -> false
    end
  end
end
