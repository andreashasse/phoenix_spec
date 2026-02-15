defmodule PhoenixSpec do
  @moduledoc """
  Generates OpenAPI 3.0 specifications from Phoenix router and typed controllers.

  Controllers that `use PhoenixSpec.Controller` and define typespecs on their
  action functions become the single source of truth for OpenAPI documentation.

  ## Usage

      {:ok, spec} = PhoenixSpec.generate_openapi(MyAppWeb.Router, %{title: "My API", version: "1.0.0"})
  """

  # Records from deps/spectra/include/spectra_internal.hrl
  require Record
  Record.defrecordp(:sp_function_spec, args: [], return: nil)
  Record.defrecordp(:sp_union, types: [], meta: %{})
  Record.defrecordp(:sp_tuple, fields: :any, meta: %{})
  Record.defrecordp(:sp_literal, value: nil, binary_value: nil, meta: %{})
  Record.defrecordp(:sp_simple_type, type: nil, meta: %{})

  @doc """
  Generates an OpenAPI 3.0 specification from a Phoenix router module.

  Introspects all routes in the router, extracts type information from
  controllers via `__spectra_type_info__/0`, and builds an OpenAPI spec.

  ## Parameters

  - `router` - A Phoenix router module
  - `metadata` - Map with `:title` and `:version` keys

  ## Returns

  - `{:ok, openapi_spec}` - Complete OpenAPI 3.0 specification as a map
  - `{:error, errors}` - List of errors if generation fails
  """
  @spec generate_openapi(module(), map()) :: {:ok, map()} | {:error, list()}
  def generate_openapi(router, metadata) do
    endpoints =
      router
      |> Phoenix.Router.routes()
      |> Enum.filter(&api_route?/1)
      |> Enum.map(&route_to_endpoint/1)

    Spectral.OpenAPI.endpoints_to_openapi(metadata, endpoints)
  end

  defp api_route?(%{plug: plug}) do
    Code.ensure_loaded(plug)
    function_exported?(plug, :__spectra_type_info__, 0)
  end

  defp route_to_endpoint(%{verb: verb, path: path, plug: controller, plug_opts: action}) do
    {_path_args, _headers, body_type, return_type} =
      extract_handler_type(controller, action)

    Spectral.OpenAPI.endpoint(verb, phoenix_path_to_openapi_path(path))
    |> maybe_add_request_body(verb, controller, body_type)
    |> add_path_parameters(path, controller)
    |> add_responses(controller, extract_responses(return_type))
  end

  defp maybe_add_request_body(endpoint, verb, controller, body_type) do
    if http_method_supports_body?(verb) do
      Spectral.OpenAPI.with_request_body(endpoint, controller, body_type)
    else
      endpoint
    end
  end

  defp add_responses(endpoint, controller, responses) do
    Enum.reduce(responses, endpoint, fn {status, body_type}, ep ->
      Spectral.OpenAPI.response(status, status_code_description(status))
      |> Spectral.OpenAPI.response_with_body(controller, body_type)
      |> then(&Spectral.OpenAPI.add_response(ep, &1))
    end)
  end

  defp extract_handler_type(controller, action) do
    type_info = controller.__spectra_type_info__()

    {:ok, [sp_function_spec(args: [path_args, headers, body], return: return_type) | _]} =
      Spectral.TypeInfo.find_function(type_info, action, 3)

    {path_args, headers, body, return_type}
  end

  defp extract_responses(sp_union(types: types)) do
    Enum.flat_map(types, &extract_single_response/1)
  end

  defp extract_responses(other) do
    extract_single_response(other)
  end

  defp extract_single_response(sp_tuple(fields: [status_type, _headers_type, body_type])) do
    sp_literal(value: status) = status_type
    [{status, body_type}]
  end


  @path_param_regex ~r/:([a-zA-Z_][a-zA-Z0-9_]*)/

  defp phoenix_path_to_openapi_path(path) do
    Regex.replace(@path_param_regex, path, "{\\1}")
  end

  defp add_path_parameters(endpoint, path, controller) do
    param_names = Regex.scan(@path_param_regex, path, capture: :all_but_first)

    Enum.reduce(param_names, endpoint, fn [name], ep ->
      param_spec = %{
        name: name,
        in: :path,
        required: true,
        schema: sp_simple_type(type: :binary)
      }

      Spectral.OpenAPI.with_parameter(ep, controller, param_spec)
    end)
  end

defp http_method_supports_body?(:post), do: true
  defp http_method_supports_body?(:put), do: true
  defp http_method_supports_body?(:patch), do: true
  defp http_method_supports_body?(_), do: false

  defp status_code_description(200), do: "OK"
  defp status_code_description(201), do: "Created"
  defp status_code_description(204), do: "No Content"
  defp status_code_description(400), do: "Bad Request"
  defp status_code_description(401), do: "Unauthorized"
  defp status_code_description(403), do: "Forbidden"
  defp status_code_description(404), do: "Not Found"
  defp status_code_description(409), do: "Conflict"
  defp status_code_description(422), do: "Unprocessable Entity"
  defp status_code_description(500), do: "Internal Server Error"
  defp status_code_description(code), do: "Response #{code}"
end
