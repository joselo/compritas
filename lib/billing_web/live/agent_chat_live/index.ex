defmodule BillingWeb.AgentChatLive.Index do
  use BillingWeb, :live_view

  alias Billing.Ai
  alias Phoenix.LiveView.AsyncResult
  alias LangChain.LangChainError
  alias LangChain.Message.ContentPart
  alias LangChain.Chains.LLMChain

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to chat with the ai agent.</:subtitle>
      </.header>

      <.form for={@form} phx-submit="save">
        <.input field={@form[:message]} placeholder="Hola!" />

        <footer>
          <.button phx-disable-with="Sending..." variant="primary">Send</.button>
        </footer>
      </.form>

      <div :for={message <- @display_messages}>
        <.markdown :if={message.role == :assistant} text={message.content} />

        <span :if={message.role == :user} class="whitespace-pre-wrap">
          {message.content}
        </span>
      </div>

      <%= if @llm_chain.delta do %>
        <div class="text-center">
          <span class="loading loading-dots loading-md"></span>
          <.markdown :if={@llm_chain.delta.role == :assistant} text={@llm_chain.delta.content} />
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    live_view_pid = self()

    handlers = %{
      on_llm_new_delta: fn _chain, deltas ->
        send(live_view_pid, {:chat_delta, deltas})
      end
    }

    system_message = %{role: :system, message_text: Ai.System.default_message()}
    messages = [system_message]
    model = Ai.Models.get_default_llm()
    llm_chain = Ai.Agent.build(model, messages, handlers)

    {:ok,
     socket
     |> assign(:page_title, "Agent Chat")
     |> assign(:form, to_form(%{"message" => ""}))
     |> assign(:display_messages, [])
     |> assign(:llm_chain, llm_chain)
     |> assign(:async_result, %AsyncResult{})
     |> append_display_message(system_message)}
  end

  @impl true
  def handle_event("save", %{"message" => text}, socket) do
    chain = socket.assigns.llm_chain
    user_message = Ai.Agent.new_message(%{role: :user, message_text: text})
    updated_chain = Ai.Agent.add_message(chain, user_message)

    socket =
      socket
      |> assign(:async_result, AsyncResult.loading())
      |> start_async(:running_llm, fn ->
        case LLMChain.run(updated_chain, mode: :while_needs_response) do
          {:ok, _chain_result} ->
            :ok

          {:error, _update_chain, %LangChainError{} = error} ->
            Logger.error("Se recibió un error al ejecutar la cadena: #{error.message}")
            {:error, error.message}
        end
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_async(:running_llm, {:ok, :ok = _success}, socket) do
    {:noreply, assign(socket, :async_result, AsyncResult.ok(%AsyncResult{}, :ok))}
  end

  @impl true
  def handle_async(:running_llm, {:ok, {:error, reason}}, socket) do
    socket =
      socket
      |> put_flash(:error, reason)
      |> assign(:async_result, AsyncResult.failed(%AsyncResult{}, reason))

    {:noreply, socket}
  end

  @impl true
  def handle_async(:running_llm, {:exit, reason}, socket) do
    socket =
      socket
      |> put_flash(:error, "Call failed: #{inspect(reason)}")
      |> assign(:async_result, %AsyncResult{})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_delta, deltas}, socket) do
    updated_chain = LLMChain.apply_deltas(socket.assigns.llm_chain, deltas)

    socket =
      if updated_chain.delta == nil do
        message = updated_chain.last_message
        content = ContentPart.content_to_string(message.content)

        append_display_message(socket, %{
          role: message.role,
          content: content,
          tool_calls: message.tool_calls,
          tool_results: message.tool_results
        })
      else
        socket
      end

    {:noreply, assign(socket, :llm_chain, updated_chain)}
  end

  # def handle_info({:tool_executed, tool_message}, socket) do
  #   # message = %ChatMessage{
  #   #   role: tool_message.role,
  #   #   hidden: false,
  #   #   content: nil,
  #   #   tool_results: tool_message.tool_results
  #   # }
  #   #
  #   # socket =
  #   #   socket
  #   #   |> assign(:llm_chain, LLMChain.add_message(socket.assigns.llm_chain, tool_message))
  #   #   |> append_display_message(message)
  #
  #   {:noreply, socket}
  # end

  defp append_display_message(socket, %{} = message) do
    assign(socket, :display_messages, socket.assigns.display_messages ++ [message])
  end
end
