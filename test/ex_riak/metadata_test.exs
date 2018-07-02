defmodule ExRiak.MetadataTest do
  use ExUnit.Case, async: true

  alias ExRiak.Metadata
  alias ExRiak.Object

  describe "get_content_type/1" do
    test "when a content_type has been set" do
      content_type = "text/plain"

      {:ok, metadata} =
        "bucket"
        |> Object.new("key", "val", content_type)
        |> Object.get_update_metadata()

      assert ^content_type = Metadata.get_content_type(metadata)
    end

    test "when a content_type has not been set" do
      {:ok, metadata} =
        "bucket"
        |> Object.new("key")
        |> Object.get_update_metadata()

      assert :undefined = Metadata.get_content_type(metadata)
    end
  end

  describe "user metadata" do
    setup [:build_metadata]

    test "can add, update and remove metadata", %{metadata: metadata} do
      {metadata_key_1, metadata_value_1} = metadata_entry_1 = {"account", "3"}
      {metadata_key_2, metadata_value_2} = metadata_entry_2 = {"valid", "true"}
      {metadata_key_3, _} = metadata_entry_3 = {"remove", "me"}

      metadata =
        metadata
        |> Metadata.set_user_entry(metadata_entry_1)
        |> Metadata.set_user_entry(metadata_entry_2)
        |> Metadata.set_user_entry(metadata_entry_3)
        |> Metadata.delete_user_entry(metadata_key_3)

      assert metadata_entry_1 in Metadata.get_user_entries(metadata)
      assert metadata_entry_2 in Metadata.get_user_entries(metadata)
      refute metadata_entry_3 in Metadata.get_user_entries(metadata)

      assert ^metadata_value_1 = Metadata.get_user_entry(metadata, metadata_key_1)
      assert ^metadata_value_2 = Metadata.get_user_entry(metadata, metadata_key_2)

      assert [] =
               metadata
               |> Metadata.clear_user_entries()
               |> Metadata.get_user_entries()
    end

    test "get_user_entry/2 found value", %{metadata: md} do
      md = Object.set_user_metadata_entry(md, {"key", "value"})

      assert "value" = Object.get_user_metadata_entry(md, "key")
    end

    test "get_user_entry/2 value not found, no default", %{metadata: md} do
      refute Object.get_user_metadata_entry(md, "key")
    end

    test "get_user_etnry/2 value not found, with default", %{metadata: md} do
      assert "default" = Object.get_user_metadata_entry(md, "key", "default")
    end
  end

  describe "secondary indexes" do
    setup [:build_metadata]

    test "can be set from Erlang and read from Elixir", %{metadata: md} do
      index_1_id = {:binary_index, "account_id"}
      index_1_value = "34"
      index_1 = {index_1_id, [index_1_value]}

      md = :riakc_obj.set_secondary_index(md, [index_1])

      assert [^index_1_value] = Metadata.get_secondary_index(md, index_1_id)
      assert [^index_1] = Metadata.get_secondary_indexes(md)
    end

    test "can be set from Elixir and read from Erlang", %{metadata: md} do
      index_locator_1 = {:binary_index, "account_id"}
      index_1_value = "34"
      index_1 = {index_locator_1, [index_1_value]}

      md = Metadata.set_secondary_index(md, [index_1])

      assert [^index_1_value] = :riakc_obj.get_secondary_index(md, index_locator_1)
    end

    test "getting a secondary index that doesn't exist returns the default value", %{metadata: md} do
      index_id = {:binary_index, "does not exist"}

      assert nil == Metadata.get_secondary_index(md, index_id)
      assert :error = Metadata.get_secondary_index(md, index_id, :error)
    end

    test "manipulating secondary indexes", %{metadata: md} do
      ids_index_id = {:integer_index, "ids"}
      pets_index_id = {:binary_index, "pets"}
      index_1 = {ids_index_id, [10, 12]}

      md = Metadata.set_secondary_index(md, index_1)

      assert [^index_1] = Metadata.get_secondary_indexes(md)

      md = Metadata.add_secondary_index(md, {pets_index_id, ["Chester"]})
      md = Metadata.add_secondary_index(md, {ids_index_id, [1]})

      assert ["Chester"] = Metadata.get_secondary_index(md, pets_index_id)
      assert [1, 10, 12] = Metadata.get_secondary_index(md, ids_index_id)

      md = Metadata.delete_secondary_index(md, pets_index_id)
      assert nil == Metadata.get_secondary_index(md, pets_index_id)

      md = Metadata.clear_secondary_indexes(md)

      assert [] = Metadata.get_secondary_indexes(md)
    end
  end

  defp build_metadata(_) do
    metadata = "bucket" |> Object.new("key") |> Object.get_metadata!()
    {:ok, [metadata: metadata]}
  end
end
