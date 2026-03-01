defmodule PhoenixSpec.OpenAPIControllerTest do
  use ExUnit.Case

  import Plug.Test

  defmodule TestOpenAPIController do
    use PhoenixSpec.OpenAPIController,
      router: TestRouter,
      title: "Test API",
      version: "1.0.0"
  end

  defmodule TestOpenAPIControllerCustomUrl do
    use PhoenixSpec.OpenAPIController,
      router: TestRouter,
      title: "Test API",
      version: "1.0.0",
      openapi_url: "/api/openapi"
  end

  defmodule TestOpenAPIControllerCached do
    use PhoenixSpec.OpenAPIController,
      router: TestRouter,
      title: "Test API",
      version: "1.0.0",
      cache: true
  end

  describe "show/2" do
    test "returns 200 with application/json content type" do
      conn = conn(:get, "/openapi") |> TestOpenAPIController.show(%{})

      assert conn.status == 200
      assert {"content-type", "application/json; charset=utf-8"} in conn.resp_headers
    end

    test "response body contains the configured title and version" do
      conn = conn(:get, "/openapi") |> TestOpenAPIController.show(%{})

      body = Jason.decode!(conn.resp_body)
      assert body["info"]["title"] == "Test API"
      assert body["info"]["version"] == "1.0.0"
    end

    test "response body includes routes from the configured router" do
      conn = conn(:get, "/openapi") |> TestOpenAPIController.show(%{})

      body = Jason.decode!(conn.resp_body)
      assert Map.has_key?(body["paths"], "/users")
    end
  end

  describe "show/2 with cache: true" do
    @cache_key {PhoenixSpec.OpenAPIController, TestOpenAPIControllerCached}

    setup do
      on_exit(fn -> :persistent_term.erase(@cache_key) end)
      :ok
    end

    test "populates persistent_term on first call" do
      assert :persistent_term.get(@cache_key, nil) == nil

      conn(:get, "/openapi") |> TestOpenAPIControllerCached.show(%{})

      assert :persistent_term.get(@cache_key, nil) != nil
    end

    test "stores the encoded JSON that matches the response body" do
      conn = conn(:get, "/openapi") |> TestOpenAPIControllerCached.show(%{})

      assert :persistent_term.get(@cache_key) == conn.resp_body
    end

    test "returns the cached JSON on subsequent calls" do
      conn(:get, "/openapi") |> TestOpenAPIControllerCached.show(%{})
      cached = :persistent_term.get(@cache_key)

      conn = conn(:get, "/openapi") |> TestOpenAPIControllerCached.show(%{})

      assert conn.resp_body == cached
    end

    test "cached response is a valid OpenAPI spec" do
      conn(:get, "/openapi") |> TestOpenAPIControllerCached.show(%{})

      body = Jason.decode!(:persistent_term.get(@cache_key))
      assert body["info"]["title"] == "Test API"
    end
  end

  describe "show/2 with cache: false (default)" do
    @no_cache_key {PhoenixSpec.OpenAPIController, TestOpenAPIController}

    test "does not populate persistent_term" do
      conn(:get, "/openapi") |> TestOpenAPIController.show(%{})

      assert :persistent_term.get(@no_cache_key, nil) == nil
    end
  end

  describe "swagger/2" do
    test "returns 200 with text/html content type" do
      conn = conn(:get, "/swagger") |> TestOpenAPIController.swagger(%{})

      assert conn.status == 200
      assert {"content-type", "text/html; charset=utf-8"} in conn.resp_headers
    end

    test "embeds the default openapi_url in the Swagger UI script" do
      conn = conn(:get, "/swagger") |> TestOpenAPIController.swagger(%{})

      assert conn.resp_body =~ ~s(url: "/openapi")
    end

    test "embeds a custom openapi_url when configured" do
      conn = conn(:get, "/swagger") |> TestOpenAPIControllerCustomUrl.swagger(%{})

      assert conn.resp_body =~ ~s(url: "/api/openapi")
    end
  end
end
