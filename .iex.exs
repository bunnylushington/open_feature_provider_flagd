alias OpenFeature.Provider.Flagd.GRPC, as: Flagd
provider = Flagd.new("localhost:8013")
OpenFeature.set_provider(provider)
client = OpenFeature.get_client()
