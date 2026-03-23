defmodule ProGen.Action.Release.Gen do
  @moduledoc """
  Create a new release
  """

  use ProGen.Action
  alias ProGen.Sys

  @impl true
  def validate(_args), do: [{"filesys", [:has_mix, :has_git, {:has_file, "Dockerfile"}]}]

  @impl true
  def perform(_args) do
    cmd = "MIX_ENV=prod mix release"
    ProGen.Script.puts(cmd)
    Sys.cmd(cmd)
  end

  # @impl true
  # def confirm(_result, _args) do
  #   if File.exists?("Dockerfile") do
  #     :ok
  #   else
  #     {:error, "Dockerfile not found"}
  #   end
  # end
end
