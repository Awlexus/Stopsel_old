defmodule Calculator do
  alias Stopsel.Command

  def unknown_operation(_) do
    "I don't know this operation"
  end

  def add(_) do
    "I pretend to add 2 numbers"
  end

  def subtract(_) do
    "I pretend to subtract 2 numbers"
  end

  def router(scope \\ nil) do
    %Command{
      name: "calc",
      scope: __MODULE__,
      function: :unknown_operation,
      commands: %{
        "add" => %Command{
          name: "add",
          function: :add,
          scope: __MODULE__
        },
        "subtract" => %Command{
          name: "subtract",
          function: :subtract,
          scope: __MODULE__
        }
      }
    }
  end
end
