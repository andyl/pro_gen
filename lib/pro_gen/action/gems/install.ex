defmodule ProGen.Action.Gems.Install do
  @moduledoc """
  Install a Ruby gem.
  """

  use ProGen.Action
  alias ProGen.Sys

  @impl true
  def opts_def do
    [
      gems: [type: :string, required: true,  doc: "Space-separated list of gems to install"],
    ]
  end

  @impl true
  def validate(_args), do: [{"lang", [:has_ruby]}]

  # @impl true
  # def depends_on(_args), do: [{"archive.install", package: "igniter_new"}]

  @impl true
  def needed?(args) do
    gems = parse_gems(args)
    Enum.any?(gems, fn gem -> not gem_installed?(gem) end)
  end

  @impl true
  def perform(args) do
    gems = Keyword.fetch!(args, :gems)
    cmd  = "gem install #{gems}" |> ProGen.Xt.StringUtil.compress()
    ProGen.Script.puts(cmd)
    Sys.cmd(cmd)
  end

  @impl true
  def confirm(_result, args) do
    gems = parse_gems(args)
    missing = Enum.reject(gems, &gem_installed?/1)

    case missing do
      [] -> :ok
      _  -> {:error, "gems not installed: #{Enum.join(missing, ", ")}"}
    end
  end

  # -----

  defp parse_gems(args) do
    args |> Keyword.fetch!(:gems) |> String.split()
  end

  defp gem_installed?(gem) do
    {_, code} = System.cmd("gem", ["list", "-i", "^#{gem}$"], stderr_to_stdout: true)
    code == 0
  end
end
