defmodule ExRiak.Docs do
  @moduledoc false

  @erlang_doc_base_url "http://basho.github.io/riak-erlang-client"

  @spec erlang_doc_url(module | mfa) :: String.t
  def erlang_doc_url({module, function, arity}) when is_atom(module) and is_atom(function) and is_number(arity) do
    "#{erlang_doc_url(module)}##{function}-#{arity}"
  end
  def erlang_doc_url(module) when is_atom(module) do
    "#{@erlang_doc_base_url}/#{module}.html"
  end

  @spec erlang_doc_link(module | mfa) :: String.t
  def erlang_doc_link({module, function, arity} = mfa) when is_atom(module) and is_atom(function) and is_number(arity) do
    "[`#{inspect module}.#{function}/#{arity}`](#{erlang_doc_url(mfa)})"
  end
  def erlang_doc_link(module) when is_atom(module) do
    "[`#{inspect module}`](#{erlang_doc_url(module)})"
  end
end
