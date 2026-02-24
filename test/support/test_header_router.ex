defmodule TestHeaderRouter do
  use Phoenix.Router

  get("/items", TestHeaderController, :index)
  get("/items/:id", TestHeaderController, :show)
end
