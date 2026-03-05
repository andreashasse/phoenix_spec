# PhoenixSpec

PhoenixSpec integrates [Spectral](https://github.com/andreashasse/spectral) with Phoenix, making controller typespecs the single source of truth for OpenAPI 3.0 spec generation and request/response validation. Define your types once — PhoenixSpec derives the API docs and enforces them at runtime.

## Installation

Add `phoenix_spec` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_spec, "~> 0.1.0"}
  ]
end
```

## Usage

### Step 1: Define typed structs with Spectral

```elixir
defmodule MyApp.User do
  use Spectral

  defstruct [:id, :name, :email]

  spectral(title: "User", description: "A user resource")
  @type t :: %__MODULE__{
    id: integer(),
    name: String.t(),
    email: String.t()
  }
end
```

### Step 2: Create a typed controller

```elixir
defmodule MyAppWeb.UserController do
  use PhoenixSpec.Controller, formats: [:json]

  spectral(summary: "Get user", description: "Returns a user by ID")
  @spec show(%{id: integer()}, %{}, nil) ::
          {200, %{}, MyApp.User.t()}
          | {404, %{}, MyApp.Error.t()}
  def show(%{id: id}, _headers, nil) do
    case MyApp.Users.get(id) do
      {:ok, user} -> {200, %{}, user}
      {:error, :not_found} -> {404, %{}, %MyApp.Error{message: "not found"}}
    end
  end
end
```

### Step 3: Serve the OpenAPI spec

```elixir
defmodule MyAppWeb.OpenAPIController do
  use PhoenixSpec.OpenAPIController,
    router: MyAppWeb.Router,
    title: "My API",
    version: "1.0.0"
end
```

Add routes in your router:

```elixir
scope "/api" do
  get "/users/:id", MyAppWeb.UserController, :show
  get "/openapi", MyAppWeb.OpenAPIController, :show
  get "/swagger", MyAppWeb.OpenAPIController, :swagger
end
```

## Design

- **Typespecs are the single source of truth** — no separate schema definitions; `@spec` drives both docs and validation
- **3-arity action convention** — `(path_args, headers, body)` → `{status, headers, body}`; union return types produce multiple OpenAPI response entries
- **Crash on bad code, error on bad user input** — malformed typespecs raise; invalid requests return 400, encoding failures return 500
- **Automatic encoding/decoding** — Spectral handles struct serialization
- **Optional caching** — via `persistent_term` for production performance
