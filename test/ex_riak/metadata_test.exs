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
end
