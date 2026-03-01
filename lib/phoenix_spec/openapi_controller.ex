defmodule PhoenixSpec.OpenAPIController do
  @moduledoc """
  A plug-and-play Phoenix controller that serves the OpenAPI spec and Swagger UI.

  ## Usage

      defmodule MyAppWeb.OpenAPIController do
        use PhoenixSpec.OpenAPIController,
          router: MyAppWeb.Router,
          title: "My API",
          version: "1.0.0"
      end

  Then add routes in your router:

      get "/openapi", MyAppWeb.OpenAPIController, :show
      get "/swagger", MyAppWeb.OpenAPIController, :swagger

  ## Options

  - `:router` — (required) your Phoenix router module
  - `:title` — (required) API title for the OpenAPI spec
  - `:version` — (required) API version string
  - `:openapi_url` — URL path where the JSON spec is served, used by Swagger UI (default: `"/openapi"`)
  - `:cache` — when `true`, the generated JSON is stored in `:persistent_term` after the first
    request and served from there on subsequent requests (default: `false`)
  """

  defmacro __using__(opts) do
    router = Keyword.fetch!(opts, :router)
    title = Keyword.fetch!(opts, :title)
    version = Keyword.fetch!(opts, :version)
    openapi_url = Keyword.get(opts, :openapi_url, "/openapi")
    cache = Keyword.get(opts, :cache, false)

    quote do
      use Phoenix.Controller, formats: [:html, :json]

      def show(conn, _params) do
        json =
          if unquote(cache) do
            PhoenixSpec.OpenAPIController.fetch_json(__MODULE__, unquote(router), %{
              title: unquote(title),
              version: unquote(version)
            })
          else
            {:ok, spec} =
              PhoenixSpec.generate_openapi(unquote(router), %{
                title: unquote(title),
                version: unquote(version)
              })

            Phoenix.json_library().encode!(spec)
          end

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, json)
      end

      def swagger(conn, _params) do
        html = PhoenixSpec.OpenAPIController.swagger_html(unquote(openapi_url))

        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, html)
      end
    end
  end

  @doc false
  def fetch_json(controller, router, metadata) do
    key = {__MODULE__, controller}

    case :persistent_term.get(key, :not_cached) do
      :not_cached ->
        {:ok, spec} = PhoenixSpec.generate_openapi(router, metadata)
        json = Phoenix.json_library().encode!(spec)
        :persistent_term.put(key, json)
        json

      cached ->
        cached
    end
  end

  @doc false
  def swagger_html(openapi_url) do
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <title>Swagger UI</title>
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist/swagger-ui.css" />
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist/swagger-ui-bundle.js"></script>
      <script>
        SwaggerUIBundle({
          url: #{Phoenix.json_library().encode!(openapi_url)},
          dom_id: "#swagger-ui",
          presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
          layout: "BaseLayout",
          deepLinking: true
        });
      </script>
    </body>
    </html>
    """
  end
end
