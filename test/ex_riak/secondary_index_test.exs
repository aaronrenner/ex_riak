defmodule ExRiak.SecondaryIndexTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExRiak.SecondaryIndex
  alias ExRiak.SecondaryIndex.Result

  property "decode_result/2 converts term values to integers on an integer_index" do
    check all index_id <- index_id(),
              result <- result(index_id) do
      if match?({:integer_index, _}, index_id) and is_list(result.terms) do
        non_integer_index_values =
          result
          |> SecondaryIndex.decode_result(index_id)
          |> Map.fetch!(:terms)
          |> Enum.reject(&match?({index_val, _} when is_integer(index_val), &1))

        assert [] == non_integer_index_values,
               "The following terms did not have integer index values #{
                 inspect(non_integer_index_values)
               }"
      else
        assert ^result = SecondaryIndex.decode_result(result, index_id)
      end
    end
  end

  defp index_id do
    tuple({one_of([:integer_index, :binary_index]), string(:ascii, max_length: 10)})
  end

  defp result(index_type) do
    %{
      continuation: :undefined,
      terms: one_of([:undefined, list_of(term_result(index_type), max_length: 10)]),
      keys: one_of([:undefined, list_of(key(), max_length: 10)])
    }
    |> fixed_map
    |> map(&struct!(Result, &1))
  end

  defp term_result({:integer_index, _}) do
    tuple({map(integer(), &to_string/1), key()})
  end

  defp term_result({:binary_index, _}) do
    tuple({string(:ascii), key()})
  end

  defp key do
    unshrinkable(string(:ascii, max_length: 10))
  end
end
