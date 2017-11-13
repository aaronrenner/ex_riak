defmodule ExRiak.Metadata do
  @moduledoc """
  Module to work with Metadata from `ExRiak.Object`.
  """

  import ExRiak.Docs

  @type t :: :riakc_obj.metadata
  @type key :: String.t
  @type value :: String.t
  @type entry :: {key, value}

  @typedoc """
  Content type of an `ExRiak.Object`'s value
  """
  @type content_type :: String.t

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
  @spec get_user_entry(t, key, default :: term) ::
    value | term
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

  @doc false
  @spec decode_content_type(charlist | :undefined) :: String.t | :undefined
  def decode_content_type(:undefined), do: :undefined
  def decode_content_type(content_type) do
    List.to_string(content_type)
  end
end
