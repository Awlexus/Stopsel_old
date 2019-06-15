defmodule Stopsel.Request do
  @type t :: %__MODULE__{
          message_content: String.t(),
          derived_content: String.t(),
          dispatcher: struct,
          current_command: Stopsel.Command.t(),
          message_id: term,
          channel_id: term,
          server_id: term,
          user_id: term,
          assigns: map,
          halted?: boolean
        }

  defstruct message_content: nil,
            derived_content: nil,
            dispatcher: nil,
            current_command: nil,
            message_id: nil,
            channel_id: nil,
            server_id: nil,
            user_id: nil,
            assigns: %{},
            halted?: false

  def assign(request, key, value) do
    put_in(request.assigns[key], value)
  end
end
