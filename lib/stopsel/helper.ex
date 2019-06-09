defmodule Stopsel.Helper do
  @doc """
  Combines 2 atoms

    iex> Stopsel.Helper.combine_atoms(String, Chars)
    String.Chars

    iex> Stopsel.Helper.combine_atoms(nil, String)
    String

    iex> Stopsel.Helper.combine_atoms(String, nil)
    String

    iex> Stopsel.Helper.combine_atoms(nil, nil)
    nil

  """
  def combine_atoms(nil, b), do: b
  def combine_atoms(a, nil), do: a

  def combine_atoms(a, b) when is_atom(a) and is_atom(b) do
    "Elixir." <> atomb = Atom.to_string(b)

    :"#{a}.#{atomb}"
  end
end
