defmodule Billing.Repo.Migrations.AddContentToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :content, :text
    end
  end
end
