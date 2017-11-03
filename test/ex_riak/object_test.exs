defmodule ExRiak.ObjectTest do
  use ExRiak.RiakCase

  alias ExRiak.DecodingError
  alias ExRiak.NoValueError
  alias ExRiak.Object
  alias ExRiak.SiblingsError

  test "decoding a string", %{conn: conn} do
    key = random_string()
    value = "world"
    obj = Object.new(basic_bucket(), key, value, 'text/plain')
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
    obj = Object.new(basic_bucket(), key, value, 'text/plain')
    :riakc_pb_socket.put(conn, obj)

    {:ok, fetched_obj} = :riakc_pb_socket.get(conn, basic_bucket(), key)

    assert {:ok, ^value} = Object.get_value(fetched_obj)
    assert ^value = Object.get_value!(fetched_obj)
  end

  test "decoding an invalid erlang term", %{conn: conn} do
    key = random_string()
    value = <<131, 116, 0, 0, 0, 1, 100, 0, 1, 97, 109, 0, 0, 3, 1, 98>>
    content_type = "application/x-erlang-binary"
    obj = Object.new(basic_bucket(), key, value, content_type)
    :riakc_pb_socket.put(conn, obj)

    {:ok, fetched_obj} = :riakc_pb_socket.get(conn, basic_bucket(), key)

    assert {:error, %DecodingError{
      value: ^value,
      content_type: ^content_type
    }} = Object.get_value(fetched_obj)

    assert_raise DecodingError, fn ->
      Object.get_value!(fetched_obj)
    end
  end

  test "decoding a string with siblings", %{conn: conn} do
    key = random_string()
    value = "world"
    content_type = "text/plain"
    obj = Object.new(basic_bucket(), key, value, content_type)
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
    assert {:error, %SiblingsError{}} = Object.get_content_type(fetched_obj)
    assert [^content_type, ^content_type] = Object.get_content_types(fetched_obj)
  end

  test "decoding an erlang term with siblings", %{conn: conn} do
    key = random_string()
    value = %{name: "Aaron"}
    obj = Object.new(basic_bucket(), key, value, 'text/plain')
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

  test "decoding metadata", %{conn: conn} do
    key = random_string()
    value = "world"
    content_type = "text/plain"
    obj = Object.new(basic_bucket(), key, value, content_type)

    :riakc_pb_socket.put(conn, obj)

    {:ok, fetched_obj} = :riakc_pb_socket.get(conn, basic_bucket(), key)

    assert {:ok, metadata} = Object.get_metadata(fetched_obj)
    assert ^metadata = Object.get_metadata!(fetched_obj)
  end

  test "decoding metadata with siblings", %{conn: conn} do
    key = random_string()
    value = "world"
    content_type = "text/plain"
    obj = Object.new(basic_bucket(), key, value, content_type)
    :riakc_pb_socket.put(conn, obj)
    :riakc_pb_socket.put(conn, obj)

    {:ok, fetched_obj} = :riakc_pb_socket.get(conn, basic_bucket(), key)

    assert {:error, %SiblingsError{}} = Object.get_metadata(fetched_obj)
    assert_raise SiblingsError, fn ->
      Object.get_metadata!(fetched_obj)
    end
  end

  test "with an empty riak object" do
    key = random_string()
    obj = Object.new(basic_bucket(), key)

    assert {:error, %NoValueError{}} = Object.get_value(obj)
    assert_raise NoValueError, fn -> Object.get_value!(obj) end
  end

  test "with a String as a content type" do
    obj = Object.new("bucket", "key", "value", "text/plain")

    assert 'text/plain' = :riakc_obj.get_update_content_type(obj)
  end

  describe "new/2" do
    test "with invalid args" do
      assert_raise ArgumentError, ~r/empty value for bucket name/, fn ->
        Object.new("", "key")
      end
      assert_raise ArgumentError, ~r/empty value for key/, fn ->
        Object.new("my_bucket", "")
      end
    end
  end

  describe "new/3" do
    test "with invalid args" do
      assert_raise ArgumentError, ~r/empty value for bucket name/, fn ->
        Object.new("", "key", "value")
      end
      assert_raise ArgumentError, ~r/empty value for key/, fn ->
        Object.new("my_bucket", "", "value")
      end
    end
  end

  describe "new/4" do
    test "with invalid args" do
      assert_raise ArgumentError, ~r/empty value for bucket name/, fn ->
        Object.new("", "key", "value", "text/plain")
      end
      assert_raise ArgumentError, ~r/empty value for key/, fn ->
        Object.new("my_bucket", "", "value", "text/plain")
      end
    end
  end
end
