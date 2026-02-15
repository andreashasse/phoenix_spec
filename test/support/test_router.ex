defmodule TestRouter do
  use Phoenix.Router

  get "/users", TestUserController, :index
  get "/users/:id", TestUserController, :show
  post "/users", TestUserController, :create
  put "/users/:id", TestUserController, :update
  delete "/users/:id", TestUserController, :delete
end
