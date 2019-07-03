## ExTrace - Elixir Tracing demo application
#### slides are [here](https://github.com/mentels/beam-tracing/tree/master/elixir/docs)
#### all the examples are based on the KV applications developed through out the [Elixir tutorial](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html).
#### implementation of KV & KVServer applications is [here](https://github.com/mentels/ex_kv).
#### to run demo application do the next:

  1. clone git repo
     ```bash
     git clone https://github.com/mentels/beam-tracing.git
     ```

  2. build it
     ```bash
     cd beam-tracing/elixir/
     mix deps.get
     mix compile
     ```

  3. node names foo@szm-mac & bar@szm-mac are
     hard-coded, so instead of changing that i propose
     to add szm-mac as 127.0.0.1 in /etc/hosts file (or
     C:\Windows\System32\drivers\etc\hosts for windows)

  4. start application
    1. for Linux:
         
         ```bash
         KVS_PORT=4040 iex --sname "foo@szm-mac" -S mix
         KVS_PORT=4041 iex --sname "bar@szm-mac" -S mix # in the second shell
         ```
    2. for Windows (run in Git Bash):
         
         ```bash
         KVS_PORT=4040 iex --werl --sname "foo@szm-mac" -S mix &
         KVS_PORT=4041 iex --werl --sname "bar@szm-mac" -S mix &
         ```

  5. test application. run in "foo@szm-mac" elixir shell
      ```elixir
      ExTrace.test_kv_server
      ExTrace.test_kv_server "zzz"
      #check kv and kv_server applications supervision trees
      :observer.start
      ```
