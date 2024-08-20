defmodule OpenFeature.Provider.Flagd.GRPC do
  @moduledoc """
  gRPC interface to flagd
  """

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
          state: :not_ready | :ready,
          hooks: list}

  @spec new(String.t) :: OpenFeature.Provider.Flagd.GRPC.t()
  def new(endpoint) do
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
  def resolve_number_value(provider, key, _default, context) do
    ctx = encode_context(context)
    request = struct(FlagRPC.ResolveFloatRequest,
                     %{flag_key: key, context: ctx})
    resolve(:resolve_float, provider.channel, request)
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

end
