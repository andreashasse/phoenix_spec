defmodule PhoenixSpecTest do
  use ExUnit.Case

  defp generate_spec do
    {:ok, spec} = PhoenixSpec.generate_openapi(TestRouter, %{title: "Test API", version: "1.0.0"})
    spec
  end

  defp generate_header_spec do
    {:ok, spec} =
      PhoenixSpec.generate_openapi(TestHeaderRouter, %{title: "Test API", version: "1.0.0"})

    spec
  end

  describe "generate_openapi/2" do
    test "generates a valid OpenAPI spec" do
      spec = generate_spec()
      assert spec["info"]["title"] == "Test API"
      assert spec["info"]["version"] == "1.0.0"
    end

    test "contains correct paths with OpenAPI format params" do
      spec = generate_spec()
      assert Map.has_key?(spec["paths"], "/users")
      assert Map.has_key?(spec["paths"], "/users/{id}")
      refute Map.has_key?(spec["paths"], "/users/:id")
    end

    test "contains correct HTTP methods" do
      spec = generate_spec()

      assert Map.has_key?(spec["paths"]["/users"], "get")
      assert Map.has_key?(spec["paths"]["/users"], "post")

      assert Map.has_key?(spec["paths"]["/users/{id}"], "get")
      assert Map.has_key?(spec["paths"]["/users/{id}"], "put")
      assert Map.has_key?(spec["paths"]["/users/{id}"], "delete")
    end

    test "union return types produce multiple response entries" do
      spec = generate_spec()

      # show action has {200, ...} | {404, ...} return type
      show_responses = spec["paths"]["/users/{id}"]["get"]["responses"]
      assert Map.has_key?(show_responses, "200")
      assert Map.has_key?(show_responses, "404")
    end

    test "single return type produces single response entry" do
      spec = generate_spec()

      # delete action has {204, ...} return type
      delete_responses = spec["paths"]["/users/{id}"]["delete"]["responses"]
      assert Map.has_key?(delete_responses, "204")
      assert map_size(delete_responses) == 1
    end

    test "required header appears as required header parameter in spec" do
      spec = generate_header_spec()

      params = spec["paths"]["/items/{id}"]["get"]["parameters"]
      header_param = Enum.find(params, &(&1["in"] == "header" && &1["name"] == "x-user-id"))
      assert header_param != nil
      assert header_param["required"] == true
    end

    test "optional header appears as non-required header parameter in spec" do
      spec = generate_header_spec()

      params = spec["paths"]["/items"]["get"]["parameters"]
      header_param = Enum.find(params, &(&1["in"] == "header" && &1["name"] == "x-trace-id"))
      assert header_param != nil
      assert header_param["required"] == false
    end
  end
end
