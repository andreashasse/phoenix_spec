defmodule Example.OpenAPIController do
  use PhoenixSpec.OpenAPIController,
    router: Example.Router,
    title: "Example API",
    version: "1.0.0"
end
