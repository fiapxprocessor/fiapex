defmodule Fiapx.Producer.Message do
  require Logger

  def producer_message_kafka(video_id, user_id, event_type) do
    message = build_kafka_message(event_type, user_id, video_id)

    case Kaffe.Producer.produce_sync("notifications", [message]) do
      :ok ->
        Logger.info("Video #{video_id} sent with event #{event_type} to user #{user_id}")

      error ->
        Logger.error("Could not send message. Error: #{inspect(error)}")
    end

    {:ok, :messages_send}
  end

  defp build_kafka_message(event_type, user_id, video_id) do
    %{
      key: "producer_message",
      headers: [
        {"timestamp", DateTime.utc_now() |> DateTime.to_string()}
      ],
      value:
        %{
          "message_id" => Ecto.UUID.autogenerate(),
          "event_type" => event_type,
          "user_id" => user_id,
          "video_id" => video_id
        }
        |> Jason.encode!()
    }
  end
end
