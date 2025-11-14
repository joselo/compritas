defmodule Billing.Repo.Migrations.RemoveSubdomainFromSettings do
  use Ecto.Migration

  def change do
    alter table(:settings) do
      remove :subdomain
    end
  end
end
