defmodule ExRiak.Metadata do
  @moduledoc """
  Module to work with Metadata from `ExRiak.Object`.
  """

  @type t :: :riakc_obj.metadata

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

  @doc false
  @spec decode_content_type(charlist | :undefined) :: String.t | :undefined
  def decode_content_type(:undefined), do: :undefined
  def decode_content_type(content_type) do
    List.to_string(content_type)
  end
end
