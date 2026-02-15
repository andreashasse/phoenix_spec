defmodule TestUserController do
  use PhoenixSpec.Controller

  @spec index(map(), map(), nil) :: {200, map(), [TestUser.t()]}
  def index(_path_args, _headers, _body) do
    {200, %{}, [%TestUser{id: 1, name: "Alice", email: "alice@example.com"}]}
  end

  @spec show(map(), map(), nil) :: {200, map(), TestUser.t()} | {404, map(), TestError.t()}
  def show(%{"id" => id}, _headers, _body) do
    case id do
      "1" -> {200, %{}, %TestUser{id: 1, name: "Alice", email: "alice@example.com"}}
      _ -> {404, %{}, %TestError{message: "User not found"}}
    end
  end

  @spec create(map(), map(), TestUserInput.t()) ::
          {201, map(), TestUser.t()} | {422, map(), TestError.t()}
  def create(_path_args, _headers, body) do
    {201, %{}, %TestUser{id: 2, name: body.name, email: body.email}}
  end

  @spec update(map(), map(), TestUserInput.t()) ::
          {200, map(), TestUser.t()} | {422, map(), TestError.t()}
  def update(%{"id" => _id}, _headers, body) do
    {200, %{}, %TestUser{id: 1, name: body.name, email: body.email}}
  end

  @spec delete(map(), map(), nil) :: {204, map(), nil}
  def delete(%{"id" => _id}, _headers, _body) do
    {204, %{}, nil}
  end
end
