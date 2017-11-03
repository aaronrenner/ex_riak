defmodule ExRiak.Object do
  @moduledoc """
  Wrapper around #{ExRiak.Docs.erlang_doc_link(:riakc_obj)} API.
  """

  import ExRiak.Docs

  alias ExRiak.DecodingError
  alias ExRiak.NoValueError
  alias ExRiak.SiblingsError

  @type t :: :riakc_obj.riakc_obj
  @type value :: term
  @type content_type :: String.t
  @type metadata :: :riakc_obj.metadata

  @doc """
  Returns the value of the object if there are no siblings.

  See #{erlang_doc_link({:riakc_obj, :get_value, 1})}.
  """
  @spec get_value(t) ::
    {:ok, value} | {:error, SiblingsError.t | NoValueError.t | DecodingError.t}
  def get_value(obj) do
    with {:ok, value} <- do_get(obj, &:riakc_obj.get_value/1),
         {:ok, content_type} <- get_content_type(obj) do
      decode_value(value, content_type)
    end
  end

  @doc """
  Returns the value for the object, erroring out if there are siblings.

  If there are no siblings, the corresponding value is returned.
  If there are siblings, a `ExRiak.SiblingsError` exception is raised.
  If there is no value, a `ExRiak.NoValueError` exception is raised.

  See #{erlang_doc_link({:riakc_obj, :get_value, 1})}.
  """
  @spec get_value!(t) :: value | no_return
  def get_value!(obj) do
    case get_value(obj) do
      {:ok, value} -> value
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns a list of content types for all siblings.

  See #{erlang_doc_link({:riakc_obj, :get_content_types, 1})}.
  """
  @spec get_content_types(t) :: [content_type]
  def get_content_types(obj) do
    obj
    |> :riakc_obj.get_content_types()
    |> Enum.map(&decode_content_type/1)
  end

  @doc """
  Returns the content type of the value if there are no siblings.

  See #{erlang_doc_link({:riakc_obj, :get_content_type, 1})}.
  """
  @spec get_content_type(t) :: {:ok, content_type} | {:error, SiblingsError.t}
  def get_content_type(obj) do
    with {:ok, content_type} <- do_get(obj, &:riakc_obj.get_content_type/1) do
      {:ok, decode_content_type(content_type)}
    end
  end

  @doc """
  Returns the content type for the value, erroring out if there are siblings.

  If there are no siblings, the content type is returned.
  If there are siblings, a `ExRiak.SiblingsError` exception is raised.

  See #{erlang_doc_link({:riakc_obj, :get_content_type, 1})}.
  """
  @spec get_content_type!(t) :: content_type | no_return
  def get_content_type!(obj) do
    case get_content_type(obj) do
      {:ok, content_type} -> content_type
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns the metadata for the object if there are no siblings.

  See #{erlang_doc_link({:riakc_obj, :get_metadata, 1})}.
  """
  @spec get_metadata(t) :: {:ok, metadata} | {:error, SiblingsError.t}
  def get_metadata(obj) do
    do_get(obj, &:riakc_obj.get_metadata/1)
  end

  @doc """
  Returns the metadata for the object, erroring out if there are siblings.

  See #{erlang_doc_link({:riakc_obj, :get_metadata, 1})}.
  """
  @spec get_metadata!(t) :: metadata | no_return
  def get_metadata!(obj) do
    case get_metadata(obj) do
      {:ok, metadata} -> metadata
      {:error, error} -> raise error
    end
  end

  @spec do_get(t, function) ::
    {:ok, term} | {:error, SiblingsError.t, NoValueError.t}
  defp do_get(obj, function) do
    {:ok, function.(obj)}
  catch
    :siblings -> {:error, SiblingsError.exception(object: obj)}
    :no_value -> {:error, NoValueError.exception(object: obj)}
  end

  @spec decode_value(value, content_type) ::
    {:ok, value} | {:error, DecodingError.t}
  defp decode_value(value, "application/x-erlang-binary" = ct) do
    {:ok, :erlang.binary_to_term(value)}
  rescue
    ArgumentError ->
      {:error, DecodingError.exception(value: value, content_type: ct)}
  end
  defp decode_value(value, _), do: {:ok, value}

  @spec decode_content_type(charlist) :: String.t
  defp decode_content_type(content_type) do
    List.to_string(content_type)
  end
end
