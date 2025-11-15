defmodule Billing.Storage do
  alias Billing.Accounts.Scope

  def save_file(file_path, content) do
    with :ok <- ensure_directory_exists(file_path),
         :ok <- File.write(file_path, content) do
      {:ok, file_path}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def ensure_directory_exists(file_path) do
    file_path
    |> Path.dirname()
    |> File.mkdir_p()
  end

  def p12_path(%Scope{} = scope, file_name) do
    "#{Billing.get_storage_path()}/#{scope.user.uuid}/p12_files/#{file_name}"
  end

  def p12_file_exists?(%Scope{} = scope, p12_file_path) do
    path = p12_path(scope, p12_file_path)

    if File.exists?(path) do
      {:ok, path}
    else
      {:error, "El certificado para firmar la factura no existe"}
    end
  end

  def upload_path(%Scope{} = scope, file_name) do
    Path.join([
      "#{Billing.get_uploads_path()}",
      "#{scope.user.uuid}",
      file_name
    ])
  end

  def copy_file!(file_path, dest_path) do
    case ensure_directory_exists(dest_path) do
      :ok ->
        File.cp!(file_path, dest_path)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def save_upload!(%Scope{} = scope, file_path, file_name) do
    dest_path = upload_path(scope, file_name)

    case ensure_directory_exists(dest_path) do
      :ok ->
        File.cp!(file_path, dest_path)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def cdn_url(path) when is_binary(path) do
    path
  end
end
