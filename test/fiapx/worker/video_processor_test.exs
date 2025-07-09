defmodule Fiapx.Worker.VideoProcessorTest do
  use Fiapx.DataCase, async: false

  alias Fiapx.Accounts.User
  alias Fiapx.Repo

  @sample_video_path "test/support/sample_video.mp4"

  setup do
    # Cria usuário
    {:ok, user} =
      %User{}
      |> User.registration_changeset(%{email: "worker@example.com", password: "SenhaForte123"})
      |> Repo.insert()

    # Copia o vídeo de teste para o local esperado pelo processor
    video_name = "sample_video.mp4"
    upload_path = "/app/uploads/videos"
    video_dest_path = Path.join(upload_path, video_name)

    File.mkdir_p!(upload_path)
    File.cp!(@sample_video_path, video_dest_path)

    # Simula o socket com current_user
    socket = %Phoenix.LiveView.Socket{assigns: %{current_user: user}}

    on_exit(fn ->
      File.rm_rf!("/app/uploads/frames")
      File.rm_rf!("/app/uploads/zips")
      File.rm_rf!(video_dest_path)
    end)

    {:ok, socket: socket, video_name: video_name, video_type: "video/mp4"}
  end
end
