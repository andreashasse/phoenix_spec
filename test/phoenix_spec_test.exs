defmodule PhoenixSpecTest do
  use ExUnit.Case

  # Helper to normalize the spec — may come back as iodata (JSON) or a map
  defp to_spec_map(spec) when is_map(spec), do: spec

  defp to_spec_map(spec) do
    spec |> IO.iodata_to_binary() |> Jason.decode!()
  end

  defp generate_spec do
    {:ok, spec} = PhoenixSpec.generate_openapi(TestRouter, %{title: "Test API", version: "1.0.0"})
    to_spec_map(spec)
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
  end
end
