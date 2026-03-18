defmodule ProGen.Action.IgniterNew.Install do
  @moduledoc """
  Install igniter.

  Skips installation when the archive is already present.
  Pass `force: true` to reinstall regardless.
  """

  use ProGen.Action

  @opts_def []

  @impl true
  def needed?(_args) do
    not igniter_installed?()
  end

  @impl true
  def perform(_args) do
    ProGen.Sys.cmd("mix archive.install hex igniter_new --force")
    :ok
  end

  @impl true
  def confirm(_result, _args) do
    if igniter_installed?() do
      :ok
    else
      {:error, "igniter_new archive was not found after installation"}
    end
  end

  defp igniter_installed? do
    case System.cmd("mix", ["archive"], stderr_to_stdout: true) do
      {output, 0} -> output =~ "igniter_new"
      _ -> false
    end
  end
end
