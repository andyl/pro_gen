defmodule ProGen.Action.PhxNew.Install do
  @moduledoc """
  Install phx.

  Skips installation when the archive is already present.
  Pass `force: true` to reinstall regardless.
  """

  use ProGen.Action

  @option_schema []

  @impl true
  def needed?(_args) do
    not phx_installed?()
  end

  @impl true
  def perform(_args) do
    ProGen.Sys.cmd("mix archive.install hex phx_new --force")
    :ok
  end

  @impl true
  def confirm(_result, _args) do
    if phx_installed?() do
      :ok
    else
      {:error, "phx_new archive was not found after installation"}
    end
  end

  defp phx_installed? do
    case System.cmd("mix", ["archive"], stderr_to_stdout: true) do
      {output, 0} -> output =~ "phx_new"
      _ -> false
    end
  end
end
