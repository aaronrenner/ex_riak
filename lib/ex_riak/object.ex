defmodule ExRiak.Object do
  @moduledoc """
  Wrapper around #{ExRiak.Docs.erlang_doc_link(:riakc_obj)} API.
  """

  import ExRiak.Docs

  alias ExRiak.DecodingError
  alias ExRiak.Metadata
  alias ExRiak.NoValueError
  alias ExRiak.SiblingsError

  @type t :: :riakc_obj.riakc_obj
  @type bucket_locator :: ExRiak.bucket_locator

  @typedoc """
  The binary value to use as this object's key.

  Can also be set to `:undefined` to have riak generate a key
  when the object is stored. See `ExRiak.PBSocket.put/2`.
  """
  @type key :: ExRiak.key | :undefined
  @type value :: term
  @type content_type :: Metadata.content_type
  @type metadata :: Metadata.t
  @type vclock :: :riakc_obj.vclock

  @typep new_object_error_reasons :: {:zero_length_bucket, :zero_length_key}

  @doc """
  Constructor for new riak_client objects.

  Raises an `ArgumentError` with an invalid bucket locator.

  See #{erlang_doc_link({:riakc_obj, :new, 2})}.
  """
  @spec new(bucket_locator, key) :: t | no_return
  def new(bucket_locator, key) do
    bucket_locator
    |> :riakc_obj.new(key)
    |> raise_on_new_error_response
  end

  @doc """
  Constructor for new riak client objects with an update value.

  Raises an `ArgumentError` with an invalid bucket locator.

  See #{erlang_doc_link({:riakc_obj, :new, 3})}.
  """
  @spec new(bucket_locator, key, value) :: t | no_return
  def new(bucket_locator, key, value) do
    bucket_locator
    |> :riakc_obj.new(key, value)
    |> raise_on_new_error_response
  end

  @doc """
  Constructor for new riak client objects with an update value and content type.

  Raises an `ArgumentError` with an invalid bucket locator.

  See #{erlang_doc_link({:riakc_obj, :new, 4})}.
  """
  @spec new(bucket_locator, key, value, content_type) :: t | no_return
  def new(bucket_locator, key, value, content_type) do
    bucket_locator
    |> :riakc_obj.new(key, value, to_charlist(content_type))
    |> raise_on_new_error_response
  end

  @doc """
  Returns the key for this object.

  ## Example

      iex(1)> obj = Object.new("bucket", "key")
      ...(1)> Object.key(obj)
      "key"

  See #{erlang_doc_link({:riakc_obj, :key, 1})}.
  """
  @spec key(t) :: key
  def key(obj), do: :riakc_obj.key(obj)

  @doc """
  Returns the bucket for this object.

  ## Example

      iex(1)> obj = Object.new("bucket", "key")
      ...(1)> Object.bucket(obj)
      "bucket"

      iex(2)> obj = Object.new({"bucket-type","bucket"}, "key")
      ...(2)> Object.bucket(obj)
      {"bucket-type","bucket"}

  See #{erlang_doc_link({:riakc_obj, :bucket, 1})}.
  """
  @spec bucket(t) :: bucket_locator
  def bucket(obj), do: :riakc_obj.bucket(obj)

  @doc """
  Returns the bucket type for this object.

  ## Example

      iex(1)> obj = Object.new("bucket", "key")
      ...(1)> Object.bucket_type(obj)
      :undefined

      iex(2)> obj = Object.new({"bucket-type","bucket"}, "key")
      ...(2)> Object.bucket_type(obj)
      "bucket-type"

  See #{erlang_doc_link({:riakc_obj, :bucket_type, 1})}.
  """
  @spec bucket_type(t) :: ExRiak.bucket_type | :undefined
  def bucket_type(obj), do: :riakc_obj.bucket_type(obj)

  @doc """
  Returns only the bucket name for this object

  ## Example

      iex(1)> obj = Object.new("bucket", "key")
      ...(1)> Object.only_bucket(obj)
      "bucket"

      iex(2)> obj = Object.new({"bucket-type","bucket"}, "key")
      ...(2)> Object.only_bucket(obj)
      "bucket"

  See #{erlang_doc_link({:riakc_obj, :only_bucket, 1})}.
  """
  @spec only_bucket(t) :: ExRiak.bucket
  def only_bucket(obj), do: :riakc_obj.only_bucket(obj)

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
  Returns a list of values for this object.

  See #{erlang_doc_link({:riakc_obj, :values, 1})}.
  """
  @spec get_values(t) :: [value | DecodingError.t]
  def get_values(obj) do
    values = :riakc_obj.get_values(obj)
    content_types = get_content_types(obj)

    [values, content_types]
    |> Enum.zip
    |> Enum.map(fn {v, ct} ->
        case decode_value(v, ct) do
          {:ok, value} -> value
          {:error, error} -> error
        end
      end)
  end

  @doc """
  Returns the contents (a list of `{metadata, value` tuples) for this object.

  See #{erlang_doc_link({:riakc_obj, :get_contents, 1})}.
  """
  @spec get_contents(t) :: [{metadata, value}]
  def get_contents(obj) do
    metadatas = get_metadatas(obj)
    values = get_values(obj)

    Enum.zip(metadatas, values)
  end

  @doc """
  Sets the updated value of an object.

  See #{erlang_doc_link({:riakc_obj, :update_value, 2})}.
  """
  @spec update_value(t, value) :: t
  def update_value(_, %DecodingError{} = error) do
    raise unexpected_decoding_error(error)
  end
  def update_value(obj, value) do
    :riakc_obj.update_value(obj, value)
  end

  @doc """
  Sets the updated value and content type of an object.

  See #{erlang_doc_link({:riakc_obj, :update_value, 3})}.
  """
  @spec update_value(t, value, content_type) :: t
  def update_value(_, %DecodingError{} = error, _) do
    raise unexpected_decoding_error(error)
  end
  def update_value(obj, value, content_type) do
    :riakc_obj.update_value(obj, value, to_charlist(content_type))
  end

  @doc """
  Returns the update value of this object if there are no siblings.

  See #{erlang_doc_link({:riakc_obj, :get_update_value, 1})}.
  """
  @spec get_update_value(t) ::
    {:ok, value} | {:error, SiblingsError.t | NoValueError.t | DecodingError.t}
  def get_update_value(obj) do
    with {:ok, value} <- do_get(obj, &:riakc_obj.get_update_value/1),
         {:ok, content_type} <- get_update_content_type(obj) do
      decode_value(value, content_type)
    end
  end

  @doc """
  Returns the update value for the object, erroring out if there are siblings.

  If there are no siblings, the corresponding value is returned.
  If there are siblings, a `ExRiak.SiblingsError` exception is raised.
  If there is no value, a `ExRiak.NoValueError` exception is raised.

  See #{erlang_doc_link({:riakc_obj, :get_update_value, 1})}.
  """
  @spec get_update_value!(t) :: value | no_return
  def get_update_value!(obj) do
    case get_update_value(obj) do
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
    |> Enum.map(&Metadata.decode_content_type/1)
  end

  @doc """
  Returns the content type of the value if there are no siblings.

  See #{erlang_doc_link({:riakc_obj, :get_content_type, 1})}.
  """
  @spec get_content_type(t) ::
    {:ok, content_type | :undefined} | {:error, SiblingsError.t}
  def get_content_type(obj) do
    with {:ok, content_type} <- do_get(obj, &:riakc_obj.get_content_type/1) do
      {:ok, Metadata.decode_content_type(content_type)}
    end
  end

  @doc """
  Returns the content type for the value, erroring out if there are siblings.

  If there are no siblings, the content type is returned.
  If there are siblings, a `ExRiak.SiblingsError` exception is raised.

  See #{erlang_doc_link({:riakc_obj, :get_content_type, 1})}.
  """
  @spec get_content_type!(t) :: content_type | :undefined | no_return
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

  @doc """
  Return a list of metadata values for the object.

  See #{erlang_doc_link({:riakc_obj, :get_metadatas, 1})}.
  """
  @spec get_metadatas(t) :: [metadata]
  def get_metadatas(obj) do
    :riakc_obj.get_metadatas(obj)
  end

  @doc """
  Returns the updated metadata for this object.

  See #{erlang_doc_link({:riakc_obj, :get_update_metadata, 1})}.
  """
  @spec get_update_metadata(t) :: {:ok, metadata} | {:error, SiblingsError.t}
  def get_update_metadata(obj) do
    do_get(obj, &:riakc_obj.get_update_metadata/1)
  end

  @doc """
  Returns the updated metadata for this object, erroring out if there are
  siblings.

  See #{erlang_doc_link({:riakc_obj, :get_update_metadata, 1})}.
  """
  @spec get_update_metadata!(t) :: metadata
  def get_update_metadata!(obj) do
    case get_update_metadata(obj) do
      {:ok, metadata} -> metadata
      {:error, error} -> raise error
    end
  end

  @doc """
  Sets the updated metadata of an object.

  See #{erlang_doc_link({:riakc_obj, :update_metadata, 2})}.
  """
  @spec update_metadata(t, metadata) :: t
  def update_metadata(obj, metadata) do
    :riakc_obj.update_metadata(obj, metadata)
  end

  defdelegate get_user_metadata_entries(metadata),
    to: Metadata, as: :get_user_entries

  defdelegate get_user_metadata_entry(metadata, metadata_key, default \\ nil),
    to: Metadata, as: :get_user_entry

  defdelegate set_user_metadata_entry(metadata, metadata_entry),
    to: Metadata, as: :set_user_entry

  defdelegate delete_user_metadata_entry(metadata, metadata_key),
    to: Metadata, as: :delete_user_entry

  defdelegate clear_user_metadata_entries(metadata),
    to: Metadata, as: :clear_user_entries

  @doc """
  Returns the content type of the update value.

  See #{erlang_doc_link({:riakc_obj, :get_update_content_type, 1})}.
  """
  @spec get_update_content_type(t) ::
    {:ok, content_type | :undefined} | {:error, SiblingsError.t}
  def get_update_content_type(obj) do
    with {:ok, ct} <- do_get(obj, &:riakc_obj.get_update_content_type/1) do
      {:ok, Metadata.decode_content_type(ct)}
    end
  end

  @doc """
  Returns the content type for the update value, erroring out if there are
  siblings.

  If there are no siblings, the content type is returned.
  If there are siblings, a `ExRiak.SiblingsError` exception is raised.

  See #{erlang_doc_link({:riakc_obj, :get_update_content_type, 1})}.
  """
  @spec get_update_content_type!(t) :: content_type | :undefined | no_return
  def get_update_content_type!(obj) do
    case get_update_content_type(obj) do
      {:ok, content_type} -> content_type
      {:error, error} -> raise error
    end
  end

  @doc """
  Sets the updated content type of an object.

  See #{erlang_doc_link({:riakc_obj, :update_content_type, 2})}.
  """
  @spec update_content_type(t, content_type) :: t
  def update_content_type(obj, content_type) do
    :riakc_obj.update_content_type(obj, content_type)
  end

  @doc """
  Returns the number of values (siblings) of an object.

  See #{erlang_doc_link({:riakc_obj, :value_count, 1})}.
  """
  @spec value_count(t) :: non_neg_integer
  def value_count(obj), do: :riakc_obj.value_count(obj)

  @doc """
  Returns true if this object has more than one sibling.

  See #{erlang_doc_link({:riakc_obj, :value_count, 1})}.
  """
  @spec siblings?(t) :: boolean
  def siblings?(obj), do: value_count(obj) > 1

  @doc """
  Returns the vector clock for this object.

  ## Examples

      iex(1)> obj = Object.new("bucket", "key")
      ...(1)> Object.vclock(obj)
      :undefined

      iex(2)> :riakc_obj.new("bucket", "key")
      ...(2)> |> :riakc_obj.set_vclock(<<107, 206>>)
      ...(2)> |> Object.vclock()
      <<107, 206>>

      iex(3)> Object.new("bucket", "key")
      ...(3)> |> Object.set_vclock(<<105, 207>>)
      ...(3)> |> Object.vclock()
      <<105, 207>>

  See #{erlang_doc_link({:riakc_obj, :vclock, 1})}.
  """
  @spec vclock(t) :: vclock | :undefined
  def vclock(obj), do: :riakc_obj.vclock(obj)

  @doc """
  Set the vector clock for this object.

  ## Examples

      iex(1)> Object.new("bucket", "key")
      ...(1)> |> Object.set_vclock(<<92, 73, 34>>)
      ...(1)> |> Object.vclock()
      <<92, 73, 34>>

      iex(2)> :riakc_obj.new("bucket", "key")
      ...(2)> |> Object.set_vclock(<<107, 206>>)
      ...(2)> |> :riakc_obj.vclock()
      <<107, 206>>

  See #{erlang_doc_link({:riakc_obj, :set_vclock, 2})}.
  """
  @spec set_vclock(t, vclock) :: t
  def set_vclock(obj, vclock), do: :riakc_obj.set_vclock(obj, vclock)

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

  @spec raise_on_new_error_response(t | {:error, new_object_error_reasons}) ::
    t | no_return
  defp raise_on_new_error_response({:error, :zero_length_bucket}) do
    raise ArgumentError, "empty value for bucket name"
  end
  defp raise_on_new_error_response({:error, :zero_length_key}) do
    raise ArgumentError, "empty value for key"
  end
  defp raise_on_new_error_response(obj), do: obj

  defp unexpected_decoding_error(%DecodingError{} = error) do
    message = """
    unexpected argument

      #{inspect error}
    """

    ArgumentError.exception(message: message)
  end
end
