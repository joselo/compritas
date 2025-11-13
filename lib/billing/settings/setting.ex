defmodule Billing.Settings.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "settings" do
    field :title, :string
    field :avatar, :string
    field :user_id, :id
    field :subdomain, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(setting, attrs, user_scope) do
    setting
    |> cast(attrs, [:title, :avatar, :subdomain])
    |> validate_required([:title])
    |> validate_subdomain()
    |> put_change(:user_id, user_scope.user.id)
  end

  defp validate_subdomain(changeset) do
    if Billing.standalone_mode() do
      changeset
    else
      changeset
      |> validate_required([:subdomain])
      |> validate_format(:subdomain, ~r/^[a-z0-9][a-z0-9-]*[a-z0-9]$/,
        message:
          "debe contener solo letras minúsculas, números y guiones, y no puede comenzar o terminar con un guión"
      )
      |> validate_length(:subdomain, min: 3, max: 63)
      |> validate_exclusion(:subdomain, reserved_subdomains(),
        message: "está reservado y no puede ser usado"
      )
      |> unique_constraint(:subdomain)
    end
  end

  defp reserved_subdomains do
    [
      "www",
      "api",
      "admin",
      "app",
      "billing",
      "support",
      "help",
      "mail",
      "email",
      "ftp",
      "blog",
      "shop",
      "store",
      "dashboard",
      "portal",
      "dev",
      "staging",
      "test",
      "demo",
      "status"
    ]
  end
end
