defmodule FiapxWeb.VideoPageLiveTest do
  use FiapxWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Fiapx.Repo

  # Usa o helper que registra e faz login automaticamente
  setup :register_and_log_in_user

  test "monta o liveview com vídeos do usuário", %{conn: conn, user: user} do
    {:ok, _view, html} = live(conn, "/videos/upload")

    assert html =~ "Upload de Vídeo"
    assert html =~ "Seus Vídeos"
    assert html =~ user.email
  end

  test "faz upload e processa vídeo", %{conn: conn} do
    source_path = "test/support/sample_video.mp4"
    assert File.exists?(source_path)

    {:ok, view, _html} = live(conn, "/videos/upload")

    upload =
      file_input(view, "#upload-form", :video, [
        %{
          last_modified: 0,
          name: "sample_video.mp4",
          content: File.read!(source_path),
          type: "video/mp4"
        }
      ])

    assert render_upload(upload, "sample_video.mp4")

    before = MapSet.new(Process.list())
    render_click(view, "save")
    :timer.sleep(100)

    after_ = MapSet.new(Process.list())
    diff = MapSet.difference(after_, before)
    [task_pid | _] = Enum.take(diff, 1)

    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), task_pid)
    :timer.sleep(200)

    assert has_element?(view, "form")
  end

  test "deleta o vídeo após upload", %{conn: conn, user: user} do
    source_path = "test/support/sample_video.mp4"
    assert File.exists?(source_path)

    {:ok, view, _html} = live(conn, "/videos/upload")

    file_input(view, "#upload-form", :video, [
      %{
        last_modified: 0,
        name: "sample_video.mp4",
        content: File.read!(source_path),
        type: "video/mp4"
      }
    ])

    render_click(view, "save")
    :timer.sleep(200)

    [] = Fiapx.Media.Persistence.list_user_videos(user.id)

    :timer.sleep(200)

    # Confirma que foi removido
    refute has_element?(view, "video")
  end
end
