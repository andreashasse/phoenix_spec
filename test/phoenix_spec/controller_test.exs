defmodule PhoenixSpec.ControllerTest do
  use ExUnit.Case

  import Plug.Test

  defp dispatch(method, path, body_params, path_params \\ %{}) do
    conn =
      conn(method, path, body_params)
      |> Map.put(:path_params, path_params)
      |> Phoenix.Controller.put_format("json")

    PhoenixSpec.Controller.dispatch(conn, TestUserController, action_from_path(method, path))
  end

  defp action_from_path(:post, "/users"), do: :create
  defp action_from_path(:put, "/users/:id"), do: :update

  describe "dispatch/3 with invalid request body" do
    test "returns 400 with field-level detail when a field has the wrong type" do
      conn = dispatch(:post, "/users", %{"name" => 123, "email" => "test@example.com"})

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "Bad Request"
      assert [%{"type" => "type_mismatch", "location" => ["name"]}] = body["details"]
    end

    test "returns 400 with field-level detail when a required field is missing" do
      conn = dispatch(:post, "/users", %{"email" => "test@example.com"})

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "Bad Request"
      assert [%{"type" => "missing_data", "location" => ["name"]}] = body["details"]
    end

    test "returns 400 with details when the body has multiple invalid fields" do
      conn = dispatch(:post, "/users", %{"name" => 123, "email" => 456})

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "Bad Request"
      assert is_list(body["details"])
      assert length(body["details"]) >= 1
      assert Enum.all?(body["details"], &is_map_key(&1, "type"))
      assert Enum.all?(body["details"], &is_map_key(&1, "location"))
    end
  end

  describe "dispatch/3 with valid request body" do
    test "returns 201 on valid create" do
      conn = dispatch(:post, "/users", %{"name" => "Alice", "email" => "alice@example.com"})

      assert conn.status == 201
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Alice"
      assert body["email"] == "alice@example.com"
    end
  end
end
