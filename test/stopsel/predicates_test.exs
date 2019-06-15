defmodule Stopsel.PredicatesTest do
  use ExUnit.Case, async: true
  @calc_moduledoc "A module that pretends to be a calculator"
  @add_doc "Pretends to add two numbers together"
  @subtract_doc "Pretends to subtract two numbers from eachother"

  alias Stopsel.{Command, Predicates}

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
            Predicates.help(fn _, help ->
              assert help.moduledoc == @calc_moduledoc
              assert help.function_doc == nil
              assert help.subcommand_docs["add"] == @add_doc
              assert help.subcommand_docs["subtract"] == @subtract_doc
            end)
          ]
      }

      Stopsel.dispatch(router, ";help calc")
    end

    test "can fetch help for function", %{router: router} do
      router = %{
        router
        | predicates: [
            Predicates.help(fn _, help ->
              assert help.moduledoc == @calc_moduledoc
              assert help.function_doc == @add_doc
              assert help.subcommand_docs == %{}
            end)
          ]
      }

      Stopsel.dispatch(router, ";help calc add")
    end
  end
end
