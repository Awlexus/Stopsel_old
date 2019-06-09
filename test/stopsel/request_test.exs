defmodule Stopsel.RequestTest do
  use ExUnit.Case, async: true

  alias Stopsel.Request

  describe "assign/3" do
    test "assign a value" do
      request =
        %Request{}
        |> Request.assign(:test, "value")
        |> Request.assign(:test2, "value 2")

      assert request.assigns.test == "value"
      assert request.assigns.test2 == "value 2"
    end
  end
end
