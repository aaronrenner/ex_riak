defmodule ExRiak.PBSocketTest do
  use ExRiak.RiakCase

  alias ExRiak.NoValueError
  alias ExRiak.Object
  alias ExRiak.PBSocket
  alias ExRiak.PBSocketError
  alias ExRiak.SiblingsError

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
end
