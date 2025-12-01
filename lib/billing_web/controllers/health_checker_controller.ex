defmodule BillingWeb.HealthCheckerController do
  use BillingWeb, :controller

  def index(conn, _params) do
    send_resp(conn, :no_content, "")
  end
end
