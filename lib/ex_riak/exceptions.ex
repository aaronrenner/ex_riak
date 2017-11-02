defmodule ExRiak.NoValueError do
  @moduledoc """
  Raised when no value was found for an object.
  """

  @type t :: %__MODULE__{
    message: String.t,
    object: ExRiak.Object.t
  }

  defexception [:message, :object]

  def exception(opts) do
    object = Keyword.fetch!(opts, :object)
    message = "no value for #{inspect object}"
    %__MODULE__{message: message, object: object}
  end
end

defmodule ExRiak.SiblingsError do
  @moduledoc """
  Raised when unexpected siblings are returned for an object.
  """

  @type t :: %__MODULE__{
    message: String.t,
    object: ExRiak.Object.t
  }

  defexception [:message, :object]

  def exception(opts) do
    object = Keyword.fetch!(opts, :object)
    message = "unexpected siblings for #{inspect object}"
    %__MODULE__{message: message, object: object}
  end
end
