defmodule ProGen.Xt.ConfigTest do
  use ExUnit.Case

  setup do
    original_dir = File.cwd!()

    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "pro_gen_test_config_#{:erlang.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)
    File.cd!(tmp_dir)

    on_exit(fn ->
      File.cd!(original_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "read/0" do
    test "returns defaults when no config file exists" do
      assert {:ok, %{use_conventional_commits: false}} = ProGen.Xt.Config.read()
    end

    test "reads .progen.yml with use_conventional_commits: true" do
      File.write!(".progen.yml", "use_conventional_commits: true\n")
      assert {:ok, %{use_conventional_commits: true}} = ProGen.Xt.Config.read()
    end

    test "reads .progen.yml with use_conventional_commits: false" do
      File.write!(".progen.yml", "use_conventional_commits: false\n")
      assert {:ok, %{use_conventional_commits: false}} = ProGen.Xt.Config.read()
    end

    test "reads .progen.yaml alternate extension" do
      File.write!(".progen.yaml", "use_conventional_commits: true\n")
      assert {:ok, %{use_conventional_commits: true}} = ProGen.Xt.Config.read()
    end

    test ".progen.yml takes precedence over .progen.yaml" do
      File.write!(".progen.yml", "use_conventional_commits: true\n")
      File.write!(".progen.yaml", "use_conventional_commits: false\n")
      assert {:ok, %{use_conventional_commits: true}} = ProGen.Xt.Config.read()
    end

    test "returns error for malformed YAML" do
      File.write!(".progen.yml", "  :\n  bad: [unterminated\n")
      assert {:error, msg} = ProGen.Xt.Config.read()
      assert msg =~ "failed to parse"
    end

    test "returns error for non-boolean use_conventional_commits" do
      File.write!(".progen.yml", "use_conventional_commits: \"yes\"\n")
      assert {:error, msg} = ProGen.Xt.Config.read()
      assert msg =~ "must be a boolean"
    end

    test "returns defaults for empty YAML file" do
      File.write!(".progen.yml", "")
      assert {:ok, %{use_conventional_commits: false}} = ProGen.Xt.Config.read()
    end

    test "ignores unknown keys" do
      File.write!(".progen.yml", "unknown_key: hello\nuse_conventional_commits: true\n")
      assert {:ok, %{use_conventional_commits: true}} = ProGen.Xt.Config.read()
    end
  end

  describe "use_conventional_commits?/0" do
    test "returns false when no config file" do
      refute ProGen.Xt.Config.use_conventional_commits?()
    end

    test "returns true when enabled" do
      File.write!(".progen.yml", "use_conventional_commits: true\n")
      assert ProGen.Xt.Config.use_conventional_commits?()
    end

    test "returns false on malformed YAML" do
      File.write!(".progen.yml", "  :\n  bad: [unterminated\n")
      refute ProGen.Xt.Config.use_conventional_commits?()
    end
  end
end
