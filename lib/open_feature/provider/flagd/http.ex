defmodule OpenFeature.Provider.Flagd.HTTP do
  @moduledoc """
  Open Feature flagd provider.
  """

  alias OpenFeature.ResolutionDetails

  @behaviour OpenFeature.Provider

  @default_service "flagd.evaluation.v1.Service"

  defstruct name: "Flagd",
            domain: nil,
            state: :not_ready,
            endpoint: nil,
            service: @default_service,
            hooks: [],
            req: nil

  @typedoc "A representation of the HTTP flagd provider."
  @type t() :: %__MODULE__{
          name: String.t,
          domain: String.t | nil,
          state: :not_ready | :ready,
          endpoint: String.t,
          service: String.t,
          hooks: list,
          req: Req.t | nil}

  @spec new(String.t) :: OpenFeature.Provider.Flagd.t
  @spec new(String.t, Keyword.t) :: OpenFeature.Provider.Flagd.t
  @doc """
  Define a new flagd provider.

  The endpoint is the HTTP(S) URL of the flagd source.

  The option `:service` may be specified.
  """
  def new(endpoint, opts \\ []) do
    service = Keyword.get(opts, :service, @default_service)
    %__MODULE__{endpoint: endpoint, service: service}
  end

  @impl true
  @spec initialize(t, any, any)
        ::  {:ok, t}
  def initialize(provider, domain, _context) do
    req = Req.new(base_url: base_url(provider),
                  method: :post,
                  headers: [{"Content-type", "application/json"}])
    {:ok, %{provider | state: :ready, domain: domain, req: req}}
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
          contect :: any()) :: OpenFeature.Provider.result
  def resolve_boolean_value(provider, key, _default, context) do
    request(provider, key, context, "/ResolveBoolean")
  end

  @impl true
  @spec resolve_map_value(
          provider :: t,
          key :: String.t,
          default :: map,
          context :: any()) :: OpenFeature.Provider.result
  def resolve_map_value(provider, key, _default, context) do
    request(provider, key, context, "/ResolveObject")
  end

  @impl true
  @spec resolve_number_value(
          provider :: t,
          key :: String.t,
          default :: number,
          context :: any()) :: OpenFeature.Provider.result
  def resolve_number_value(provider, key, default, context) do
    method = if is_integer(default),
                do: "/ResolveInt",
                else: "/ResolveFloat"
    request(provider, key, context, method)
  end

  @impl true
  @spec resolve_string_value(
          provider :: t,
          key :: String.t,
          default :: String.t,
          context :: any()) :: OpenFeature.Provider.result
  def resolve_string_value(provider, key, _default, context) do
    request(provider, key, context, "/ResolveString")
  end

  defp base_url(provider) do
    URI.merge(URI.parse(provider.endpoint), provider.service)
  end

  defp payload(key, context) do
    Jason.encode!(%{"flagKey" => key, "context" => context})
  end

  defp request(provider, key, context, function) do
    provider.req
    |> Req.merge(url: function)
    |> Req.merge(body: payload(key, context))
    |> Req.Request.run_request()
    |> parse_result()
  catch
    e -> {:error, :unexpected_error, e}
  end

  defp parse_result({_req, res}) when res.status == 200 do
    {:ok, struct(ResolutionDetails,
                 %{value: res.body["value"],
                   variant: res.body["variant"],
                   reason: res.body["reason"]})}

  end
  defp parse_result({_req, res}) do
    case res.body["code"] do
      "not_found" -> {:error, :flag_not_found}
    end
  end

end
