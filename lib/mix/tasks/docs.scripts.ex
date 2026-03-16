defmodule Mix.Tasks.Docs.Scripts do
  @shortdoc "Generate markdown guides from example scripts"

  @moduledoc """
  Generates a single markdown guide from all example scripts in `scripts/`.

  ```bash
  mix docs.scripts
  ```

  All executable scripts in `scripts/` (files without a `.md` extension)
  are collected into a single `guides/example_scripts.md` file, with each
  script as an `## h2` section containing its description, run command,
  source link, and code block.

  ## Script comment-block convention

  The description for each script section is extracted from a comment block
  immediately after the shebang line. For example:

      #!/usr/bin/env elixir

      # A simple greeting script that demonstrates CLI argument parsing,
      # flags, and basic ProGen.Script usage.

      Mix.install([{:pro_gen, path: "~/src/pro_gen"}])
      ...

  The contiguous `#` comment lines after the shebang become the description
  paragraph in the generated markdown. If no comment block is found, a
  generic fallback is used.
  """

  use Mix.Task

  @scripts_dir "scripts"
  @output_path "guides/example_scripts.md"
  @source_url "https://github.com/andyl/pro_gen/blob/master"

  @impl true
  def run(_args) do
    File.mkdir_p!(Path.dirname(@output_path))

    sections =
      @scripts_dir
      |> File.ls!()
      |> Enum.reject(&String.ends_with?(&1, ".md"))
      |> Enum.reject(&File.dir?(Path.join(@scripts_dir, &1)))
      |> Enum.sort()
      |> Enum.map(fn filename ->
        script_path = Path.join(@scripts_dir, filename)
        source = File.read!(script_path)
        desc = extract_desc(source)

        """
        ## #{filename}

        #{desc}

        **Run it:**

        ```bash
        ./#{script_path} --help
        ```

        **Source:** [`#{script_path}`](#{@source_url}/#{script_path})

        ```elixir
        #{String.trim(source)}
        ```
        """
      end)

    md = "# Example Scripts\n\n" <> Enum.join(sections, "\n")

    File.write!(@output_path, md)
    Mix.shell().info("Generated #{@output_path}")
  end

  defp extract_desc(source) do
    source
    |> String.split("\n")
    |> Enum.drop_while(&String.starts_with?(&1, "#!"))
    |> Enum.drop_while(&(&1 == "" or &1 == "#"))
    |> Enum.take_while(&String.starts_with?(&1, "#"))
    |> case do
      [] ->
        "Example ProGen script."

      comment_lines ->
        comment_lines
        |> Enum.map_join("\n", fn line ->
          line |> String.replace_leading("# ", "") |> String.replace_prefix("#", "")
        end)
        |> String.trim()
    end
  end
end
