defmodule ExRiak.SecondaryIndex.Result do
  @moduledoc """
  Struct representing a secondary index result.

  This is the struct version of the `:index_results_v1` record.

  See #{ExRiak.Docs.erlang_doc_link(:riakc_pb_socket)}.
  """

  import Record

  alias ExRiak.SecondaryIndex

  @record_tag :index_results_v1

  @type key :: ExRiak.key()
  @type term_result :: {SecondaryIndex.index_value(), key}

  @type t :: %__MODULE__{
          keys: [key] | :undefined,
          terms: [term_result] | :undefined,
          continuation: SecondaryIndex.continuation() | :undefined
        }

  @type index_results_v1_record ::
          record(
            :index_results_v1,
            keys: [key] | :undefined,
            terms: [term_result] | :undefined,
            continuation: SecondaryIndex.continuation() | :undefined
          )

  defstruct [:keys, :terms, :continuation]

  defrecordp(@record_tag, extract(@record_tag, from_lib: "riakc/include/riakc.hrl"))

  @doc """
  Converts a `#{inspect(@record_tag)}` record to a `#{inspect(__MODULE__)}` struct.
  """
  @spec from_record(index_results_v1_record) :: t
  def from_record(record) when Record.is_record(record, @record_tag) do
    struct!(__MODULE__, index_results_v1(record))
  end

  @doc """
  Converts a `#{inspect(__MODULE__)}` struct to a `#{inspect(@record_tag)}` record.
  """
  @spec to_record(t) :: index_results_v1_record
  def to_record(%__MODULE__{continuation: continuation, keys: keys, terms: terms}) do
    index_results_v1(continuation: continuation, keys: keys, terms: terms)
  end
end
