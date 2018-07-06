defmodule ExRiak.DataType do
  @moduledoc """
  Module for working with any type of riak CRDT data types.
  """

  @type t :: :riakc_datatype.datatype()
end
