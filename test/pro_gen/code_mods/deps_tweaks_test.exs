defmodule ProGen.CodeMods.DepsTweaksTest do
  use ExUnit.Case, async: false

  alias ProGen.CodeMods.DepsTweaks

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
      [
        {:igniter, "~> 0.6"},
        {:ex_doc, "~> 0.31", only: :dev, runtime: false},
        {:usage_rules, "~> 0.2", only: [:dev, :test]},
        {:nimble_options, "~> 1.0"}
      ]
    end
  end
  """

  setup do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "pro_gen_deps_tweaks_test_#{:erlang.unique_integer([:positive])}"
      )

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

  describe "remove_only/2" do
    test "removes only: :atom from a dependency", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = DepsTweaks.remove_only(:ex_doc, path: path)
      content = File.read!(path)
      assert content =~ ~s({:ex_doc, "~> 0.31", runtime: false})
      refute content =~ "only: :dev"
    end

    test "removes only: [list] from a dependency", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = DepsTweaks.remove_only(:usage_rules, path: path)
      content = File.read!(path)
      assert content =~ ~s({:usage_rules, "~> 0.2"})
      refute content =~ "usage_rules, \"~> 0.2\", only:"
    end

    test "returns :already_set when no only: option present", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :already_set} = DepsTweaks.remove_only(:nimble_options, path: path)
    end

    test "is idempotent — second call returns :already_set", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = DepsTweaks.remove_only(:usage_rules, path: path)
      assert {:ok, :already_set} = DepsTweaks.remove_only(:usage_rules, path: path)
    end

    test "preserves other dependencies", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = DepsTweaks.remove_only(:ex_doc, path: path)
      content = File.read!(path)
      assert content =~ ~s({:igniter, "~> 0.6"})
      assert content =~ ~s({:usage_rules, "~> 0.2", only: [:dev, :test]})
      assert content =~ ~s({:nimble_options, "~> 1.0"})
    end

    test "returns error for missing dependency", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:error, msg} = DepsTweaks.remove_only(:nonexistent, path: path)
      assert msg =~ "not found"
    end

    test "raises for missing mix.exs" do
      assert_raise RuntimeError, ~r/mix.exs not found/, fn ->
        DepsTweaks.remove_only(:foo, path: "/nonexistent/mix.exs")
      end
    end
  end

  describe "set_only/3" do
    test "adds only: to a dependency without one", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = DepsTweaks.set_only(:nimble_options, [:dev, :test], path: path)
      content = File.read!(path)
      assert content =~ ~s({:nimble_options, "~> 1.0", only: [:dev, :test]})
    end

    test "replaces existing only: :atom with a list", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = DepsTweaks.set_only(:ex_doc, [:dev, :test], path: path)
      content = File.read!(path)
      assert content =~ "only: [:dev, :test]"
      # runtime: false should still be present
      assert content =~ "runtime: false"
    end

    test "replaces existing only: [list] with a different list", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = DepsTweaks.set_only(:usage_rules, [:dev], path: path)
      content = File.read!(path)
      assert content =~ ~s({:usage_rules, "~> 0.2", only: [:dev]})
    end

    test "returns :already_set when only: already matches", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :already_set} = DepsTweaks.set_only(:usage_rules, [:dev, :test], path: path)
    end

    test "supports single atom env", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = DepsTweaks.set_only(:nimble_options, :dev, path: path)
      content = File.read!(path)
      assert content =~ ~s({:nimble_options, "~> 1.0", only: :dev})
    end

    test "is idempotent — second call returns :already_set", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:ok, :updated} = DepsTweaks.set_only(:igniter, [:dev], path: path)
      assert {:ok, :already_set} = DepsTweaks.set_only(:igniter, [:dev], path: path)
    end

    test "returns error for missing dependency", %{tmp_dir: tmp_dir} do
      path = write_fixture(tmp_dir)
      assert {:error, msg} = DepsTweaks.set_only(:nonexistent, [:dev], path: path)
      assert msg =~ "not found"
    end

    test "raises for missing mix.exs" do
      assert_raise RuntimeError, ~r/mix.exs not found/, fn ->
        DepsTweaks.set_only(:foo, [:dev], path: "/nonexistent/mix.exs")
      end
    end
  end
end
