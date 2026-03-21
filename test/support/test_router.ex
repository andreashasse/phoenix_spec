defmodule TestRouter do
  @moduledoc false
  use Phoenix.Router

  get("/users", TestUserController, :index)
  get("/users/:id", TestUserController, :show)
  post("/users", TestUserController, :create)
  put("/users/:id", TestUserController, :update)
  delete("/users/:id", TestUserController, :delete)
end
