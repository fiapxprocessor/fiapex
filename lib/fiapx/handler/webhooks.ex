defmodule Fiapx.Handler.Webhooks do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "http://app:4001/api"
  plug Tesla.Middleware.JSON

  def create_webhook(attrs) do
    post("/webhooks", attrs)
  end

  @doc """
  Lista todos os webhooks para o usuário informado.
  """
  def list_webhooks(user_id) do
    get("/webhooks", query: [user_id: user_id])
  end

  def delete_webhook(user_id) do
    delete("/webhooks/#{user_id}")
  end
end
