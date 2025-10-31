defmodule Billing.Repo.Migrations.AddEmissionProfileIdToInvoices do
  use Ecto.Migration

  def change do
    alter table(:quotes) do
      add :emission_profile_id, references(:emission_profiles, on_delete: :nothing)
    end

    create index(:quotes, [:emission_profile_id])
  end
end
