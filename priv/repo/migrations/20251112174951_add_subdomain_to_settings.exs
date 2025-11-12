defmodule Billing.Repo.Migrations.AddSubdomainToSettings do
  use Ecto.Migration

  def change do
    alter table(:settings) do
      add :subdomain, :string
    end

    create unique_index(:settings, [:subdomain])
  end
end
