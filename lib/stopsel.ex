defmodule Stopsel do
  alias Stopsel.{Command, Dispatcher, Request}

  @doc """
  Creates the toplevel of your command-graph and should not be used inside the 
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
  def command(options) do
    struct!(Command, options)
  end

  @doc """
  Dispatches a message.

  See [`dispatch/2`](Stopsel.Dispatcher.html#dispatch/2) for more info.
  """
  @spec dispatch(Dispatcher.t(), String.t() | Request.t()) :: term | :ignored | :halted
  def dispatch(dispatcher, message_content) when is_binary(message_content) do
    dispatch(dispatcher, %Request{message_content: message_content})
  end

  defdelegate dispatch(dispatcher, request), to: Dispatcher

  @doc """
  Creates an alias-command that points to given path
  """
  def alias(name, alias_path) do
    forwarder = fn request ->
      dispatch(
        request.dispatcher,
        %{
          request
          | derived_content: nil,
            message_content: "#{alias_path} #{request.derived_content}"
        }
      )
    end

    %Command{name: name, scope: nil, function: forwarder}
  end
end
