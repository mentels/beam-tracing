use Mix.Config

config :kv_server,
  port: System.get_env("KVS_PORT") |> Integer.parse |> elem(0)

config :kv, routing_table: [{?a..?m, :"foo@szm-mac"},
                             {?n..?z, :"bar@szm-mac"}]
