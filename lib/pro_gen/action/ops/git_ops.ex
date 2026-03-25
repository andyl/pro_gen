defmodule ProGen.Action.Ops.GitOps do
  @moduledoc """
  Installs and Configures GitOps

  # Add documentation that describes
  # The function of GitOps
  # The URL of the GitOps repo (https://github.com/zachdaniel/git_ops)
  #
  """

  use ProGen.Action
  alias ProGen.Xt.Sys, as: Sys

  @impl true
  def validate(_args), do: [{"filesys", [:has_mix, :has_git]}]

  @impl true
  def depends_on(_args) do
    [
      "ops.conv_commit_hook",
      {"deps.install", deps: "git_ops", only: "dev"}
    ]
  end

  @impl true
  def needed?(_args) do
    not (File.exists?(".githooks/commit-msg") and File.exists?("bin/install-git-hooks.sh"))
  end

  @impl true
  def perform(_args) do
    File.mkdir_p!(".githooks")
    File.mkdir_p!("bin")

    File.write!(".githooks/commit-msg", commit_msg_hook())
    File.chmod!(".githooks/commit-msg", 0o755)

    File.write!("bin/install-git-hooks.sh", install_script())
    File.chmod!("bin/install-git-hooks.sh", 0o755)

    if File.exists?("README.md") do
      ProGen.Patch.File.append_block("README.md", readme_text())
    end

    Sys.cmd("bin/install-git-hooks.sh")

    IO.puts("Git hooks have been installed")
    IO.puts("Conventional Commit messages are enforced")

    :ok
  end

  @impl true
  def confirm(_result, _args) do
    cond do
      not File.exists?(".githooks/commit-msg") ->
        {:error, ".githooks/commit-msg was not created"}

      not File.exists?("bin/install-git-hooks.sh") ->
        {:error, "bin/install-git-hooks.sh was not created"}

      true ->
        :ok
    end
  end

  # -----

  defp readme_text do
    """
    ## Git Hooks

    We enforce Conventional Commit messages locally so the repo stays clean.

    Learn more at [https://www.conventionalcommits.org](https://www.conventionalcommits.org).

    After cloning, install the githook. Run once:
    ```bash
    ./bin/install-git-hooks.sh
    ```

    After the githook is installed - test by trying to commit an invalid
    message.

    ```bash
    echo hello > tmpfile.txt
    git add .
    git commit -am'My Bad Commit Message'
    ```
    """
    |> String.trim()
  end

  defp commit_msg_hook do
    """
    #!/usr/bin/env bash
    # .githooks/commit-msg
    # Lints commit messages to enforce Conventional Commits format
    # (you can customize the regex or replace with commitlint, etc.)

    COMMIT_MSG_FILE="$1"

    # Skip empty messages or merge/revert commits (Git handles those)
    if [[ -z "$(cat "$COMMIT_MSG_FILE")" ]]; then
        echo "Commit message cannot be empty."
        exit 1
    fi

    # Basic Conventional Commits regex:
    # type[(scope)]: description
    # Allowed types: feat, fix, chore, docs, test, style, refactor, perf, build, ci, revert
    if ! head -n1 "$COMMIT_MSG_FILE" | grep -qE '^(feat|fix|chore|docs|test|style|refactor|perf|build|ci|revert)(\\([a-z0-9-]+\\))?!?: .+'; then
        echo "Invalid commit message format."
        echo "   Use Conventional Commits: <type>[optional scope]: <description>"
        echo "   Example: feat(api): add user authentication"
        echo "   Full spec: https://www.conventionalcommits.org"
        exit 1
    fi

    # Optional: enforce reasonable length
    if [[ $(head -n1 "$COMMIT_MSG_FILE" | wc -c) -gt 100 ]]; then
        echo "Commit message subject is too long (max 100 chars recommended)."
        exit 1
    fi

    echo "Commit message looks good!"
    exit 0
    """
    |> String.trim()
  end

  defp install_script do
    """
    #!/usr/bin/env bash
    # bin/install-git-hooks.sh
    HOOKS_DIR="$(git rev-parse --show-toplevel)/.githooks"
    git config --local core.hooksPath "$HOOKS_DIR"
    echo "Git hooks installed from .githooks/"
    """
    |> String.trim()
  end
end
