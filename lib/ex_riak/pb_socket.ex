defmodule ExRiak.PBSocket do
  @moduledoc """
  Wrapper around `:riakc_pb_socket` API.
  """

  alias ExRiak.Object
  alias ExRiak.PBSocketError
  alias ExRiak.SiblingsError

  @type bucket :: String.t
  @type bucket_type :: String.t
  @type bucket_and_type :: {bucket_type, bucket}
  @type bucket_locator :: bucket_and_type | bucket
  @type key :: String.t

  @doc """
  Gets bucket/key from server
  """
  @spec get(pid, bucket_locator, key) ::
    {:ok, Object.t} | {:error, :not_found | PBSocketError.t}
  def get(client, bucket_locator, key) do
    case :riakc_pb_socket.get(client, bucket_locator, key) do
      {:ok, obj} -> {:ok, obj}
      {:error, :notfound} -> {:error, :not_found}
      {:error, reason} -> {:error, PBSocketError.exception(reason: reason)}
    end
  end

  @doc """
  Puts the metadata/value in the object under the bucket/key.
  """
  @spec put(pid, Object.t) ::
    :ok | {:ok, Object.t} | {:error, PBSocketError.t | SiblingsError.t}
  def put(client, obj) do
    case :riakc_pb_socket.put(client, obj) do
      :ok -> :ok
      {:ok, obj} -> {:ok, obj}
      {:error, reason} -> {:error, PBSocketError.exception(reason: reason)}
    end
  catch
    :siblings -> {:error, SiblingsError.exception(object: obj)}
  end

  @doc """
  Puts the metadata/value in the object under the bucket/key and raises on
  failure.
  """
  @spec put!(pid, Object.t) ::
    :ok | Object.t
  def put!(client, obj) do
    case put(client, obj) do
      :ok -> :ok
      {:ok, obj} -> obj
      {:error, error} -> raise error
    end
  end
end
