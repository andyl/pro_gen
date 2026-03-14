defmodule ProGen.ActionInfo do
  @moduledoc """
  Struct bundling an action's metadata for runtime inspection.
  """

  @type t :: %__MODULE__{
          module: module(),
          name: atom(),
          description: String.t(),
          option_schema: keyword(),
          usage: String.t()
        }

  defstruct [:module, :name, :description, :option_schema, :usage]
end
