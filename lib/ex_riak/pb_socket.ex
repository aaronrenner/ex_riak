defmodule ExRiak.PBSocket do
  @moduledoc """
  Wrapper around the #{ExRiak.Docs.erlang_doc_link(:riakc_pb_socket)} API.
  """

  import ExRiak.Docs

  alias ExRiak.DataType
  alias ExRiak.NoValueError
  alias ExRiak.Object
  alias ExRiak.PBSocketError
  alias ExRiak.SecondaryIndex
  alias ExRiak.SecondaryIndex.Result
  alias ExRiak.SiblingsError

  @type t :: pid

  @type bucket_locator :: ExRiak.bucket_locator()
  @type key :: ExRiak.key()
  @type port_number :: 0..65_535

  @type client_opt ::
          :queue_if_disconnected
          | {:queue_if_disconnected, boolean}
          | {:connect_timeout, pos_integer}
          | :auto_reconnect
          | {:auto_reconnect, boolean}
          | :keepalive
          | {:keepalive, boolean}

  @type client_opts :: [client_opt]

  @type index_opt ::
          {:timeout, timeout()}
          | {:call_timeout, timeout()}
          | {:stream, boolean()}
          | {:continuation, SecondaryIndex.continuation()}
          | {:pagination_sort, binary()}
          | {:max_results, non_neg_integer()}
          | :all

  @type range_index_opt ::
          {:return_terms, boolean()}
          | index_opt

  @type start_link_opt ::
          {:hostname, String.t()}
          | {:port, port_number}
          | client_opt

  @type start_link_opts :: [start_link_opt]

  @type secondary_index_id :: SecondaryIndex.index_id()
  @type secondary_index_value :: SecondaryIndex.index_value()

  @doc """
  Creates a linked process to communicate with the riak server.

  Options:
    * `:hostname` - IP/Hostname of the riak server. Defaults to `"localhost"`.
      Can also set default value in application config with:

          config :ex_riak, default_hostname: "my-riak-host"
    * `:port` - Port of the riak server. Defaults to `8087`
      Can also set default value in application config with:

          config :ex_riak, default_port: 8087
    * Additional options are passed directly to `:riak_pb_socket.start_link/3`

  See #{erlang_doc_link({:riakc_pb_socket, :start_link, 3})}.
  """
  @spec start_link(start_link_opts) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {hostname, opts} = Keyword.pop_lazy(opts, :hostname, &default_hostname/0)
    {port, opts} = Keyword.pop_lazy(opts, :port, &default_port/0)

    :riakc_pb_socket.start_link(to_charlist(hostname), port, opts)
  end

  @doc """
  Gets bucket/key from server

  See #{erlang_doc_link({:riakc_pb_socket, :get, 3})}.
  """
  @spec get(t, bucket_locator, key) ::
          {:ok, Object.t()} | {:error, :not_found | PBSocketError.t()}
  def get(client, bucket_locator, key) do
    case :riakc_pb_socket.get(client, bucket_locator, key) do
      {:ok, obj} -> {:ok, obj}
      {:error, :notfound} -> {:error, :not_found}
      {:error, reason} -> {:error, PBSocketError.exception(reason: reason)}
    end
  end

  @doc """
  Gets a bucket/key from server.

  Returns nil if not found. Raises an `ExRiak.PBSocketError` on failure.

  ## Example

  This function is especially useful for fetching or creating an object during
  an [Object Update Cycle][update-cycle].

      {:ok, conn} = PBSocket.start_link()

      obj = PBSocket.get!(conn, "bucket", "key") || Object.new("bucket", "key")

  See #{erlang_doc_link({:riakc_pb_socket, :get, 3})}.

  [update-cycle]: http://docs.basho.com/riak/kv/2.2.3/developing/usage/updating-objects/
  """
  @spec get!(t, bucket_locator, key) :: Object.t() | nil | no_return
  def get!(client, bucket_locator, key) do
    case get(client, bucket_locator, key) do
      {:ok, obj} -> obj
      {:error, :not_found} -> nil
      {:error, error} -> raise error
    end
  end

  @doc """
  Puts the metadata/value in the object under the bucket/key.

  When the object's key is `:undefined`, riak will generate a key for this
  object and that key will be returned as a `{:ok, key}` tuple. If the object's
  key is already set, `:ok` will be returned.

  See #{erlang_doc_link({:riakc_pb_socket, :put, 2})}.
  """
  @spec put(t, Object.t()) :: :ok | {:ok, key} | {:error, PBSocketError.t() | SiblingsError.t()}
  def put(client, obj) do
    case :riakc_pb_socket.put(client, obj) do
      :ok -> :ok
      {:ok, key} when is_binary(key) -> {:ok, key}
      {:error, reason} -> {:error, PBSocketError.exception(reason: reason)}
    end
  catch
    :siblings -> {:error, SiblingsError.exception(object: obj)}
    :no_value -> {:error, NoValueError.exception(object: obj)}
  end

  @doc """
  Puts the metadata/value in the object under the bucket/key and raises on
  failure.

  See `put/2` for more details.
  """
  @spec put!(t, Object.t()) :: :ok | {:ok, key} | no_return
  def put!(client, obj) do
    case put(client, obj) do
      :ok -> :ok
      {:ok, obj} -> obj
      {:error, error} -> raise error
    end
  end

  @doc """
  Deletes the key/value.

  See #{erlang_doc_link({:riakc_pb_socket, :delete, 3})}.
  """
  @spec delete(t, bucket_locator, key) :: :ok | {:error, PBSocketError.t()}
  def delete(pid, bucket_locator, key) do
    case :riakc_pb_socket.delete(pid, bucket_locator, key) do
      :ok -> :ok
      {:error, reason} -> {:error, PBSocketError.exception(reason: reason)}
    end
  end

  @doc """
  Deletes the key/value, raising an error if there's an issue.

  See #{erlang_doc_link({:riakc_pb_socket, :delete, 3})}.
  """
  @spec delete!(t, bucket_locator, key) :: :ok | no_return
  def delete!(pid, bucket_locator, key) do
    case delete(pid, bucket_locator, key) do
      :ok -> :ok
      {:error, error} -> raise error
    end
  end

  @doc """
  Fetches the representation of a convergent data type from Riak.

  See #{erlang_doc_link({:riakc_pb_socket, :fetch_type, 3})}.
  """
  @spec fetch_type(t, bucket_locator, key) ::
          {:ok, DataType.t()} | {:error, :not_found | PBSocketError.t()}
  def fetch_type(pid, bucket_locator, key) do
    case :riakc_pb_socket.fetch_type(pid, bucket_locator, key) do
      {:ok, dt} -> {:ok, dt}
      {:error, {:notfound, _}} -> {:error, :not_found}
      {:error, reason} -> {:error, PBSocketError.exception(reason: reason)}
    end
  end

  @doc """
  Fetches the representation of a convergent data type from Riak.

  Returns nil if not found. Raises an `ExRiak.PBSocketError` on failure.

  See #{erlang_doc_link({:riakc_pb_socket, :fetch_type, 3})}.
  """
  @spec fetch_type!(t, bucket_locator, key) :: DataType.t() | nil | no_return
  def fetch_type!(pid, bucket_locator, key) do
    case fetch_type(pid, bucket_locator, key) do
      {:ok, dt} -> dt
      {:error, :not_found} -> nil
      {:error, error} -> raise error
    end
  end

  @doc """
  Lists all keys in a bucket.

  *This is a potentially expensive operation and should not be used in
  production.*

  See #{erlang_doc_link({:riakc_pb_socket, :list_keys, 2})}.
  """
  @spec list_keys(t, bucket_locator) :: {:ok, [key]} | {:error, PBSocketError.t()}
  def list_keys(pid, bucket_locator) do
    case :riakc_pb_socket.list_keys(pid, bucket_locator) do
      {:ok, keys} -> {:ok, keys}
      {:error, reason} -> {:error, PBSocketError.exception(reason: reason)}
    end
  end

  @doc """
  Lists all keys in a bucket.

  Raises an `ExRiak.PBSocketError` on failure.

  *This is a potentially expensive operation and should not be used in
  production.*

  See #{erlang_doc_link({:riakc_pb_socket, :list_keys, 2})}.
  """
  @spec list_keys!(t, bucket_locator) :: [key] | no_return
  def list_keys!(pid, bucket_locator) do
    case list_keys(pid, bucket_locator) do
      {:ok, keys} -> keys
      {:error, error} -> raise error
    end
  end

  @doc """
  Execute a secondary index query.

  See #{erlang_doc_link({:riakc_pb_socket, :get_index_eq, 5})}.
  """
  @spec get_index_eq(t, bucket_locator, secondary_index_id, secondary_index_value, [index_opt]) ::
          {:ok, Result.t()} | {:error, PBSocketError.t()}
  def get_index_eq(pid, bucket_locator, index_id, key, opts \\ []) do
    index_id = SecondaryIndex.encode_secondary_index_id(index_id)

    case :riakc_pb_socket.get_index_eq(pid, bucket_locator, index_id, key, opts) do
      {:ok, record} -> {:ok, Result.from_record(record)}
      {:error, reason} -> {:error, PBSocketError.exception(reason: reason)}
    end
  end

  @doc """
  Execute a secondary index range query.

  See #{erlang_doc_link({:riakc_pb_socket, :get_index_range, 6})}.
  """
  @spec get_index_range(
          t,
          bucket_locator,
          secondary_index_id,
          secondary_index_value,
          secondary_index_value,
          [range_index_opt]
        ) :: {:ok, Result.t()} | {:error, PBSocketError.t()}
  def get_index_range(pid, bucket_locator, index_id, start_value, end_value, opts \\ []) do
    case :riakc_pb_socket.get_index_range(
           pid,
           bucket_locator,
           SecondaryIndex.encode_secondary_index_id(index_id),
           start_value,
           end_value,
           opts
         ) do
      {:ok, record} ->
        result =
          record
          |> Result.from_record()
          |> SecondaryIndex.decode_result(index_id)

        {:ok, result}

      {:error, reason} ->
        {:error, PBSocketError.exception(reason: reason)}
    end
  end

  @spec default_hostname :: String.t()
  defp default_hostname do
    Application.get_env(:ex_riak, :default_hostname, "localhost")
  end

  @spec default_port :: port_number
  defp default_port do
    Application.get_env(:ex_riak, :default_port, 8087)
  end
end
