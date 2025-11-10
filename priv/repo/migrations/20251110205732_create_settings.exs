defmodule Billing.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings) do
      add :title, :string
      add :avatar, :string

      timestamps(type: :utc_datetime)
    end
  end
end
