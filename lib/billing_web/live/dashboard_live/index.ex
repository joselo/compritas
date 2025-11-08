defmodule BillingWeb.DashboardLive.Index do
  use BillingWeb, :live_view

  alias Billing.ElectronicInvoices

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
      </.header>

      <div id="line-simple" phx-hook="Echart" class="w-full h-[20rem]" phx-update="ignore"></div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Dashboard")}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    data = ElectronicInvoices.chart_data_by_month()
    option = build_chart_option(format_data(data))

    {:noreply, push_event(socket, "chart-option-line-simple", option)}
  end

  defp format_data(data) do
    monthly_data =
      data
      |> Enum.map(&{&1.month, &1.total})
      |> Map.new()

    Enum.map(1..12, fn month ->
      Map.get(monthly_data, month, 0.0)
    end)
  end

  defp build_chart_option(data) do
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    %{
      xAxis: %{
        type: "category",
        data: months
      },
      yAxis: %{
        type: "value"
      },
      series: [
        %{
          data: data,
          type: "line"
        }
      ]
    }
  end
end
