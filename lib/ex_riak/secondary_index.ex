defmodule ExRiak.SecondaryIndex do
  @moduledoc """
  Data types used for working with secondary indexes.
  """

  alias ExRiak.SecondaryIndex.Result

  @binary_index_type :binary_index
  @integer_index_type :integer_index

  @secondary_index_types [@binary_index_type, @integer_index_type]

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

  @doc false
  @spec decode_result(Result.t(), index_id) :: Result.t()
  def decode_result(%Result{terms: terms} = result, {@integer_index_type, _})
      when is_list(terms) do
    terms = Enum.map(terms, fn {index_val, key} -> {String.to_integer(index_val), key} end)

    %Result{result | terms: terms}
  end

  def decode_result(%Result{} = result, {index_type, _})
      when index_type in @secondary_index_types do
    result
  end
end
