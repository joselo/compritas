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
  alias LangChain.Message
  alias Billing.ChatMessages
  alias Billing.ChatMessages.ChatMessage

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to chat with the ai agent.</:subtitle>
      </.header>

      <.form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:content]} placeholder="Hola!" />

        <footer>
          <.button phx-disable-with="Sending..." variant="primary">Send</.button>
        </footer>
      </.form>

      <div :for={message <- @display_messages}>
        <.markdown :if={message.role == :assistant} text={message.content} />

        <span :if={message.role == :user} class="whitespace-pre-wrap">
          {message.content}
        </span>

        <div :if={message.role == :tool} class="text-sm text-gray-500 italic">
          {message.content}
        </div>
      </div>

      <%= if @delta_text do %>
        <div>
          <.markdown text={@delta_text} />
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
     |> assign(:delta_text, nil)
     |> assign_display_messages()}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> reset_message_form()
      |> assign_llm_chain()
      |> assign(:async_result, %AsyncResult{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"chat_message" => params}, socket) do
    changeset =
      %ChatMessage{}
      |> ChatMessages.change_chat_message(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"chat_message" => params}, socket) do
    case ChatMessages.create_chat_message(params) do
      {:ok, chat_message} ->
        {:noreply,
         socket
         |> add_user_message(chat_message.content)
         |> reset_message_form()
         |> run_chain()}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("save", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_async(:running_llm, {:ok, {:ok, chain_updated}}, socket) do
    {:noreply,
     socket
     |> assign(:llm_chain, chain_updated)
     |> assign(:async_result, AsyncResult.ok(%AsyncResult{}, :ok))}
  end

  @impl true
  def handle_async(:running_llm, {:ok, {:error, reason}}, socket) do
    socket =
      socket
      |> put_flash(:error, reason)
      |> assign(:delta_text, nil)
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
  def handle_info({:chat_delta, delta}, socket) do
    if delta && delta.content do
      content = ContentPart.content_to_string([delta.content])
      delta_text = socket.assigns.delta_text || ""

      {:noreply, assign(socket, :delta_text, delta_text <> content)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:message_processed, last_message}, socket) do
    content = ContentPart.content_to_string(last_message.content)

    chat_message_attrs = %{
      role: last_message.role,
      content: content,
      tool_calls: last_message.tool_calls,
      tool_results: last_message.tool_results
    }

    case ChatMessages.create_chat_message(chat_message_attrs) do
      {:ok, chat_message} ->
        {:noreply,
         socket
         |> append_display_message(chat_message)
         |> assign(:delta_text, nil)}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, inspect(changeset))}
    end
  end

  def handle_info({:tool_executed, tool_message}, socket) do
    chat_message_attrs = %{
      role: tool_message.role,
      hidden: false,
      content: "Herramienta ejecutada",
      tool_results: tool_message.tool_results
    }

    {:noreply, append_display_message(socket, chat_message_attrs)}
  end

  defp assign_llm_chain(socket) do
    live_view_pid = self()
    llm = LLM.get_default_llm()

    handlers = %{
      on_llm_new_delta: fn _chain, deltas ->
        Enum.each(deltas, fn delta ->
          send(live_view_pid, {:chat_delta, delta})
        end)
      end,
      on_message_processed: fn _chain, %Message{} = data ->
        send(live_view_pid, {:message_processed, data})
      end,
      on_tool_response_created: fn _chain, %Message{role: :tool} = message ->
        send(live_view_pid, {:tool_executed, message})
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
        {:ok, chain_updated} ->
          {:ok, chain_updated}

        {:error, _update_chain, %LangChainError{} = error} ->
          Logger.error("Se recibió un error al ejecutar la cadena: #{error.message}")
          {:error, error.message}
      end
    end)
  end

  defp append_display_message(socket, %{} = message) do
    assign(socket, :display_messages, socket.assigns.display_messages ++ [message])
  end

  defp reset_message_form(socket) do
    changeset = ChatMessages.change_chat_message(%ChatMessage{})
    assign_form(socket, changeset)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_display_messages(socket) do
    welcome_message = [
      %{
        role: :assistant,
        hidden: false,
        content:
          "¡Hola! Me llamo Joselo y soy tu asistente tributario personal. ¿Cómo puedo ayudarte?"
      }
    ]

    assign(socket, :display_messages, welcome_message ++ ChatMessages.list_chat_messages())
  end
end
