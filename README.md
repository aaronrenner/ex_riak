# ExRiak
[![Build Status](https://travis-ci.org/aaronrenner/ex_riak.svg?branch=master)](https://travis-ci.org/aaronrenner/ex_riak)
[![Hex pm](https://img.shields.io/hexpm/v/ex_riak.svg?style=flat)](https://hex.pm/packages/ex_riak)
[![Inline docs](http://inch-ci.org/github/aaronrenner/ex_riak.svg)](http://inch-ci.org/github/aaronrenner/ex_riak)


ExRiak is simple wrapper around [riak-erlang-client][riak_erlang_client_github],
designed to let you follow Elixir coding conventions, while providing the
flexibility drop down to the underlying erlang client when needed. Here's an
example:

```elixir
# Can use the :riakc_pb_socket directly from erlang
{:ok, conn} = :riakc_pb_socket.start_link('127.0.0.1', 8087)

with {:ok, obj} <- ExRiak.PBSocket.get(conn, "tv_show_ratings", "simpsons"),
     # Can drop down to erlang if nessecary
     obj <- :riakc_obj.update_value(obj, 10) do

  # Save to riak. Will raise a ExRiak.SiblingsError if there are unresolved
  # siblings instead of throwing :siblings. Can also use ExRiak.PBSocket.put/2
  # to pattern match the result.
  ExRiak.PBSocket.put!(conn, obj)
end
```

See the [online documentation][docs] for more information.

## Usage

Add ExRiak to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ex_riak, "~> 0.4.1"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

### Interop with riak-erlang-client

This library closely mirrors the riak-erlang-client's API. Below are the
mappings between `ExRiak` modules and the `riak-erlang-client` modules.

| Elixir            | Erlang             |
| ----------------- | -----------------  |
| `ExRiak.PBSocket` | `:riakc_pb_socket` |
| `ExRiak.Object`   | `:riakc_obj`       |

More information on these modules is available in the
[online documentation][docs].

## Development

### Running tests

Before running tests, you need will need to update your riak setup:

1. Update your `riak.conf` to set up the appropriate backend. (If riak was
   installed with homebrew, the riak config file will be at
    `/usr/local/Cellar/riak/2.2.3/libexec/etc/riak.conf`.) Replace the line
    containing `storage_backend` with the following:

        storage_backend = multi

        multi_backend.ex_riak_leveldb.storage_backend = leveldb
        multi_backend.ex_riak_leveldb.leveldb.data_root = $(platform_data_dir)/ex_riak_leveldb

2. Run `riak start`.
3. Run the following commands to create the ExRiak bucket types.
    ```shell
    riak-admin bucket-type create ex_riak
    riak-admin bucket-type create ex_riak_maps '{"props":{"datatype":"map"}}'
    riak-admin bucket-type create ex_riak_leveldb '{"props":{"backend":"ex_riak_leveldb"}}'
    riak-admin bucket-type activate ex_riak
    riak-admin bucket-type activate ex_riak_maps
    riak-admin bucket-type activate ex_riak_leveldb
    ```

After that, make sure you've got Elixir 1.5+ installed and then:

```shell
$ mix deps.get
$ mix test
```

[docs]: https://hexdocs.pm/ex_riak
[riak_erlang_client_github]: https://github.com/basho/riak-erlang-client
