defmodule Billing.ChatMessages do
  alias Billing.Repo
  alias Billing.ChatMessages.ChatMessage

  alias Billing.Accounts.Scope

  def create_chat_message(%Scope{} = scope, attrs) do
    %ChatMessage{}
    |> change_chat_message(attrs, scope)
    |> Repo.insert()
  end

  def change_chat_message(%Scope{} = scope, %ChatMessage{} = chat_message, attrs \\ %{}) do
    ChatMessage.changeset(chat_message, attrs, scope)
  end

  def list_chat_messages(%Scope{} = scope) do
    Repo.all_by(ChatMessage, user_id: scope.user.id)
  end
end
