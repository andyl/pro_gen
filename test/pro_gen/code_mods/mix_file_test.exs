defmodule ProGen.CodeMods.MixFileTest do
  use ExUnit.Case, async: false

  alias ProGen.CodeMods.MixFile

  @fixture """
  defmodule TestProject.MixProject do
    use Mix.Project

    def project do
      [
        app: :test_project,
        version: "0.1.0"
      ]
    end

    defp deps do
      []
    end
  end
  """

  setup do
    tmp_dir =
      Path.join(System.tmp_dir!(), "pro_gen_mix_file_test_#{:erlang.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)
    {:ok, tmp_dir: tmp_dir}
  end

  defp write_fixture(tmp_dir, content \\ nil) do
    content = content || @fixture
    path = Path.join(tmp_dir, "mix.exs")
    File.write!(path, content)
    path
  end

  describe "add_to_project/3" do
    test "adds a new key to project/0", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = MixFile.add_to_project(:usage_rules, "usage_rules()", path: path)
      content = File.read!(path)
      assert content =~ "usage_rules: usage_rules()"
    end

    test "is idempotent — second call returns :already_exists", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = MixFile.add_to_project(:foo, ":bar", path: path)
      assert {:ok, :already_exists} = MixFile.add_to_project(:foo, ":bar", path: path)
    end

    test "does not modify existing keys", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :already_exists} = MixFile.add_to_project(:app, ":other", path: path)
      content = File.read!(path)
      assert content =~ "app: :test_project"
    end

    test "preserves existing entries when adding new key", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)

      assert {:ok, :updated} =
               MixFile.add_to_project(:description, "\"A test project\"", path: path)

      content = File.read!(path)
      assert content =~ "app: :test_project"
      assert content =~ "version: \"0.1.0\""
      assert content =~ "description: \"A test project\""
    end

    test "returns error for missing file" do
      assert {:error, msg} = MixFile.add_to_project(:foo, ":bar", path: "/nonexistent/mix.exs")
      assert msg =~ "could not read"
    end

    test "returns error when project/0 is missing", %{tmp_dir: tmp_dir} do
      path =
        write_fixture(tmp_dir, """
        defmodule TestProject.MixProject do
          use Mix.Project
        end
        """)

      assert {:error, msg} = MixFile.add_to_project(:foo, ":bar", path: path)
      assert msg =~ "project/0"
    end
  end

  describe "add_defp/4" do
    test "adds a new private function", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)

      body = """
      defp usage_rules do
        [file: "CLAUDE.md"]
      end
      """

      assert {:ok, :updated} = MixFile.add_defp(:usage_rules, 0, body, path: path)
      content = File.read!(path)
      assert content =~ "defp usage_rules do"
      assert content =~ ~s(file: "CLAUDE.md")
    end

    test "is idempotent — second call returns :already_exists", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)

      body = """
      defp my_func do
        :ok
      end
      """

      assert {:ok, :updated} = MixFile.add_defp(:my_func, 0, body, path: path)
      assert {:ok, :already_exists} = MixFile.add_defp(:my_func, 0, body, path: path)
    end

    test "does not overwrite existing defp", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)

      assert {:ok, :already_exists} =
               MixFile.add_defp(:deps, 0, "defp deps, do: [:new]", path: path)

      content = File.read!(path)
      # Original deps function should still be intact
      assert content =~ "defp deps do"
    end

    test "preserves existing module content", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)

      body = """
      defp my_config do
        [enabled: true]
      end
      """

      assert {:ok, :updated} = MixFile.add_defp(:my_config, 0, body, path: path)
      content = File.read!(path)
      # All original content should still be present
      assert content =~ "use Mix.Project"
      assert content =~ "def project do"
      assert content =~ "defp deps do"
      assert content =~ "defp my_config do"
    end

    test "returns error for missing file" do
      assert {:error, msg} =
               MixFile.add_defp(:foo, 0, "defp foo, do: :ok", path: "/nonexistent/mix.exs")

      assert msg =~ "could not read"
    end
  end
end
