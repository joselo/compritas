defmodule Billing.Repo.Migrations.AddFilesToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :files, {:array, :string}, default: []
    end
  end
end
