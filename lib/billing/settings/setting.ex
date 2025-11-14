defmodule Billing.Settings.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "settings" do
    field :title, :string
    field :avatar, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(setting, attrs, user_scope) do
    setting
    |> cast(attrs, [:title, :avatar])
    |> validate_required([:title])
    |> put_change(:user_id, user_scope.user.id)
  end
end
