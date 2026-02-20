defmodule Example.Endpoint do
  use Phoenix.Endpoint, otp_app: :example

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Example.Router)
end
