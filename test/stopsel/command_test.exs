defmodule Stopsel.CommandTest do
  use ExUnit.Case
  doctest Stopsel.Command

  alias Stopsel.{Command, Dispatcher, Request}
  import ExUnit.CaptureIO

  describe "build/2" do
    test "build command" do
      predicates = [& &1]

      command =
        Command.build(
          name: "timer",
          scope: Timer,
          function: :count_down,
          help: "Starts a countdown",
          predicates: predicates
        )

      expected = %Command{
        name: "timer",
        scope: Timer,
        function: :count_down,
        commands: %{},
        help: "Starts a countdown",
        predicates: predicates
      }

      equal_by?(command, expected, [:name, :scope, :function, :commands, :predicates])
    end

    test "build command recursively" do
      actual =
        Command.build(
          name: "calc",
          scope: Calculator,
          function: :unknown_operation,
          commands: [
            [
              name: "add",
              help: "Adds to numbers",
              function: :add
            ],
            [
              help: "Subtracts b from a",
              function: :subtract
            ]
          ]
        )

      expected = %Command{
        name: "calc",
        scope: Calculator,
        function: :unknown_operation,
        commands: %{
          "add" => %Command{
            name: "add",
            help: "Adds to numbers",
            function: :add,
            scope: Calculator
          },
          "subtract" => %Command{
            name: "subtract",
            help: "Subtracts b from a",
            function: :subtract,
            scope: Calculator
          }
        }
      }

      %{"add" => actual1, "subtract" => actual2} = actual.commands
      %{"add" => expected1, "subtract" => expected2} = expected.commands
      keys = [:name, :help, :function, :scope]

      equal_by?(actual1, expected1, keys)
      equal_by?(actual2, expected2, keys)
    end

    test "building from with structs returns the same as with keywordlists" do
      actual =
        %Command{
          name: "calc",
          scope: Calculator,
          function: :unknown_operation,
          commands: [
            %Command{
              name: "add",
              help: "Adds to numbers",
              function: :add,
              scope: nil
            },
            %Command{
              name: "subtract",
              help: "Subtracts b from a",
              function: :subtract,
              scope: nil
            }
          ]
        }
        |> Command.build()

      expected = %Command{
        name: "calc",
        scope: Calculator,
        function: :unknown_operation,
        commands: %{
          "add" => %Command{
            name: "add",
            help: "Adds to numbers",
            function: :add,
            scope: Calculator
          },
          "subtract" => %Command{
            name: "subtract",
            help: "Subtracts b from a",
            function: :subtract,
            scope: Calculator
          }
        }
      }

      assert actual == expected
    end

    test "building a command without name or function raises" do
      assert_raise RuntimeError, fn ->
        Command.build([])
      end
    end

    defp equal_by?(map1, map2, keys) do
      assert Map.take(map1, keys) == Map.take(map2, keys)
    end
  end

  describe "dispatch/2" do
    setup context do
      command_with_request(context.message_content)
    end

    @tag message_content: "calc something not good"
    test "dispatch message executes default function", %{command: command, request: request} do
      assert Calculator.unknown_operation(request) == Dispatcher.dispatch(command, request)
    end

    @tag message_content: "calc add 1 + 2"
    test "dispatch message executes nested function ", %{command: command, request: request} do
      assert Calculator.add(request) == Dispatcher.dispatch(command, request)
    end

    @tag message_content: "Some unrelated message"
    test "ignores other messages", %{command: command, request: request} do
      assert :ignore == Dispatcher.dispatch(command, request)
    end

    @tag message_content: "calc add 1 + 2"
    test "applies predicates", %{command: command, request: request} do
      command =
        put_in(command.commands["add"].predicates, [
          fn request -> IO.puts(request.cropped_message_content) end
        ])

      assert capture_io(fn -> Dispatcher.dispatch(command, request) end) == "1 + 2\n"
    end

    @tag message_content: "calc add 1 + 2"
    test "can execute anonymous function", %{command: command, request: request} do
      command =
        put_in(
          command.commands["add"].function,
          fn request -> IO.puts(request.cropped_message_content) end
        )

      assert capture_io(fn -> Dispatcher.dispatch(command, request) end) == "1 + 2\n"
    end
  end

  describe "add_command/3" do
    setup do
      command_with_request("")
    end

    test "add command", %{command: command} do
      {:ok, new_command} = Dispatcher.add_command(command, ~w"calc add", %Command{name: "this"})
      assert new_command.commands["add"].commands["this"].name == "this"
    end

    test "Can't add command if path is invalid", %{command: command} do
      assert {:error, :no_match} ==
               Dispatcher.add_command(command, ~w"calc adds", %Command{name: "this"})
    end
  end

  describe "unload_command/3" do
    setup do
      command_with_request("")
    end

    test "unload command", %{command: command} do
      {:ok, {deleted_command, new_command}} = Dispatcher.unload_command(command, ~w"calc add")
      assert new_command.commands["add"] == nil
      assert deleted_command.name == "add"
    end

    test "Can't unload command if path is invalid", %{command: command} do
      assert Dispatcher.unload_command(command, ~w"calc adds") == {:error, :no_match}
    end
  end

  defp command_with_request(message_content) do
    {:ok,
     %{
       command: %Command{
         name: "calc",
         scope: Calculator,
         function: :unknown_operation,
         commands: %{
           "add" => %Command{
             name: "add",
             help: "Adds to numbers",
             function: :add,
             scope: Calculator
           },
           "subtract" => %Command{
             name: "subtract",
             help: "Subtracts b from a",
             function: :subtract,
             scope: Calculator
           }
         }
       },
       request: %Request{
         message_content: message_content
       }
     }}
  end

  describe "fetch/2" do
    test "can fetch values from command" do
      assert Access.get(%Command{name: "name"}, :name) == "name"
    end
  end

  describe "pop/2" do
    test "can pop values from command" do
      assert Access.pop(%Command{name: "name"}, :name) == {"name", %Command{}}
    end
  end
end
