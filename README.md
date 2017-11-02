# ExRiak

Simple wrapper around [riak-erlang-client](github.com/basho/riak-erlang-client),
designed to let you drop down to the original erlang client whenever you need.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_riak` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_riak, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_riak](https://hexdocs.pm/ex_riak).


## Development

### Running tests

Before running tests, you need to create a few bucket types:

```shell
riak-admin bucket-type create ex_riak
riak-admin bucket-type activate ex_riak
