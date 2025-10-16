defmodule Billing.ChatMessages do
  alias Billing.Repo
  alias Billing.ChatMessages.ChatMessage

  def create_chat_message(attrs) do
    %ChatMessage{}
    |> change_chat_message(attrs)
    |> Repo.insert()
  end

  def change_chat_message(%ChatMessage{} = chat_message, attrs \\ %{}) do
    ChatMessage.changeset(chat_message, attrs)
  end

  def list_chat_messages do
    Repo.all(ChatMessage)
  end
end
