defmodule Stopsel do
  alias Stopsel.{Command, Dispatcher, Request}

  @doc """
  Same as `command/1` except you can use `:prefix` instead of `:name`
  """
  def router(options) do
    options
    |> Keyword.put_new(:name, options[:prefix])
    |> Keyword.delete(:prefix)
    |> Command.build()
  end

  @doc """
  Builds a command for the given options.

  See [`build/2`](Stopsel.Command.html#build/2) for more information.
  """
  defdelegate command(options), to: Command, as: :build

  @doc """
  Dispatches a message.

  See [`dispatch/2`](Stopsel.Dispatcher.html#dispatch/2) for more info.
  """
  @spec dispatch(Dispatcher.t(), String.t() | Request.t()) :: term | :ignored | :halted
  def dispatch(dispatcher, message_content) when is_binary(message_content) do
    dispatch(dispatcher, %Request{message_content: message_content})
  end

  def alias(name, alias_path, help_text_fun \\ &"Alias to #{&1}") do
    %Command{
      name: name,
      scope: nil,
      function: &dispatch(&1.dispatcher, alias_path),
      extras: %{help: help_text_fun.(alias_path)}
    }
  end

  defdelegate dispatch(dispatcher, request), to: Dispatcher
end
