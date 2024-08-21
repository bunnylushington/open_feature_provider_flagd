defmodule OpenFeature.Provider.Flagd.GRPC do
  @moduledoc """
  gRPC interface to flagd
  """

  require Logger

  alias OpenFeature.EventEmitter
  alias OpenFeature.ResolutionDetails
  alias Flagd.Schema.V1, as: FlagRPC

  @behaviour OpenFeature.Provider

  defstruct name: "FlagdGRPC",
            domain: nil,
            endpoint: nil,
            channel: nil,
            state: :not_ready,
            hooks: []

  @typedoc "A representation of the gRPC flagd provider."
  @type t() :: %__MODULE__{
          name: String.t,
          domain: String.t | nil,
          endpoint: String.t,
          channel: GRPC.Channel.t | nil,
          state: atom,
          hooks: list}

  @spec new(String.t) :: t()
  @spec new(String.t, keyword) :: t()
  def new(endpoint, _opts \\ []) do
    %__MODULE__{endpoint: endpoint}
  end

  @impl true
  @spec initialize(t(), String.t, any) :: {:ok, t()}
  def initialize(provider, domain, _context) do
    {:ok, channel} = GRPC.Stub.connect(provider.endpoint)
    {:ok, %{provider | state: :ready, domain: domain, channel: channel}}
  end

  @impl true
  @spec shutdown(any()) :: :ok
  def shutdown(_),
      do: :ok

  @impl true
  @spec resolve_boolean_value(
      provider :: t,
      key :: String.t,
      default :: boolean,
      context :: any()) :: OpenFeature.Provider.result
  def resolve_boolean_value(provider, key, _default, context) do
    ctx = encode_context(context)
    request = struct(FlagRPC.ResolveBooleanRequest,
                     %{flag_key: key, context: ctx})
    resolve(:resolve_boolean, provider.channel, request)
  end

  @impl true
  @spec resolve_map_value(
      provider :: t,
      key :: String.t,
      default :: map,
      context :: any()) :: OpenFeature.Provider.result
  def resolve_map_value(provider, key, _default, context) do
    ctx = encode_context(context)
    request = struct(FlagRPC.ResolveObjectRequest,
                     %{flag_key: key, context: ctx})
    resolve(:resolve_object, provider.channel, request)
  end

  @impl true
  @spec resolve_number_value(
      provider :: t,
      key :: String.t,
      default :: number,
      context :: any()) :: OpenFeature.Provider.result
  def resolve_number_value(provider, key, default, context) do
    {method, type} =
      if is_integer(default),
         do:   {:resolve_int,   FlagRPC.ResolveIntRequest},
         else: {:resolve_float, FlagRPC.ResolveFloatRequest}
    ctx = encode_context(context)
    request = struct(type, %{flag_key: key, context: ctx})
    resolve(method, provider.channel, request)
  end

  @impl true
  @spec resolve_string_value(
      provider :: t,
      key :: String.t,
      default :: String.t,
      context :: any()) :: OpenFeature.Provider.result
    def resolve_string_value(provider, key, _default, context) do
    ctx = encode_context(context)
    request = struct(FlagRPC.ResolveStringRequest,
                     %{flag_key: key, context: ctx})
    resolve(:resolve_string, provider.channel, request)
  end

  defp resolve(function, channel, request) do
    case apply(FlagRPC.Service.Stub, function, [channel, request]) do
      {:ok, response} ->
        {:ok, struct(ResolutionDetails, %{value: wash(response.value),
                                          variant: response.variant,
                                          reason: response.reason})}
      {:error, _response} ->
        {:error, :flag_not_found}
    end
  end

  defp wash(value) when is_struct(value, Google.Protobuf.Struct) do
    Protobuf.JSON.Encode.encodable(value, nil)
  end
  defp wash(value) do
    value
  end

  defp encode_context(context) do
    Enum.map(context, fn {k, v} -> {to_string(k), v} end)
    |> Enum.into(%{})
    |> Protobuf.JSON.Decode.from_json_data(Google.Protobuf.Struct)
  end

  def start_event_stream(client) do
    channel = client.provider.channel
    request = %FlagRPC.EventStreamRequest{}
    {:ok, stream} = FlagRPC.Service.Stub.event_stream(channel, request)
    process_event_stream(stream, client.domain)
  end

  defp process_event_stream(stream, domain) do
    stream
    |> Stream.take(1)
    |> Enum.to_list()
    |> hd()
    |> process_event_message(domain)
    process_event_stream(stream, domain)
  end

  defp process_event_message({:ok, msg}, domain) do
    case Protobuf.JSON.Encode.encodable(msg, nil) do
      %{"type" => "keep_alive"} -> :ok

      %{"type" => "provider_ready"} ->
        EventEmitter.emit(domain, :provider_ready, %{})

      %{"type" => "configuration_change"} = data ->
        Enum.each(data["data"]["flags"], fn {flag, attrs} ->
          change = %{type: attrs["type"],
                     source: attrs["source"],
                     flag_key: flag}
          EventEmitter.emit(domain, :configuration_change, change)
        end)

      %{"type" => type} = data ->
        Logger.debug("unknown event #{type} #{inspect(data)}")
    end
  end

  defp process_event_message({:error, err}, _domain) do
    Logger.warning("error from flagd event: #{err}")
  end

end
