defmodule ExRiak.SecondaryIndex.ResultTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ExRiak.SecondaryIndex.Result

  require Record

  Record.defrecordp(
    :index_results_v1,
    Record.extract(:index_results_v1, from_lib: "riakc/include/riakc.hrl")
  )

  property "record can be converted to a struct and back without losing info" do
    check all record <- index_result_record() do
      assert ^record =
               record
               |> Result.from_record()
               |> Result.to_record()
    end
  end

  test "from_record/1 does not allow invalid data" do
    assert_raise FunctionClauseError, fn ->
      Result.from_record("foo")
    end
  end

  defp index_result_record do
    gen all continuation <- one_of([:undefined, binary(max_length: 10)]),
            keys <- one_of([:undefined, list_of(key(), max_length: 5)]),
            terms <- one_of([:undefined, list_of(tuple({key(), value()}))]) do
      index_results_v1(continuation: continuation, keys: keys, terms: terms)
    end
  end

  defp key do
    binary(max_length: 10)
  end

  defp value do
    one_of([
      binary(max_length: 10),
      integer()
    ])
  end
end
