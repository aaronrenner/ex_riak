defmodule ExRiak do
  @moduledoc """
  ExRiak's main modules closely mirrors
  [riak-erlang-client's API](http://basho.github.io/riak-erlang-client/).

  Below are the mappings between `ExRiak` modules and the
  [`riak-erlang-client`](https://github.com/basho/riak-erlang-client) modules.

  | Elixir            | Erlang             |
  | ----------------- | -----------------  |
  | `ExRiak.PBSocket` | #{ExRiak.Docs.erlang_doc_link(:riakc_pb_socket)} |
  | `ExRiak.Object`   | #{ExRiak.Docs.erlang_doc_link(:riakc_object)} |

  To get a better understanding of how to use this client, review the above
  modules and check out the following resources:

  * [Basho Riak Docs](http://docs.basho.com/riak/kv/2.2.3)
  * [basho/riak-erlang-client](https://github.com/basho/riak-erlang-client)
  """
end
