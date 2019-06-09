defmodule StopselTest do
  use ExUnit.Case
  doctest Stopsel

  alias Stopsel.Command

  describe "router/1" do
    test "create router with prefix" do
      assert %Command{name: "aaa"} == Stopsel.router(prefix: "aaa")
    end
  end
end
