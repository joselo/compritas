defmodule Billing do
  @moduledoc """
  Billing keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def get_storage_path do
    Application.get_env(:billing, :storage_path)
  end

  def standalone_mode do
    System.get_env("STANDALONE_MODE", "true") == "true"
  end
end
