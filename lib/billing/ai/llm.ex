defmodule Billing.Ai.Models do
  alias LangChain.ChatModels.ChatGoogleAI
  alias LangChain.ChatModels.ChatOpenAI

  def get_default_llm do
    get_llm("gemini-2.5-flash")
  end

  def get_llm("gemini-2.5-flash") do
    api_key = System.fetch_env!("GEMINI_API_KEY")
    model = "gemini-2.5-flash"

    ChatGoogleAI.new!(%{model: model, api_key: api_key, stream: true})
  end

  def get_llm("gpt-5-mini") do
    api_key = System.fetch_env!("OPENAI_API_KEY")
    model = "gpt-5-mini"

    ChatOpenAI.new!(%{model: model, api_key: api_key, stream: true})
  end
end
