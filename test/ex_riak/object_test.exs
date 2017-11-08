defmodule ExRiak.ObjectTest do
  use ExRiak.RiakCase

  alias ExRiak.DecodingError
  alias ExRiak.NoValueError
  alias ExRiak.Object
  alias ExRiak.PBSocket
  alias ExRiak.SiblingsError

  test "decoding a string", %{conn: conn} do
    key = random_string()
    value = "world"
    obj = Object.new(basic_bucket(), key, value, "text/plain")
    :riakc_pb_socket.put(conn, obj)

    {:ok, fetched_obj} = :riakc_pb_socket.get(conn, basic_bucket(), key)

    assert {:ok, ^value} = Object.get_value(fetched_obj)
    assert ^value = Object.get_value!(fetched_obj)
    assert {:ok, ^value} = Object.get_update_value(fetched_obj)
    assert ^value = Object.get_update_value!(fetched_obj)
    assert {:ok, "text/plain"} = Object.get_content_type(fetched_obj)
    assert "text/plain" = Object.get_content_type!(fetched_obj)
  end

  test "decoding an erlang term", %{conn: conn} do
    key = random_string()
    value = %{name: "Aaron"}
    obj = Object.new(basic_bucket(), key, value, "text/plain")
    :riakc_pb_socket.put(conn, obj)

    {:ok, fetched_obj} = :riakc_pb_socket.get(conn, basic_bucket(), key)

    assert {:ok, ^value} = Object.get_value(fetched_obj)
    assert ^value = Object.get_value!(fetched_obj)
    assert {:ok, ^value} = Object.get_update_value(fetched_obj)
    assert ^value = Object.get_update_value!(fetched_obj)
    assert 1 = Object.value_count(fetched_obj)
    refute Object.siblings?(fetched_obj)
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

    assert {:error, %DecodingError{
      value: ^value,
      content_type: ^content_type
    }} = Object.get_update_value(fetched_obj)

    assert_raise DecodingError, fn ->
      Object.get_update_value!(fetched_obj)
    end
  end

  test "saving and retrieving string without a content type", %{conn: conn} do
    key = random_string()
    value = "Hello"
    obj = Object.new(basic_bucket(), key, value)

    PBSocket.put!(conn, obj)

    {:ok, fetched_obj} = PBSocket.get(conn, basic_bucket(), key)
    assert ^value = Object.get_value!(fetched_obj)
    assert :undefined = Object.get_content_type!(fetched_obj)
  end

  test "trying to clear a content type for an object" do
    obj = Object.new(basic_bucket(), "key", "val", "text/plain")

    assert_raise FunctionClauseError, fn ->
      Object.update_content_type(obj, :undefined)
    end
  end

  test "saving and retrieving term without a content type", %{conn: conn} do
    key = random_string()
    value = %{password: "secret"}
    obj = Object.new(basic_bucket(), key, value)

    PBSocket.put!(conn, obj)

    {:ok, fetched_obj} = PBSocket.get(conn, basic_bucket(), key)
    assert ^value = Object.get_value!(fetched_obj)
    assert "application/x-erlang-binary" = Object.get_content_type!(fetched_obj)
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
    assert {:error, %SiblingsError{}} = Object.get_update_value(fetched_obj)
    assert_raise SiblingsError, fn ->
       Object.get_update_value!(fetched_obj)
    end
    assert {:error, %SiblingsError{}} = Object.get_content_type(fetched_obj)
    assert_raise SiblingsError, fn ->
      Object.get_content_type!(fetched_obj)
    end
    assert {:error, %SiblingsError{}} = Object.get_update_content_type(fetched_obj)
    assert_raise SiblingsError, fn ->
      Object.get_update_content_type!(fetched_obj)
    end
    assert [^content_type, ^content_type] = Object.get_content_types(fetched_obj)

    assert 2 = Object.value_count(fetched_obj)
    assert Object.siblings?(fetched_obj)
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
    assert {:error, %SiblingsError{}} = Object.get_update_value(fetched_obj)
    assert_raise SiblingsError, fn ->
       Object.get_update_value!(fetched_obj)
    end
    assert {:error, %SiblingsError{}} = Object.get_content_type(fetched_obj)
    assert_raise SiblingsError, fn ->
      Object.get_content_type!(fetched_obj)
    end
  end

  test "decoding metadata", %{conn: conn} do
    key = random_string()
    {metadata_key_1, metadata_value_1} = metadata_entry_1 = {"account", "3"}
    {metadata_key_2, metadata_value_2} = metadata_entry_2 = {"valid", "true"}
    {metadata_key_3, _} = metadata_entry_3 = {"remove", "me"}
    obj = Object.new(basic_bucket(), key, "val", "text/plain")
    metadata =
      obj
      |> Object.get_metadata!()
      |> Object.set_user_metadata_entry(metadata_entry_1)
      |> Object.set_user_metadata_entry(metadata_entry_2)
      |> Object.set_user_metadata_entry(metadata_entry_3)
      |> Object.delete_user_metadata_entry(metadata_key_3)
    obj = Object.update_metadata(obj, metadata)
    PBSocket.put!(conn, obj)

    {:ok, fetched_obj} = PBSocket.get(conn, basic_bucket(), key)

    assert {:ok, metadata} = Object.get_metadata(fetched_obj)
    assert ^metadata = Object.get_metadata!(fetched_obj)

    assert metadata_entry_1 in Object.get_user_metadata_entries(metadata)
    assert metadata_entry_2 in Object.get_user_metadata_entries(metadata)
    refute metadata_entry_3 in Object.get_user_metadata_entries(metadata)

    assert ^metadata_value_1 =
      Object.get_user_metadata_entry(metadata, metadata_key_1)
    assert ^metadata_value_2 =
      Object.get_user_metadata_entry(metadata, metadata_key_2)
    assert is_nil(Object.get_user_metadata_entry(metadata, "does not exist"))

    assert [] =
      metadata
      |> Object.clear_user_metadata_entries
      |> Object.get_user_metadata_entries
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
    assert {:error, %NoValueError{}} = Object.get_update_value(obj)

    assert [] = Object.get_content_types(obj)
    assert {:ok, :undefined} = Object.get_content_type(obj)
    assert :undefined = Object.get_update_content_type!(obj)

    metadata = Object.get_update_metadata(obj)
    assert [] = Object.get_user_metadata_entries(metadata)

    assert 0 = Object.value_count(obj)
    refute Object.siblings?(obj)
  end

  test "with a String as a content type" do
    obj = Object.new("bucket", "key", "value", "text/plain")

    assert 'text/plain' = :riakc_obj.get_update_content_type(obj)
    assert "text/plain" = Object.get_update_content_type!(obj)

    obj = Object.update_content_type(obj, "application/json")

    assert 'application/json' = :riakc_obj.get_update_content_type(obj)
    assert "application/json" = Object.get_update_content_type!(obj)
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

  describe "update_value/2" do
    test "updates the value and does not set the content type" do
      obj =
        "my_bucket"
        |> Object.new("key", "value")
        |> Object.update_value("new value")

      assert "new value" = Object.get_update_value!(obj)
      assert :undefined = Object.get_content_type!(obj)
    end
  end
end
