defmodule Billing.Subdomains do
  import Ecto.Query

  alias Billing.Repo
  alias Billing.Settings.Setting

  def generate_unique_subdomain do
    subdomain = generate_random_string()

    if subdomain_available?(subdomain) do
      {:ok, subdomain}
    else
      generate_unique_subdomain()
    end
  end

  defp generate_random_string do
    Ecto.UUID.generate()
    |> String.replace("-", "")
    |> String.slice(0, 10)
    |> String.downcase()
  end

  defp subdomain_available?(subdomain) do
    query = from s in Setting, where: s.subdomain == ^subdomain, select: count(s.id)

    Repo.one(query) == 0
  end
end
