defmodule Billing do
  @moduledoc """
  Billing keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def get_storage_path do
    System.get_env("STORAGE_PATH", "./storage")
  end

  def get_uploads_path do
    System.get_env("UPLOADS_PATH", "./uploads")
  end

  def get_from_email do
    System.get_env("FROM_EMAIL", "contact@example.com")
  end
end
