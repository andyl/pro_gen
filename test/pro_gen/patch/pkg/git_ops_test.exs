defmodule ProGen.Patch.Pkg.GitOpsTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  describe "update_git_ops_config/0" do
    test "replaces github_handle_lookup? true with false", %{tmp_dir: tmp} do
      config_dir = Path.join(tmp, "config")
      config_file = Path.join(config_dir, "config.exs")
      File.mkdir_p!(config_dir)

      File.write!(config_file, """
      import Config

      config :git_ops,
        mix_project: MyApp.MixProject,
        changelog_file: "CHANGELOG.md",
        repository_url: "https://github.com/me/my_app",
        manage_mix_version?: true,
        manage_readme_version: true,
        github_handle_lookup?: true
      """)

      File.cd!(tmp, fn ->
        assert :ok = ProGen.Patch.Pkg.GitOps.update_git_ops_config()
        contents = File.read!(config_file)
        assert String.contains?(contents, "github_handle_lookup?: false")
        refute String.contains?(contents, "github_handle_lookup?: true")
      end)
    end

    test "is idempotent when already patched", %{tmp_dir: tmp} do
      config_dir = Path.join(tmp, "config")
      config_file = Path.join(config_dir, "config.exs")
      File.mkdir_p!(config_dir)

      File.write!(config_file, """
      import Config

      config :git_ops,
        github_handle_lookup?: false
      """)

      File.cd!(tmp, fn ->
        assert :ok = ProGen.Patch.Pkg.GitOps.update_git_ops_config()
        contents = File.read!(config_file)
        assert String.contains?(contents, "github_handle_lookup?: false")
      end)
    end

    test "returns error when config/config.exs does not exist", %{tmp_dir: tmp} do
      File.cd!(tmp, fn ->
        assert {:error, msg} = ProGen.Patch.Pkg.GitOps.update_git_ops_config()
        assert String.contains?(msg, "does not exist")
      end)
    end
  end
end
