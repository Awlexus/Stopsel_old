alias Stopsel.{Command, Request}

defprotocol Stopsel.Dispatcher do
  @doc """
  Dispatches a message.

  Returns the result of the called function or `ignored`,
  if no matching command was found
  """
  def dispatch(dispatcher, request)

  @doc """
  Adds a command to the dispatcher.

  Returns a new dispatcher
  """
  def add_command(dispatcher, path, command)

  @doc """
  Removes a command from the dispatcher.

  Returns the removed command and a new dispatcher.
  """
  def unload_command(dispatcher, path)

  @doc """
  Returns the command located at the command path
  """
  def find_command(dispatcher, path)
end

defimpl Stopsel.Dispatcher, for: Command do
  # This clause checks if the message matches the root commands name (the routers prefix)
  @spec dispatch(Command.t(), Request.t()) :: term | :ingored | :halted
  def dispatch(%Command{} = command, %Request{cropped_message_content: nil} = request) do
    if String.starts_with?(request.message_content, command.name) do
      dispatch(command, request, request.message_content)
    else
      :ignore
    end
  end

  def dispatch(%Command{} = command, %Request{} = request) do
    message_content = remove_prefix(request.cropped_message_content, command.name)

    # Check if one of the subcommands matches this message
    with nil <- find_subcommand(command, message_content),
         # No match, so we try to execute this function, after applying the predicates
         request =
           Map.update!(request, :cropped_message_content, &remove_prefix(&1, command.name)),
         %Request{} = request <-
           apply_predicates(request, command.predicates) do
      execute(command, request)
    else
      # A matching subcommand was found!
      %Command{} = command ->
        cropped_message_content = remove_prefix(message_content, command.name)

        dispatch(command, request, cropped_message_content)

      :ignored ->
        :ignored

      :halted ->
        :halted
    end
  end

  # Helper for updating the cropped_message_content
  defp dispatch(command, request, cropped_message_content) do
    dispatch(command, %{request | cropped_message_content: cropped_message_content})
  end

  def add_command(%Command{} = dispatcher, [name | path], command) do
    if dispatcher.name == name do
      target_path = [:commands | Enum.intersperse(path ++ [command.name], :commands)]

      try do
        {:ok, put_in(dispatcher, target_path, command)}
      rescue
        ArgumentError ->
          {:error, :no_match}
      end
    else
      {:error, :no_match}
    end
  end

  def unload_command(%Command{} = dispatcher, [name | path]) do
    if dispatcher.name == name do
      path = [:commands | Enum.intersperse(path, :commands)]

      case pop_in(dispatcher, path) do
        {nil, _} -> {:error, :no_match}
        command -> {:ok, command}
      end
    else
      {:error, :no_match}
    end
  end

  def find_command(%Command{} = command, [name | [next | _path] = path]) do
    if command.name == name do
      case Enum.find(command.commands, &(elem(&1, 1).name == next)) do
        {_name, %Command{} = subcommand} ->
          find_command(subcommand, path)

        nil ->
          {:error, :no_match}
      end
    end
  end

  def find_command(%Command{} = command, [name | []]) do
    if command.name == name do
      {:ok, command}
    else
      {:error, :no_match}
    end
  end

  defp execute(%Command{function: nil}, _), do: :ignored

  defp execute(%Command{function: function}, request) when is_function(function, 1),
    do: function.(request)

  defp execute(%Command{function: function, scope: scope}, request)
       when is_atom(function),
       do: apply(scope, function, [request])

  defp remove_prefix(message_content, prefix) do
    message_content
    |> String.replace_prefix(prefix, "")
    |> String.trim()
  end

  defp find_subcommand(command, message_content) do
    result =
      Enum.find(command.commands, fn {name, _subcommand} ->
        String.starts_with?(message_content, name)
      end)

    case result do
      nil -> nil
      {_name, command} -> command
    end
  end

  defp apply_predicates(request, predicates) do
    Enum.reduce_while(predicates, request, fn predicate, request ->
      case predicate.(request) do
        %Request{} = request ->
          {:cont, request}

        _ ->
          {:halt, :halt}
      end
    end)
  end
end
