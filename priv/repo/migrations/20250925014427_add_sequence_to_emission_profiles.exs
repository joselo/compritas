defmodule Billing.Repo.Migrations.AddSequenceToEmissionProfiles do
  use Ecto.Migration

  def change do
    alter table(:emission_profiles) do
      add :sequence, :integer, default: 1
    end
  end
end
