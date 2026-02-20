defmodule Example.OpenAPIController do
  use Phoenix.Controller, formats: [:html, :json]

  def show(conn, _params) do
    {:ok, spec} =
      PhoenixSpec.generate_openapi(Example.Router, %{
        title: "Example API",
        version: "1.0.0"
      })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(spec))
  end

  def swagger(conn, _params) do
    html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <title>Example API — Swagger UI</title>
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist/swagger-ui.css" />
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist/swagger-ui-bundle.js"></script>
      <script>
        SwaggerUIBundle({
          url: "/openapi",
          dom_id: "#swagger-ui",
          presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
          layout: "BaseLayout",
          deepLinking: true
        });
      </script>
    </body>
    </html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end
end
