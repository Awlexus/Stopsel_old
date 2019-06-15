defmodule Calculator do
  @moduledoc "A module that pretends to be a calculator"
  alias Stopsel.Command

  def unknown_operation(_) do
    "I don't know this operation"
  end

  @doc "Pretends to add two numbers together"
  def add(_) do
    "I pretend to add 2 numbers"
  end

  @doc "Pretends to subtract two numbers from eachother"
  def subtract(_) do
    "I pretend to subtract 2 numbers"
  end

  def router(scope \\ nil) do
    Command.build(
      %Command{
        name: "calc",
        scope: __MODULE__,
        function: :unknown_operation,
        commands: [
          %Command{
            name: "add",
            function: :add
          },
          %Command{
            name: "subtract",
            function: :subtract
          }
        ]
      },
      scope
    )
  end
end
