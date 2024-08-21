alias OpenFeature.Provider.Flagd.HTTP, as: Flagd
provider = Flagd.new("http://localhost:8013")
OpenFeature.set_provider(provider)
client = OpenFeature.get_client()
