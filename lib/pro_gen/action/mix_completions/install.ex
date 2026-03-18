defmodule ProGen.Action.MixCompletions.Install do
  @moduledoc """
  Install mix_completions.

  Skips installation when the archive is already present.
  Pass `force: true` to reinstall regardless.
  """

  use ProGen.Action

  @opts_def []

  @impl true
  def needed?(_args) do
    not completions_installed?()
  end

  @impl true
  def perform(_args) do
    ProGen.Sys.cmd("mix archive.install hex mix_completions --force")
    :ok
  end

  @impl true
  def confirm(_result, _args) do
    if completions_installed?() do
      :ok
    else
      {:error, "mix_completions archive was not found after installation"}
    end
  end

  defp completions_installed? do
    case System.cmd("mix", ["archive"], stderr_to_stdout: true) do
      {output, 0} -> output =~ "mix_completions"
      _ -> false
    end
  end
end
