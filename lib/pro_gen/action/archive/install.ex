defmodule ProGen.Action.Archive.Install do
  @moduledoc """
  Install a hex archive.

  Skips installation when the archive is already present.
  Pass `force: true` to reinstall regardless.
  """

  use ProGen.Action

  @impl true
  def opts_def do
    [package: [type: :string, required: true, doc: "The package to install"]]
  end

  @impl true
  def needed?(args) do
    pkg = Keyword.fetch!(args, :package)
    not archive_installed(pkg)
  end

  @impl true
  def perform(args) do
    pkg = Keyword.fetch!(args, :package)
    ProGen.Xt.Sys.cmd("mix archive.install hex #{pkg} --force")
    :ok
  end

  @impl true
  def confirm(_result, args) do
    pkg = Keyword.fetch!(args, :package)

    if archive_installed(pkg) do
      :ok
    else
      {:error, "#{pkg} archive was not found after installation"}
    end
  end

  defp archive_installed(pkg) do
    case System.cmd("mix", ["archive"], stderr_to_stdout: true) do
      {output, 0} -> output =~ pkg
      _ -> false
    end
  end
end
