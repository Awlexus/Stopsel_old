defmodule Stopsel.Predicates do
  alias Stopsel.{Dispatcher, Request}

  @type good_result :: %{
          moduledoc: String.t() | nil,
          function_doc: String.t() | nil,
          subcommand_docs: [String.t()]
        }
  @type bad_result :: {:error, :no_docs | :module_not_found}
  @type result :: good_result | bad_result
  @type callback :: (Request.t(), result -> term)
  @type option :: {:name, String.t()} | {:help_help, String.t()}
  @doc """
  Fetches the help for a command.

  If the extra `:help` is set for the command it'll returned.
  Otherwise this function will try to fetch the Dokumentation provided with `@doc`
  Calls the callback upon completion

  #### Options
  * `name` - This function tries to imitate a command. If you add this predicate to
  the Command with the name ";", your users can access help for commands with ";help"
  * `help_help` - sets `:function_doc` when the user asks for help on the help command
  """
  @spec help(callback, [option]) :: Request.t() | :halted
  def help(callback, options \\ []) do
    name = Keyword.get(options, :name, "help")

    fn request ->
      cond do
        # User wants help for helpcommand
        match?([^name, ^name | _], String.split(request.derived_content, " ", parts: 3)) ->
          callback.(request, %{
            module_doc: nil,
            function_docs: Keyword.get(options, :help_help, "Shows you how to use this bot"),
            subcommand_docs: []
          })

        # user wants help for a command.
        String.starts_with?(request.derived_content, name) ->
          # Find out which command the user wants help with
          result =
            case get_command(request) do
              # Command has a custom help field. We'll use this
              {:ok, %{extras: %{help: help}} = command} ->
                command
                |> helpmap()
                |> Map.update!(:function_doc, help)

              # Fetch help for command
              {:ok, %{function: function} = command} when is_atom(function) ->
                helpmap(command)

              # Return error that the user may handle
              error ->
                error
            end

          callback.(request, result)

          %{request | halted?: true}

        true ->
          request
      end
    end
  end

  defp helpmap(command) do
    with {_, _, _, _, moduledoc, _, function_docs} <-
           Code.fetch_docs(command.scope),
         {:docs, function_doc} <-
           {:docs, Keyword.get(function_docs, command.function)} do
      %{
        moduledoc: maybe_moduledoc(moduledoc),
        function_doc: maybe_function_doc(function_doc),
        subcommand_docs: subcommand_docs(command.commands)
      }
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp maybe_moduledoc(%{"en" => moduledoc}) when is_binary(moduledoc), do: moduledoc
  defp maybe_moduledoc(_), do: nil

  defp maybe_function_doc({_, _, _, _, function_doc}), do: function_doc["en"]
  defp maybe_function_doc(nil), do: nil

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
end
