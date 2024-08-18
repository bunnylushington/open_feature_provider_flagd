# OpenFeature Provider Flagd

Use `flagd` as an OpenFeature provider.

## Example Use

``` elixir
provider = Flagd.new("http://localhost:8013")
OpenFeature.set_provider(provider)
client = OpenFeature.get_client()

## without a context
OpenFeature.Client.get_boolean_value(client, "key", true)

## with a context
OpenFeature.Client.get_boolean_value(client, "key", true,
    context: %{company: "example.com"})

```

## Testing

Tests require a live `flagd` and expect to communicate via http to
port 8013.  Running `docker-compose -f docker-compose.yaml up` in the
base of this repository will set up a flagd server with the sample
configuration `priv/demo.flagd.json`.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `open_feature_provider_flagd` to your
list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:open_feature_provider_flagd, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/open_feature_provider_flagd>.
