defmodule ExRiak.DocsTest do
  use ExUnit.Case, async: true

  alias ExRiak.Docs

  @erlang_doc_base_url "http://basho.github.io/riak-erlang-client"

  describe "erlang_doc_url/1" do
    test "with a module" do
      assert "#{@erlang_doc_base_url}/riakc_obj.html" ==
        Docs.erlang_doc_url(:riakc_obj)
    end

    test "with a mfa" do
      assert "#{@erlang_doc_base_url}/riakc_obj.html#update_value-2" ==
        Docs.erlang_doc_url({:riakc_obj, :update_value, 2})
    end
  end

  describe "erlang_doc_link/1" do
    test "with a module" do
      assert "[`:riakc_obj`](#{Docs.erlang_doc_url(:riakc_obj)})" ==
        Docs.erlang_doc_link(:riakc_obj)
    end

    test "with a mfa" do
      mfa = {:riakc_obj, :update_value, 2}

      assert "[`:riakc_obj.update_value/2`](#{Docs.erlang_doc_url(mfa)})" ==
        Docs.erlang_doc_link(mfa)
    end
  end
end
