defmodule Stopsel do
  @moduledoc """
  Documentation for Stopsel.
  """

  alias Stopsel.Command

  @doc """
  Same as `command/1` except you can use `:prefix` instead of `:name`
  """
  def router(options) do
    options
    |> Keyword.put_new(:name, options[:prefix])
    |> command()
  end

  @doc """
  Builds a command for the given options.

  See `Stopsel.Command` for more information.
  """
  defdelegate command(options), to: Command, as: :build
end
