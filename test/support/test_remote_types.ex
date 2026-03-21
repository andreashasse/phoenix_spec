defmodule TestRemoteTypes do
  @moduledoc false
  use Spectral

  @type request_headers :: %{required(:"x-request-id") => String.t()}
end
