defmodule ExRiak.PBSocketTest do
  use ExRiak.RiakCase

  alias ExRiak.NoValueError
  alias ExRiak.Object
  alias ExRiak.PBSocket
  alias ExRiak.PBSocketError
  alias ExRiak.SiblingsError

  test "start_link/1 with client options" do
    # This would not start if the auto_reconnect option was not passed through
    {:ok, conn} =
      PBSocket.start_link(hostname: 'does_not_exist', auto_reconnect: true)

    assert {false, _} = :riakc_pb_socket.is_connected(conn)
  end

  describe "get/3" do
    test "when an object is found", %{conn: conn} do
      key = random_string()
      value = "world"
      obj = Object.new(basic_bucket(), key, value, 'text/plain')
      :riakc_pb_socket.put(conn, obj)

      assert {:ok, obj} = PBSocket.get(conn, basic_bucket(), key)
      assert ^value = Object.get_value!(obj)

      obj = PBSocket.get!(conn, basic_bucket(), key)
      assert ^value = Object.get_value!(obj)
    end

    test "when an object is not found", %{conn: conn} do
      assert {:error, :not_found} =
        PBSocket.get(conn, basic_bucket(), "does not exist")

     refute PBSocket.get!(conn, basic_bucket(), "does not exist")
    end

    test "when there is an error", %{conn: conn} do
      assert {:error, %PBSocketError{}} =
        PBSocket.get(conn, {"invalid type", "bucket"}, "key")

      assert_raise PBSocketError, fn ->
        PBSocket.get!(conn, {"invalid type", "bucket"}, "key")
      end
    end
  end

  test "trying to update an object with siblings", %{conn: conn} do
    key = random_string()
    value = "world"
    obj = Object.new(basic_bucket(), key, value, 'text/plain')
    :riakc_pb_socket.put(conn, obj)
    :riakc_pb_socket.put(conn, obj)

    {:ok, fetched_obj} = PBSocket.get(conn, basic_bucket(), key)
    fetched_obj = :riakc_obj.update_value(fetched_obj, "test")

    assert {:error, %SiblingsError{}} = PBSocket.put(conn, fetched_obj)
    assert_raise SiblingsError, fn -> PBSocket.put!(conn, fetched_obj) end
  end

  test "trying to put an empty object", %{conn: conn} do
    key = random_string()
    obj = Object.new(basic_bucket(), key)

    assert {:error, %NoValueError{}} = PBSocket.put(conn, obj)
    assert_raise NoValueError, fn -> PBSocket.put!(conn, obj) end
  end

  describe "delete/3" do
    test "deleting an object that exists in the db", %{conn: conn} do
      key = random_string()
      obj = Object.new(basic_bucket(), key, "hello")
      PBSocket.put!(conn, obj)

      assert :ok = PBSocket.delete(conn, basic_bucket(), key)

      assert {:error, :not_found} = PBSocket.get(conn, basic_bucket(), key)
    end

    test "deleting a non-existent key", %{conn: conn} do
      key = random_string()

      assert :ok = PBSocket.delete(conn, basic_bucket(), key)
      assert {:error, :not_found} = PBSocket.get(conn, basic_bucket(), key)
    end
  end

  describe "delete!/3" do
    test "deleting an object that exists in the db", %{conn: conn} do
      key = random_string()
      obj = Object.new(basic_bucket(), key, "hello")
      PBSocket.put!(conn, obj)

      assert :ok = PBSocket.delete(conn, basic_bucket(), key)

      assert {:error, :not_found} = PBSocket.get(conn, basic_bucket(), key)
    end

    test "deleting a non-existent key", %{conn: conn} do
      key = random_string()

      assert :ok = PBSocket.delete(conn, basic_bucket(), key)
      assert {:error, :not_found} = PBSocket.get(conn, basic_bucket(), key)
    end
  end

  describe "fetching crdt types" do
    test "when a value is found", %{conn: conn} do
      key = random_string()
      map = :riakc_map.new()
      map = :riakc_map.update({"name", :register}, fn register ->
        :riakc_register.set("Aaron", register)
      end, map)
      :ok =
        :riakc_pb_socket.update_type(
            conn,
            maps_bucket(),
            key,
            :riakc_map.to_op(map)
        )

      assert {:ok, fetched_map} = PBSocket.fetch_type(conn, maps_bucket(), key)
      assert "Aaron" = :riakc_map.fetch({"name", :register}, fetched_map)
      assert fetched_map = PBSocket.fetch_type!(conn, maps_bucket(), key)
      assert "Aaron" = :riakc_map.fetch({"name", :register}, fetched_map)
    end

    test "when a value is not found", %{conn: conn} do
      key = "does not exist"

      assert {:error, :not_found} =
        PBSocket.fetch_type(conn, maps_bucket(), key)
      refute PBSocket.fetch_type!(conn, maps_bucket(), key)
    end

    test "when there is an error", %{conn: conn} do
      key = random_string()
      bucket = {"unknown", "unknown"}

      assert {:error, %PBSocketError{}} = PBSocket.fetch_type(conn, bucket, key)
      assert_raise PBSocketError, fn ->
        PBSocket.fetch_type!(conn, bucket, key)
      end
    end
  end

  describe "listing keys" do
    test "when everything goes right", %{conn: conn} do
      bucket_locator = basic_bucket()
      clean_bucket(conn, bucket_locator)

      {:ok, []} = PBSocket.list_keys(conn, bucket_locator)
      [] = PBSocket.list_keys!(conn, bucket_locator)

      key = random_string()
      obj = Object.new(bucket_locator, key, "val")
      PBSocket.put!(conn, obj)

      {:ok, [^key]} = PBSocket.list_keys(conn, bucket_locator)
      [^key] = PBSocket.list_keys!(conn, bucket_locator)
    end

    test "when bucket type doesn't exist", %{conn: conn} do
      bucket_locator = {"apf-invalid", "bucket"}

      assert {:error, %PBSocketError{}} =
        PBSocket.list_keys(conn, bucket_locator)

      assert_raise PBSocketError, fn ->
        PBSocket.list_keys!(conn, bucket_locator)
      end
    end
  end
end
