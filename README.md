# OpenFeature Provider Flagd

Use `flagd` as an OpenFeature provider.

## Example Use

``` elixir
## an HTTP provider
provider = OpenFeature.Provider.Flagd.HTTP.new("http://localhost:8013")

## a gRPC provider
provider = OpenFeature.Provider.Flagd.GRPC.new("localhost:8013")

## both the HTTP and gRPC providers use the same API:
OpenFeature.set_provider(provider)
client = OpenFeature.get_client()

## without a context
OpenFeature.Client.get_boolean_value(client, "key", true)

## with a context
OpenFeature.Client.get_boolean_value(client, "key", true,
    context: %{company: "example.com"})

## the gRPC client can listen to events:
OpenFeature.Provider.Flagd.GRPC.start_event_stream(client)

## perhaps log configuration changes:
require Logger
OpenFeature.Client.add_event_handler(client, :configuration_change,
                         fn details ->
                           Logger.debug(inspect(details))
                         end)
```

There are two events emitted: `:provider_ready` and `:configuration_change`.

## Testing

Tests require a live `flagd` and expect to communicate via http to
port 8013.  Running `docker-compose -f docker-compose.yaml up` in the
base of this repository will set up a flagd server with the sample
configuration `priv/demo.flagd.json`.

## Building

To create the `flagd.pb.ex` asset:

``` shell
$ brew install protobuf
$ mix escript.install hex protobug
$ wget https://buf.build/open-feature/flagd/raw/main/-/schema/v1/schema.proto \
    -Osrc/flagd.proto
$ protoc --elixir_out=plugins=grpc:./lib --elixir_opt=package_prefix=flagd \
    -I src flagd.proto

```

```
