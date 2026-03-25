defmodule ProGen.Xtool.AutoCommit do
  @moduledoc """
  Shared auto-commit logic used by `ProGen.Script` and CLI Mix tasks.

  After an action or command succeeds, this module stages all changes and
  commits with a formatted message. Respects the `:auto_commit` application
  env and per-invocation `commit: false` option.
  """

  require Logger

  @doc """
  Conditionally auto-commits after a successful operation.

  Checks `Application.get_env(:pro_gen, :auto_commit, true)` and
  `Keyword.get(opts, :commit, true)`. If both are truthy, formats
  the commit message and runs the `git.commit` action.

  Always returns `:ok` — commit failures are logged as warnings.
  """
  def auto_commit(desc, commit_type, opts \\ []) do
    if Application.get_env(:pro_gen, :auto_commit, true) and
         Keyword.get(opts, :commit, true) do
      message = format_commit_message(desc, commit_type)

      case ProGen.Actions.run("git.commit", message: message) do
        :ok ->
          :ok

        {:ok, :skipped} ->
          :ok

        {:error, reason} ->
          Logger.warning("Auto-commit failed: #{inspect(reason)}")
          :ok
      end
    else
      :ok
    end
  end

  @doc """
  Formats a commit message based on conventional commits config.

  With CC enabled: `"<commit_type>: [ProGen] <desc>"`
  Without CC:      `"[ProGen] <desc>"`
  """
  def format_commit_message(desc, commit_type) do
    if ProGen.Config.use_conventional_commits?() do
      "#{commit_type}: [ProGen] #{desc}"
    else
      "[ProGen] #{desc}"
    end
  end
end
