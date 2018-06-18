defmodule ExRiak.IndexResults do
  @moduledoc """
    Struct version of the `index_results_v1` record from #{ExRiak.Docs.erlang_doc_link(:riakc_pb_socket)}.
  """
  require Record

  record_path = Path.join(["..", "..", "deps", "riakc", "include", "riakc.hrl"]) |> Path.expand(__DIR__)
  record_kv = Record.extract(:index_results_v1, from: record_path)
  Record.defrecord :index_results_v1, record_kv

  @external_resource record_path


  @type keys :: [binary()]
  @type terms :: binary() | integer()
  @type continuation :: binary()

  @type t :: %__MODULE__{
    keys: keys() | nil,
    terms: terms() | nil,
    continuation: continuation() | nil
  }

  @type index_results_v1 :: record(:index_results_v1,
    keys: keys() | :undefined,
    terms: terms() | :undefined,
    continuation: continuation() | :undefined
  )

  defstruct Keyword.keys(record_kv)

  @spec to_struct(index_results_v1) :: t
  def to_struct(record) do
    results =
      record
      |> index_results_v1()
      |> Enum.filter(fn {_k, v} -> v != :undefined end)
    struct(__MODULE__, results)
  end
end
