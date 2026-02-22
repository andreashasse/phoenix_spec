defmodule Example.UserController do
  use PhoenixSpec.Controller, formats: [:json]

  alias Example.Types.{User, UserInput, Error}

  # In-memory store for demo purposes
  @users %{
    "1" => %User{id: 1, name: "Andreas", email: "andreas@example.com"},
    "2" => %User{id: 2, name: "Hasse", email: "hasse@example.com"}
  }

  @spec index(map(), map(), nil) :: {200, map(), [User.t()]}
  def index(_path_args, _headers, _body) do
    {200, %{}, Map.values(@users)}
  end

  @spec show(map(), map(), nil) :: {200, map(), User.t()} | {404, map(), Error.t()}
  def show(%{"id" => id}, _headers, _body) do
    case Map.get(@users, id) do
      nil -> {404, %{}, %Error{message: "User #{id} not found"}}
      user -> {200, %{}, user}
    end
  end

  @spec create(map(), map(), UserInput.t()) ::
          {201, map(), User.t()} | {422, map(), Error.t()}
  def create(_path_args, _headers, body) do
    new_user = %User{id: 3, name: body.name, email: body.email}
    {201, %{}, new_user}
  end

  @spec update(map(), map(), UserInput.t()) ::
          {200, map(), User.t()} | {404, map(), Error.t()} | {422, map(), Error.t()}
  def update(%{"id" => id}, _headers, body) do
    case Map.get(@users, id) do
      nil ->
        {404, %{}, %Error{message: "User #{id} not found"}}

      %User{} = user ->
        updated = %User{user | name: body.name, email: body.email}
        {200, %{}, updated}
    end
  end

  @spec delete(map(), map(), nil) :: {204, map(), nil}
  def delete(_path_args, _headers, _body) do
    {204, %{}, nil}
  end
end
