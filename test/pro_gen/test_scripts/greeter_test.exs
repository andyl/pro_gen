defmodule ProGen.ScriptTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @schema [
    name: "greeter",
    description: "A greeting script",
    version: "0.1.0",
    options: [
      name: [
        short: "-n",
        long: "--name",
        help: "Name to greet",
        required: true
      ]
    ],
    flags: [
      loud: [
        short: "-l",
        long: "--loud",
        help: "Greet loudly"
      ]
    ]
  ]

  describe "parse_args/2" do
    test "returns {:ok, %ParseResult{}} with correct values" do
      assert {:ok, parsed} = ProGen.Script.parse_args(@schema, ["--name", "World"])
      assert parsed.options[:name] == "World"
      assert parsed.flags[:loud] == false
    end

    test "returns {:ok, %ParseResult{}} with flag set" do
      assert {:ok, parsed} = ProGen.Script.parse_args(@schema, ["--name", "World", "--loud"])
      assert parsed.options[:name] == "World"
      assert parsed.flags[:loud] == true
    end

    test "returns {:error, _} for missing required options" do
      assert {:error, _errors} = ProGen.Script.parse_args(@schema, [])
    end

    test "returns :help for [\"--help\"]" do
      assert :help = ProGen.Script.parse_args(@schema, ["--help"])
    end

    test "returns :version for [\"--version\"]" do
      assert :version = ProGen.Script.parse_args(@schema, ["--version"])
    end

    test "accepts a string and splits it into argv" do
      assert {:ok, parsed} = ProGen.Script.parse_args(@schema, "--name World")
      assert parsed.options[:name] == "World"
      assert parsed.flags[:loud] == false
    end

    test "accepts a string with flags" do
      assert {:ok, parsed} = ProGen.Script.parse_args(@schema, "--name World --loud")
      assert parsed.options[:name] == "World"
      assert parsed.flags[:loud] == true
    end

    test "accepts a string and returns :help" do
      assert :help = ProGen.Script.parse_args(@schema, "--help")
    end

    test "accepts a string and returns :version" do
      assert :version = ProGen.Script.parse_args(@schema, "--version")
    end
  end

  describe "usage/1" do
    test "returns a string containing option names" do
      usage = ProGen.Script.usage(@schema)
      assert is_binary(usage)
      assert usage =~ "--name"
      assert usage =~ "--loud"
    end
  end

  describe "cli_args/1 and cli_args/0" do
    test "round-trip stores and retrieves schema" do
      ProGen.Script.cli_args(@schema)
      assert ProGen.Script.cli_args() == @schema
    end
  end

  describe "parse_args/1" do
    setup do
      ProGen.Script.cli_args(@schema)
      Application.put_env(:pro_gen, :system_halt, fn code -> throw({:halted, code}) end)
      on_exit(fn -> Application.delete_env(:pro_gen, :system_halt) end)
      :ok
    end

    test "parses argv using stored schema and returns merged map" do
      assert {:ok, args} = ProGen.Script.parse_args(["--name", "World"])
      assert args[:name] == "World"
      assert args[:loud] == false
    end

    test "stores merged args in :pg_cli_vals" do
      {:ok, args} = ProGen.Script.parse_args(["--name", "World", "--loud"])
      assert ProGen.Script.Env.get(:pg_cli_vals) == args
      assert args[:name] == "World"
      assert args[:loud] == true
    end

    test "auto-prints usage and returns :help for --help" do
      output =
        capture_io(fn ->
          assert :help = ProGen.Script.parse_args(["--help"])
        end)

      assert output =~ "--name"
      assert output =~ "--loud"
    end

    test "auto-prints version and returns :version for --version" do
      output =
        capture_io(fn ->
          assert :version = ProGen.Script.parse_args(["--version"])
        end)

      assert output =~ "0.1.0"
    end

    test "prints usage and halts with code 1 for missing required options" do
      capture_io(:stderr, fn ->
        output =
          capture_io(fn ->
            assert {:halted, 1} =
                     catch_throw(ProGen.Script.parse_args([]))
          end)

        assert output =~ "--name"
      end)
    end

    test "prints error details to stderr for missing required options" do
      stderr =
        capture_io(:stderr, fn ->
          capture_io(fn ->
            catch_throw(ProGen.Script.parse_args([]))
          end)
        end)

      assert stderr =~ "name"
    end
  end

  describe "usage/0" do
    setup do
      ProGen.Script.cli_args(@schema)
      :ok
    end

    test "returns help text from stored schema" do
      usage = ProGen.Script.usage()
      assert is_binary(usage)
      assert usage =~ "--name"
      assert usage =~ "--loud"
    end
  end

  describe "puts/1" do
    test "prints formatted message" do
      output = capture_io(fn -> ProGen.Script.puts("hello") end)
      assert output =~ "> " <> IO.ANSI.color(208) <> "hello" <> IO.ANSI.reset()
    end
  end

  describe "command/2" do
    test "logs description and runs command" do
      {result, output} = with_io(fn -> ProGen.Script.command("listing", "echo hi") end)
      assert output =~ "hi"
      assert :ok = result
    end
  end

  describe "validate/3" do
    test "accepts check list" do
      assert :ok = ProGen.Script.validate("Test", "filesys", [:has_mix])
    end

    test "multiple checks" do
      assert :ok = ProGen.Script.validate("Test", "filesys", [:has_mix, :has_git])
    end
  end

  describe "cmd/1,2" do
    test "runs a command string and returns output" do
      {_result, output} = with_io(fn -> ProGen.Xt.Sys.cmd("echo hello") end)
      assert output =~ "hello"
    end

    test "runs a command with arg list and returns output" do
      {_result, output} = with_io(fn -> ProGen.Xt.Sys.cmd("echo", ["hello"]) end)
      assert output =~ "hello"
    end

    test "returns :ok on success" do
      capture_io(fn -> send(self(), ProGen.Xt.Sys.cmd("echo", ["hi"])) end)
      assert_received :ok
    end

    test "returns {:error, _} on failure" do
      capture_io(fn -> send(self(), ProGen.Xt.Sys.cmd("false", [])) end)
      assert_received {:error, code} when is_integer(code)
    end

    test "handles shell redirects" do
      output_path = Path.join(System.tmp_dir!(), "pro_gen_sys_redirect_test_#{System.unique_integer([:positive])}")

      try do
        capture_io(fn -> send(self(), ProGen.Xt.Sys.cmd("echo asdf > #{output_path}")) end)
        assert_received :ok
        assert File.read!(output_path) =~ "asdf"
      after
        File.rm(output_path)
      end
    end

    test "handles shell pipes" do
      {_result, output} = with_io(fn -> ProGen.Xt.Sys.cmd("echo hello world | tr h H") end)
      assert output =~ "Hello"
    end
  end
end
