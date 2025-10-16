defmodule Billing.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages) do
      add :role, :string
      add :hidden, :boolean, default: false, null: false
      add :content, :text
      add :tool_calls, {:array, :map}
      add :tool_results, {:array, :map}

      timestamps(type: :utc_datetime)
    end
  end
end
