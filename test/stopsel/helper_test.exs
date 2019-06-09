defmodule Stopsel.HelperTest do
  use ExUnit.Case, async: true

  import Stopsel.Helper

  describe "combine_atoms/2" do
    setup do
      {:ok, %{a: String, b: Chars}}
    end

    test "a is nil", %{b: b} do
      assert combine_atoms(nil, b) == Chars
    end

    test "b is nil", %{a: a} do
      assert combine_atoms(a, nil) == String
    end

    test "a & b are nil" do
      assert combine_atoms(nil, nil) == nil
    end

    test "a & b are valid atoms", %{a: a, b: b} do
      assert combine_atoms(a, b) == String.Chars
    end
  end
end
