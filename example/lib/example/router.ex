defmodule Example.Router do
  use Phoenix.Router

  get("/openapi", Example.OpenAPIController, :show)
  get("/swagger", Example.OpenAPIController, :swagger)

  get("/users", Example.UserController, :index)
  get("/users/:id", Example.UserController, :show)
  post("/users", Example.UserController, :create)
  put("/users/:id", Example.UserController, :update)
  delete("/users/:id", Example.UserController, :delete)
end
