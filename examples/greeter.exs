Mix.install([{:pro_gen, path: ".."}])

import ProGen.Script

put_arg_schema(
  name: "greeter",
  description: "A simple greeting script",
  version: "0.1.0",
  options: [
    name: [
      short: "-n",
      long: "--name",
      help: "Name to greet",
      required: true
    ]
  ],
  flags: [
    loud: [
      short: "-l",
      long: "--loud",
      help: "Greet loudly"
    ]
  ]
)

case parse_args(System.argv()) do
  {:ok, args} ->
    name = args[:name]
    greeting = "Hello, #{name}!"

    if args[:loud] do
      IO.puts(String.upcase(greeting))
    else
      IO.puts(greeting)
    end

  :help ->
    System.halt(0)

  :version ->
    System.halt(0)

  {:error, _errors} ->
    System.halt(1)
end
