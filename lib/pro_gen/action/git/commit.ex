defmodule ProGen.Action.Git.Commit do
  @moduledoc """
  Stages all changes and commits with the given message.
  """

  use ProGen.Action

  @description "Stage all changes and commit"
  @option_schema [
    message: [type: :string, required: true, doc: "Commit message"]
  ]

  @impl true
  def needed?(_args) do
    if File.dir?(".git") do
      case System.cmd("git", ["status", "--porcelain"], stderr_to_stdout: true) do
        {output, 0} -> String.trim(output) != ""
        _ -> false
      end
    else
      false
    end
  end

  @impl true
  def perform(args) do
    message = Keyword.fetch!(args, :message)

    with :ok <- ProGen.Sys.syscmd("git", ["add", "."]) do
      ProGen.Sys.syscmd("git", ["commit", "-m", message])
    end
  end

  @impl true
  def confirm(result, _args) do
    case result do
      :ok -> :ok
      {:error, _} -> {:error, "git commit failed"}
    end
  end
end
