defmodule StopselTest do
  use ExUnit.Case, async: true
  doctest Stopsel

  alias Stopsel.{Command, Request}

  describe "router/1" do
    test "create router with prefix" do
      assert %Command{name: "aaa"} == Stopsel.router(prefix: "aaa")
    end
  end

  describe "alias/3" do
    setup do
      {:ok,
       %{
         router: %Command{
           name: ";",
           scope: nil,
           commands: %{
             "calc" => Calculator.router(),
             "c" => Stopsel.alias("c", ";calc")
           }
         }
       }}
    end

    test "alias can redirect to other functions", %{router: router} do
      assert Calculator.add(%Request{}) == Stopsel.dispatch(router, ";c add")
    end
  end
end
