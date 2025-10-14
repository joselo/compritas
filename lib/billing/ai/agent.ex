defmodule Billing.Ai.Agent do
  alias LangChain.Chains.LLMChain
  alias LangChain.Message
  alias Billing.Ai.Tools.InvoiceFunction

  def build(llm, messages \\ [], handlers \\ %{}) do
    %{llm: llm}
    |> LLMChain.new!()
    |> LLMChain.add_callback(handlers)
    |> add_tool(InvoiceFunction.new!())
    |> add_chat_history(messages)
  end

  defp add_tool(chain, function) do
    LLMChain.add_tools(chain, function)
  end

  defp add_chat_history(chain, []), do: chain

  defp add_chat_history(chain, messages) do
    Enum.reduce(messages, chain, fn message, acc_chain ->
      message = new_message(message)

      add_message(acc_chain, message)
    end)
  end

  def new_message(%{role: :user, message_text: text}) do
    Message.new_user!(text)
  end

  def new_message(%{role: :assistant, message_text: text}) do
    Message.new_assistant!(text)
  end

  def new_message(%{role: :system, message_text: text}) do
    Message.new_system!(text)
  end

  def add_message(chain, message) do
    LLMChain.add_message(chain, message)
  end
end
