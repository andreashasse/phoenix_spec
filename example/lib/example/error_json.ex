defmodule Example.ErrorJSON do
  # FIXME: Is there a simpler way to handle these errors?
  def render("400.json", _assigns) do
    %{error: "Bad Request", message: "Invalid JSON body"}
  end

  def render("404.json", _assigns) do
    %{error: "Not Found"}
  end

  def render("500.json", _assigns) do
    %{error: "Internal Server Error"}
  end

  def render(template, _assigns) do
    %{error: Phoenix.Controller.status_message_from_template(template)}
  end
end
