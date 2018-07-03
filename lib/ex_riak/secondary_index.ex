defmodule ExRiak.SecondaryIndex do
  @moduledoc """
  Data types used for working with secondary indexes.
  """
  @secondary_index_types [:binary_index, :integer_index]

  @type continuation :: binary()

  @type index_id :: binary_index_id | integer_index_id
  @type index_value :: binary_index_value | integer_index_value

  @type binary_index_id :: {:binary_index, String.t()}
  @type binary_index_value :: String.t()

  @type integer_index_id :: {:integer_index, String.t()}
  @type integer_index_value :: integer()

  @doc false
  @spec encode_secondary_index_id(index_id) :: {atom, charlist}
  def encode_secondary_index_id({type, string})
      when type in @secondary_index_types and is_binary(string) do
    {type, String.to_charlist(string)}
  end

  @doc false
  @spec decode_secondary_index_id({atom, charlist}) :: index_id
  def decode_secondary_index_id({type, name}) do
    {type, List.to_string(name)}
  end
end
