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

  @typedoc """
  A riak bucket name
  """
  @type bucket :: String.t

  @typedoc """
  A riak bucket type.
  """
  @type bucket_type :: String.t

  @typedoc """
  Combination of bucket_type and bucket
  """
  @type bucket_and_type :: {bucket_type, bucket}

  @typedoc """
  Term used to locate a bucket
  """
  @type bucket_locator :: bucket_and_type | bucket

  @typedoc """
  Riak object key
  """
  @type key :: String.t

  @typedoc """
  Riak index name
  """
  @type index :: String.t

  @typedoc """
  Riak index binary value
  """
  @type binary_index_value :: String.t
end
