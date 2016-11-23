.PHONY: foo bar visualixir

foo:
	iex --sname foo -S mix

bar:
	KVS_PORT=4041 iex --sname bar -S mix

visualixir:
	cd ../visualixir && elixir --sname visualixir --hidden -S mix phoenix.server
