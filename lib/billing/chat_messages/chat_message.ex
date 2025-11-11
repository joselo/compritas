defmodule Billing.ChatMessages.ChatMessage do
  use Ecto.Schema

  import Ecto.Changeset

  alias LangChain.Message.ContentPart

  schema "chat_messages" do
    field :role, Ecto.Enum, values: [:system, :assistant, :user, :tool], default: :user
    field :hidden, :boolean, default: false
    field :content, :string
    field :tool_calls, {:array, :map}, default: []
    field :tool_results, {:array, :map}, default: []
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_message, attrs, user_scope) do
    chat_message
    |> cast(attrs, [:role, :hidden, :content, :tool_calls, :tool_results])
    |> validate_required([:role, :hidden])
    |> validate_required_content()
    |> serialize_tool_calls()
    |> serialize_tool_results()
    |> put_change(:user_id, user_scope.user.id)
  end

  defp validate_required_content(changeset) do
    case get_change(changeset, :role) do
      role when role in [:assistant, :tool] ->
        validate_required_content_by_tool(changeset)

      _role ->
        validate_required(changeset, [:content])
    end
  end

  defp validate_required_content_by_tool(changeset) do
    tool_calls = get_change(changeset, :tool_calls)
    tool_results = get_change(changeset, :tool_results)

    if tool_calls in [[], nil] || tool_results in [[], nil] do
      put_change(changeset, :hidden, true)
    else
      validate_required(changeset, [:content])
    end
  end

  defp serialize_tool_calls(changeset) do
    case get_change(changeset, :tool_calls) do
      nil ->
        changeset

      tool_calls when is_list(tool_calls) ->
        serialized = Enum.map(tool_calls, &serialize_tool_call/1)
        put_change(changeset, :tool_calls, serialized)
    end
  end

  defp serialize_tool_results(changeset) do
    case get_change(changeset, :tool_results) do
      nil ->
        changeset

      tool_results when is_list(tool_results) ->
        serialized = Enum.map(tool_results, &serialize_tool_result/1)
        put_change(changeset, :tool_results, serialized)
    end
  end

  defp serialize_tool_call(%LangChain.Message.ToolCall{} = tc) do
    %{
      "status" => to_string(tc.status),
      "type" => to_string(tc.type),
      "call_id" => tc.call_id,
      "name" => tc.name,
      "arguments" => tc.arguments,
      "index" => tc.index
    }
  end

  defp serialize_tool_call(map) when is_map(map), do: map

  defp serialize_tool_result(%LangChain.Message.ToolResult{} = tr) do
    content = ContentPart.content_to_string(tr.content)

    %{
      "type" => to_string(tr.type),
      "tool_call_id" => tr.tool_call_id,
      "name" => tr.name,
      "content" => content,
      "processed_content" => tr.processed_content,
      "display_text" => tr.display_text,
      "is_error" => tr.is_error,
      "options" => tr.options
    }
  end

  defp serialize_tool_result(map) when is_map(map), do: map
end
