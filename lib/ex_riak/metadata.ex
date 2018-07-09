defmodule ExRiak.Metadata do
  @moduledoc """
  Module to work with Metadata from `ExRiak.Object`.
  """

  import ExRiak.Docs

  alias ExRiak.SecondaryIndex

  @type t :: :riakc_obj.metadata()
  @type key :: String.t()
  @type value :: String.t()

  @type entry :: {key, value}

  @type secondary_index :: binary_index | integer_index
  @type secondary_index_id :: SecondaryIndex.index_id()
  @type secondary_index_value :: SecondaryIndex.index_value()

  @type binary_index :: {SecondaryIndex.binary_index_id(), [SecondaryIndex.binary_index_value()]}

  @type integer_index ::
          {SecondaryIndex.integer_index_id(), [SecondaryIndex.integer_index_value()]}

  @typedoc """
  Content type of an `ExRiak.Object`'s value
  """
  @type content_type :: String.t()

  @content_type_metadata_key "content-type"

  @doc """
  Returns the content type from metadata
  """
  @spec get_content_type(t) :: content_type | :undefined
  def get_content_type(metadata) do
    case :dict.find(@content_type_metadata_key, metadata) do
      {:ok, content_type} ->
        decode_content_type(content_type)

      :error ->
        :undefined
    end
  end

  @doc """
  Get all metadata entries.

  See #{erlang_doc_link({:riakc_obj, :get_user_metadata_entries, 1})}.
  """
  @spec get_user_entries(t) :: [entry]
  def get_user_entries(metadata) do
    :riakc_obj.get_user_metadata_entries(metadata)
  end

  @doc """
  Get specific metadata entry.

  If `metadata_key` is present in the user metadata with then the associated
  value is returned. Otherwise `default` is returned (which is `nil` unless
  specified otherwise).

  See #{erlang_doc_link({:riakc_obj, :get_user_metadata_entry, 2})}.
  """
  @spec get_user_entry(t, key, default :: term) :: value | term
  def get_user_entry(metadata, metadata_key, default \\ nil) do
    case :riakc_obj.get_user_metadata_entry(metadata, metadata_key) do
      :notfound -> default
      value -> value
    end
  end

  @doc """
  Sets a metadata entry.

  See #{erlang_doc_link({:riakc_obj, :set_user_metadata_entry, 2})}.
  """
  @spec set_user_entry(t, entry) :: t
  def set_user_entry(metadata, metadata_entry) do
    :riakc_obj.set_user_metadata_entry(metadata, metadata_entry)
  end

  @doc """
  Deletes a specific metadata entry.

  See #{erlang_doc_link({:riakc_obj, :delete_user_metadata_entry, 2})}.
  """
  @spec delete_user_entry(t, key) :: t
  def delete_user_entry(metadata, metadata_key) do
    :riakc_obj.delete_user_metadata_entry(metadata, metadata_key)
  end

  @doc """
  Clears all metadata entries.

  See #{erlang_doc_link({:riakc_obj, :clear_user_metadata_entries, 1})}.
  """
  @spec clear_user_entries(t) :: t
  def clear_user_entries(metadata) do
    :riakc_obj.clear_user_metadata_entries(metadata)
  end

  @doc """
  Gets all secondary indexes in this Metadata.

  See #{erlang_doc_link({:riakc_obj, :get_secondary_indexes, 1})}.
  """
  @spec get_secondary_indexes(t) :: [secondary_index]
  def get_secondary_indexes(metadata) do
    metadata
    |> :riakc_obj.get_secondary_indexes()
    |> Enum.map(&decode_secondary_index/1)
  end

  @doc """
  Gets the value(s) for a specific secondary index.

  If `secondary_index_id` is present in the list of secondary indexes, then
  the associated values are returned. Otherwise `default` is returned (which is
  `nil` unless specified otherwise).

  See #{erlang_doc_link({:riakc_obj, :get_secondary_index, 2})}.
  """
  @spec get_secondary_index(t, secondary_index_id, default :: term()) ::
          [secondary_index_value] | term()
  def get_secondary_index(metadata, secondary_index_id, default \\ nil) do
    secondary_index_id = SecondaryIndex.encode_secondary_index_id(secondary_index_id)

    case :riakc_obj.get_secondary_index(metadata, secondary_index_id) do
      :notfound -> default
      value -> value
    end
  end

  @doc """
  Adds a secondary index to the metatadata.

  If a value is already set for an index, it appends the new value to the list.

  See #{erlang_doc_link({:riakc_obj, :add_secondary_index, 2})}.
  """
  @spec add_secondary_index(t, secondary_index | [secondary_index]) :: t
  def add_secondary_index(metadata, index) do
    index = encode_secondary_index(index)
    :riakc_obj.add_secondary_index(metadata, index)
  end

  @doc """
  Set a secondary index on the metadata.

  See #{erlang_doc_link({:riakc_obj, :set_secondary_index, 2})}.
  """
  @spec set_secondary_index(t, secondary_index | [secondary_index]) :: t
  def set_secondary_index(metadata, indexes) do
    indexes =
      indexes
      |> List.wrap()
      |> Enum.map(&encode_secondary_index/1)

    :riakc_obj.set_secondary_index(metadata, indexes)
  end

  @doc """
  Delete a secondary index by id.

  See #{erlang_doc_link({:riakc_obj, :delete_secondary_index, 2})}.
  """
  @spec delete_secondary_index(t, secondary_index_id) :: t
  def delete_secondary_index(metadata, secondary_index_id) do
    secondary_index_id = SecondaryIndex.encode_secondary_index_id(secondary_index_id)
    :riakc_obj.delete_secondary_index(metadata, secondary_index_id)
  end

  @doc """
  Clear all secondary indexes on this metadata.

  See #{erlang_doc_link({:riakc_obj, :clear_secondary_indexes, 2})}.
  """
  @spec clear_secondary_indexes(t) :: t
  def clear_secondary_indexes(metadata) do
    :riakc_obj.clear_secondary_indexes(metadata)
  end

  @doc false
  @spec decode_content_type(charlist | :undefined) :: String.t() | :undefined
  def decode_content_type(:undefined), do: :undefined

  def decode_content_type(content_type) do
    List.to_string(content_type)
  end

  defp encode_secondary_index({id, val}) do
    {SecondaryIndex.encode_secondary_index_id(id), val}
  end

  defp decode_secondary_index({id, values}) do
    {SecondaryIndex.decode_secondary_index_id(id), values}
  end
end
