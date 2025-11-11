defmodule BillingWeb.QuoteLive.Index do
  use BillingWeb, :live_view

  alias Billing.Quotes

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Quotes")}
        <:actions>
          <.button variant="primary" navigate={~p"/quotes/new"}>
            <.icon name="hero-plus" /> {gettext("New Quote")}
          </.button>
        </:actions>
      </.header>

      <.table
        id="quotes"
        rows={@streams.quotes}
        row_click={fn {_id, quote} -> JS.navigate(~p"/quotes/#{quote}") end}
      >
        <:col :let={{_id, quote}} label={gettext("Id")}>{quote.id}</:col>
        <:col :let={{_id, quote}} label={gettext("Issued at")}>{quote.issued_at}</:col>
        <:col :let={{_id, quote}} label={gettext("Due date")}>{quote.due_date}</:col>
        <:col :let={{_id, quote}} label={gettext("Customer")}>{quote.customer.full_name}</:col>
        <:col :let={{_id, quote}} label={gettext("Amount")}>{quote.amount}</:col>
        <:action :let={{_id, quote}}>
          <div class="sr-only">
            <.link navigate={~p"/quotes/#{quote}"}>{gettext("Show")}</.link>
          </div>
          <.link navigate={~p"/quotes/#{quote}/edit"}>{gettext("Edit")}</.link>
        </:action>
        <:action :let={{id, quote}}>
          <.link
            phx-click={JS.push("delete", value: %{id: quote.id}) |> hide("##{id}")}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Quotes"))
     |> stream(:quotes, Quotes.list_quotes(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    quote = Quotes.get_quote!(socket.assigns.current_scope, id)
    {:ok, _} = Quotes.delete_quote(socket.assigns.current_scope, quote)

    {:noreply, stream_delete(socket, :quotes, quote)}
  end
end
