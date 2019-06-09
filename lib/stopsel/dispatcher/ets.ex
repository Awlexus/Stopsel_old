defmodule Stopsel.Dispatcher.ETS do
  # @behaviour Stopsel.Dispatcher
  # use GenServer

  # def start_link(routers) when is_list(router) do
  #   GenServer.start_link(__MODULE__, routers, [])
  # end

  # def start_link(router) do
  #   router
  #   |> List.wrap()
  #   |> start_link()
  # end

  # def init(router) do
  #   table = :ets.new(:routers, [:set, {:read_concurrency, true}])
  #   fill_table()

  #   {:ok, table}
  # end

  # def dispatch(dispatcher, message) do
  #   GenServer.call(dispatcher, {:dispatch, message})
  # end

  # def add_router(dispatcher, router) do
  #   GenServer.call(dispatcher, {:add_router, router})
  # end

  # def unload_router(dispatcher, router) do
  #   GenServer.call(dispatcher, {:unload_router, router})
  # end

  # def add_command(dispatcher, command) do
  #   GenServer.call(dispatcher, {:add_command, command})
  # end

  # def unload_command(dispatcher, command) do
  #   GenServer.call(dispatcher, {:unload_command, command})
  # end

  # def handle_call({:dispatch, message}, from, state) do
  #   Task.start_link(fn ->
  #   end)

  #   {:noreply, state}
  # end

  # defp fill_table(routers, table) do
  #   routers
  #   |> Stream.flat_map(&build_commands/1)
  # end

  # defp build_commands(router) do
  #   Stream.flat_map(router.commands, &build_command(&1, [router.prefix]))
  # end

  # defp build_command(command, previous) do
  #   List.to_tuple()

  #   command.commands
  #   |> Stream.flat_map(&build_commands(&1, [previous | command.name]))
  #   |> Stream.concat([{command_tuple(command.name, previous), command}])
  # end

  # defp command_tuple(name, previous) do
  #   [name | previous]
  #   |> Enum.reverse()
  #   |> List.to_tuple()
  # end
end
