defmodule Stopsel.Predicates.Help do
  @moduledoc """
  Fetches the help for a command.

  If the extra `:help` is set for the command it'll returned.
  Otherwise this function will try to fetch the Dokumentation provided with `@doc`
  Calls the callback upon completion

  #### Options
  * `name` - This function tries to imitate a command. If you add this predicate to
  the Command with the name ";", your users can access help for commands with ";help"
  * `help_help` - sets `:function_doc` when the user asks for help on the help command
  """

  alias Stopsel.Dispatcher

  @behaviour Stopsel.Predicates
  alias Stopsel.Predicates.Help
  defstruct function_docs: nil, module_docs: nil, subcommand_docs: []

  @impl true
  def predicate(request, options) do
    name = Keyword.get(options, :name, "help")
    callback = Keyword.fetch!(options, :callback)
    help_help = Keyword.get(options, :help_help, "Shows you how to use this bot")
    split_message = String.split(request.derived_content, " ", parts: 3)

    cond do
      # User wants help for helpcommand
      match?([^name, ^name | _], split_message) ->
        call_callback(callback, request, %Help{function_docs: help_help})

        %{request | halted?: true}

      match?([^name], split_message) ->
        call_callback(callback, request, %Help{function_docs: help_help})

        %{request | halted?: true}

      # user wants help for a command.
      String.starts_with?(request.derived_content, name) ->
        # Find out which command the user wants help with
        result =
          case get_command(request) do
            # Command has a custom help field. We'll use this
            {:ok, %{extra: %{help: help}} = command} ->
              command
              |> helpmap()
              |> Map.put(:function_docs, help)

            # Fetch help for command
            {:ok, %{function: function} = command} when is_atom(function) ->
              helpmap(command)

            # Return error that the user may handle
            error ->
              error
          end

        call_callback(callback, request, result)

        %{request | halted?: true}

      true ->
        request
    end
  end

  defp helpmap(command) do
    case Code.fetch_docs(command.scope) do
      {_, _, _, _, moduledoc, _, function_docs} ->
        %Help{
          module_docs: maybe_moduledoc(moduledoc),
          function_docs: find_docs(function_docs, command.function),
          subcommand_docs: subcommand_docs(command.commands)
        }

      {:error, error} ->
        {:error, error}
    end
  end

  defp maybe_moduledoc(%{"en" => moduledoc}) when is_binary(moduledoc), do: moduledoc
  defp maybe_moduledoc(_), do: nil

  defp get_command(request) do
    Dispatcher.find_command(request.current_command, [
      request.current_command.name | tl(String.split(request.derived_content))
    ])
  end

  defp subcommand_docs(subcommands) do
    subcommands
    |> Stream.map(fn
      {name, %{extras: %{help: help}}} ->
        {name, help}

      {name, %{scope: scope, function: function}} when is_atom(function) ->
        with {_, _, _, _, _, _, function_docs} <-
               Code.fetch_docs(scope),
             doc when is_binary(doc) <- find_docs(function_docs, function) do
          {name, doc}
        else
          _ ->
            nil
        end

      _ ->
        nil
    end)
    |> Stream.filter(& &1)
    |> Enum.into(%{})
  end

  defp find_docs(function_docs, function) do
    result =
      Enum.find(function_docs, fn
        {{:function, ^function, 1}, _, _, _, _} -> true
        _ -> false
      end)

    case result do
      {_, _, _, %{"en" => docs}, _} -> docs
      _ -> nil
    end
  end

  defp call_callback({module, function}, request, help) do
    apply(module, function, [request, help])
  end

  defp call_callback(callback, request, help) when is_function(callback, 2) do
    callback.(request, help)
  end
end
