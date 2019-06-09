defmodule Stopsel.Helper do
  @moduledoc false

  # Combines 2 atoms

  def combine_atoms(nil, b), do: b
  def combine_atoms(a, nil), do: a

  def combine_atoms(a, b) when is_atom(a) and is_atom(b) do
    "Elixir." <> atomb = Atom.to_string(b)

    :"#{a}.#{atomb}"
  end
end
