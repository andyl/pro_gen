defmodule ProGen.Action.MixCompletions.Run do
  @moduledoc """
  Run mix completions

  Skips creation when the project directory already exists.
  Pass `force: true` to regenerate regardless.
  """

  use ProGen.Action

  @cache_file ".mix_complete.cache"

  @impl true
  def validate(_args), do: [{"filesys", [{:has_file, "mix.exs"}]}]

  @impl true
  def depends_on(_args) do
    [{"archive.install", [package: "mix_completions"]}]
  end

  @impl true
  def needed?(_args) do
    # always run - even if @cache_file exists
    # it rebuilds cache if mix tasks have changed
    true
  end

  @impl true
  def perform(_args) do
    ProGen.Sys.cmd("mix complete.bash > @cache_file")
  end

  @impl true
  def confirm(_result, _args) do
    if File.exists?(@cache_file) do
      :ok
    else
      {:error, "cache file '#{@cache_file}' was not created"}
    end
  end
end
