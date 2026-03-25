defmodule ProGen.Patch.FileTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  describe "append_line/2" do
    test "appends a line to a file", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      File.write!(path, "first\n")

      assert :ok = ProGen.Patch.File.append_line(path, "second")
      assert File.read!(path) == "first\nsecond\n"
    end

    test "adds trailing newline when file doesn't end with one", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      File.write!(path, "first")

      assert :ok = ProGen.Patch.File.append_line(path, "second")
      assert File.read!(path) == "first\nsecond\n"
    end

    test "is idempotent — does not duplicate existing line", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      File.write!(path, "existing line\n")

      assert :ok = ProGen.Patch.File.append_line(path, "existing line")
      assert File.read!(path) == "existing line\n"
    end

    test "appends to an empty file", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      File.write!(path, "")

      assert :ok = ProGen.Patch.File.append_line(path, "hello")
      assert File.read!(path) == "\nhello\n"
    end

    test "returns error for non-existent file", %{tmp_dir: tmp} do
      path = Path.join(tmp, "missing.txt")

      assert {:error, :enoent} = ProGen.Patch.File.append_line(path, "line")
    end
  end

  describe "append_block/2" do
    test "appends a multi-line block to a file", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      File.write!(path, "header\n")

      block = "line1\nline2\nline3"
      assert :ok = ProGen.Patch.File.append_block(path, block)
      assert File.read!(path) == "header\nline1\nline2\nline3\n"
    end

    test "is idempotent — does not duplicate existing block", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      block = "line1\nline2\nline3\n"
      File.write!(path, "header\n" <> block)

      assert :ok = ProGen.Patch.File.append_block(path, block)
      assert File.read!(path) == "header\nline1\nline2\nline3\n"
    end

    test "adds trailing newline when file doesn't end with one", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      File.write!(path, "header")

      block = "line1\nline2"
      assert :ok = ProGen.Patch.File.append_block(path, block)
      assert File.read!(path) == "header\nline1\nline2\n"
    end

    test "handles block with trailing whitespace", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      File.write!(path, "header\nline1\nline2\n")

      # Block with extra trailing newlines should still match
      block = "line1\nline2\n\n\n"
      assert :ok = ProGen.Patch.File.append_block(path, block)
      # File unchanged since block already present
      assert File.read!(path) == "header\nline1\nline2\n"
    end

    test "appends to an empty file", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      File.write!(path, "")

      block = "line1\nline2"
      assert :ok = ProGen.Patch.File.append_block(path, block)
      assert File.read!(path) == "\nline1\nline2\n"
    end

    test "returns error for non-existent file", %{tmp_dir: tmp} do
      path = Path.join(tmp, "missing.txt")

      assert {:error, :enoent} = ProGen.Patch.File.append_block(path, "block")
    end
  end

  describe "sed_file/2" do
    test "performs in-place substitution", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      File.write!(path, "hello world\n")

      assert :ok = ProGen.Patch.File.sed_file(path, "s/hello/goodbye/")
      assert File.read!(path) == "goodbye world\n"
    end

    test "handles global substitution", %{tmp_dir: tmp} do
      path = Path.join(tmp, "test.txt")
      File.write!(path, "aaa bbb aaa\n")

      assert :ok = ProGen.Patch.File.sed_file(path, "s/aaa/ccc/g")
      assert File.read!(path) == "ccc bbb ccc\n"
    end

    test "returns error for non-existent file", %{tmp_dir: tmp} do
      path = Path.join(tmp, "missing.txt")

      assert {:error, :enoent} = ProGen.Patch.File.sed_file(path, "s/a/b/")
    end
  end
end
