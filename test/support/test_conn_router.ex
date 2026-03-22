defmodule TestConnRouter do
  @moduledoc false
  use Phoenix.Router

  get("/users/:id", TestConnController, :show_with_assigns)
  get("/download", TestConnController, :download)
end
