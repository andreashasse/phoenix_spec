defmodule PhoenixSpec.Controller do
  @moduledoc """
  A Phoenix controller module that validates requests and responses using typespecs.

  When you `use PhoenixSpec.Controller`, your controller actions use a 3-arity
  convention `(path_args, headers, body)` instead of the standard Phoenix
  `(conn, params)`. Request data is decoded and validated against your typespecs,
  and responses are encoded automatically.

  ## Usage

      defmodule MyAppWeb.UserController do
        use PhoenixSpec.Controller

        @spec show(map(), map(), nil) :: {200, map(), User.t()}
        def show(path_args, _headers, _body) do
          user = Repo.get!(User, path_args.id)
          {200, %{}, user}
        end

        @spec create(map(), map(), UserInput.t()) :: {201, map(), User.t()} | {422, map(), Error.t()}
        def create(_path_args, _headers, body) do
          case Repo.insert(body) do
            {:ok, user} -> {201, %{}, user}
            {:error, changeset} -> {422, %{}, format_errors(changeset)}
          end
        end
      end

  ## How It Works

  1. Extracts path params, headers, and body from `conn`
  2. Decodes and validates them against the action's typespec via `Spectral.decode`
  3. Calls your handler as `action(path_args, headers, decoded_body)`
  4. Encodes the `{status, headers, body}` response via `Spectral.encode`
  5. Sends the response on `conn`
  6. On validation failure, returns a 400 response
  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Controller
      use Spectral

      @before_compile PhoenixSpec.Controller
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable action: 2

      def action(conn, _opts) do
        action_name = Phoenix.Controller.action_name(conn)
        PhoenixSpec.Controller.dispatch(conn, __MODULE__, action_name)
      end
    end
  end

  @doc false
  def dispatch(conn, controller, action) do
    path_args = conn.path_params
    headers = extract_headers(conn)

    body =
      case conn.body_params do
        %Plug.Conn.Unfetched{} -> nil
        params -> params
      end

    case apply(controller, action, [path_args, headers, body]) do
      {status, response_headers, response_body} when is_integer(status) ->
        send_typed_response(conn, controller, action, status, response_headers, response_body)

      other ->
        raise "PhoenixSpec action #{inspect(controller)}.#{action}/3 must return " <>
                "{status, headers, body}, got: #{inspect(other)}"
    end
  rescue
    e in FunctionClauseError ->
      if e.module == controller and e.function == action do
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(400, ~s({"error":"Bad Request","message":"Invalid request parameters"}))
      else
        reraise e, __STACKTRACE__
      end
  end

  defp send_typed_response(conn, controller, action, status, response_headers, response_body) do
    conn = apply_response_headers(conn, response_headers)

    case encode_response_body(controller, action, response_body) do
      {:ok, encoded} ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(status, encoded)

      {:error, _errors} ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(500, ~s({"error":"Internal Server Error","message":"Response encoding failed"}))
    end
  end

  defp encode_response_body(_controller, _action, nil), do: {:ok, ""}

  defp encode_response_body(_controller, _action, body) when is_struct(body) do
    struct_module = body.__struct__
    Spectral.encode(body, struct_module, :t)
  end

  defp encode_response_body(controller, action, body) do
    raise ArgumentError,
          "#{inspect(controller)}.#{action}/3 must return a struct with a Spectral type " <>
            "as the response body, got: #{inspect(body)}"
  end

  defp extract_headers(conn) do
    Map.new(conn.req_headers)
  end

  defp apply_response_headers(conn, headers) when is_map(headers) do
    Enum.reduce(headers, conn, fn {key, value}, acc ->
      Plug.Conn.put_resp_header(acc, to_string(key), to_string(value))
    end)
  end

  defp apply_response_headers(conn, _), do: conn
end
