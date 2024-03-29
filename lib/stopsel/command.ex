defmodule Stopsel.Command do
  @moduledoc """
  Module used to define a single command, and may define multiple subcommands
  """
  alias Stopsel.Request

  import Stopsel.Helper, only: [combine_atoms: 2]

  defstruct name: nil,
            function: nil,
            predicates: [],
            commands: %{},
            scope: nil,
            extra: %{}

  @behaviour Access
  @type name :: String.t()
  @type command_function :: (Request.t() -> term) | {module, atom} | atom | nil
  @type predicate :: (Request.t() -> Request.t())

  @type t :: %__MODULE__{
          name: name,
          function: command_function,
          predicates: [predicate],
          scope: module,
          extra: map
        }

  @type option ::
          {:name, name}
          | {:function, command_function}
          | {:predicates, [predicate]}
          | {:scope, module}
          | {:extra, [{atom, term}] | map}
  @type definition :: [option]

  def build(options, scope \\ nil)

  def build(%__MODULE__{} = command, scope) do
    do_build(command, scope)
  end

  def build(options, scope) do
    __MODULE__
    |> struct!(options)
    |> do_build(scope)
  end

  defp do_build(command, scope) do
    command
    |> name_from_function()
    |> apply_scope(scope)
    |> build_subcommands()
    |> extra_to_map()
  end

  defp apply_scope(command, scope), do: Map.update!(command, :scope, &combine_atoms(scope, &1))

  defp name_from_function(%{name: name} = command) when is_binary(name) do
    if name =~ ~r"\s", do: raise("Command names may not contain whitespaces")

    command
  end

  defp name_from_function(%{function: function} = command) when function != nil and is_atom(function) do
    name =
      function
      |> to_string()
      |> String.replace(" ", "_")

    Map.put(command, :name, name)
  end

  defp name_from_function(%{function: {_module, function}} = command) when is_atom(function) do
    Map.put(command, :name, to_string(function))
  end

  defp name_from_function(_),
    do: raise("A function needs a valid name or a function to defer the name from")

  defp build_subcommands(command) do
    update_in(command.commands, fn commands ->
      Enum.into(commands, %{}, fn subcommand ->
        subcommand
        |> build(command.scope)
        |> with_name()
      end)
    end)
  end

  defp with_name(command), do: {command.name, command}

  defp extra_to_map(%{extra: extra} = command) when is_list(extra) do
    Map.update!(command, :extra, &Enum.into(&1, %{}))
  end

  defp extra_to_map(%{extra: extra} = command) when is_map(extra) do
    command
  end

  # Mandatory implementation of the Access behaviour

  @impl Access
  @doc false
  def fetch(command, key) do
    Map.fetch(command, key)
  end

  @impl Access
  @doc false
  def get_and_update(command, key, function) do
    Map.get_and_update(command, key, &function.(&1))
  end

  @impl Access
  @doc false
  def pop(command, key) do
    {Map.get(command, key), %{command | key => nil}}
  end
end
