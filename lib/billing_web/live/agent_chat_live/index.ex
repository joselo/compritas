defmodule BillingWeb.AgentChatLive.Index do
  use BillingWeb, :live_view

  alias Billing.LLM
  alias Billing.LLM.InvoiceTool
  alias Phoenix.LiveView.AsyncResult
  alias LangChain.LangChainError
  alias LangChain.Message.ContentPart
  alias LangChain.Chains.LLMChain
  alias LangChain.Message
  alias LangChain.PromptTemplate

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
        <div>
          <.markdown :if={@llm_chain.delta.role == :assistant} text={@delta_text} />
          <span class="loading loading-dots loading-md"></span>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Agent Chat")
     |> assign(:form, to_form(%{"message" => ""}))
     |> assign(:delta_text, nil)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> assign(:display_messages, [
        %{
          role: :assistant,
          hidden: false,
          content:
            "¡Hola! Me llamo Joselo y soy tu asistente tributario personal. ¿Cómo puedo ayudarte?"
        }
      ])
      |> assign_llm_chain()
      |> assign(:async_result, %AsyncResult{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"message" => text}, socket) do
    socket =
      socket
      |> add_user_message(text)
      |> run_chain()

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
        |> assign(:delta_text, nil)
      else
        delta_text = ContentPart.content_to_string(updated_chain.delta.merged_content)

        assign(socket, :delta_text, delta_text)
      end

    {:noreply, assign(socket, :llm_chain, updated_chain)}
  end

  defp assign_llm_chain(socket) do
    live_view_pid = self()
    llm = LLM.get_default_llm()

    handlers = %{
      on_llm_new_delta: fn _chain, deltas ->
        send(live_view_pid, {:chat_delta, deltas})
      end
    }

    system_message = """
      Eres Joselo, un asistente inteligente especializado en temas tributarios del Ecuador.
      Respondes siempre en español, de forma clara, respetuosa y eficiente.
      Tu objetivo es ayudar al usuario con información precisa sobre impuestos, facturación electrónica, obligaciones fiscales, y normativa tributaria vigente en Ecuador.

      ## Herramientas disponibles

      - `invoices`: Usa esta herramienta cuando el usuario pregunte sobre montos, totales o información relacionada con facturas.
    """

    llm_chain =
      %{llm: llm}
      |> LLMChain.new!()
      |> LLMChain.add_callback(handlers)
      |> LLMChain.add_tools(InvoiceTool.new!())
      |> LLMChain.add_message(Message.new_system!(system_message))

    assign(socket, :llm_chain, llm_chain)
  end

  defp add_user_message(
         %{assigns: %{llm_chain: %LLMChain{last_message: %Message{role: :system}} = llm_chain}} =
           socket,
         user_text
       )
       when is_binary(user_text) do
    today = Date.utc_today()

    template =
      PromptTemplate.from_template!(~S|
Hoy es <%= @today %>

El usuario dice:
<%= @user_text %>|)

    updated_chain =
      llm_chain
      |> LLMChain.add_message(
        PromptTemplate.to_message!(template, %{
          today: today |> Calendar.strftime("%A, %Y-%m-%d"),
          user_text: user_text
        })
      )

    socket
    |> assign(llm_chain: updated_chain)
    |> append_display_message(%{role: :user, content: user_text})
  end

  defp add_user_message(socket, user_text) when is_binary(user_text) do
    updated_chain = LLMChain.add_message(socket.assigns.llm_chain, Message.new_user!(user_text))

    socket
    |> assign(llm_chain: updated_chain)
    |> append_display_message(%{role: :user, content: user_text})
  end

  defp run_chain(socket) do
    chain = socket.assigns.llm_chain

    socket
    |> assign(:async_result, AsyncResult.loading())
    |> start_async(:running_llm, fn ->
      case LLMChain.run(chain, mode: :while_needs_response) do
        {:ok, _chain_result} ->
          :ok

        {:error, _update_chain, %LangChainError{} = error} ->
          Logger.error("Se recibió un error al ejecutar la cadena: #{error.message}")
          {:error, error.message}
      end
    end)
  end

  defp append_display_message(socket, %{} = message) do
    assign(socket, :display_messages, socket.assigns.display_messages ++ [message])
  end
end
