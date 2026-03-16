defmodule Mix.Tasks.Docs.Scripts do
  @shortdoc "Generate markdown guides from example scripts"

  @moduledoc """
  Generates markdown guide files from example scripts in `scripts/`.

  ```bash
  mix docs.scripts
  ```

  For each executable script in `scripts/` (files without a `.md` extension),
  a markdown wrapper is written to `guides/scripts/<name>.md`. Any existing
  `.md` files in `guides/scripts/` are removed first to keep the output clean.

  ## Script comment-block convention

  The description for each generated guide is extracted from a comment block
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
  @guides_dir "guides/scripts"
  @source_url "https://github.com/andyl/pro_gen/blob/master"

  @impl true
  def run(_args) do
    File.mkdir_p!(@guides_dir)

    # Remove old generated markdown
    @guides_dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".md"))
    |> Enum.each(fn file ->
      path = Path.join(@guides_dir, file)
      File.rm!(path)
    end)

    # Generate new markdown from scripts
    @scripts_dir
    |> File.ls!()
    |> Enum.reject(&String.ends_with?(&1, ".md"))
    |> Enum.reject(&File.dir?(Path.join(@scripts_dir, &1)))
    |> Enum.sort()
    |> Enum.each(fn filename ->
      script_path = Path.join(@scripts_dir, filename)
      source = File.read!(script_path)
      desc = extract_desc(source)

      md = """
      # #{filename}

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

      md_path = Path.join(@guides_dir, "#{filename}.md")
      File.write!(md_path, md)
      Mix.shell().info("Generated #{md_path}")
    end)
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
