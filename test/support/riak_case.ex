defmodule ExRiak.RiakCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import unquote(__MODULE__)
    end
  end

  setup_all do
    {:ok, conn} = build_connection()

    on_exit fn ->
      {:ok, conn} = build_connection()
      clean_bucket(conn, basic_bucket())
    end

    [conn: conn]
  end

  def random_string(length \\ 48) do
    length
    |> :crypto.strong_rand_bytes
    |> Base.url_encode64
    |> binary_part(0, length)
  end

  def basic_bucket do
    {"ex_riak", "ex_riak"}
  end

  def build_connection do
    :riakc_pb_socket.start_link('127.0.0.1', 8087)
  end

  def clean_bucket(conn, bucket) do
    {:ok, keys} = :riakc_pb_socket.list_keys(conn, bucket)
    Enum.each keys, fn key ->
      :ok = :riakc_pb_socket.delete(conn, bucket, key)
    end
    wait_for_empty(conn, bucket)
  end

  defp wait_for_empty(conn, bucket) do
    case :riakc_pb_socket.list_keys(conn, bucket) do
      {:ok, []} ->
        :ok
      {:ok, _} ->
        Process.sleep(100)
        wait_for_empty(conn, bucket)
    end
  end
end
