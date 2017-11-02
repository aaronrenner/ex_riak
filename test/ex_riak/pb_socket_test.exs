defmodule ExRiak.PBSocketTest do
  use ExRiak.RiakCase

  alias ExRiak.PBSocket

  describe "get/3" do
    test "when an object is found", %{conn: conn} do
      key = random_string()
      value = "world"
      obj = :riakc_obj.new(basic_bucket(), key, value, 'text/plain')
      :riakc_pb_socket.put(conn, obj)

      assert {:ok, _} = PBSocket.get(conn, basic_bucket(), key)
    end

    test "when an object is not found", %{conn: conn} do
      assert {:error, :not_found} =
        PBSocket.get(conn, basic_bucket(), "does not exist")
    end
  end
end
