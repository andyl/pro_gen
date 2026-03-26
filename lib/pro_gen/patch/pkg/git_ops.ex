defmodule ProGen.Patch.Pkg.GitOps do
  @moduledoc """
  Config changes required by the 'git_ops' package.

  Learn more about GitOps config on the README.

  https://github.com/zachdaniel/git_ops#configuration

  After `mix igniter.install git_ops`, the generated `config/config.exs`
  sets `github_handle_lookup?: true` by default. This module patches that
  to `false` to avoid GitHub API calls during changelog generation.

  The operation is idempotent — if the old value is not found, the file
  is left unchanged.
  """

  @doc """
  Replaces `github_handle_lookup?: true` with `false` in `config/config.exs`.

  Returns `:ok` on success (including when already patched), or
  `{:error, reason}` if the config file does not exist.
  """
  def update_git_ops_config do
    file = "config/config.exs"

    if File.exists?(file) do
      ProGen.Patch.File.replace(file, "github_handle_lookup?: true", "github_handle_lookup?: false")
    else
      {:error, "#{file} does not exist — run `mix igniter.install git_ops` first"}
    end
  end

end
