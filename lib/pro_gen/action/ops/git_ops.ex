defmodule ProGen.Action.Ops.GitOps.Setup do
  @moduledoc """
  Setup GitOps

  Learn more about GitOps config on the README.

  https://github.com/zachdaniel/git_ops#configuration

  This Action skips installation when the dependency is already present.
  Pass `force: true` to reinstall regardless.

  Updates the mix file with initial UsageRules configuration. See
  ProGen.Patch.Pkg.GitOps for the patch code.

  The default configuration ingests all usage_rules for all dependencies
  and creates a file `RULES.md`.

  The project maintainer must perform the following periodic actions:

  1. run `mix usage_rules.sync` as dependencies change
  2. visit the `usage_rules` config in the mix.exs file to update skills
  """

  use ProGen.Action

  @impl true
  def validate(_args), do: [{"filesys", [:has_git, :has_mix]}]

  @impl true
  def depends_on(_args) do
    [{"deps.install", [deps: "usage_rules", only: "dev"]}]
  end

  @impl true
  def needed?(_args) do
    #
    true
  end

  @impl true
  def perform(_args) do
    # these are idempotent...
    ProGen.Patch.Pkg.GitOps.install_config_block()
    ProGen.Patch.Pkg.GitOps.update_mix_version()
    # initial sync
    ProGen.Xt.Sys.cmd("mix git_opts.release --initial")
    :ok
  end

  @impl true
  def confirm(_result, _args) do
    # if File.exists?("RULES.md") do
    #   :ok
    # else
    #   {:error, "RULES.md was not created"}
    # end
    :ok
  end

  # -----

  def config_block do
    """
    config :git_ops,
      # see https://github.com/zachdaniel/git_ops#configuration
      mix_project: Mix.Project.get!(),
      changelog_file: "CHANGELOG.md",

      # for release notes: if true, use git user.email to find
      # user on github, else use author name in the commit
      github_handle_lookup?: false,
      github_api_base_url: "https://api.github.com",

      # repository_url: "https://github.com/my_user/my_repo",
      types: [
        # The type `style` is not shown in the changelog...
        style: [ hidden?: true ],
        refactor: [ hidden?: true ],
        build: [ hidden?: true ],
        ci: [ hidden?: true ],
        # The type `important` gets a changelog section header
        important: [ header: "Important Changes" ]
      ],
      tags: [
        # Only add commits to the changelog that have the "backend" tag
        # allowed: ["backend"],
        # Filter out or not commits that don't contain tags
        allow_untagged?: true
      ],
      # manage mix version in `mix.exs`
      manage_mix_version?: true,
      # manage the version in `README.md`
      manage_readme_version: false,
      version_tag_prefix: "v"
    """
    |> String.trim()
  end
end
