defmodule Fiapx.Worker.VideoProcessor do
  require Logger
  alias Fiapx.Media.Persistence, as: PersistenceVideo
  alias Fiapx.Producer.Message

  def process({name, type, socket, liv_pid}) do
    url_path = "/uploads/videos/#{name}"
    current_user = socket.assigns.current_user

    {:ok, video} =
      PersistenceVideo.create_video(%{
        filename: name,
        content_type: type,
        path: url_path,
        user_id: current_user.id
      })

    absolute_input_path = Path.join(["/app/uploads/videos", name])
    frames_output_dir = Path.join(["/app/uploads/frames", video.id])
    File.mkdir_p!(frames_output_dir)

    Fiapx.Media.FrameExtractor.extract_frames(%{
      input_video: absolute_input_path,
      output_path: frames_output_dir
    })

    case PersistenceVideo.save_frames(video.id, frames_output_dir) do
      {:ok, _} ->
        send(liv_pid, {:video_processed, video})
        Logger.info("Video with id: #{video.id}, was succefull saved")
        Message.producer_message_kafka(video.id, current_user.id, "processed_video")
        {:ok, url_path}

      {:error, reason} ->
        Logger.error("Error occurrs with reason: #{inspect(reason)}")
        Message.producer_message_kafka(video.id, current_user.id, "error_processed_video")
        {:error, url_path}
    end
  end
end
