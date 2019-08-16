defmodule Stopsel.PredicatesTest do
  use ExUnit.Case, async: true
  @calc_moduledoc "A module that pretends to be a calculator"
  @add_doc "Pretends to add two numbers together"
  @subtract_doc "Pretends to subtract two numbers from eachother"

  alias Stopsel.{Command, Predicates.Help}

  describe "help/1" do
    setup do
      {:ok,
       %{
         router: %Command{
           name: ";",
           commands: %{
             "calc" => Calculator.router()
           }
         }
       }}
    end

    test "can fetch help for module", %{router: router} do
      router = %{
        router
        | predicates: [
            {Help,
             callback: fn _, help ->
               assert help.module_docs == @calc_moduledoc
               assert help.function_docs == nil
               assert help.subcommand_docs["add"] == @add_doc
               assert help.subcommand_docs["subtract"] == @subtract_doc
             end}
          ]
      }

      Stopsel.dispatch(router, ";help calc")
    end

    test "can fetch help for function", %{router: router} do
      router = %{
        router
        | predicates: [
            {Help,
             callback: fn _, help ->
               assert help.module_docs == @calc_moduledoc
               assert help.function_docs == @add_doc
               assert help.subcommand_docs == %{}
             end}
          ]
      }

      Stopsel.dispatch(router, ";help calc add")
    end

    test "can call a module function", %{router: router} do
      router = %{
        router
        | predicates: [
            {Help, callback: {__MODULE__, :accept_help}}
          ]
      }

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Stopsel.dispatch(router, ";help, calc add")
        end)

      assert output == "help received\n"
    end

    def accept_help(_, _) do
      IO.puts("help received")
    end
  end
end
