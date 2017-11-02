defmodule ExRiak.ObjectTest do
  use ExRiak.RiakCase

  alias ExRiak.Object
  alias ExRiak.SiblingsError

  test "decoding a string", %{conn: conn} do
    key = random_string()
    value = "world"
    obj = :riakc_obj.new(basic_bucket(), key, value, 'text/plain')
    :riakc_pb_socket.put(conn, obj)

    {:ok, fetched_obj} = :riakc_pb_socket.get(conn, basic_bucket(), key)

    assert {:ok, ^value} = Object.get_value(fetched_obj)
    assert ^value = Object.get_value!(fetched_obj)
    assert {:ok, "text/plain"} = Object.get_content_type(fetched_obj)
    assert "text/plain" = Object.get_content_type!(fetched_obj)
  end

  test "decoding an erlang term", %{conn: conn} do
    key = random_string()
    value = %{name: "Aaron"}
    obj = :riakc_obj.new(basic_bucket(), key, value, 'text/plain')
    :riakc_pb_socket.put(conn, obj)

    {:ok, fetched_obj} = :riakc_pb_socket.get(conn, basic_bucket(), key)

    assert {:ok, ^value} = Object.get_value(fetched_obj)
    assert ^value = Object.get_value!(fetched_obj)
  end

  test "decoding a string with siblings", %{conn: conn} do
    key = random_string()
    value = "world"
    obj = :riakc_obj.new(basic_bucket(), key, value, 'text/plain')
    :riakc_pb_socket.put(conn, obj)
    :riakc_pb_socket.put(conn, obj)

    {:ok, fetched_obj} = :riakc_pb_socket.get(conn, basic_bucket(), key)

    assert {:error, %SiblingsError{}} = Object.get_value(fetched_obj)
    assert_raise SiblingsError, fn ->
       Object.get_value!(fetched_obj)
    end
    assert {:error, %SiblingsError{}} = Object.get_content_type(fetched_obj)
    assert_raise SiblingsError, fn ->
      Object.get_content_type!(fetched_obj)
    end
  end
end
