defmodule TestQueryController do
  @moduledoc false
  use PhoenixSpectral.Controller, formats: [:json]

  @type pagination :: %{optional(:page) => integer(), optional(:per_page) => integer()}

  spectral(description: "Search query string")
  @type search_query :: String.t()

  @spec index(%{}, pagination(), %{}, nil) :: {200, %{}, [TestUser.t()]}
  def index(_path_args, query_params, _headers, _body) do
    page = Map.get(query_params, :page, 1)
    {200, %{}, [%TestUser{id: page, name: "Alice", email: "alice@example.com"}]}
  end

  @spec search(%{}, %{required(:q) => search_query()}, %{}, nil) :: {200, %{}, [TestUser.t()]}
  def search(_path_args, %{q: q}, _headers, _body) do
    {200, %{}, [%TestUser{id: 1, name: q, email: "alice@example.com"}]}
  end
end
