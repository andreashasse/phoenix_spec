import Config

config :example, Example.Endpoint,
  secret_key_base: String.duplicate("a", 64),
  adapter: Bandit.PhoenixAdapter,
  http: [port: 4000],
  server: true
