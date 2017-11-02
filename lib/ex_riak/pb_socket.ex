defmodule ExRiak.PBSocket do
  @moduledoc """
  Wrapper around `:riakc_pb_socket` API.
  """

  alias ExRiak.Object
  alias ExRiak.PBSocketError

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
end
