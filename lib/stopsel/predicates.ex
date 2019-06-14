defmodule Stopsel.Predicates do
  alias Stopsel.{Dispatcher, Request}

  @type success_function ::
          (Request.t(),
           %{
             moduledoc: String.t() | nil,
             function_doc: String.t() | nil,
             subcommand_docs: [String.t()]
           } ->
             term)

  @type option ::
          {:name, String.t()}
          | {:callback_success, success_function}
          | {:callback_failure, (Request.t(), {:error, :no_docs | :module_not_found} -> term)}
          | {:help_help, String.t()}
  @doc """
  Fetches the help for a command.

  If the extra `:help` is set for the command it'll returned.
  Otherwise this function will try to fetch the Dokumentation provided with `@doc`

    Options:
      * name             - This function tries to imitate a command. If you add this predicate to
                           the Command with the name ";", your users can access help for commands
                           with ";help"
      * callback_success - A function which will be called when help was successfully retrieved.
      * callback_failure - A function which will be called when help was could not be retrieved.
      * help_help        - sets `:function_doc` when the user asks for help on the help command
  """
  @spec help([option]) :: Request.t() | :halted
  def help(options) do
    name = Keyword.get(options, :name, "help")
    callback_success = Keyword.get(options, :callback_success)
    callback_failure = Keyword.get(options, :callback_failure)

    fn request ->
      cond do
        match?([^name, ^name | _], String.split(request.derived_content, parts: 3)) ->
          callback_success.(%{
            module_doc: nil,
            function_docs: Keyword.get(options, :help_help, "Shows you how to use this bot"),
            subcommand_docs: []
          })

        String.starts_with?(request.derived_content, name) ->
          case get_command(request) do
            {:ok, %{extras: %{help: help}}} ->
              callback_success.(help)

            {:ok, %{function: function} = command} when is_atom(function) ->
              with {_, _, _, moduledoc, _, _, function_docs} <- Code.fetch_docs(command.scope),
                   {:docs, {_, _, _, _, function_doc}} <-
                     {:docs, Keyword.get(function_docs, request.command.function)} do
                callback_success.(request, %{
                  moduledoc:
                    if is_binary(moduledoc) do
                      moduledoc
                    else
                      nil
                    end,
                  function_doc: function_doc["en"],
                  subcommand_docs: subcommand_docs(command.subcommands)
                })
              else
                {:error, error} ->
                  callback_failure.(request, {:error, error})

                {:docs, _} ->
                  callback_failure.(request, {:error, :no_docs})
              end

              :halted
          end

        true ->
          request
      end
    end
  end

  defp get_command(request) do
    Dispatcher.find_command(request.current_command, [
      request.current_command.name | String.split(request.derived_content)
    ])
  end

  defp subcommand_docs(subcommands) do
    subcommands
    |> Enum.map(fn
      %{extras: %{help: help}} ->
        help

      %{scope: scope, function: function} when is_atom(function) ->
        with {_, _, _, _, _, _, function_docs} <- Code.fetch_docs(scope),
             doc when is_binary(doc) <- Keyword.get(function_docs, function) do
          doc
        else
          _ ->
            nil
        end

      _ ->
        nil
    end)
    |> Enum.filter(& &1)
  end
end
