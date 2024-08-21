defmodule OpenFeature.Provider.Flagd.HTTPTest do
  use ExUnit.Case

  alias OpenFeature.Client
  alias OpenFeature.Provider.Flagd.HTTP, as: Flagd

  @endpoint "http://localhost:8013"

  setup do
    provider = Flagd.new(@endpoint)
    OpenFeature.set_provider(provider)
    client = OpenFeature.get_client()
    {:ok, provider: provider, client: client}
  end

  test "resolve boolean value", %{client: c} do
    assert Client.get_boolean_value(c, "boolean", true) == false
    detail = Client.get_boolean_details(c, "boolean", true)
    refute detail.error_code
  end

  test "resolve boolean value, does not exist", %{client: c} do
    assert Client.get_boolean_value(c, "xxx", true) == true
    detail = Client.get_boolean_details(c, "no-key", true)
    assert detail.error_code == :flag_not_found
  end

  test "resolve string value", %{client: c} do
    assert Client.get_string_value(c, "string", "red") == "#00FF00"
    detail = Client.get_string_details(c, "string", "red")
    refute detail.error_code
  end

  test "resolve string value, does not exist", %{client: c} do
    assert Client.get_string_value(c, "xxx", "red") == "red"
    detail = Client.get_string_details(c, "xxx", "red")
    assert detail.error_code == :flag_not_found
  end

  test "resolve number value, integer", %{client: c} do
    assert Client.get_number_value(c, "integer", 10) == "1"
    detail = Client.get_number_details(c, "integer", 10)
    refute detail.error_code
  end

  test "resolve number value, float", %{client: c} do
    assert Client.get_number_value(c, "float", 1.1)
    detail = Client.get_number_details(c, "float", 1.1)
    refute detail.error_code
  end

  test "resolve number value, does not exist", %{client: c} do
    assert Client.get_number_value(c, "xxx", 15) == 15
    detail = Client.get_number_details(c, "xxx", 15)
    assert detail.error_code == :flag_not_found
  end

  test "resolve map value", %{client: c} do
    assert Client.get_map_value(c, "map", %{}) ==
             %{"a" => 10, "b" => 20}
    detail = Client.get_map_details(c, "map", %{})
    refute detail.error_code
  end

  test "resolve map value, does not exist", %{client: c} do
    assert Client.get_map_value(c, "xxx", %{"a" => "value"}) ==
             %{"a" => "value"}
    detail = Client.get_map_details(c, "xxx", %{})
    assert detail.error_code == :flag_not_found
  end

  test "contexts", %{client: c} do
    ctx = Client.set_context(c, %{company: "example.com"})
    assert Client.get_boolean_value(c, "bool-target", true) == false
    assert Client.get_boolean_value(ctx, "bool-target", false) == true
    assert Client.get_boolean_value(
             c, "bool-target", false,
             context: %{company: "example.com"}) == true

    details = Client.get_boolean_details(ctx, "bool-target", false)
    refute details.error_code
    assert details.reason == "TARGETING_MATCH"
  end

end
