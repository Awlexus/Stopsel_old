# Stopsel

## Introduction
Stopsel is a library that helps chatbot developers
parse incomming text messages.

This library was heavily inspired by Plug. As such it uses similar concepts
when dealing with user messages.

**trivia:** "Stöpsel" is german for "plug". I omitted the ö or œ, because it's
easier to pronounce for english speakers.
### Commands and Routers
You can define a router (or rather a tree of commands), which describes
how a message is "routed". Messages can be routed to execute functions
in Modules, anonymous functions to subcommands. Such functions need to
accept one argument - the [request](#Requests).

You can create a router using the functions `Stopsel.router/1`
and `Stopsel.command/1`.

```
import Stopsel, only: [router: 1, command: 1]

router(
  prefix: ";",
  scope: Cogs,
  commands: [
    command(
      name: "echo",
      function: :echo,
      extra: %{
        help: ~s/Replies with whatever the user wrote (excluding the "echo")./
      }
    ),
    command(
      name: "reverse",
      function: :reverse,
      extra: %{
        help: ~s/Reverses and replies with whatever the user wrote (excluding the "reverse")./
      }
    )
  ]
)
```

These are just helper functions. You can also define the router, using only keyword lists.
```
Command.build(
  name: ";",
  scope: Cogs,
  commands: [
    [
      name: "echo",
      function: :echo,
      extra: %{
        help: ~s/Replies with whatever the user wrote (excluding the "echo")./
      }
    ],
    [
      name: "reverse",
      function: :reverse,
      extra: %{
        help: ~s/Reverses and replies with whatever the user wrote (excluding the "reverse")./
      }
    ]
  ]
)
```
If you want to implement your own parsing method, take a look at the "Parsing commands" section.

### Dispatchers
Messages are handled by a dispatcher. A dispatcher is just an implementation of the
`Stopsel.Dispatcher` Protocol. A Dispatcher only has 3 things to do:
* Dispatch a message ([`dispatch/2`](`Stopsel.Dispatcher.dispatch/2`))
* Add a command to the dispatcher ([`add_command/3`](`Stopsel.Dispatcher.add_command/3`))
* Remove a command from the dispatcher ([`unload_command/2`](`Stopsel.Dispatcher.unload_command/2`))

Commands also implement dispatching. If you need custom dispatching logic, check out
["Writing a dispatcher"](#).

### Requests
Requests are similar to Plug.Conn structs. They are used to accumulate state and
are passed passed through each command and predicate.

Commands only remove the prefix they needed, before passing it along (for example,
the ";" from ";echo"), but predicates on the other hands can modify a Request
however they like.

### Predicates
Predicates are anonymous functions, which accept a request, modify it and return it,
or halt the execution of the request.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `stopsel` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:stopsel, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/stopsel](https://hexdocs.pm/stopsel).

